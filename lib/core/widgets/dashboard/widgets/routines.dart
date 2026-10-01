/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
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

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/date.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/core.dart';
import 'package:wger/core/widgets/dashboard/widgets/nothing_found.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/guided_mode.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';
import 'package:wger/features/routines/screens/routine_screen.dart';
import 'package:wger/features/routines/widgets/forms/routine.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class DashboardRoutineWidget extends ConsumerStatefulWidget {
  const DashboardRoutineWidget();

  @override
  _DashboardRoutineWidgetState createState() => _DashboardRoutineWidgetState();
}

class _DashboardRoutineWidgetState extends ConsumerState<DashboardRoutineWidget> {
  var _showDetail = false;

  /// Renders the dashboard card shell so loading / error / empty / data
  /// states all share the same outline (icon + title) instead of the card
  /// hopping around. The trailing widget changes per state.
  Widget _shell(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget trailing,
    Widget? child,
  }) {
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.fitness_center,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
          ?child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = localizedDate(context);
    final i18n = AppLocalizations.of(context);

    final asyncState = ref.watch(routinesRiverpodProvider);
    final isOnline = ref.watch(networkStatusProvider);

    // Auto-hydrate the current routine once it appears in the sparse list
    //
    // Gate the watch on the routine's own `isHydrated` flag (which lives on the
    // keep-alive routines provider and survives remounts) so a completed load
    // never re-fires. While offline the structure fetch is unavailable, so it
    // is skipped. A reconnect re-runs build and starts the load.
    final currentRoutine = asyncState.value?.currentRoutine;
    final currentId = currentRoutine?.id;
    final hydration = isOnline && currentId != null && !currentRoutine!.isHydrated
        ? ref.watch(routineHydrationProvider(currentId))
        : null;

    return AsyncValueWidget<RoutinesState>(
      value: asyncState,
      loggerName: 'DashboardRoutineWidget',
      loading: _shell(
        context,
        title: i18n.labelWorkoutPlan,
        subtitle: '',
        trailing: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorBuilder: (e, st) => _shell(
        context,
        title: i18n.labelWorkoutPlan,
        subtitle: i18n.anErrorOccurred,
        trailing: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        child: StreamErrorIndicator(e, stacktrace: st),
      ),
      data: (state) {
        final routine = state.currentRoutine;

        // Offline and never fetched: the structure is unavailable, so lock
        // the detail UI instead of showing an empty block.
        final detailsLocked = routine != null && !isOnline && !routine.isHydrated;

        if (routine == null) {
          return _shell(
            context,
            title: i18n.labelWorkoutPlan,
            subtitle: '',
            trailing: const SizedBox(),
            child: NothingFound(
              i18n.noRoutines,
              i18n.newRoutine,
              RoutineForm(Routine.empty()),
            ),
          );
        }

        final isHydrating = hydration?.isLoading ?? false;

        final days = routine.dayDataCurrentIterationFiltered;
        final today = days.firstWhereOrNull(
          (d) => !d.day!.isRest && d.date.isSameDayAs(DateTime.now()),
        );

        final card = AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHeader(
                icon: Icons.fitness_center,
                title: routine.name,
                subtitle: '${dateFormat.format(routine.start)} - ${dateFormat.format(routine.end)}',
                trailing: isHydrating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : detailsLocked
                    ? Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.outline)
                    : IconButton(
                        // The toggle is meaningless while the day data is still
                        // loading or unavailable offline, so it is not shown then.
                        tooltip: i18n.toggleDetails,
                        icon: _showDetail ? const Icon(Icons.info) : const Icon(Icons.info_outline),
                        onPressed: () => setState(() => _showDetail = !_showDetail),
                      ),
              ),
              const SizedBox(height: 12),
              if (isHydrating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!detailsLocked)
                DetailContentWidget(days, _showDetail),
              TextButton(
                onPressed: detailsLocked
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(
                          RoutineScreen.routeName,
                          arguments: routine.id,
                        );
                      },
                child: Text(i18n.goToDetailPage),
              ),
            ],
          ),
        );

        // The workout of today leads, the whole plan follows below it
        if (today == null || isHydrating || detailsLocked) {
          return card;
        }
        return Column(
          children: [
            TodayHero(today),
            const SizedBox(height: 12),
            card,
          ],
        );
      },
    );
  }
}

