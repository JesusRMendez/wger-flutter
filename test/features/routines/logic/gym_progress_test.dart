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
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/logic/gym_progress.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';

import '../../../../test_data/routines.dart';

void main() {
  late GymStateNotifier notifier;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final container = ProviderContainer.test();
    notifier = container.read(gymStateProvider.notifier);
    notifier.state = notifier.state.copyWith(
      showExercisePages: false,
      showTimerPages: false,
      dayId: 1,
      iteration: 1,
      routine: getTestRoutine(),
    );
    notifier.calculatePages();
  });

  List<SlotPageEntry> logs() => [
    for (final p in notifier.state.pages)
      for (final s in p.slotPages)
        if (s.type == SlotPageType.log) s,
  ];

  test('the position names the exercise and the set', () {
    final all = logs();
    final first = setPositionOf(notifier.state, all.first.uuid)!;
    expect(first.exercise, 1);
    expect(first.set, 1);
    expect(first.exercises, 2);

    final last = setPositionOf(notifier.state, all.last.uuid)!;
    expect(last.exercise, 2);
    expect(last.set, last.sets);
  });

  test('a page that is not a log page has no position', () {
    expect(setPositionOf(notifier.state, 'nope'), isNull);
  });

  test('the estimate falls as sets are done and is zero when all are', () {
    final before = estimatedMinutesLeft(notifier.state);
    expect(before, greaterThan(0));

    notifier.markSlotPageAsDone(logs().first.uuid, isDone: true);
    expect(estimatedMinutesLeft(notifier.state), lessThan(before));

    for (final s in logs()) {
      notifier.markSlotPageAsDone(s.uuid, isDone: true);
    }
    expect(estimatedMinutesLeft(notifier.state), 0);
  });

  test('rest is formatted as m:ss', () {
    expect(formatRest(90), '1:30');
    expect(formatRest(5), '0:05');
    expect(formatRest(600), '10:00');
  });

  group('dayStats', () {
    SetConfigData cfg({num? sets, num? reps, num? weight, num? rest, int? weightUnit}) =>
        SetConfigData(
          exerciseId: 1,
          slotEntryId: 1,
          nrOfSets: sets,
          repetitions: reps,
          weight: weight,
          restTime: rest,
          weightUnitId: weightUnit,
        );

    test('adds up the sets, the mean rest and the volume', () {
      final stats = dayStats([
        cfg(sets: 4, reps: 8, weight: 100, rest: 120),
        cfg(sets: 2, reps: 10, weight: 50, rest: 60),
      ]);

      expect(stats.sets, 6);
      expect(stats.averageRestSeconds, closeTo((4 * 120 + 2 * 60) / 6, 0.001));
      expect(stats.volumeKg, 4 * 8 * 100 + 2 * 10 * 50);
    });

    test('a set without a plan counts once and adds nothing else', () {
      final stats = dayStats([cfg()]);

      expect(stats.sets, 1);
      expect(stats.averageRestSeconds, isNull);
      expect(stats.volumeKg, isNull);
    });

    test('weights in pounds are left out of the volume', () {
      final stats = dayStats([cfg(sets: 3, reps: 5, weight: 100, weightUnit: 2)]);

      expect(stats.volumeKg, isNull);
    });

    test('volume is shown in tonnes from one tonne', () {
      expect(formatVolume(6920), '6.9 t');
      expect(formatVolume(850.4), '850 kg');
    });
  });
}
