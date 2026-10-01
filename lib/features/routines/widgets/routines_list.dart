/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2020 - 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/core/widgets/text_prompt.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/routine_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class RoutinesList extends ConsumerStatefulWidget {
  const RoutinesList();

  @override
  ConsumerState<RoutinesList> createState() => _RoutinesListState();
}

class _RoutinesListState extends ConsumerState<RoutinesList> {
  int? _loadingRoutine;

  @override
  Widget build(BuildContext context) {
    final dateFormat = localizedDate(context);
    final routineProvider = ref.read(routinesRiverpodProvider.notifier);
    final routinesAsync = ref.watch(routinesRiverpodProvider);
    final isOnline = ref.watch(networkStatusProvider);

    return AsyncValueWidget<RoutinesState>(
      value: routinesAsync,
      loggerName: 'RoutinesList',
      data: (state) {
        final routines = state.routines;
        if (routines.isEmpty) {
          return const TextPrompt();
        }
        final active = state.currentRoutine;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: routines.length + (active == null ? 0 : 1),
          itemBuilder: (context, i) {
            if (active != null && i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ActiveRoutineCard(
                  active,
                  onOpen: () => Navigator.of(context).pushNamed(
                    RoutineScreen.routeName,
                    arguments: active.id,
                  ),
                ),
              );
            }
            final index = active == null ? i : i - 1;
            final currentRoutine = routines[index];
            final routineId = currentRoutine.id!;

            // The routine structure is fetched via REST. Offline it can only
            // be opened if it was already loaded earlier
            final canOpen = isOnline || currentRoutine.isHydrated;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                enabled: canOpen,
                contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                leading: const IconBadge(Icons.fitness_center, size: 44),
                onTap: canOpen
                    ? () async {
                        if (isOnline) {
                          setState(() {
                            _loadingRoutine = routineId;
                          });
                          try {
                            await routineProvider.fetchAndSetRoutineFull(routineId);
                          } finally {
                            if (mounted) {
                              setState(() => _loadingRoutine = null);
                            }
                          }
                        }

                        if (context.mounted) {
                          Navigator.of(context).pushNamed(
                            RoutineScreen.routeName,
                            arguments: routineId,
                          );
                        }
                      }
                    : null,
                title: Text(currentRoutine.name),
                subtitle: Text(
                  '${dateFormat.format(currentRoutine.start)}'
                  ' - ${dateFormat.format(currentRoutine.end)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!canOpen) const Icon(Icons.cloud_off),
                    if (_loadingRoutine == currentRoutine.id)
                      const IconButton(
                        icon: CircularProgressIndicator(),
                        onPressed: null,
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: context.atlas.ink3,
                        tooltip: AppLocalizations.of(context).delete,
                        onPressed: () => showConfirmDeleteDialog(
                          context,
                          itemName: currentRoutine.name,
                          onConfirm: () => routineProvider.deleteRoutine(currentRoutine.id!),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The running routine: name, dates and how far into its weeks we are
class _ActiveRoutineCard extends StatelessWidget {
  const _ActiveRoutineCard(this.routine, {required this.onOpen});

  final Routine routine;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final dateFormat = localizedDate(context);

    final totalDays = routine.end.difference(routine.start).inDays.clamp(1, 100000);
    final elapsed = DateTime.now().difference(routine.start).inDays.clamp(0, totalDays);
    final weeks = (totalDays / 7).ceil().clamp(1, 16);
    final currentWeek = (elapsed / 7).floor().clamp(0, weeks - 1);

    return AtlasCard(
      hero: true,
      radius: AtlasRadius.dialog,
      padding: const EdgeInsets.all(18),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionEyebrow(i18n.labelWorkoutPlan, color: atlas.onHero.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            routine.name,
            style: theme.textTheme.headlineMedium?.copyWith(color: atlas.onHero),
          ),
          const SizedBox(height: 2),
          Text(
            '${dateFormat.format(routine.start)} - ${dateFormat.format(routine.end)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: atlas.onHero.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var w = 0; w < weeks; w++) ...[
                if (w > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AtlasRadius.pill),
                      color: atlas.onHero.withValues(alpha: w <= currentWeek ? 0.85 : 0.18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
