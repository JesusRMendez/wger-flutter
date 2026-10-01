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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/locations/models/zone_order.dart';
import 'package:wger/features/routines/logic/time_budget.dart';
import 'package:wger/features/routines/logic/zone_order_logic.dart';
import 'package:wger/features/routines/models/slot_data.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';

import '../../../../test_data/exercises.dart';
import '../../../../test_data/routines.dart';

/// Slot of one exercise whose sets belong to the slot entry [entryId]
SlotData slot(int exerciseIndex, int entryId, {int sets = 2, num? rest}) {
  final s = getTestSlot(getTestExercises()[exerciseIndex], sets: sets, restTime: rest);
  for (final c in s.setConfigs) {
    c.slotEntryId = entryId;
  }
  return s;
}

ZoneOrderItem item(int entryId, int exerciseId, int? zone, int planned) => ZoneOrderItem(
  slotId: entryId,
  slotEntryId: entryId,
  exerciseId: exerciseId,
  zoneId: zone,
  zoneName: zone == null ? null : 'Zone $zone',
  plannedIndex: planned,
);

void main() {
  final exercises = getTestExercises();

  test('countZoneChanges ignores unknown zones', () {
    expect(countZoneChanges([]), 0);
    expect(countZoneChanges([1, 1, 1]), 0);
    expect(countZoneChanges([1, 2, 1, 2]), 3);
    expect(countZoneChanges([1, null, 1, 2]), 1);
    expect(countZoneChanges([null, null]), 0);
  });

  group('with a workout', () {
    late ProviderContainer container;
    late GymStateNotifier notifier;

    // Planned: bench (entry 10, zone A=1), crunches (11, zone B=2),
    // deadlift (12, zone A=1), curls (13, zone B=2)
    // Suggested: bench, deadlift, crunches, curls
    final order = ZoneOrder(
      locationId: 3,
      locationName: 'Gym',
      zoneChangesPlanned: 3,
      zoneChangesSuggested: 1,
      items: [
        item(10, exercises[0].id, 1, 0),
        item(12, exercises[2].id, 1, 2),
        item(11, exercises[1].id, 2, 1),
        item(13, exercises[3].id, 2, 3),
      ],
    );

    List<int> exerciseOrder() => [
      for (final p in notifier.state.pages)
        if (p.type == PageType.set) p.exercises.first.id,
    ];

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      container = ProviderContainer.test();
      notifier = container.read(gymStateProvider.notifier);
      notifier.state = notifier.state.copyWith(
        showExercisePages: false,
        showTimerPages: true,
        dayId: 1,
        iteration: 1,
        routine: getTestRoutineWithSlots([
          slot(0, 10, sets: 3, rest: 60),
          slot(1, 11, sets: 2, rest: 30),
          slot(2, 12, sets: 4, rest: 120),
          slot(3, 13, sets: 3, rest: 60),
        ]),
        zoneOrder: order,
      );
      notifier.calculatePages();
    });

    test('finds the zone of a page', () {
      final pages = notifier.state.pages.where((p) => p.type == PageType.set).toList();
      expect(zoneItemForPage(pages[0], order)!.zoneId, 1);
      expect(zoneItemForPage(pages[1], order)!.zoneId, 2);
      expect(currentZoneChanges(notifier.state.pages, order), 3);
    });

    test('falls back to the exercise if the slot entry is unknown', () {
      final other = ZoneOrder(items: [item(99, exercises[1].id, 7, 0)]);
      final page = notifier.state.pages.where((p) => p.type == PageType.set).toList()[1];
      expect(zoneItemForPage(page, other)!.zoneId, 7);
      expect(zoneItemForPage(page, const ZoneOrder()), isNull);
    });

    test('suggestedPageOrder follows the suggestion', () {
      final uuids = suggestedPageOrder(notifier.state.pages, order);
      final byUuid = {for (final p in notifier.state.pages) p.uuid: p};
      expect(
        [for (final u in uuids) byUuid[u]!.exercises.first.id],
        [
          exercises[0].id,
          exercises[2].id,
          exercises[1].id,
          exercises[3].id,
        ],
      );
    });

    test('unknown exercises stay behind the exercise they followed', () {
      final partial = ZoneOrder(
        items: [
          item(12, exercises[2].id, 1, 0),
          item(10, exercises[0].id, 1, 1),
          item(13, exercises[3].id, 2, 2),
        ],
      );
      final uuids = suggestedPageOrder(notifier.state.pages, partial);
      final byUuid = {for (final p in notifier.state.pages) p.uuid: p};
      // crunches (unknown) followed bench press, so they stay together
      expect(
        [for (final u in uuids) byUuid[u]!.exercises.first.id],
        [
          exercises[2].id,
          exercises[0].id,
          exercises[1].id,
          exercises[3].id,
        ],
      );
    });

    test('orderByZone reorders with moveSlot and reduces the zone changes', () {
      final before = notifier.state.pages.where((p) => p.type == PageType.set).length;
      expect(notifier.orderByZone(), isTrue);

      expect(exerciseOrder(), [
        exercises[0].id,
        exercises[2].id,
        exercises[1].id,
        exercises[3].id,
      ]);
      expect(notifier.state.pages.where((p) => p.type == PageType.set).length, before);
      expect(currentZoneChanges(notifier.state.pages, order), 1);

      // Page indices are consistent
      final indices = notifier.state.pages.map((p) => p.pageIndex).toList();
      expect(indices, [...indices]..sort());

      // Nothing left to do
      expect(notifier.orderByZone(), isFalse);
    });

    test('orderByZone keeps pages that are done or started in place', () {
      final first = notifier.state.pages[1];
      for (final s in first.slotPages.where((s) => s.type == SlotPageType.log)) {
        notifier.markSlotPageAsDone(s.uuid, isDone: true);
      }
      // Start the second: crunches
      final second = notifier.state.pages[2];
      notifier.markSlotPageAsDone(
        second.slotPages.firstWhere((s) => s.type == SlotPageType.log).uuid,
        isDone: true,
      );

      notifier.orderByZone();
      expect(exerciseOrder(), [
        exercises[0].id,
        exercises[1].id,
        exercises[2].id,
        exercises[3].id,
      ]);
    });

    test('orderByZone does nothing without a zone order or zones', () {
      notifier.setZoneOrder(null);
      expect(notifier.orderByZone(), isFalse);
      notifier.setZoneOrder(ZoneOrder(items: [item(10, exercises[0].id, null, 0)]));
      expect(notifier.orderByZone(), isFalse);
    });

    test('changing the location drops the zone order', () {
      notifier.setLocationId(5);
      expect(notifier.state.locationId, 5);
      expect(notifier.state.zoneOrder, isNull);
    });

    test('budgetItems lists the sets that are open', () {
      final items = notifier.budgetItems();
      expect(items, hasLength(4));
      // bench: 10 reps * 4 s + 60 s rest = 100 s per set, 3 sets
      expect(items[0].setSeconds, [100, 100, 100]);
      expect(items[2].setSeconds, hasLength(4));

      final first = notifier.state.pages[1];
      notifier.markSlotPageAsDone(
        first.slotPages.firstWhere((s) => s.type == SlotPageType.log).uuid,
        isDone: true,
      );
      final after = notifier.budgetItems();
      expect(after[0].setSeconds, [100, 100]);
      expect(after[0].minKeep, 0);
    });

    test('dropSets removes the last open sets with their timers', () {
      final page = notifier.state.pages[3]; // deadlift, 4 sets
      final before = notifier.state.totalPages;

      expect(notifier.dropSets(page.uuid, 2), 2);

      final updated = notifier.state.pages[3];
      expect(updated.slotPages.where((s) => s.type == SlotPageType.log), hasLength(2));
      expect(updated.slotPages.where((s) => s.type == SlotPageType.timer), hasLength(2));
      expect(notifier.state.totalPages, before - 4);

      // Indices are consistent afterwards
      final all = [for (final p in notifier.state.pages) ...p.slotPages.map((s) => s.pageIndex)];
      expect(all, [...all]..sort());
    });

    test('applyBudgetDrops applies a suggestion', () {
      final items = notifier.budgetItems();
      // 12 sets * ~100 s: budget of 10 minutes needs a lot of drops
      final suggestion = suggestSetsToDrop(items, 10);
      expect(suggestion.totalDropped, greaterThan(0));
      final removed = notifier.applyBudgetDrops(suggestion.drops);
      expect(removed, suggestion.totalDropped);

      final after = estimateDurationSeconds(notifier.budgetItems());
      expect(after, suggestion.estimatedAfterSeconds);
    });
  });
}
