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
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/snackbar.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/features/routines/logic/gym_progress.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/models/slot_entry.dart';
import 'package:wger/features/routines/providers/gym_log_notifier.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/plate_weights.dart';
import 'package:wger/features/routines/providers/workout_logs_notifier.dart';
import 'package:wger/features/routines/validators.dart';
import 'package:wger/features/routines/widgets/forms/repetitions.dart';
import 'package:wger/features/routines/widgets/forms/rir.dart';
import 'package:wger/features/routines/widgets/forms/weight.dart';
import 'package:wger/features/routines/widgets/gym_mode/elapsed_time.dart';
import 'package:wger/features/routines/widgets/gym_mode/navigation.dart';
import 'package:wger/features/routines/widgets/gym_mode/weight_visual.dart';
import 'package:wger/features/routines/widgets/gym_mode/zone_chip.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The set screen of the gym mode. Everything fits on one screen, there is no
/// scrolling: the exercise, what is planned, the load drawn as a barbell with
/// its plates (or a dumbbell), quick weights, the previous sessions, the reps
/// and the save button.
class LogPage extends ConsumerWidget {
  final _logger = Logger('LogPage');

  final PageController _controller;

  /// Identifies which slot page this widget renders, so it shows its own
  /// content instead of whatever the globally-current page happens to be.
  final String slotUuid;

  LogPage(this._controller, this.slotUuid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final i18n = AppLocalizations.of(context);
    final gymState = ref.watch(gymStateProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    final slotEntryPage = gymState.getSlotPageByUUID(slotUuid);
    if (slotEntryPage == null) {
      _logger.info('getSlotPageByUUID for $slotUuid returned null, showing empty container.');
      return Container();
    }

    final page = gymState.getPageByIndex(slotEntryPage.pageIndex);
    if (page == null) {
      _logger.info(
        'getPageByIndex for ${slotEntryPage.pageIndex} returned null, showing empty container.',
      );
      return Container();
    }
    final setConfigData = slotEntryPage.setConfigData!;

    // Past logs come straight from the local DB (not the gym-mode routine
    // snapshot) so a set logged during this workout shows up right away.
    final pastLogs = ref.watch(
      pastExerciseLogsProvider(
        routineId: gymState.routine.id!,
        exerciseId: setConfigData.exerciseId,
        weeksBack: gymState.logScopeWeeks,
        distinct: gymState.showDistinctLogs,
      ),
    );

    final logPages = page.slotPages.where((e) => e.type == SlotPageType.log).toList();
    final position = setPositionOf(gymState, slotEntryPage.uuid);
    final decoration = slotEntryPage.logDone ? TextDecoration.lineThrough : TextDecoration.none;

    return Column(
      children: [
        NavigationHeader(
          setConfigData.exercise.getTranslation(languageCode).name,
          _controller,
          showSettings: true,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (gymState.showWorkoutDuration) const ElapsedWorkoutTimer(),
              Text(
                i18n.gymMinutesLeft(estimatedMinutesLeft(gymState)),
                key: const ValueKey('gym-minutes-left'),
                style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: position == null
                        ? SectionEyebrow(
                            '${i18n.sets} ${slotEntryPage.setIndex + 1}/${logPages.length}',
                          )
                        : SectionEyebrow(
                            i18n.gymSetHeader(
                              position.exercise,
                              position.exercises,
                              position.set,
                              position.sets,
                            ),
                          ),
                  ),
                  if (setConfigData.type != SlotEntryType.normal) ...[
                    const SizedBox(width: 8),
                    PillChip(
                      setConfigData.type.name.toUpperCase(),
                      tone: ChipTone.brand,
                      height: 22,
                      fontSize: 10.5,
                    ),
                  ],
                  const SizedBox(width: 8),
                  ZoneChip(page),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      setConfigData.exercise.getTranslation(languageCode).name,
                      style: theme.textTheme.titleLarge?.copyWith(height: 1.15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SetDots(pages: logPages, current: slotEntryPage.uuid),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                decoration: BoxDecoration(
                  color: atlas.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 15, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i18n.gymSuggested(setConfigData.textRepr),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: decoration,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    if (setConfigData.weight != null || setConfigData.repetitions != null)
                      PillChip(
                        i18n.gymUseSuggestion,
                        key: const ValueKey('use-suggestion'),
                        tone: ChipTone.inverse,
                        height: 32,
                        fontSize: 13,
                        onTap: () {
                          final log = ref.read(gymLogProvider.notifier);
                          final weight = setConfigData.weight;
                          final reps = setConfigData.repetitions;
                          if (weight != null) {
                            log.setWeight(weight);
                            ref.read(plateCalculatorProvider.notifier).setWeight(weight);
                          }
                          if (reps != null) {
                            log.setRepetitions(reps);
                          }
                        },
                      ),
                  ],
                ),
              ),
              if (setConfigData.comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    setConfigData.comment,
                    style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: LogFormWidget(
              controller: _controller,
              configData: setConfigData,
              pastLogs: _pastLogs(pastLogs),
              pastLogsError: pastLogs.hasError ? pastLogs.error : null,
              pastLogsStack: pastLogs.hasError ? pastLogs.stackTrace : null,
              key: ValueKey('log-form-${slotEntryPage.uuid}'),
            ),
          ),
        ),
        NavigationFooter(_controller),
      ],
    );
  }

