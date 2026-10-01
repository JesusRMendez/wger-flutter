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

  const GuidedRoutineView(this.steps, {super.key, this.onClose});

  @override
  ConsumerState<GuidedRoutineView> createState() => _GuidedRoutineViewState();
}

class _GuidedRoutineViewState extends ConsumerState<GuidedRoutineView> {
  late final GuidedEngine _engine = GuidedEngine(widget.steps);
  Timer? _timer;
  final _repsController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

    return Column(
      children: [
        header,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AtlasRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: widget.steps.isEmpty ? 0 : _engine.completedCount / widget.steps.length,
                ),
              ),
              const SizedBox(height: 20),
              if (timed)
                Center(
                  child: ProgressRing(
                    size: 232,
                    strokeWidth: 14,
                    value: _engine.phaseTotalSeconds == 0
                        ? 0
                        : _engine.remainingSeconds! / _engine.phaseTotalSeconds,
                    color: switch (phase) {
                      GuidedPhase.rest => atlas.ok,
                      GuidedPhase.countdown => atlas.warn,
                      _ => theme.colorScheme.primary,
                    },
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
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: atlas.brandSoft,
                      borderRadius: BorderRadius.circular(AtlasRadius.pill),
                    ),
                    child: Text(
                      phaseLabel,
                      key: const ValueKey('guided-phase'),
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (phase != GuidedPhase.rest) ...[
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: ExerciseImageWidget(image: step.exercise.getMainImage, height: 96),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _name(step),
                  key: const ValueKey('guided-exercise'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  _summary(step),
                  key: const ValueKey('guided-summary'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      i18n.guidedSetOf(step.round, step.totalRounds),
                      key: const ValueKey('guided-round'),
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('guided-pause-button'),
                    icon: Icon(_engine.isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_engine.isPaused ? i18n.guidedResume : i18n.pause),
                    onPressed: () => setState(_engine.isPaused ? _engine.resume : _engine.pause),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('guided-skip-button'),
                    icon: const Icon(Icons.skip_next),
                    label: Text(i18n.guidedSkip),
                    onPressed: () => setState(_engine.skip),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MusicBpmCard(initialPhase: _musicPhase),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.check_circle_outline, size: 64),
        Text(
          i18n.guidedDone,
          key: const ValueKey('guided-finished'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          i18n.guidedSummary(engine.completedCount, formatGuidedTime(engine.elapsedSeconds)),
          textAlign: TextAlign.center,
        ),
        for (final s in withReps)
          ListTile(
            dense: true,
            title: Text(nameOf(s)),
            trailing: Text('${engine.repsFor(s)} ${i18n.reps}'),
          ),
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
