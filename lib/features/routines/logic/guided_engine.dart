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

import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/widgets/gym_mode/countdown_alert.dart';

/// Seconds of the 3-2-1 countdown before a set starts
const GUIDED_COUNTDOWN_SECONDS = 3;

/// Rest between sets if the exercise has no rest configured
const GUIDED_DEFAULT_REST_SECONDS = 30;

/// How a set is performed, derived from its repetition unit
enum GuidedKind {
  /// Repetitions: the user taps "Done"
  reps,

  /// Seconds or minutes: runs on a timer
  timed,

  /// Max reps: the user taps "Done" and is asked for the repetitions
  maxReps,

  /// Until failure: the user taps "Done"
  failure,
}

/// One set of the guided routine: work followed by the rest of the exercise
class GuidedStep {
  /// The slot of the day this set belongs to, sets of a slot stay together
  final int slotIndex;

  /// 1-based round of the exercise within its slot, and the number of rounds
  final int round;
  final int totalRounds;

  final SetConfigData config;
  final GuidedKind kind;

  /// Duration of the work for timed sets, null if the user ends it
  final int? workSeconds;

  /// Rest after the set, 0 for none
  final int restSeconds;

  const GuidedStep({
    required this.slotIndex,
    required this.round,
    required this.totalRounds,
    required this.config,
    required this.kind,
    this.workSeconds,
    required this.restSeconds,
  });

  Exercise get exercise => config.exercise;

  /// This step with [work] seconds added to a timed work (never below 5 s) and
  /// [rest] seconds added to the rest (never below 0)
  GuidedStep adjusted({int work = 0, int rest = 0}) {
    if (work == 0 && rest == 0) {
      return this;
    }
    return GuidedStep(
      slotIndex: slotIndex,
      round: round,
      totalRounds: totalRounds,
      config: config,
      kind: kind,
      workSeconds: workSeconds == null ? null : (workSeconds! + work).clamp(5, 3600),
      restSeconds: (restSeconds + rest).clamp(0, 1800),
    );
  }
}

/// Seconds a set without a timer is assumed to take, for the estimate
const GUIDED_ASSUMED_WORK_SECONDS = 45;

/// Estimated duration of running [steps]: the countdown, the work and the rest
/// of every set. The rest after the last set is not taken.
int estimateGuidedSeconds(List<GuidedStep> steps) {
  var total = 0;
  for (final (i, s) in steps.indexed) {
    total += GUIDED_COUNTDOWN_SECONDS + (s.workSeconds ?? GUIDED_ASSUMED_WORK_SECONDS);
    if (i < steps.length - 1) {
      total += s.restSeconds;
    }
  }
  return total;
}

/// Kind and work duration of a planned set. The units are the ones of the
/// configuration: seconds and minutes run on a timer, everything else is
/// ended by the user.
(GuidedKind, int?) guidedKindFor(SetConfigData config) {
  final unit = config.repetitionsUnit?.name.toLowerCase();
  final value = config.repetitions ?? config.maxRepetitions;

  switch (unit) {
    case 'seconds':
      return value != null && value > 0
          ? (GuidedKind.timed, value.round())
          : (GuidedKind.reps, null);
    case 'minutes':
      return value != null && value > 0
          ? (GuidedKind.timed, (value * 60).round())
          : (GuidedKind.reps, null);
    case 'max reps':
      return (GuidedKind.maxReps, null);
    case 'until failure':
      return (GuidedKind.failure, null);
    default:
      return (GuidedKind.reps, null);
  }
}

/// The sets of a day as steps, in the order they are done. The rest comes
/// from each set's own configuration.
List<GuidedStep> buildGuidedSteps(
  DayData day, {
  int defaultRestSeconds = GUIDED_DEFAULT_REST_SECONDS,
}) {
  final steps = <GuidedStep>[];

  for (var slotIndex = 0; slotIndex < day.slots.length; slotIndex++) {
    final configs = day.slots[slotIndex].setConfigs;
    final totals = <int, int>{};
    for (final c in configs) {
      totals[c.exerciseId] = (totals[c.exerciseId] ?? 0) + 1;
    }

    final seen = <int, int>{};
    for (final config in configs) {
      final round = (seen[config.exerciseId] ?? 0) + 1;
      seen[config.exerciseId] = round;
      final (kind, work) = guidedKindFor(config);

      steps.add(
        GuidedStep(
          slotIndex: slotIndex,
          round: round,
          totalRounds: totals[config.exerciseId]!,
          config: config,
          kind: kind,
          workSeconds: work,
          restSeconds: (config.restTime ?? defaultRestSeconds).round(),
        ),
      );
    }
  }
  return steps;
}