  List<Log> _pastLogs(AsyncValue<List<Log>> pastLogs) {
    if (pastLogs.hasError) {
      _logger.warning('Could not load past logs', pastLogs.error, pastLogs.stackTrace);
    }
    return pastLogs.value ?? const <Log>[];
  }
}

/// One dot per set of the exercise: done, current, still to do
class _SetDots extends StatelessWidget {
  const _SetDots({required this.pages, required this.current});

  final List<SlotPageEntry> pages;
  final String current;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in pages)
          AnimatedContainer(
            duration: AtlasMotion.of(context, const Duration(milliseconds: 240)),
            curve: AtlasMotion.curve,
            margin: const EdgeInsets.only(left: 5),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.logDone ? atlas.ok : Colors.transparent,
              border: Border.all(
                color: p.logDone
                    ? atlas.ok
                    : p.uuid == current
                    ? primary
                    : atlas.line2,
                width: 2,
              ),
            ),
          ),
      ],
    );
  }
}

class LogFormWidget extends ConsumerStatefulWidget {
  final PageController controller;
  final SetConfigData configData;

  /// Earlier logs of the exercise, offered as one-tap chips
  final List<Log> pastLogs;
  final Object? pastLogsError;
  final StackTrace? pastLogsStack;

  const LogFormWidget({
    super.key,
    required this.controller,
    required this.configData,
    this.pastLogs = const [],
    this.pastLogsError,
    this.pastLogsStack,
  });

  @override
  _LogFormWidgetState createState() => _LogFormWidgetState();
}

class _LogFormWidgetState extends ConsumerState<LogFormWidget> {
  final _form = GlobalKey<FormState>();

  /// Weights offered as quick chips around the planned weight
  List<num> _quickWeights() {
    final planned = widget.configData.weight;
    if (planned == null) {
      return const [];
    }
    final step = widget.configData.weightRounding ?? 1.25;
    final inc = step < 2.5 ? step * 2 : step;
    final out = <num>[];
    for (var k = -3; k <= 3; k++) {
      final w = planned + inc * k;
      if (w >= 0 && !out.contains(w)) {
        out.add(w);
      }
    }
    return out;
  }

