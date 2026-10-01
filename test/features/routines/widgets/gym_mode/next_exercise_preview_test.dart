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
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/exercises/widgets/exercises.dart';
import 'package:wger/features/exercises/widgets/images.dart';
import 'package:wger/features/routines/models/repetition_unit.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/models/weight_unit.dart';
import 'package:wger/features/routines/widgets/gym_mode/next_exercise_preview.dart';

import '../../../../../test_data/exercises.dart';
import '../../../../../test_data/routines.dart';
import 'timer_harness.dart';

/// One planned set with the units to check and the expected summary
class _Case {
  final String name;
  final num? reps;
  final num? maxReps;
  final RepetitionUnit? repUnit;
  final num? weight;
  final num? maxWeight;
  final WeightUnit? weightUnit;
  final String expected;

  const _Case(
    this.name, {
    this.reps,
    this.maxReps,
    this.repUnit = testRepUnitReps,
    this.weight,
    this.maxWeight,
    this.weightUnit = testWeightUnitKg,
    required this.expected,
  });
}

const _cases = [
  _Case('kg', reps: 8, weight: 50, expected: '8 × 50 kg'),
  _Case('lb', reps: 8, weight: 135, weightUnit: testWeightUnitLb, expected: '8 × 135 lb'),
  _Case('decimal weight', reps: 10, weight: 22.5, expected: '10 × 22.5 kg'),
  _Case('range', reps: 8, maxReps: 12, weight: 50, maxWeight: 60, expected: '8-12 × 50-60 kg'),
  _Case(
    'body weight',
    reps: 10,
    weight: null,
    weightUnit: testWeightUnitBodyWeight,
    expected: '10 × Body Weight',
  ),
  _Case(
    'plates',
    reps: 5,
    weight: 2,
    weightUnit: testWeightUnitPlates,
    expected: '5 × 2 Plates',
  ),
  _Case(
    'seconds',
    reps: 30,
    repUnit: testRepUnitSeconds,
    weight: null,
    expected: '30 Seconds',
  ),
  _Case(
    'minutes with weight',
    reps: 2,
    repUnit: testRepUnitMinutes,
    weight: 20,
    weightUnit: testWeightUnitLb,
    expected: '2 Minutes × 20 lb',
  ),
  _Case(
    'until failure',
    reps: null,
    repUnit: testRepUnitUntilFailure,
    weight: 40,
    expected: 'Until Failure × 40 kg',
  ),
  _Case('reps without weight', reps: 12, weight: null, expected: '12 Repetitions'),
  _Case('weight 0', reps: 12, weight: 0, expected: '12 Repetitions'),
];