/// The workout of today as the loud call-to-action card of the dashboard
class TodayHero extends StatelessWidget {
  final DayData dayData;

  const TodayHero(this.dayData, {super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final day = dayData.day!;

    final exercises = dayData.slots.length;
    final sets = dayData.slots.fold<int>(
      0,
      (sum, slot) => sum + slot.setConfigs.fold<int>(0, (s, c) => s + (c.nrOfSets ?? 1).toInt()),
    );
    final args = GymModeArguments(day.routineId, day.id!, dayData.iteration);

    return AtlasCard(
      hero: true,
      radius: AtlasRadius.dialog,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionEyebrow(i18n.todaysWorkout, color: atlas.onHero.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            day.nameWithType,
            style: theme.textTheme.headlineMedium?.copyWith(color: atlas.onHero),
          ),
          if (day.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              day.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: atlas.onHero.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '$exercises ${i18n.exercises} · $sets ${i18n.sets}',
            style: theme.textTheme.bodySmall?.copyWith(color: atlas.onHero.withValues(alpha: 0.66)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('dashboard-start-today'),
                  style: FilledButton.styleFrom(
                    backgroundColor: atlas.onHero,
                    foregroundColor: theme.colorScheme.onSurface,
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: Text(i18n.start),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(GymModeScreen.routeName, arguments: args),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: i18n.guidedMode,
                style: IconButton.styleFrom(
                  backgroundColor: atlas.onHero.withValues(alpha: 0.1),
                  foregroundColor: atlas.onHero,
                  fixedSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.timer_outlined),
                onPressed: () =>
                    Navigator.of(context).pushNamed(GuidedModeScreen.routeName, arguments: args),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DetailContentWidget extends StatelessWidget {
  final List<DayData> dayDataList;
  final bool showDetail;

  const DetailContentWidget(this.dayDataList, this.showDetail, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...dayDataList.where((dayData) => dayData.day != null).map((dayData) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    if (dayData.date.isSameDayAs(DateTime.now())) ...[
                      PillChip(
                        AppLocalizations.of(context).today,
                        tone: ChipTone.brand,
                        height: 22,
                        fontSize: 11,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        dayData.day == null || dayData.day!.isRest
                            ? AppLocalizations.of(context).restDay
                            : dayData.day!.nameWithType,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: MutedText(
                        dayData.day != null ? dayData.day!.description : '',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dayData.day == null || dayData.day!.isRest)
                      const Icon(Icons.hotel)
                    else ...[
                      IconButton(
                        tooltip: AppLocalizations.of(context).guidedMode,
                        icon: const Icon(Icons.timer_outlined),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            GuidedModeScreen.routeName,
                            arguments: GymModeArguments(
                              dayData.day!.routineId,
                              dayData.day!.id!,
                              dayData.iteration,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context).gymMode,
                        icon: const Icon(Icons.play_arrow),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            GymModeScreen.routeName,
                            arguments: GymModeArguments(
                              dayData.day!.routineId,
                              dayData.day!.id!,
                              dayData.iteration,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              ...dayData.slots.map(
                (slotData) => SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...slotData.setConfigs.map(
                        (s) => showDetail
                            ? Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.exercise
                                            .getTranslation(
                                              Localizations.localeOf(context).languageCode,
                                            )
                                            .name,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: MutedText(
                                          s.textRepr,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              )
                            : Container(),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
            ],
          );
        }),
      ],
    );
  }
}
