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
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/models/zone_order.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';

/// In-memory stand-in for the REST repository
class FakeLocationsRepository extends Fake implements LocationsRepository {
  final List<TrainingLocation> locations;
  final Map<int, List<LocationZone>> zones;
  ZoneOrder? zoneOrder;

  final List<TrainingLocation> savedLocations = [];
  final List<LocationZone> savedZones = [];
  final List<int> deletedLocations = [];
  final List<int> deletedZones = [];
  final List<({int? locationId})> zoneOrderRequests = [];

  int _nextId = 100;

  FakeLocationsRepository({this.locations = const [], this.zones = const {}, this.zoneOrder});

  @override
  Future<List<TrainingLocation>> fetchLocations() async => locations;

  @override
  Future<TrainingLocation> saveLocation(TrainingLocation location) async {
    final saved = location.id == null ? location.copyWith(id: _nextId++) : location;
    savedLocations.add(saved);
    return saved;
  }

  @override
  Future<void> deleteLocation(int id) async => deletedLocations.add(id);

  @override
  Future<List<LocationZone>> fetchZones(int locationId) async => zones[locationId] ?? [];

  @override
  Future<LocationZone> saveZone(LocationZone zone) async {
    final saved = zone.id == null ? zone.copyWith(id: _nextId++) : zone;
    savedZones.add(saved);
    return saved;
  }

  @override
  Future<void> deleteZone(int id) async => deletedZones.add(id);

  @override
  Future<ZoneOrder> fetchZoneOrder({
    required int routineId,
    required int dayId,
    int? locationId,
  }) async {
    zoneOrderRequests.add((locationId: locationId));
    final order = zoneOrder;
    if (order == null) {
      throw Exception('no zone order');
    }
    return order;
  }
}
