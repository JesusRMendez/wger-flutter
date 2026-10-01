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

import 'package:equatable/equatable.dart';

/// One exercise of the suggested order, see `routine/{id}/zone-order/`
class ZoneOrderItem extends Equatable {
  final int slotId;
  final int slotEntryId;
  final int exerciseId;
  final int? zoneId;
  final String? zoneName;
  final int plannedIndex;

  const ZoneOrderItem({
    required this.slotId,
    required this.slotEntryId,
    required this.exerciseId,
    this.zoneId,
    this.zoneName,
    required this.plannedIndex,
  });

  factory ZoneOrderItem.fromJson(Map<String, dynamic> json) {
    return ZoneOrderItem(
      slotId: json['slot_id'] as int,
      slotEntryId: json['slot_entry_id'] as int,
      exerciseId: json['exercise_id'] as int,
      zoneId: json['zone_id'] as int?,
      zoneName: json['zone_name'] as String?,
      plannedIndex: json['planned_index'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [slotId, slotEntryId, exerciseId, zoneId, zoneName, plannedIndex];
}

/// An exercise whose equipment is not available at the location
class MissingEquipment extends Equatable {
  final int exerciseId;
  final Map<int, String> equipment;

  const MissingEquipment({required this.exerciseId, this.equipment = const {}});

  factory MissingEquipment.fromJson(Map<String, dynamic> json) {
    return MissingEquipment(
      exerciseId: json['exercise_id'] as int,
      equipment: {
        for (final e in (json['equipment'] as List? ?? const []))
          (e as Map<String, dynamic>)['id'] as int: e['name'] as String,
      },
    );
  }

  @override
  List<Object?> get props => [exerciseId, equipment];
}

/// Response of the zone-order endpoint (contract A)
class ZoneOrder extends Equatable {
  final int? locationId;
  final String? locationName;

  /// In the suggested order
  final List<ZoneOrderItem> items;
  final int zoneChangesPlanned;
  final int zoneChangesSuggested;
  final List<MissingEquipment> missingEquipment;

  const ZoneOrder({
    this.locationId,
    this.locationName,
    this.items = const [],
    this.zoneChangesPlanned = 0,
    this.zoneChangesSuggested = 0,
    this.missingEquipment = const [],
  });

  factory ZoneOrder.fromJson(Map<String, dynamic> json) {
    return ZoneOrder(
      locationId: json['location'] as int?,
      locationName: json['location_name'] as String?,
      items: [
        for (final e in (json['items'] as List? ?? const []))
          ZoneOrderItem.fromJson(e as Map<String, dynamic>),
      ],
      zoneChangesPlanned: json['zone_changes_planned'] as int? ?? 0,
      zoneChangesSuggested: json['zone_changes_suggested'] as int? ?? 0,
      missingEquipment: [
        for (final e in (json['missing_equipment'] as List? ?? const []))
          MissingEquipment.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  /// Whether the server knows the zones, i.e. at least one item has a zone
  bool get hasZones => items.any((i) => i.zoneId != null);

  /// Whether following the suggestion saves zone changes
  bool get suggestionHelps => zoneChangesSuggested < zoneChangesPlanned;

  @override
  List<Object?> get props => [
    locationId,
    locationName,
    items,
    zoneChangesPlanned,
    zoneChangesSuggested,
    missingEquipment,
  ];
}
