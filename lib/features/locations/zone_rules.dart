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

import 'package:wger/features/locations/models/training_location.dart';

/// Equipment ids of the zone that the location does not offer (the zone's
/// equipment must be a subset of the location's)
List<int> zoneEquipmentOutsideLocation(LocationZone zone, TrainingLocation location) {
  final available = location.equipmentIds.toSet();
  return [
    for (final id in zone.equipmentIds)
      if (!available.contains(id)) id,
  ];
}

/// Whether the zone's equipment is a subset of the location's
bool isZoneValidFor(LocationZone zone, TrainingLocation location) =>
    zoneEquipmentOutsideLocation(zone, location).isEmpty;

/// Zone with all equipment removed that is not available at the location
LocationZone pruneZoneEquipment(LocationZone zone, TrainingLocation location) {
  final available = location.equipmentIds.toSet();
  return zone.copyWith(
    equipmentIds: [
      for (final id in zone.equipmentIds)
        if (available.contains(id)) id,
    ],
  );
}

/// Moves the zone at [oldIndex] to [newIndex] (as given by the
/// ReorderableListView's \`onReorderItem\`, i.e. already adjusted for the
/// removed item) and renumbers the order from 0 so that it is gapless.
List<LocationZone> reorderZones(List<LocationZone> zones, int oldIndex, int newIndex) {
  final list = [...zones];
  if (oldIndex < 0 || oldIndex >= list.length) {
    return renumberZones(list);
  }
  final target = newIndex.clamp(0, list.length - 1);
  list.insert(target, list.removeAt(oldIndex));
  return renumberZones(list);
}

List<LocationZone> renumberZones(List<LocationZone> zones) => [
  for (var i = 0; i < zones.length; i++) zones[i].copyWith(order: i),
];

/// Whether the available time is sensible: empty or 1 to 600 minutes
bool isValidAvailableMinutes(String? value) {
  if (value == null || value.trim().isEmpty) {
    return true;
  }
  final minutes = int.tryParse(value.trim());
  return minutes != null && minutes >= 1 && minutes <= 600;
}