SetConfigData _config(_Case c, {String textRepr = 'server text'}) => SetConfigData(
  exerciseId: 1,
  slotEntryId: 1,
  repetitions: c.reps,
  maxRepetitions: c.maxReps,
  repetitionsUnit: c.repUnit,
  repetitionsUnitId: c.repUnit?.id,
  weight: c.weight,
  maxWeight: c.maxWeight,
  weightUnit: c.weightUnit,
  weightUnitId: c.weightUnit?.id,
  textRepr: textRepr,
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('plannedSetSummary', () {
    for (final c in _cases) {
      test('uses the units of the set: ${c.name}', () {
        expect(plannedSetSummary(_config(c), translate: (v) => v), c.expected);
      });
    }

    test('translates the unit names', () {
      final summary = plannedSetSummary(
        _config(_cases.firstWhere((c) => c.name == 'seconds')),
        translate: (v) => 'x$v',
      );

      expect(summary, '30 xSeconds');
    });

    test('falls back to the server text if a unit is not available', () {
      // e.g. the unit catalogue was not loaded when the routine was hydrated
      final config = SetConfigData(
        exerciseId: 1,
        slotEntryId: 1,
        repetitions: 30,
        repetitionsUnit: null,
        repetitionsUnitId: testRepUnitSeconds.id,
        textRepr: '30 Seconds',
      );
      expect(plannedSetSummary(config, translate: (v) => v), '30 Seconds');

      final lb = SetConfigData(
        exerciseId: 1,
        slotEntryId: 1,
        repetitions: 8,
        weight: 135,
        weightUnitId: testWeightUnitLb.id,
        textRepr: '8 × 135 lb',
      );
      expect(plannedSetSummary(lb, translate: (v) => v), '8 × 135 lb');
    });

    test('falls back to the server text if there is nothing to show', () {
      final config = SetConfigData(
        exerciseId: 1,
        slotEntryId: 1,
        repetitionsUnit: testRepUnitReps,
        textRepr: 'AMRAP',
      );

      expect(plannedSetSummary(config, translate: (v) => v), 'AMRAP');
    });
  });

  group('NextExercisePreview on the countdown page', () {
    final exercises = getTestExercises();
    late TimerHarness harness;

    tearDown(() => harness.dispose());

    // Bench press (2 sets) followed by side raises
    Routine routine({SetConfigData? nextSetConfig}) {
      final bench = getTestSlot(exercises[0], restTime: 30);
      final raises = getTestSlot(exercises[5], restTime: 45, repetitions: 12, weight: 10);
      if (nextSetConfig != null) {
        raises.setConfigs[0] = nextSetConfig;
      }
      return getTestRoutineWithSlots([bench, raises]);
    }

    Future<void> pumpAt(WidgetTester tester, Routine r, int page) async {
      harness = TimerHarness(r, initialPage: page);
      await tester.pumpWidget(harness.build());
    }

    Finder inPreview(Finder f) =>
        find.descendant(of: find.byKey(const ValueKey('next-exercise-preview')), matching: f);

    testWidgets('shows the next set of the same exercise', (tester) async {
      // Page 2: timer after the first set of the bench press
      await pumpAt(tester, routine(), 2);

      expect(find.byKey(const ValueKey('next-exercise-preview')), findsOneWidget);
      expect(inPreview(find.text('Next set')), findsOneWidget);
      expect(inPreview(find.text('New exercise')), findsNothing);
      expect(inPreview(find.text('Bench press')), findsOneWidget);
      expect(inPreview(find.text('10 × 50 kg')), findsOneWidget);
      expect(inPreview(find.byType(ExerciseImageWidget)), findsOneWidget);
    });

    testWidgets('labels a different exercise as new', (tester) async {
      // Page 4: timer after the last set of the bench press
      await pumpAt(tester, routine(), 4);

      expect(inPreview(find.text('New exercise')), findsOneWidget);
      expect(inPreview(find.text('Next set')), findsNothing);
      expect(inPreview(find.text('Side raises')), findsOneWidget);
      expect(inPreview(find.text('12 × 10 kg')), findsOneWidget);
    });

    testWidgets('shows nothing after the last set of the workout', (tester) async {
      // Page 8: timer after the last set of the side raises
      await pumpAt(tester, routine(), 8);

      expect(find.byKey(const ValueKey('next-exercise-preview')), findsNothing);
    });

    for (final c in _cases) {
      testWidgets('shows the units of the next set: ${c.name}', (tester) async {
        await pumpAt(
          tester,
          routine(nextSetConfig: _config(c).copyWith(exercise: exercises[5])),
          4,
        );

        expect(find.byKey(const ValueKey('next-exercise-summary')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('next-exercise-summary'))).data,
          c.expected,
        );
      });
    }

    testWidgets('never shows kg or repetitions for other units', (tester) async {
      const c = _Case(
        'seconds on plates',
        reps: 45,
        repUnit: testRepUnitSeconds,
        weight: 3,
        weightUnit: testWeightUnitPlates,
        expected: '45 Seconds × 3 Plates',
      );
      await pumpAt(tester, routine(nextSetConfig: _config(c).copyWith(exercise: exercises[5])), 4);

      final text = tester.widget<Text>(find.byKey(const ValueKey('next-exercise-summary'))).data!;
      expect(text, c.expected);
      expect(text, isNot(contains('kg')));
      expect(text, isNot(contains('Repetitions')));
    });

    testWidgets('the details button opens the exercise in a bottom sheet', (tester) async {
      await pumpAt(tester, routine(), 4);
      expect(find.byType(ExerciseDetail), findsNothing);

      await tester.tap(find.byKey(const ValueKey('next-exercise-details-button')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(ExerciseDetail), findsOneWidget);
      // The sheet is headed by the name of the next exercise, not the current one
      expect(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Side raises')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Bench press')),
        findsNothing,
      );

      // Closing it leaves the timer page where it was
      await tester.tap(find.byKey(const ValueKey('exercise-details-close')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(harness.controller.page, 4);
    });

    testWidgets('follows a reordered workout', (tester) async {
      await pumpAt(tester, routine(), 4);
      expect(inPreview(find.text('Side raises')), findsOneWidget);

      // Side raises first: the timer on page 2 is now the one after them, and
      // what follows is the bench press
      final raisesPage = harness.state.pages[2];
      harness.notifier.moveSlot(raisesPage.uuid, 1);
      harness.controller.jumpToPage(2);
      await tester.pumpWidget(harness.build());

      expect(inPreview(find.text('Next set')), findsOneWidget);
      expect(inPreview(find.text('Side raises')), findsOneWidget);

      harness.controller.jumpToPage(4);
      await tester.pumpWidget(harness.build());
      expect(inPreview(find.text('New exercise')), findsOneWidget);
      expect(inPreview(find.text('Bench press')), findsOneWidget);
    });
  });
}
