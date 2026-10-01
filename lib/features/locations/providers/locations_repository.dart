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
import 'package:wger/core/consts.dart';
import 'package:wger/core/network/base_provider.dart';
import 'package:wger/core/network/wger_base.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/models/zone_order.dart';

/// Read per operation, like the other repositories
final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(ref.read(wgerBaseProvider));
});

/// REST access for training locations, their zones and the zone order of a
/// routine day.
class LocationsRepository {
  LocationsRepository(this._base);

  final WgerBaseProvider _base;

  static const locationPath = 'training-location';
  static const zonePath = 'location-zone';
  static const routinePath = 'routine';
  static const zoneOrderSubpath = 'zone-order';

  Future<List<TrainingLocation>> fetchLocations() async {
    final url = _base.makeUrl(locationPath, query: {'limit': API_MAX_PAGE_SIZE});
    final data = await _base.fetchPaginated(url);
    return data.map((e) => TrainingLocation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TrainingLocation> saveLocation(TrainingLocation location) async {
    final Map<String, dynamic> data;
    if (location.id == null) {
      data = await _base.post(location.toJson(), _base.makeUrl(locationPath));
    } else {
      data = await _base.patch(
        location.toJson(),
        _base.makeUrl(locationPath, id: location.id),
      );
    }
    return TrainingLocation.fromJson(data);
  }

  Future<void> deleteLocation(int id) async {
    await _base.deleteRequest(locationPath, id);
  }

  Future<List<LocationZone>> fetchZones(int locationId) async {
    final url = _base.makeUrl(
      zonePath,
      query: {'limit': API_MAX_PAGE_SIZE, 'location': locationId.toString()},
    );
    final data = await _base.fetchPaginated(url);
    final zones = data
        .map((e) => LocationZone.fromJson(e as Map<String, dynamic>))
        .where((z) => z.locationId == locationId)
        .toList();
    zones.sort((a, b) => a.order.compareTo(b.order));
    return zones;
  }

  Future<LocationZone> saveZone(LocationZone zone) async {
    final Map<String, dynamic> data;
    if (zone.id == null) {
      data = await _base.post(zone.toJson(), _base.makeUrl(zonePath));
    } else {
      data = await _base.patch(zone.toJson(), _base.makeUrl(zonePath, id: zone.id));
    }
    return LocationZone.fromJson(data);
  }

  Future<void> deleteZone(int id) async {
    await _base.deleteRequest(zonePath, id);
  }

  /// Suggested order of the exercises of a routine day. Without a
  /// [locationId] the server uses the default location of the user.
  Future<ZoneOrder> fetchZoneOrder({
    required int routineId,
    required int dayId,
    int? locationId,
  }) async {
    final url = _base.makeUrl(
      routinePath,
      id: routineId,
      objectMethod: zoneOrderSubpath,
      query: {
        'day': dayId.toString(),
        if (locationId != null) 'location': locationId.toString(),
      },
    );
    final data = await _base.fetch(url);
    return ZoneOrder.fromJson(data as Map<String, dynamic>);
  }
}

final trainingLocationsProvider = FutureProvider.autoDispose<List<TrainingLocation>>((ref) {
  return ref.read(locationsRepositoryProvider).fetchLocations();
});

final locationZonesProvider = FutureProvider.autoDispose.family<List<LocationZone>, int>((
  ref,
  locationId,
) {
  return ref.read(locationsRepositoryProvider).fetchZones(locationId);
});
