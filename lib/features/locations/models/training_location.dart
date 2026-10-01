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

/// A place where the user trains (home, gym, ...) with the equipment that is
/// available there.
class TrainingLocation extends Equatable {
  final int? id;
  final String name;
  final bool isDefault;
  final List<int> equipmentIds;

  /// Time the user usually has available at this location, in minutes
  final int? availableMinutes;

  const TrainingLocation({
    this.id,
    required this.name,
    this.isDefault = false,
    this.equipmentIds = const [],
    this.availableMinutes,
  });

  factory TrainingLocation.fromJson(Map<String, dynamic> json) {
    return TrainingLocation(
      id: json['id'] as int?,
      name: json['name'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      equipmentIds: [for (final e in (json['equipment'] as List? ?? const [])) e as int],
      availableMinutes: json['available_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'is_default': isDefault,
    'equipment': equipmentIds,
    'available_minutes': availableMinutes,
  };

  TrainingLocation copyWith({
    int? id,
    String? name,
    bool? isDefault,
    List<int>? equipmentIds,
    int? availableMinutes,
    bool clearAvailableMinutes = false,
  }) {
    return TrainingLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      availableMinutes: clearAvailableMinutes ? null : (availableMinutes ?? this.availableMinutes),
    );
  }

  @override
  List<Object?> get props => [id, name, isDefault, equipmentIds, availableMinutes];
}

/// An area of a [TrainingLocation], e.g. "Racks" or "Machines". The zones are
/// visited in their [order] and only offer a subset of the location's equipment.
class LocationZone extends Equatable {
  final int? id;
  final int locationId;
  final String name;
  final int order;
  final List<int> equipmentIds;

  const LocationZone({
    this.id,
    required this.locationId,
    required this.name,
    this.order = 0,
    this.equipmentIds = const [],
  });

  factory LocationZone.fromJson(Map<String, dynamic> json) {
    return LocationZone(
      id: json['id'] as int?,
      locationId: json['location'] as int,
      name: json['name'] as String,
      order: json['order'] as int? ?? 0,
      equipmentIds: [for (final e in (json['equipment'] as List? ?? const [])) e as int],
    );
  }

  Map<String, dynamic> toJson() => {
    'location': locationId,
    'name': name,
    'order': order,
    'equipment': equipmentIds,
  };

  LocationZone copyWith({
    int? id,
    int? locationId,
    String? name,
    int? order,
    List<int>? equipmentIds,
  }) {
    return LocationZone(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      order: order ?? this.order,
      equipmentIds: equipmentIds ?? this.equipmentIds,
    );
  }

  @override
  List<Object?> get props => [id, locationId, name, order, equipmentIds];
}
