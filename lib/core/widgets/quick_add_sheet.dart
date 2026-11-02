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
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/coach/screens/coach_screen.dart';
import 'package:wger/features/gallery/widgets/forms.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/measurements/screens/measurement_categories_screen.dart';
import 'package:wger/features/measurements/screens/weight_screen.dart';
import 'package:wger/features/measurements/widgets/weight_form.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Opens the "Log" sheet of the central plus button: one tile per thing the
/// user records. [onSelectTab] switches the home tabs (0 dashboard, 1 workout,
/// 2 nutrition, 3 progress) for the tiles that live in one.
Future<void> showQuickAddSheet(BuildContext context, {required ValueChanged<int> onSelectTab}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => QuickAddSheet(onSelectTab: onSelectTab, rootContext: context),
  );
}

class QuickAddSheet extends ConsumerWidget {
  const QuickAddSheet({super.key, required this.onSelectTab, required this.rootContext});

  final ValueChanged<int> onSelectTab;

  /// Context of the screen below the sheet: the sheet's own is gone once it is
  /// popped, and the destinations are pushed on the screen's navigator.
  final BuildContext rootContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final navigator = Navigator.of(rootContext);

    final routine = ref.watch(routinesRiverpodProvider).value?.currentRoutine;
    final today = routine?.dayDataCurrentIterationFiltered.firstWhereOrNull(
      (d) => !d.day!.isRest && d.date.isSameDayAs(DateTime.now()),
    );
    final weightCategory = ref.watch(bodyWeightCategoryOnlyProvider).value;
    final isOnline = ref.watch(networkStatusProvider);

    void close() => Navigator.of(context).pop();

    final tiles = [
      _Tile(
        key: const ValueKey('quick-add-workout'),
        icon: Icons.fitness_center,
        color: Theme.of(context).colorScheme.primary,
        title: today?.day?.name ?? i18n.labelBottomNavWorkout,
        subtitle: today == null ? i18n.quickAddWorkoutNone : i18n.quickAddWorkoutHint,
        onTap: () {
          close();
          if (today == null) {
            onSelectTab(1);
          } else {
            navigator.pushNamed(
              GymModeScreen.routeName,
              arguments: GymModeArguments(today.day!.routineId, today.day!.id!, today.iteration),
            );
          }
        },
      ),
      _Tile(
        key: const ValueKey('quick-add-meal'),
        icon: Icons.restaurant,
        color: atlas.carbs,
        title: i18n.quickAddMeal,
        subtitle: i18n.quickAddMealHint,
        onTap: () {
          close();
          onSelectTab(2);
        },
      ),
      _Tile(
        key: const ValueKey('quick-add-coach'),
        icon: Icons.auto_awesome,
        color: Theme.of(context).colorScheme.primary,
        title: i18n.coach,
        subtitle: i18n.quickAddCoachHint,
        onTap: () {
          close();
          navigator.pushNamed(CoachScreen.routeName);
        },
      ),
      _Tile(
        key: const ValueKey('quick-add-weight'),
        icon: Icons.monitor_weight_outlined,
        color: atlas.ok,
        title: i18n.weight,
        subtitle: i18n.quickAddWeightHint,
        onTap: () {
          close();
          if (weightCategory == null) {
            navigator.pushNamed(WeightScreen.routeName);
          } else {
            navigator.pushNamed(
              FormScreen.routeName,
              arguments: FormScreenArguments(i18n.newEntry, WeightForm(weightCategory)),
            );
          }
        },
      ),
      _Tile(
        key: const ValueKey('quick-add-measurement'),
        icon: Icons.straighten,
        color: atlas.fat,
        title: i18n.measurement,
        subtitle: i18n.quickAddMeasurementHint,
        onTap: () {
          close();
          navigator.pushNamed(MeasurementCategoriesScreen.routeName);
        },
      ),
      _Tile(
        key: const ValueKey('quick-add-photo'),
        icon: Icons.photo_camera_outlined,
        color: atlas.accent,
        title: i18n.quickAddPhoto,
        subtitle: i18n.quickAddPhotoHint,
        // Uploading an image is a binary REST call, so it needs connectivity
        onTap: isOnline
            ? () {
                close();
                navigator.pushNamed(
                  FormScreen.routeName,
                  arguments: FormScreenArguments(i18n.addImage, ImageForm(), hasListView: true),
                );
              }
            : null,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(i18n.quickAddTitle, style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                style: IconButton.styleFrom(
                  side: BorderSide(color: atlas.line),
                  fixedSize: const Size.square(44),
                ),
                onPressed: close,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.84,
            children: tiles,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);

    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: AtlasCard(
        onTap: onTap,
        color: atlas.surface2,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, size: 40, color: color, background: atlas.surface3),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
