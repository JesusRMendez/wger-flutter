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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/exercises/widgets/exercises.dart';
import 'package:wger/features/routines/logic/gym_progress.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/workout_logs_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/navigation.dart';
import 'package:wger/features/routines/widgets/gym_mode/next_exercise_preview.dart';
import 'package:wger/features/routines/widgets/gym_mode/zone_chip.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The introduction of an exercise, shown before its first set: where it sits
/// in the workout, what is planned, how it is done, and how it went last time.
class ExerciseOverview extends ConsumerWidget {
  final _logger = Logger('ExerciseOverview');
  final PageController _controller;

  /// Identifies which slot page this widget renders, so it shows its own
  /// content instead of whatever the globally-current page happens to be.
  final String slotUuid;

  ExerciseOverview(this._controller, this.slotUuid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymStateProvider);
    final page = gymState.getSlotPageByUUID(slotUuid);

    if (page == null) {
      _logger.info(
        'getSlotPageByUUID for $slotUuid returned null, showing empty container.',
      );
      return Container();
    }
    final config = page.setConfigData!;
    final exercise = config.exercise;
    final entry = gymState.getPageByIndex(page.pageIndex);

    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final name = exercise.getTranslation(Localizations.localeOf(context).languageCode).name;

    final logPages = entry?.slotPages.where((s) => s.type == SlotPageType.log).toList() ?? [];
    final position = logPages.isEmpty ? null : setPositionOf(gymState, logPages.first.uuid);

    final reps = config.repetitions == null
        ? null
        : formatRange(config.repetitions!, config.maxRepetitions);
    final rest = config.restTime;

    final past = ref.watch(
      pastExerciseLogsProvider(
        routineId: gymState.routine.id!,
        exerciseId: config.exerciseId,
        weeksBack: gymState.logScopeWeeks,
        distinct: gymState.showDistinctLogs,
      ),
    );
    final Log? last = past.value?.firstOrNull;

    return Column(
      children: [
        NavigationHeader(
          name,
          _controller,
          center: position == null
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionEyebrow(i18n.gymIntroEyebrow(position.exercise, position.exercises)),
                  ],
                ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (entry != null) ZoneChip(entry),
                    if (reps != null && logPages.isNotEmpty)
                      PillChip(
                        i18n.gymIntroSets('${logPages.length}', reps),
                        key: const ValueKey('intro-sets'),
                        mono: true,
                        height: 28,
                      ),
                    if (rest != null)
                      PillChip(
                        i18n.gymIntroRest(formatRest(rest)),
                        key: const ValueKey('intro-rest'),
                        mono: true,
                        height: 28,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ExerciseDetail(exercise),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: i18n.gymSuggested(
                          plannedSetSummary(
                            config,
                            translate: (value) => getServerStringTranslation(value, context),
                          ),
                        ),
                      ),
                      if (last != null)
                        TextSpan(
                          text:
                              ' · ${i18n.gymIntroLast('${formatRange(last.repetitions ?? 0, null)} × ${formatRange(last.weight ?? 0, null)}')}',
                        ),
                    ],
                  ),
                  key: const ValueKey('intro-suggested'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2),
                ),
              ),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: const ValueKey('intro-start'),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(i18n.gymIntroStart(1)),
                  style: FilledButton.styleFrom(
                    textStyle: theme.textTheme.titleMedium,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => _controller.nextPage(
                    duration: DEFAULT_ANIMATION_DURATION,
                    curve: DEFAULT_ANIMATION_CURVE,
                  ),
                ),
              ),
            ],
          ),
        ),
        NavigationFooter(_controller),
      ],
    );
  }
}
