/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/exercises/widgets/images.dart';
import 'package:wger/features/glossary/widgets/glossary_widgets.dart';
import 'package:wger/features/routines/logic/guided_engine.dart';
import 'package:wger/features/routines/logic/music_bpm.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/countdown_alert.dart';
import 'package:wger/features/routines/widgets/gym_mode/next_exercise_preview.dart';
import 'package:wger/features/routines/widgets/music_bpm_card.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

String formatGuidedTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Plays the sound and haptic feedback of an alert
void playCountdownAlert(CountdownAlert alert) {
  switch (alert) {
    case CountdownAlert.none:
      break;
    case CountdownAlert.warning:
      HapticFeedback.mediumImpact();
      Timer(const Duration(milliseconds: 150), HapticFeedback.mediumImpact);
      SystemSound.play(SystemSoundType.alert);
    case CountdownAlert.tick:
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    case CountdownAlert.end:
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
  }
}

/// Runs the [steps] as timed intervals. Uses the alert settings of the gym mode.
class GuidedRoutineView extends ConsumerStatefulWidget {
  final List<GuidedStep> steps;

  /// Called when the user leaves with the close button
  final VoidCallback? onClose;

  /// Name of the day, shown on the setup page
  final String? title;

  /// Starts with the setup page (the exercises, work and rest adjustments and
  /// the estimated time). Off, the routine starts right away.
  final bool showSetup;

  const GuidedRoutineView(this.steps, {super.key, this.onClose, this.title, this.showSetup = true});

  @override
  ConsumerState<GuidedRoutineView> createState() => _GuidedRoutineViewState();
}

class _GuidedRoutineViewState extends ConsumerState<GuidedRoutineView> {
  late GuidedEngine _engine = GuidedEngine(widget.steps);
  Timer? _timer;
  final _repsController = TextEditingController();

  late bool _started = !widget.showSetup;
  int _workDelta = 0;
  int _restDelta = 0;

  @override
  void initState() {
    super.initState();
    if (_started) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
  }

  List<GuidedStep> get _adjustedSteps => [
    for (final s in widget.steps) s.adjusted(work: _workDelta, rest: _restDelta),
  ];