enum GuidedPhase { countdown, work, rest, askReps, done }

/// What jumping to a step would skip or repeat
enum GuidedJumpWarning { none, skipsAhead, repeatsDone }

/// The interval engine of the guided routine: 3-2-1 countdown, work, rest,
/// asking for the repetitions of max-reps sets and done.
///
/// It is a plain state machine without timers: the UI calls [tick] once per
/// second and plays the returned alert. This keeps it deterministic and easy
/// to test.
class GuidedEngine {
  GuidedEngine(List<GuidedStep> steps, {this.countdownSeconds = GUIDED_COUNTDOWN_SECONDS})
    : _steps = [...steps] {
    if (_steps.isEmpty) {
      _phase = GuidedPhase.done;
    } else {
      _startCountdown();
    }
  }

  final int countdownSeconds;
  List<GuidedStep> _steps;
  int _stepIndex = 0;
  GuidedPhase _phase = GuidedPhase.countdown;

  /// Seconds left in the current phase, null if the user ends it
  int? _remaining;
  int _phaseTotal = 0;
  bool _paused = false;
  int _elapsedSeconds = 0;

  final Set<GuidedStep> _completed = {};
  final Map<GuidedStep, int> _reps = {};

  List<GuidedStep> get steps => List.unmodifiable(_steps);
  int get stepIndex => _stepIndex;
  GuidedPhase get phase => _phase;
  int? get remainingSeconds => _remaining;
  int get phaseTotalSeconds => _phaseTotal;
  bool get isPaused => _paused;
  bool get isDone => _phase == GuidedPhase.done;

  /// Time the engine has been running, without pauses
  int get elapsedSeconds => _elapsedSeconds;

  GuidedStep? get currentStep => _steps.isEmpty || isDone ? null : _steps[_stepIndex];

  /// The step that follows the current one, null at the end
  GuidedStep? get nextStep => _stepIndex + 1 < _steps.length ? _steps[_stepIndex + 1] : null;

  bool isCompleted(GuidedStep step) => _completed.contains(step);

  /// Repetitions the user entered for a max-reps step
  int? repsFor(GuidedStep step) => _reps[step];

  int get completedCount => _completed.length;

  void _startCountdown() {
    _phase = GuidedPhase.countdown;
    _remaining = countdownSeconds;
    _phaseTotal = countdownSeconds;
  }

  void _startWork() {
    final step = _steps[_stepIndex];
    _phase = GuidedPhase.work;
    _remaining = step.workSeconds;
    _phaseTotal = step.workSeconds ?? 0;
  }

  void _startRest() {
    final step = _steps[_stepIndex];
    _phase = GuidedPhase.rest;
    _remaining = step.restSeconds;
    _phaseTotal = step.restSeconds;
  }

  void _finish() {
    _phase = GuidedPhase.done;
    _remaining = null;
    _phaseTotal = 0;
  }

  /// After the work (and the question for the reps) of the current step
  void _afterWork() {
    if (_stepIndex + 1 >= _steps.length) {
      _finish();
    } else if (_steps[_stepIndex].restSeconds > 0) {
      _startRest();
    } else {
      _stepIndex++;
      _startWork();
    }
  }

  void _endWork({required bool completed}) {
    final step = _steps[_stepIndex];
    if (completed) {
      _completed.add(step);
    }
    if (step.kind == GuidedKind.maxReps && completed) {
      _phase = GuidedPhase.askReps;
      _remaining = null;
      _phaseTotal = 0;
    } else {
      _afterWork();
    }
  }

  void _endPhase({required bool completed}) {
    switch (_phase) {
      case GuidedPhase.countdown:
        _startWork();
      case GuidedPhase.work:
        _endWork(completed: completed);
      case GuidedPhase.rest:
        _stepIndex++;
        _startWork();
      case GuidedPhase.askReps:
        _afterWork();
      case GuidedPhase.done:
        break;
    }
  }

