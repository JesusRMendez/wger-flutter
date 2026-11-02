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
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/exercises/models/equipment.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';
import 'package:wger/features/locations/screens/location_edit_screen.dart';
import 'package:wger/features/locations/screens/locations_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import 'fake_locations_repository.dart';

const bench = Equipment(id: 1, name: 'Bench');
const barbell = Equipment(id: 3, name: 'Barbell');
const mat = Equipment(id: 10, name: 'Gym mat');

void main() {
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget render(FakeLocationsRepository repo, {Widget home = const LocationsScreen()}) {
    return ProviderScope(
      overrides: [
        locationsRepositoryProvider.overrideWithValue(repo),
        exerciseEquipmentProvider.overrideWith(
          (ref) => Stream<List<Equipment>>.value(const [bench, barbell, mat]),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
        routes: {
          LocationEditScreen.routeName: (_) => const LocationEditScreen(),
        },
      ),
    );
  }

  testWidgets('shows the empty state', (tester) async {
    await tester.pumpWidget(render(FakeLocationsRepository()));
    await tester.pumpAndSettle();
    expect(find.textContaining('no training locations'), findsOneWidget);
  });

  testWidgets('shows a tab per location, the equipment as toggles, and deletes one', (
    tester,
  ) async {
    tall(tester);
    final repo = FakeLocationsRepository(
      locations: const [
        TrainingLocation(
          id: 1,
          name: 'Home',
          isDefault: true,
          equipmentIds: [1, 10],
          availableMinutes: 45,
        ),
        TrainingLocation(id: 2, name: 'Gym'),
      ],
    );
    await tester.pumpWidget(render(repo));
    await tester.pumpAndSettle();

    // The default location is shown first, with its equipment switched on
    expect(find.byKey(const ValueKey('location-tab-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('location-tab-2')), findsOneWidget);
    expect(find.text('2 pieces of equipment · 45 min · Default location'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byKey(const ValueKey('equipment-switch-1'))).value,
      isTrue,
    );
    expect(
      tester.widget<SwitchListTile>(find.byKey(const ValueKey('equipment-switch-3'))).value,
      isFalse,
    );

    // The other tab
    await tester.tap(find.byKey(const ValueKey('location-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('No equipment'), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-button')));
    await tester.pumpAndSettle();
    expect(repo.deletedLocations, [2]);
  });

  testWidgets('switching equipment saves the location and prunes its zones', (tester) async {
    tall(tester);
    final repo = FakeLocationsRepository(
      locations: const [
        TrainingLocation(id: 1, name: 'Gym', equipmentIds: [1, 3]),
      ],
      zones: const {
        1: [
          LocationZone(id: 7, locationId: 1, name: 'Racks', order: 0, equipmentIds: [3]),
        ],
      },
    );
    await tester.pumpWidget(render(repo));
    await tester.pumpAndSettle();

    // Switching something on
    await tester.tap(find.byKey(const ValueKey('equipment-switch-10')));
    await tester.pumpAndSettle();
    expect(repo.savedLocations.last.equipmentIds, [1, 3, 10]);
    expect(find.text('3 of 3'), findsOneWidget);

    // Switching the barbell off removes it from the zone as well
    await tester.tap(find.byKey(const ValueKey('equipment-switch-3')));
    await tester.pumpAndSettle();
    expect(repo.savedLocations.last.equipmentIds, [1, 10]);
    expect(repo.savedZones.single.equipmentIds, isEmpty);
    expect(find.text('2 of 3'), findsOneWidget);
  });

  testWidgets('creates a location with equipment, then adds a zone', (tester) async {
    tall(tester);
    final repo = FakeLocationsRepository();
    await tester.pumpWidget(render(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-location-button')));
    await tester.pumpAndSettle();

    // Zones need a saved location
    expect(find.byKey(const ValueKey('zones-save-first')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('location-name-field')), 'Garage');
    await tester.enterText(find.byKey(const ValueKey('location-minutes-field')), '50');

    await tester.tap(find.byKey(const ValueKey('location-equipment-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('equipment-option-1')));
    await tester.tap(find.byKey(const ValueKey('equipment-option-3')));
    await tester.tap(find.byKey(const ValueKey('equipment-picker-ok')));
    await tester.pumpAndSettle();
    expect(find.text('2 pieces of equipment'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('location-save-button')));
    await tester.tap(find.byKey(const ValueKey('location-save-button')));
    await tester.pumpAndSettle();

    final saved = repo.savedLocations.single;
    expect(saved.name, 'Garage');
    expect(saved.availableMinutes, 50);
    expect(saved.equipmentIds, [1, 3]);

    // Zones are available now
    expect(find.byKey(const ValueKey('zones-save-first')), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('add-zone-button')));
    await tester.tap(find.byKey(const ValueKey('add-zone-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('zone-name-field')), 'Racks');

    // Only the equipment of the location can be chosen for the zone
    await tester.tap(find.byKey(const ValueKey('zone-equipment-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('equipment-option-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('equipment-option-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('equipment-option-10')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('equipment-option-3')));
    await tester.tap(find.byKey(const ValueKey('equipment-picker-ok')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('zone-save-button')));
    await tester.pumpAndSettle();

    final zone = repo.savedZones.single;
    expect(zone.name, 'Racks');
    expect(zone.locationId, saved.id);
    expect(zone.equipmentIds, [3]);
    expect(find.text('Racks'), findsOneWidget);
  });

  testWidgets('validates the name and the minutes', (tester) async {
    tall(tester);
    final repo = FakeLocationsRepository();
    await tester.pumpWidget(render(repo, home: const LocationEditScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('location-minutes-field')), '0');
    await tester.ensureVisible(find.byKey(const ValueKey('location-save-button')));
    await tester.tap(find.byKey(const ValueKey('location-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a value'), findsOneWidget);
    expect(find.text('Enter a number between 1 and 600'), findsOneWidget);
    expect(repo.savedLocations, isEmpty);
  });

  testWidgets('removing location equipment prunes the zones that used it', (tester) async {
    tall(tester);
    final repo = FakeLocationsRepository(
      locations: const [
        TrainingLocation(id: 1, name: 'Gym', equipmentIds: [1, 3]),
      ],
      zones: const {
        1: [
          LocationZone(id: 7, locationId: 1, name: 'Racks', order: 0, equipmentIds: [3]),
        ],
      },
    );
    await tester.pumpWidget(render(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('location-edit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Racks'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('location-equipment-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('equipment-option-3')));
    await tester.tap(find.byKey(const ValueKey('equipment-picker-ok')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('location-save-button')));
    await tester.tap(find.byKey(const ValueKey('location-save-button')));
    await tester.pumpAndSettle();

    expect(repo.savedLocations.single.equipmentIds, [1]);
    expect(repo.savedZones.single.equipmentIds, isEmpty);
  });
}