  void _start() {
    setState(() {
      _engine = GuidedEngine(_adjustedSteps);
      _started = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repsController.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) {
      return;
    }
    final settings = ref.read(gymStateProvider);
    late CountdownAlert alert;
    setState(() {
      alert = _engine.tick(
        alertAt20s: settings.alertAt20s,
        alertLast5s: settings.alertLast5s,
        alertAtEnd: settings.alertOnCountdownEnd,
      );
    });
    playCountdownAlert(alert);
  }

  String _name(GuidedStep step) =>
      step.exercise.getTranslation(Localizations.localeOf(context).languageCode).name;

  String _summary(GuidedStep step) => plannedSetSummary(
    step.config,
    translate: (value) => getServerStringTranslation(value, context),
  );

  MusicPhase get _musicPhase {
    switch (_engine.phase) {
      case GuidedPhase.countdown:
        return MusicPhase.warmUp;
      case GuidedPhase.rest:
      case GuidedPhase.done:
        return MusicPhase.rest;
      // Asking for the reps comes right after the work, the music shouldn't
      // switch to the rest tempo for that short moment
      case GuidedPhase.askReps:
      case GuidedPhase.work:
        return _engine.currentStep?.kind == GuidedKind.timed
            ? MusicPhase.hiit
            : MusicPhase.strength;
    }
  }

  Future<void> _jump(int target) async {
    final warning = _engine.jumpWarning(target);
    if (warning != GuidedJumpWarning.none) {
      final i18n = AppLocalizations.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const ValueKey('guided-jump-warning'),
          content: Text(
            warning == GuidedJumpWarning.skipsAhead
                ? i18n.guidedJumpSkipsWarning
                : i18n.guidedJumpRepeatsWarning,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            TextButton(
              key: const ValueKey('guided-jump-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(i18n.guidedJumpAnyway),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) {
        return;
      }
    }
    setState(() => _engine.jumpTo(target));
  }

  void _openOverview() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _Overview(
          engine: _engine,
          nameOf: _name,
          summaryOf: _summary,
          onJump: (index) {
            Navigator.of(ctx).pop();
            _jump(index);
          },
          onMove: (slot, up) {
            _engine.moveSlot(slot, up: up);
            setSheetState(() {});
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final step = _engine.currentStep;
    final phase = _engine.phase;

    final atlas = context.atlas;

    if (!_started) {
      return _GuidedSetup(
        steps: widget.steps,
        title: widget.title,
        workDelta: _workDelta,
        restDelta: _restDelta,
        nameOf: _name,
        summaryOf: _summary,
        onWork: (v) => setState(() => _workDelta = v),
        onRest: (v) => setState(() => _restDelta = v),
        onStart: _start,
        onClose: widget.onClose,
      );
    }

    final circle = IconButton.styleFrom(
      backgroundColor: atlas.card,
      side: BorderSide(color: atlas.line),
      fixedSize: const Size(40, 40),
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
    );
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          IconButton(
            style: circle,
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              i18n.guidedMode,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const GlossaryHelpButton(),
          const SizedBox(width: 6),
          IconButton(
            style: circle,
            key: const ValueKey('guided-overview-button'),
            icon: const Icon(Icons.menu, size: 20),
            tooltip: i18n.jumpTo,
            onPressed: _openOverview,
          ),
        ],
      ),
    );

    if (phase == GuidedPhase.done || step == null) {
      return Column(
        children: [
          header,
          Expanded(child: _DoneSummary(_engine, _name)),
        ],
      );
    }

    final timed = _engine.remainingSeconds != null;
    final phaseLabel = switch (phase) {
      GuidedPhase.countdown => i18n.guidedGetReady,
      GuidedPhase.work => i18n.guidedWork,
      GuidedPhase.rest => i18n.guidedRest,
      GuidedPhase.askReps => i18n.guidedHowManyReps,
      GuidedPhase.done => '',
    };

    final shown = phase == GuidedPhase.rest ? _engine.nextStep ?? step : step;
    final steps = _engine.steps;
    final left = (estimateGuidedSeconds(steps) - _engine.elapsedSeconds).clamp(0, 1 << 30);

    final ringColor = switch (phase) {
      GuidedPhase.rest => atlas.ok,
      GuidedPhase.countdown => atlas.warn,
      _ => theme.colorScheme.primary,
    };
    final phaseChip = PillChip(
      phaseLabel,
      key: const ValueKey('guided-phase-chip'),
      tone: switch (phase) {
        GuidedPhase.rest => ChipTone.ok,
        GuidedPhase.countdown => ChipTone.warn,
        _ => ChipTone.brand,
      },
      height: 32,
      fontSize: 13,
    );

    // The ring: the time left of a timed phase, otherwise the set within the
    // sets of the exercise, so a reps set has a progress visual as well
    Widget ring() {
      if (timed) {
        return ProgressRing(
          size: 232,
          strokeWidth: 14,
          value: _engine.phaseTotalSeconds == 0
              ? 0
              : _engine.remainingSeconds! / _engine.phaseTotalSeconds,
          color: ringColor,
          duration: const Duration(milliseconds: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MonoText(
                formatGuidedTime(_engine.remainingSeconds!),
                key: const ValueKey('guided-time'),
                size: 56,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                phaseLabel,
                key: const ValueKey('guided-phase'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ringColor,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        );
      }
      return ProgressRing(
        key: const ValueKey('guided-reps-ring'),
        size: 232,
        strokeWidth: 14,
        value: step.totalRounds == 0 ? 0 : step.round / step.totalRounds,
        color: ringColor,
        duration: const Duration(milliseconds: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MonoText(
              _summary(step),
              size: 30,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 6),
            Text(
              phaseLabel,
              key: const ValueKey('guided-phase'),
              style: theme.textTheme.labelMedium?.copyWith(color: ringColor, letterSpacing: 0.9),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            key: const ValueKey('guided-segments'),
            spacing: 4,
            children: [
              for (final (i, s) in steps.indexed)
                Expanded(
                  child: AnimatedContainer(
                    duration: AtlasMotion.of(context),
                    curve: AtlasMotion.curve,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AtlasRadius.pill),
                      color: _engine.isCompleted(s)
                          ? atlas.ok
                          : i == _engine.stepIndex
                          ? theme.colorScheme.primary
                          : atlas.surface3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              SectionEyebrow(i18n.guidedProgressLine(_engine.stepIndex + 1, steps.length)),
              const Spacer(),
              MonoText(
                '${formatGuidedTime(_engine.elapsedSeconds)} · ${i18n.guidedTimeLeft('≈ ${formatGuidedTime(left)}')}',
                key: const ValueKey('guided-elapsed'),
                size: 12,
                weight: FontWeight.w500,
                color: atlas.ink3,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (phase != GuidedPhase.rest) ...[
                Row(
                  spacing: 8,
                  children: [
                    phaseChip,
                    PillChip(
                      i18n.guidedSetOf(step.round, step.totalRounds),
                      key: const ValueKey('guided-round'),
                      height: 32,
                      fontSize: 13,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _name(step),
                        key: const ValueKey('guided-exercise'),
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: ExerciseImageWidget(image: step.exercise.getMainImage, height: 56),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _summary(step),
                    key: const ValueKey('guided-summary'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2),
                  ),
                ),
              ] else
                _NextIntro(
                  key: const ValueKey('guided-next-intro'),
                  step: shown,
                  name: _name(shown),
                  summary: _summary(shown),
                  isLast: _engine.nextStep == null,
                ),
              const SizedBox(height: 20),
              Center(child: ring()),
              const SizedBox(height: 20),
              if (phase == GuidedPhase.askReps)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('guided-reps-field'),
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: i18n.reps),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const ValueKey('guided-reps-confirm'),
                      onPressed: () {
                        final reps = int.tryParse(_repsController.text.trim());
                        if (reps == null || reps < 0) {
                          return;
                        }
                        _repsController.clear();
                        setState(() => _engine.submitReps(reps));
                      },
                      child: Text(i18n.save),
                    ),
                  ],
                ),
              if (phase == GuidedPhase.work)
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    key: const ValueKey('guided-done-button'),
                    icon: const Icon(Icons.check),
                    style: FilledButton.styleFrom(
                      textStyle: theme.textTheme.titleMedium,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () => setState(_engine.done),
                    label: Text(i18n.done),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 24,
                children: [
                  IconButton(
                    key: const ValueKey('guided-previous-button'),
                    style: circle.copyWith(fixedSize: const WidgetStatePropertyAll(Size(52, 52))),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: i18n.guidedPrevious,
                    onPressed: _engine.stepIndex > 0 ? () => _jump(_engine.stepIndex - 1) : null,
                  ),
                  IconButton(
                    key: const ValueKey('guided-pause-button'),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      fixedSize: const Size(72, 72),
                      minimumSize: const Size(72, 72),
                    ),
                    iconSize: 32,
                    icon: Icon(_engine.isPaused ? Icons.play_arrow : Icons.pause),
                    tooltip: _engine.isPaused ? i18n.guidedResume : i18n.pause,
                    onPressed: () => setState(_engine.isPaused ? _engine.resume : _engine.pause),
                  ),
                  IconButton(
                    key: const ValueKey('guided-skip-button'),
                    style: circle.copyWith(fixedSize: const WidgetStatePropertyAll(Size(52, 52))),
                    icon: const Icon(Icons.chevron_right),
                    tooltip: i18n.guidedSkip,
                    onPressed: () => setState(_engine.skip),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MusicBpmCard(initialPhase: _musicPhase),
            ],
          ),
        ),
      ],
    );
  }
}

/// The page before the routine runs: the exercises of the day, how much time
/// to add to the work and the rests, the estimated time and the start button.
class _GuidedSetup extends StatelessWidget {
  final List<GuidedStep> steps;
  final String? title;
  final int workDelta;
  final int restDelta;
  final String Function(GuidedStep) nameOf;
  final String Function(GuidedStep) summaryOf;
  final ValueChanged<int> onWork;
  final ValueChanged<int> onRest;
  final VoidCallback onStart;
  final VoidCallback? onClose;

  const _GuidedSetup({
    required this.steps,
    required this.title,
    required this.workDelta,
    required this.restDelta,
    required this.nameOf,
    required this.summaryOf,
    required this.onWork,
    required this.onRest,
    required this.onStart,
    required this.onClose,
  });

  static const _step = 5;

  String _delta(BuildContext context, int v) =>
      AppLocalizations.of(context).guidedSeconds('${v >= 0 ? '+' : '-'}${v.abs()}');

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final circle = IconButton.styleFrom(
      backgroundColor: atlas.card,
      side: BorderSide(color: atlas.line),
      fixedSize: const Size(40, 40),
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
    );

    // One row per exercise: the first set stands for all of its sets
    final slots = <int, List<GuidedStep>>{};
    for (final s in steps) {
      slots.putIfAbsent(s.slotIndex, () => []).add(s);
    }
    final adjusted = [for (final s in steps) s.adjusted(work: workDelta, rest: restDelta)];
    final estimate = estimateGuidedSeconds(adjusted);

    Widget adjustRow(
      String label,
      String hint,
      int value,
      ValueChanged<int> onChanged,
      String id,
    ) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3)),
                ],
              ),
            ),
            StepButton(
              key: ValueKey('$id-minus'),
              icon: Icons.remove,
              size: 40,
              onPressed: value > -30 ? () => onChanged(value - _step) : null,
            ),
            SizedBox(
              width: 64,
              child: MonoText(
                _delta(context, value),
                key: ValueKey(id),
                size: 16,
                textAlign: TextAlign.center,
                color: theme.colorScheme.onSurface,
              ),
            ),
            StepButton(
              key: ValueKey('$id-plus'),
              icon: Icons.add,
              size: 40,
              onPressed: value < 60 ? () => onChanged(value + _step) : null,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(
            children: [
              IconButton(
                style: circle,
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(i18n.guidedMode, style: theme.textTheme.titleMedium),
                    Text(
                      i18n.guidedSetupSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
              const GlossaryHelpButton(),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('guided-setup'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              AtlasCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null && title!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(title!, style: theme.textTheme.titleLarge),
                      ),
                    for (final (i, e) in slots.entries.indexed)
                      Container(
                        key: ValueKey('guided-setup-row-$i'),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: atlas.line)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: atlas.surface3,
                                shape: BoxShape.circle,
                              ),
                              child: MonoText('${i + 1}', size: 13),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nameOf(e.value.first), style: theme.textTheme.bodyLarge),
                                  Text(
                                    '${i18n.guidedSetsLine(e.value.length)} · ${summaryOf(e.value.first)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: atlas.ink3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            MonoText(
                              i18n.guidedRestShort(
                                formatGuidedTime(
                                  e.value.first.adjusted(rest: restDelta).restSeconds,
                                ),
                              ),
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: atlas.ink3,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AtlasCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    adjustRow(
                      i18n.guidedAdjustWork,
                      i18n.guidedAdjustWorkHint,
                      workDelta,
                      onWork,
                      'guided-work-delta',
                    ),
                    Divider(height: 1, color: atlas.line),
                    adjustRow(
                      i18n.guidedAdjustRest,
                      i18n.guidedAdjustRestHint,
                      restDelta,
                      onRest,
                      'guided-rest-delta',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        i18n.guidedEstimatedDuration,
                        style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                      ),
                    ),
                    MonoText(
                      formatGuidedTime(estimate),
                      key: const ValueKey('guided-estimate'),
                      size: 32,
                      color: theme.colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: const ValueKey('guided-start-button'),
                  icon: const Icon(Icons.play_arrow),
                  style: FilledButton.styleFrom(
                    textStyle: theme.textTheme.titleMedium,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: steps.isEmpty ? null : onStart,
                  label: Text(i18n.guidedStart),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextIntro extends StatelessWidget {
  final GuidedStep step;
  final String name;
  final String summary;
  final bool isLast;

  const _NextIntro({
    super.key,
    required this.step,
    required this.name,
    required this.summary,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: ExerciseImageWidget(image: step.exercise.getMainImage, height: 96),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLast ? i18n.guidedLastSet : i18n.guidedNextUp,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                  Text(name, style: theme.textTheme.titleMedium),
                  Text(summary),
                  Text(
                    i18n.guidedSetOf(step.round, step.totalRounds),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneSummary extends StatelessWidget {
  final GuidedEngine engine;
  final String Function(GuidedStep) nameOf;

  const _DoneSummary(this.engine, this.nameOf);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final withReps = [
      for (final s in engine.steps)
        if (engine.repsFor(s) != null) s,
    ];

    final atlas = context.atlas;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: atlas.ok, shape: BoxShape.circle),
            child: Icon(Icons.check, size: 44, color: theme.colorScheme.surface),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          i18n.guidedDone,
          key: const ValueKey('guided-finished'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          i18n.guidedSummary(engine.completedCount, formatGuidedTime(engine.elapsedSeconds)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
        ),
        const SizedBox(height: 20),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: StatTile(
                label: i18n.duration,
                value: formatGuidedTime(engine.elapsedSeconds),
                valueSize: 30,
              ),
            ),
            Expanded(
              child: StatTile(
                label: i18n.sets,
                value: '${engine.completedCount}/${engine.steps.length}',
                valueSize: 30,
              ),
            ),
          ],
        ),
        if (withReps.isNotEmpty) ...[
          const SizedBox(height: 12),
          AtlasCard(
            child: Column(
              children: [
                for (final s in withReps)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(nameOf(s)),
                    trailing: MonoText('${engine.repsFor(s)} ${i18n.reps}', size: 13),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  final GuidedEngine engine;
  final String Function(GuidedStep) nameOf;
  final String Function(GuidedStep) summaryOf;
  final ValueChanged<int> onJump;
  final void Function(int slot, bool up) onMove;

  const _Overview({
    required this.engine,
    required this.nameOf,
    required this.summaryOf,
    required this.onJump,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final steps = engine.steps;
    final current = engine.currentStep;
    final moved = <int>{};

    return SingleChildScrollView(
      key: const ValueKey('guided-overview'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(i18n.jumpTo, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (var i = 0; i < steps.length; i++) ...[
            if (moved.add(steps[i].slotIndex) && i >= 0)
              _SlotHeader(
                title: nameOf(steps[i]),
                canUp: engine.canMoveSlot(steps[i].slotIndex, up: true),
                canDown: engine.canMoveSlot(steps[i].slotIndex, up: false),
                slot: steps[i].slotIndex,
                onMove: onMove,
              ),
            ListTile(
              key: ValueKey('guided-step-$i'),
              dense: true,
              leading: Icon(
                engine.isCompleted(steps[i])
                    ? Icons.check_circle
                    : (identical(steps[i], current)
                          ? Icons.play_circle_fill
                          : Icons.circle_outlined),
              ),
              title: Text(summaryOf(steps[i])),
              subtitle: Text(i18n.guidedSetOf(steps[i].round, steps[i].totalRounds)),
              onTap: () => onJump(i),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              i18n.gymModeOrderChangedWarning,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotHeader extends StatelessWidget {
  final String title;
  final bool canUp;
  final bool canDown;
  final int slot;
  final void Function(int slot, bool up) onMove;

  const _SlotHeader({
    required this.title,
    required this.canUp,
    required this.canDown,
    required this.slot,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        IconButton(
          key: ValueKey('guided-move-up-$slot'),
          tooltip: i18n.gymModeMoveUp,
          icon: const Icon(Icons.arrow_upward),
          onPressed: canUp ? () => onMove(slot, true) : null,
        ),
        IconButton(
          key: ValueKey('guided-move-down-$slot'),
          tooltip: i18n.gymModeMoveDown,
          icon: const Icon(Icons.arrow_downward),
          onPressed: canDown ? () => onMove(slot, false) : null,
        ),
      ],
    );
  }
}