  /// Advances the clock by one second and returns the alert that is due.
  /// Nothing happens while paused, done or when the user has to end the phase.
  CountdownAlert tick({
    bool alertAt20s = true,
    bool alertLast5s = true,
    bool alertAtEnd = true,
  }) {
    if (_paused || isDone) {
      return CountdownAlert.none;
    }
    _elapsedSeconds++;

    final remaining = _remaining;
    if (remaining == null) {
      return CountdownAlert.none;
    }

    final left = remaining - 1;
    _remaining = left;
    final alert = countdownAlertFor(
      remainingSeconds: left,
      totalSeconds: _phaseTotal,
      alertAt20s: alertAt20s,
      alertLast5s: alertLast5s,
      alertAtEnd: alertAtEnd,
    );

    if (left <= 0) {
      _endPhase(completed: true);
    }
    return alert;
  }

  /// The user is done with a set that is not timed (or ends a timed one early)
  void done() {
    if (_phase == GuidedPhase.work) {
      _endWork(completed: true);
    }
  }

  /// Answer to the "how many reps?" question after a max-reps set
  void submitReps(int reps) {
    if (_phase != GuidedPhase.askReps) {
      return;
    }
    _reps[_steps[_stepIndex]] = reps;
    _afterWork();
  }

  /// Ends the current phase early. Skipping the work of a set does not count
  /// the set as done.
  void skip() => _endPhase(completed: false);

  void pause() => _paused = true;

  void resume() => _paused = false;

  /// What [jumpTo] would skip or repeat
  GuidedJumpWarning jumpWarning(int target) {
    if (target < 0 || target >= _steps.length) {
      return GuidedJumpWarning.none;
    }
    if (_completed.contains(_steps[target])) {
      return GuidedJumpWarning.repeatsDone;
    }
    final skipsOpen = _steps.take(target).any((s) => !_completed.contains(s));
    return target > _stepIndex && skipsOpen ? GuidedJumpWarning.skipsAhead : GuidedJumpWarning.none;
  }

  /// Continues with the step at [target], after a new 3-2-1 countdown
  void jumpTo(int target) {
    if (target < 0 || target >= _steps.length) {
      return;
    }
    _stepIndex = target;
    _paused = false;
    _startCountdown();
  }

  // Reordering works on the slots (an exercise with all its sets) that were
  // not started yet.

  bool _groupStarted(int slotIndex) {
    final inGroup = _steps.where((s) => s.slotIndex == slotIndex);
    if (inGroup.any(_completed.contains)) {
      return true;
    }
    final current = currentStep;
    return current != null && current.slotIndex == slotIndex && _phase != GuidedPhase.countdown;
  }

  /// Slot indices in the order they are done
  List<int> get slotOrder {
    final out = <int>[];
    for (final s in _steps) {
      if (!out.contains(s.slotIndex)) {
        out.add(s.slotIndex);
      }
    }
    return out;
  }

  /// Slots that can still be moved
  List<int> get movableSlots => [
    for (final slot in slotOrder)
      if (!_groupStarted(slot) && !isDone) slot,
  ];

  bool canMoveSlot(int slotIndex, {required bool up}) {
    final movable = movableSlots;
    final rank = movable.indexOf(slotIndex);
    if (rank == -1) {
      return false;
    }
    return up ? rank > 0 : rank < movable.length - 1;
  }

  /// Moves the slot one place up or down among the movable ones, the others
  /// keep their position. Returns whether the order changed.
  bool moveSlot(int slotIndex, {required bool up}) {
    if (!canMoveSlot(slotIndex, up: up)) {
      return false;
    }
    final movable = movableSlots;
    final rank = movable.indexOf(slotIndex);
    final swapWith = movable[up ? rank - 1 : rank + 1];

    final order = slotOrder;
    final a = order.indexOf(slotIndex);
    final b = order.indexOf(swapWith);
    // Exchange the two slots' places
    final newOrder = [...order];
    newOrder[a] = swapWith;
    newOrder[b] = slotIndex;

    final current = currentStep;
    _steps = [
      for (final slot in newOrder) ..._steps.where((s) => s.slotIndex == slot),
    ];
    if (current != null) {
      _stepIndex = _steps.indexOf(current);
    }
    return true;
  }
}
