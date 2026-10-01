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
import 'package:wger/features/routines/logic/time_budget.dart';
import 'package:wger/features/routines/models/set_config_data.dart';

import '../../../../test_data/routines.dart';

SetConfigData config({num? reps, unit = testRepUnitReps, num? rest}) => SetConfigData(
  exerciseId: 1,
  slotEntryId: 1,
  repetitions: reps,
  repetitionsUnit: unit,
  restTime: rest,
);

void main() {
  group('estimateWorkSeconds', () {
    test('seconds and minutes are taken as they are', () {
      expect(estimateWorkSeconds(config(reps: 45, unit: testRepUnitSeconds)), 45);
      expect(estimateWorkSeconds(config(reps: 2, unit: testRepUnitMinutes)), 120);
    });

    test('repetitions are estimated', () {
      expect(estimateWorkSeconds(config(reps: 10)), 10 * SECONDS_PER_REPETITION);
    });

    test('no usable value uses the default', () {
      expect(estimateWorkSeconds(config(reps: null)), DEFAULT_WORK_SECONDS);
      expect(
        estimateWorkSeconds(config(reps: null, unit: testRepUnitUntilFailure)),
        DEFAULT_WORK_SECONDS,
      );
    });
  });

  test('estimateRestSeconds uses the configured rest or the default', () {
    expect(estimateRestSeconds(config(rest: 90)), 90);
    expect(estimateRestSeconds(config()), DEFAULT_REST_SECONDS);
    expect(estimateRestSeconds(config(), defaultRest: 20), 20);
  });

  group('suggestSetsToDrop', () {
    // 4 sets of 100 s and 3 sets of 100 s: 700 s
    final items = [
      const BudgetItem(id: 'a', setSeconds: [100, 100, 100, 100]),
      const BudgetItem(id: 'b', setSeconds: [100, 100, 100]),
    ];

    test('estimates the duration', () {
      expect(estimateDurationSeconds(items), 700);
    });

    test('drops nothing if it fits', () {
      final s = suggestSetsToDrop(items, 12);
      expect(s.fitsAlready, isTrue);
      expect(s.drops, isEmpty);
      expect(s.totalDropped, 0);
    });

    test('drops from the exercise with the most sets, the last one on ties', () {
      // 600 s budget: one set must go, "a" has the most
      var s = suggestSetsToDrop(items, 10);
      expect(s.drops, {'a': 1});
      expect(s.estimatedAfterSeconds, 600);
      expect(s.fitsAfter, isTrue);

      // 500 s: a 4->3, then tie 3/3 goes to the last one (b)
      s = suggestSetsToDrop(items, 500 ~/ 60 + 0);
      expect(s.budgetSeconds, 480);
      expect(s.drops, {'a': 2, 'b': 1}.map((k, v) => MapEntry(k, v)));
      expect(s.estimatedAfterSeconds, 400);
    });

    test('keeps at least one set per exercise', () {
      final s = suggestSetsToDrop(items, 1);
      expect(s.drops, {'a': 3, 'b': 2});
      expect(s.estimatedAfterSeconds, 200);
      expect(s.fitsAfter, isFalse);
    });

    test('supersets are dropped in groups', () {
      final s = suggestSetsToDrop(
        [
          const BudgetItem(id: 's', setSeconds: [30, 30, 30, 30, 30, 30], granularity: 2),
        ],
        1,
      );
      expect(s.drops, {'s': 4});
    });

    test('a started exercise can be shortened completely', () {
      final s = suggestSetsToDrop(
        [
          const BudgetItem(id: 'x', setSeconds: [120, 120], minKeep: 0),
        ],
        1,
      );
      expect(s.drops, {'x': 2});
      expect(s.estimatedAfterSeconds, 0);
      expect(s.fitsAfter, isTrue);
    });
  });

  test('timeBudgetChoices adds the location minutes sorted without duplicates', () {
    expect(timeBudgetChoices(), [30, 45, 60, 75]);
    expect(timeBudgetChoices(locationMinutes: 50), [30, 45, 50, 60, 75]);
    expect(timeBudgetChoices(locationMinutes: 45), [30, 45, 60, 75]);
    expect(timeBudgetChoices(locationMinutes: 90), [30, 45, 60, 75, 90]);
  });
}
