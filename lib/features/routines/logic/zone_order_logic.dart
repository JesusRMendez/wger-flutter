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

import 'package:wger/features/locations/models/zone_order.dart';
import 'package:wger/features/routines/providers/gym_state.dart';

/// The item of the zone order that belongs to the exercise(s) of [page].
///
/// An item is matched by slot entry and exercise, then by the slot entry
/// alone (the exercise may have been swapped in the workout) and finally by the
/// exercise alone (the page may have been added in the workout). For
/// supersets the earliest item in the suggested order is used.
ZoneOrderItem? zoneItemForPage(PageEntry page, ZoneOrder order) {
  final configs = [
    for (final slotPage in page.slotPages)
      if (slotPage.setConfigData != null) slotPage.setConfigData!,
  ];
  if (configs.isEmpty) {
    return null;
  }

  ZoneOrderItem? find(bool Function(ZoneOrderItem item) test) {
    for (final item in order.items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }

  final entryAndExercise = {for (final c in configs) (c.slotEntryId, c.exercise.id)};
  final entries = {for (final c in configs) c.slotEntryId};
  final exercises = {for (final c in configs) c.exercise.id};

  return find((i) => entryAndExercise.contains((i.slotEntryId, i.exerciseId))) ??
      find((i) => entries.contains(i.slotEntryId)) ??
      find((i) => exercises.contains(i.exerciseId));
}

/// Number of times the zone changes when the zones are visited in this order.
/// Unknown zones (null) are ignored, they neither start nor end a block.
int countZoneChanges(Iterable<int?> zoneIds) {
  var changes = 0;
  int? previous;
  for (final zone in zoneIds) {
    if (zone == null) {
      continue;
    }
    if (previous != null && zone != previous) {
      changes++;
    }
    previous = zone;
  }
  return changes;
}

/// Zone changes of the set pages in their current order
int currentZoneChanges(List<PageEntry> pages, ZoneOrder order) {
  return countZoneChanges([
    for (final page in pages)
      if (page.type == PageType.set) zoneItemForPage(page, order)?.zoneId,
  ]);
}

/// UUIDs of the movable pages in the order suggested by [order].
///
/// Pages that the zone order does not know keep their place relative to the
/// page in front of them, so they stay next to what they followed. The sort
/// is stable: pages in the same position of the suggestion keep their order.
List<String> suggestedPageOrder(List<PageEntry> pages, ZoneOrder order) {
  final movable = pages.where((p) => p.isMovable).toList();
  final indexOf = {for (var i = 0; i < order.items.length; i++) order.items[i]: i};

  var lastKey = -1.0;
  final keyed = <(double, int, String)>[];
  for (var rank = 0; rank < movable.length; rank++) {
    final item = zoneItemForPage(movable[rank], order);
    final key = item == null ? lastKey + 0.5 : indexOf[item]!.toDouble();
    keyed.add((key, rank, movable[rank].uuid));
    lastKey = key;
  }

  keyed.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return [for (final k in keyed) k.$3];
}
