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

import 'package:flutter_test/flutter_test.dart';
import 'package:wger/features/routines/logic/guided_engine.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/repetition_unit.dart';
import 'package:wger/features/routines/models/slot_data.dart';
import 'package:wger/features/routines/widgets/gym_mode/countdown_alert.dart';

import '../../../../test_data/exercises.dart';
import '../../../../test_data/routines.dart';

const testRepUnitMaxReps = RepetitionUnit(id: 5, name: 'Max Reps');

DayData day(List<SlotData> slots) =>
    DayData(iteration: 1, date: DateTime(2024), day: null, slots: slots);

/// Ticks the engine [seconds] times and returns the alerts
List<CountdownAlert> run(GuidedEngine e, int seconds) => [
  for (var i = 0; i < seconds; i++) e.tick(),
];

void main() {
  final exercises = getTestExercises();

  group('buildGuidedSteps', () {
    test('creates one step per set with rounds, kind and rest', () {
      final steps = buildGuidedSteps(
        day([
          getTestSlot(exercises[0], sets: 3, restTime: 45),
          getTestSlot(
            exercises[1],
            sets: 2,
            repetitions: 30,
            repetitionsUnit: testRepUnitSeconds,
            weight: null,
          ),
          getTestSlot(exercises[0], sets: 1, repetitions: 2, repetitionsUnit: testRepUnitMinutes),
          getTestSlot(
            exercises[1],
            sets: 1,
            repetitions: null,
            repetitionsUnit: testRepUnitMaxReps,
          ),
          getTestSlot(
            exercises[1],
            sets: 1,
            repetitions: null,
            repetitionsUnit: testRepUnitUntilFailure,
          ),
        ]),
      );

      expect(steps, hasLength(8));
      expect([for (final s in steps.take(3)) s.round], [1, 2, 3]);
      expect(steps[0].totalRounds, 3);
      expect(steps[0].kind, GuidedKind.reps);
      expect(steps[0].workSeconds, isNull);
      expect(steps[0].restSeconds, 45);
      expect(steps[3].kind, GuidedKind.timed);
      expect(steps[3].workSeconds, 30);
      expect(steps[3].restSeconds, GUIDED_DEFAULT_REST_SECONDS);
      expect(steps[5].workSeconds, 120);
      expect(steps[6].kind, GuidedKind.maxReps);
      expect(steps[7].kind, GuidedKind.failure);
      expect([for (final s in steps) s.slotIndex], [0, 0, 0, 1, 1, 2, 3, 4]);
    });
  });

  group('GuidedEngine', () {
    GuidedEngine engine(List<SlotData> slots) => GuidedEngine(buildGuidedSteps(day(slots)));

    test('an empty routine is done immediately', () {
      final e = GuidedEngine([]);
      expect(e.isDone, isTrue);
      expect(e.currentStep, isNull);
    });

    test('3-2-1 countdown, then timed work, then rest, then the next set', () {
      final e = engine([
        getTestSlot(
          exercises[0],
          sets: 2,
          repetitions: 10,
          repetitionsUnit: testRepUnitSeconds,
          restTime: 4,
        ),
      ]);

      expect(e.phase, GuidedPhase.countdown);
      expect(e.remainingSeconds, 3);
      run(e, 3);
      expect(e.phase, GuidedPhase.work);
      expect(e.remainingSeconds, 10);
      run(e, 10);
      expect(e.phase, GuidedPhase.rest);
      expect(e.remainingSeconds, 4);
      expect(e.stepIndex, 0);
      expect(e.isCompleted(e.steps[0]), isTrue);
      run(e, 4);
      expect(e.phase, GuidedPhase.work);
      expect(e.stepIndex, 1);
      run(e, 10);
      // The last set has no rest
      expect(e.phase, GuidedPhase.done);
      expect(e.completedCount, 2);
      expect(e.elapsedSeconds, 3 + 10 + 4 + 10);
    });

    test('rep based sets wait for the Done button', () {
      final e = engine([getTestSlot(exercises[0], sets: 2, restTime: 5)]);
      run(e, 3);
      expect(e.phase, GuidedPhase.work);
      expect(e.remainingSeconds, isNull);

      run(e, 100);
      expect(e.phase, GuidedPhase.work);

      e.done();
      expect(e.phase, GuidedPhase.rest);
      run(e, 5);
      expect(e.stepIndex, 1);
      e.done();
      expect(e.isDone, isTrue);
    });

    test('a rest of 0 goes straight to the next set', () {
      final e = engine([getTestSlot(exercises[0], sets: 2, restTime: 0)]);
      run(e, 3);
      e.done();
      expect(e.phase, GuidedPhase.work);
      expect(e.stepIndex, 1);
    });

    test('max reps asks for the repetitions and remembers them', () {
      final e = engine([
        getTestSlot(
          exercises[0],
          sets: 2,
          repetitions: null,
          repetitionsUnit: testRepUnitMaxReps,
          restTime: 5,
        ),
      ]);
      run(e, 3);
      e.done();
      expect(e.phase, GuidedPhase.askReps);
      // Time does not run while asking
      run(e, 10);
      expect(e.phase, GuidedPhase.askReps);

      e.submitReps(17);
      expect(e.repsFor(e.steps[0]), 17);
      expect(e.phase, GuidedPhase.rest);
    });

    test('submitReps outside of the question is ignored', () {
      final e = engine([getTestSlot(exercises[0], sets: 1)]);
      e.submitReps(3);
      expect(e.phase, GuidedPhase.countdown);
      expect(e.repsFor(e.steps[0]), isNull);
    });

    test('alerts: 20 seconds, last 5 seconds and the end of a rest', () {
      final e = engine([getTestSlot(exercises[0], sets: 2, restTime: 30)]);
      run(e, 3);
      e.done();

      final alerts = run(e, 30);
      // 29 .. 0 remaining
      expect(alerts[9], CountdownAlert.warning); // 20 left
      expect(alerts.where((a) => a == CountdownAlert.tick), hasLength(5));
      expect(alerts.last, CountdownAlert.end);
      expect(alerts.where((a) => a == CountdownAlert.warning), hasLength(1));
    });

    test('alerts can be switched off', () {
      final e = engine([getTestSlot(exercises[0], sets: 2, restTime: 30)]);
      run(e, 3);
      e.done();
      final alerts = [
        for (var i = 0; i < 30; i++)
          e.tick(alertAt20s: false, alertLast5s: false, alertAtEnd: false),
      ];
      expect(alerts.every((a) => a == CountdownAlert.none), isTrue);
      expect(e.phase, GuidedPhase.work);
    });

    test('the countdown ticks the last seconds as well', () {
      final e = engine([getTestSlot(exercises[0], sets: 1)]);
      expect(run(e, 3), [CountdownAlert.tick, CountdownAlert.tick, CountdownAlert.end]);
    });

    test('pause stops the clock', () {
      final e = engine([getTestSlot(exercises[0], sets: 1)]);
      e.pause();
      run(e, 10);
      expect(e.remainingSeconds, 3);
      expect(e.elapsedSeconds, 0);
      e.resume();
      e.tick();
      expect(e.remainingSeconds, 2);
    });

    test('skip ends the phase, skipping work does not complete the set', () {
      final e = engine([getTestSlot(exercises[0], sets: 2, restTime: 5)]);
      e.skip();
      expect(e.phase, GuidedPhase.work);
      e.skip();
      expect(e.phase, GuidedPhase.rest);
      expect(e.isCompleted(e.steps[0]), isFalse);
      e.skip();
      expect(e.stepIndex, 1);
      expect(e.phase, GuidedPhase.work);
    });

    group('jumping', () {
      late GuidedEngine e;
      setUp(() {
        e = engine([
          getTestSlot(exercises[0], sets: 2, restTime: 5),
          getTestSlot(exercises[1], sets: 2, restTime: 5),
        ]);
        run(e, 3);
        e.done(); // step 0 done
      });

      test('warns when open sets are skipped', () {
        // Step 1 is next, nothing open before it besides ... none (0 is done)
        expect(e.jumpWarning(1), GuidedJumpWarning.none);
        expect(e.jumpWarning(2), GuidedJumpWarning.skipsAhead);
      });

      test('warns when a done set is repeated', () {
        expect(e.jumpWarning(0), GuidedJumpWarning.repeatsDone);
      });

      test('going back to an open set does not warn', () {
        e.jumpTo(3);
        expect(e.jumpWarning(1), GuidedJumpWarning.none);
      });

      test('jumping starts with a countdown on the target', () {
        e.jumpTo(2);
        expect(e.stepIndex, 2);
        expect(e.phase, GuidedPhase.countdown);
        expect(e.remainingSeconds, 3);
        run(e, 3);
        expect(e.phase, GuidedPhase.work);
        expect(e.currentStep, e.steps[2]);
      });

      test('out of range targets are ignored', () {
        e.jumpTo(99);
        expect(e.stepIndex, 0);
        expect(e.jumpWarning(99), GuidedJumpWarning.none);
      });
    });

    group('reordering', () {
      GuidedEngine three() => engine([
        getTestSlot(exercises[0], sets: 2, restTime: 5),
        getTestSlot(exercises[1], sets: 1, restTime: 5),
        getTestSlot(exercises[0], sets: 1, restTime: 5),
      ]);

      test('moves a slot with all its sets', () {
        final e = three();
        expect(e.slotOrder, [0, 1, 2]);
        expect(e.moveSlot(2, up: true), isTrue);
        expect(e.slotOrder, [0, 2, 1]);
        expect(e.steps.map((s) => s.slotIndex), [0, 0, 2, 1]);
      });

      test('the current slot is movable only before it started', () {
        final e = three();
        expect(e.canMoveSlot(0, up: false), isTrue);
        run(e, 3);
        expect(e.phase, GuidedPhase.work);
        expect(e.canMoveSlot(0, up: false), isFalse);
        expect(e.movableSlots, [1, 2]);
        expect(e.canMoveSlot(1, up: true), isFalse);
        expect(e.canMoveSlot(1, up: false), isTrue);
      });

      test('done slots stay and the current step is kept', () {
        final e = three();
        run(e, 3);
        e.done();
        e.done(); // rest -> skip? no, done only works in work
        e.skip(); // end rest
        e.done();
        e.skip();
        // now in slot 1
        expect(e.currentStep!.slotIndex, 1);
        final current = e.currentStep;
        expect(e.moveSlot(1, up: false), isFalse);
        expect(e.currentStep, current);
      });

      test('the step index follows the current step', () {
        final e = three();
        // still in the countdown of step 0: slot 0 can move down
        expect(e.moveSlot(0, up: false), isTrue);
        expect(e.currentStep!.slotIndex, 0);
        expect(e.stepIndex, 1);
      });
    });
  });
}