  String _fmt(num? v) {
    if (v == null) {
      return '–';
    }
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  Future<void> _save(Log log) async {
    final i18n = AppLocalizations.of(context);
    final logProvider = ref.read(workoutLogProvider);

    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    }
    _form.currentState!.save();

    final error = validateWorkoutLogCrossField(
      repetitions: log.repetitions,
      weight: log.weight,
      i18n: i18n,
    );
    if (error != null) {
      showSnackbar(context, error);
      return;
    }

    final gymState = ref.read(gymStateProvider);
    final gymProvider = ref.read(gymStateProvider.notifier);
    final page = gymState.getSlotEntryPageByIndex()!;

    // A failed write is intentionally left to propagate to the global
    // error handler; the success path below is then skipped.
    await logProvider.addEntry(log, dayId: gymState.dayId);
    if (!mounted) {
      return;
    }

    gymProvider.markSlotPageAsDone(page.uuid, isDone: true);
    showSnackbar(
      context,
      i18n.successfullySaved,
      center: true,
      duration: const Duration(seconds: 2),
    );
    widget.controller.nextPage(
      duration: DEFAULT_ANIMATION_DURATION,
      curve: DEFAULT_ANIMATION_CURVE,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final log = ref.watch(gymLogProvider);

    // The log is populated when the page becomes current: the PageView can lay
    // out and mount this page before that happens, so guard against null.
    if (log == null) {
      return const SizedBox.shrink();
    }

    final quick = _quickWeights();
    final past = widget.pastLogs;
    final dateFormat = DateFormat.Md(Localizations.localeOf(context).languageCode);
    final exercise = widget.configData.exercise;

    // Not enough room for the whole page (a very small window): let it scroll
    // instead of overflowing
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 470;

        final weightCard = AtlasCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            children: [
              if (!compact)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: WeightVisual(exercise: exercise, weight: log.weight),
                  ),
                ),
              WeightInputWidget(
                key: const ValueKey('logs-weight-widget'),
                stepper: true,
                value: log.weight,
                valueChange: widget.configData.weightRounding,
                unit: log.weightUnitObj,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(gymLogProvider.notifier).setWeight(v);
                    ref.read(plateCalculatorProvider.notifier).setWeight(v);
                  }
                },
                onUnitChanged: (v) {
                  if (v != null) {
                    ref.read(gymLogProvider.notifier).setWeightUnit(v);
                  }
                },
              ),
            ],
          ),
        );

        final content = <Widget>[
          if (compact) weightCard else Expanded(child: weightCard),
          if (quick.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final w in quick)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PillChip(
                        _fmt(w),
                        key: ValueKey('quick-weight-$w'),
                        mono: true,
                        height: 38,
                        fontSize: 13,
                        selected: log.weight == w,
                        onTap: () {
                          ref.read(gymLogProvider.notifier).setWeight(w);
                          ref.read(plateCalculatorProvider.notifier).setWeight(w);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (widget.pastLogsError != null) ...[
            const SizedBox(height: 8),
            StreamErrorIndicator(widget.pastLogsError!, stacktrace: widget.pastLogsStack),
          ] else if (past.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 14, color: atlas.ink3),
                        const SizedBox(width: 4),
                        Text(
                          i18n.labelWorkoutLogs,
                          style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                        ),
                      ],
                    ),
                  ),
                  for (final pastLog in past.take(4))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PillChip(
                        '${dateFormat.format(pastLog.date)}  ${_fmt(pastLog.repetitions)}×${_fmt(pastLog.weight)}',
                        key: ValueKey('past-log-${pastLog.id}'),
                        mono: true,
                        height: 32,
                        fontSize: 11.5,
                        onTap: () {
                          ref.read(gymLogProvider.notifier).setLog(pastLog, exercise: exercise);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          showSnackbar(context, i18n.dataCopied);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          RiRInputWidget(
            key: const ValueKey('rir-input-widget'),
            log.rir,
            showHelp: true,
            onChanged: (value) {
              log.rir = value == '' ? null : num.parse(value);
            },
          ),
          Row(
            children: [
              Container(
                width: 190,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: atlas.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: atlas.line),
                ),
                child: RepetitionInputWidget(
                  key: const ValueKey('logs-reps-widget'),
                  stepper: true,
                  value: log.repetitions,
                  valueChange: widget.configData.repetitionsRounding,
                  unit: log.repetitionsUnitObj,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(gymLogProvider.notifier).setRepetitions(v);
                    }
                  },
                  onUnitChanged: (v) {
                    if (v != null) {
                      ref.read(gymLogProvider.notifier).setRepetitionUnit(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: FilledButton.icon(
                    key: const ValueKey('save-log-button'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    icon: const Icon(Icons.check, size: 22),
                    label: Text(i18n.save),
                    onPressed: () => _save(log),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ];

        return Form(
          key: _form,
          child: compact
              ? SingleChildScrollView(child: Column(children: content))
              : Column(children: content),
        );
      },
    );
  }
}
