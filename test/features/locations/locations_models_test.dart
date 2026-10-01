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
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wger/core/network/base_provider.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/models/zone_order.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';
import 'package:wger/features/locations/zone_rules.dart';

import 'locations_models_test.mocks.dart';

@GenerateMocks([WgerBaseProvider])
void main() {
  group('models', () {
    test('TrainingLocation json', () {
      final location = TrainingLocation.fromJson(const {
        'id': 3,
        'name': 'Gym',
        'is_default': true,
        'equipment': [1, 2],
        'available_minutes': 60,
      });
      expect(location.id, 3);
      expect(location.isDefault, isTrue);
      expect(location.equipmentIds, [1, 2]);
      expect(location.availableMinutes, 60);
      expect(location.toJson(), {
        'name': 'Gym',
        'is_default': true,
        'equipment': [1, 2],
        'available_minutes': 60,
      });
      expect(TrainingLocation.fromJson(const {'id': 1, 'name': 'x'}).availableMinutes, isNull);
      expect(
        location.copyWith(clearAvailableMinutes: true).availableMinutes,
        isNull,
      );
    });

    test('LocationZone json', () {
      final zone = LocationZone.fromJson(const {
        'id': 5,
        'location': 3,
        'name': 'Racks',
        'order': 2,
        'equipment': [3],
      });
      expect(zone.locationId, 3);
      expect(zone.order, 2);
      expect(zone.toJson(), {
        'location': 3,
        'name': 'Racks',
        'order': 2,
        'equipment': [3],
      });
    });

    test('ZoneOrder json (contract A)', () {
      final order = ZoneOrder.fromJson(const {
        'location': 3,
        'location_name': 'Gym centro',
        'items': [
          {
            'slot_id': 10,
            'slot_entry_id': 22,
            'exercise_id': 192,
            'zone_id': 5,
            'zone_name': 'Rack y barras',
            'planned_index': 0,
          },
          {
            'slot_id': 11,
            'slot_entry_id': 23,
            'exercise_id': 193,
            'zone_id': null,
            'zone_name': null,
            'planned_index': 1,
          },
        ],
        'zone_changes_planned': 4,
        'zone_changes_suggested': 2,
        'missing_equipment': [
          {
            'exercise_id': 88,
            'equipment': [
              {'id': 8, 'name': 'Bench'},
            ],
          },
        ],
      });
      expect(order.locationName, 'Gym centro');
      expect(order.items, hasLength(2));
      expect(order.items.first.zoneName, 'Rack y barras');
      expect(order.items.last.zoneId, isNull);
      expect(order.hasZones, isTrue);
      expect(order.suggestionHelps, isTrue);
      expect(order.missingEquipment.single.equipment, {8: 'Bench'});
    });

    test('ZoneOrder without zones', () {
      final order = ZoneOrder.fromJson(const {'location': null, 'items': []});
      expect(order.hasZones, isFalse);
      expect(order.suggestionHelps, isFalse);
    });
  });

  group('zone rules', () {
    const location = TrainingLocation(id: 1, name: 'Gym', equipmentIds: [1, 2, 3]);
    const zone = LocationZone(locationId: 1, name: 'A', equipmentIds: [2, 9]);

    test('equipment of a zone must be part of the location', () {
      expect(zoneEquipmentOutsideLocation(zone, location), [9]);
      expect(isZoneValidFor(zone, location), isFalse);
      expect(isZoneValidFor(zone.copyWith(equipmentIds: [1, 2]), location), isTrue);
      expect(pruneZoneEquipment(zone, location).equipmentIds, [2]);
    });

    test('reorderZones moves and renumbers', () {
      final zones = [
        for (var i = 0; i < 4; i++) LocationZone(id: i, locationId: 1, name: '$i', order: i * 10),
      ];
      var out = reorderZones(zones, 3, 0);
      expect([for (final z in out) z.id], [3, 0, 1, 2]);
      expect([for (final z in out) z.order], [0, 1, 2, 3]);

      out = reorderZones(zones, 0, 2);
      expect([for (final z in out) z.id], [1, 2, 0, 3]);

      out = reorderZones(zones, 9, 0);
      expect([for (final z in out) z.id], [0, 1, 2, 3]);
    });

    test('available minutes validation', () {
      expect(isValidAvailableMinutes(null), isTrue);
      expect(isValidAvailableMinutes(' '), isTrue);
      expect(isValidAvailableMinutes('45'), isTrue);
      expect(isValidAvailableMinutes('0'), isFalse);
      expect(isValidAvailableMinutes('abc'), isFalse);
      expect(isValidAvailableMinutes('601'), isFalse);
    });
  });

  group('repository', () {
    late MockWgerBaseProvider base;
    late LocationsRepository repository;

    setUp(() {
      base = MockWgerBaseProvider();
      repository = LocationsRepository(base);
      when(
        base.makeUrl(
          any,
          id: anyNamed('id'),
          objectMethod: anyNamed('objectMethod'),
          query: anyNamed('query'),
        ),
      ).thenAnswer((i) => Uri.parse('https://example.org/${i.positionalArguments.first}'));
    });

    test('fetches the locations', () async {
      when(base.fetchPaginated(any)).thenAnswer(
        (_) async => [
          {
            'id': 1,
            'name': 'Home',
            'is_default': false,
            'equipment': [],
            'available_minutes': null,
          },
        ],
      );
      final out = await repository.fetchLocations();
      expect(out.single.name, 'Home');
    });

    test('fetches the zones of a location sorted by order', () async {
      when(base.fetchPaginated(any)).thenAnswer(
        (_) async => [
          {'id': 2, 'location': 1, 'name': 'B', 'order': 1, 'equipment': []},
          {'id': 1, 'location': 1, 'name': 'A', 'order': 0, 'equipment': []},
          {'id': 3, 'location': 2, 'name': 'other', 'order': 0, 'equipment': []},
        ],
      );
      final out = await repository.fetchZones(1);
      expect([for (final z in out) z.name], ['A', 'B']);
    });

    test('creates and updates', () async {
      when(base.post(any, any)).thenAnswer(
        (_) async => {
          'id': 7,
          'name': 'New',
          'is_default': false,
          'equipment': [1],
        },
      );
      when(base.patch(any, any)).thenAnswer(
        (_) async => {'id': 7, 'name': 'Renamed', 'is_default': false, 'equipment': []},
      );

      final created = await repository.saveLocation(
        const TrainingLocation(name: 'New', equipmentIds: [1]),
      );
      expect(created.id, 7);
      verify(
        base.post({
          'name': 'New',
          'is_default': false,
          'equipment': [1],
          'available_minutes': null,
        }, any),
      ).called(1);

      final updated = await repository.saveLocation(created.copyWith(name: 'Renamed'));
      expect(updated.name, 'Renamed');
      verify(base.patch(any, any)).called(1);
    });

    test('fetches the zone order', () async {
      when(base.fetch(any)).thenAnswer(
        (_) async => {
          'location': 3,
          'location_name': 'Gym',
          'items': [],
          'zone_changes_planned': 1,
          'zone_changes_suggested': 0,
          'missing_equipment': [],
        },
      );
      final order = await repository.fetchZoneOrder(routineId: 7, dayId: 2, locationId: 3);
      expect(order.locationId, 3);
      verify(
        base.makeUrl(
          'routine',
          id: 7,
          objectMethod: 'zone-order',
          query: {'day': '2', 'location': '3'},
        ),
      ).called(1);

      await repository.fetchZoneOrder(routineId: 7, dayId: 2);
      verify(
        base.makeUrl('routine', id: 7, objectMethod: 'zone-order', query: {'day': '2'}),
      ).called(1);
    });
  });
}
