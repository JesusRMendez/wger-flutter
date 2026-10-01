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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/models/zone_order.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';
import 'package:wger/features/routines/logic/zone_order_logic.dart';
import 'package:wger/features/routines/models/slot_data.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/planning_card.dart';
import 'package:wger/features/routines/widgets/gym_mode/zone_chip.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/exercises.dart';
import '../../../../../test_data/routines.dart';
import '../../../locations/fake_locations_repository.dart';

SlotData slot(int exerciseIndex, int entryId, {int sets = 3, num? rest = 60, num reps = 10}) {
  final s = getTestSlot(
    getTestExercises()[exerciseIndex],
    sets: sets,
    restTime: rest,
    repetitions: reps,
  );
  for (final c in s.setConfigs) {
    c.slotEntryId = entryId;
  }
  return s;
}

ZoneOrderItem item(int entryId, int exerciseId, int zone, int planned) => ZoneOrderItem(
  slotId: entryId,
  slotEntryId: entryId,
  exerciseId: exerciseId,
  zoneId: zone,
  zoneName: 'Zone $zone',
  plannedIndex: planned,
);

void main() {
  final exercises = getTestExercises();
  late ProviderContainer container;
  late GymStateNotifier notifier;
  late FakeLocationsRepository currentRepo;

  final order = ZoneOrder(
    locationId: 2,
    locationName: 'Gym',
    zoneChangesPlanned: 3,
    zoneChangesSuggested: 1,
    items: [
      item(10, exercises[0].id, 1, 0),
      item(12, exercises[2].id, 1, 2),
      item(11, exercises[1].id, 2, 1),
    ],
    missingEquipment: [
      MissingEquipment(exerciseId: exercises[1].id, equipment: const {8: 'Bench'}),
    ],
  );

  FakeLocationsRepository repo({int? minutes}) => FakeLocationsRepository(
    locations: [
      const TrainingLocation(id: 1, name: 'Home'),
      TrainingLocation(id: 2, name: 'Gym', isDefault: true, availableMinutes: minutes),
    ],
    zoneOrder: order,
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    currentRepo = FakeLocationsRepository();
    container = ProviderContainer.test(
      overrides: [locationsRepositoryProvider.overrideWith((ref) => currentRepo)],
    );
    notifier = container.read(gymStateProvider.notifier);
    notifier.state = notifier.state.copyWith(
      showExercisePages: false,
      showTimerPages: true,
      dayId: 1,
      iteration: 1,
      routine: getTestRoutineWithSlots([
        slot(0, 10),
        slot(1, 11),
        slot(2, 12),
      ]),
    );
    notifier.calculatePages();
  });

  Widget render(FakeLocationsRepository fake, {Widget? child}) {
    currentRepo = fake;
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child ?? const GymPlanningCard())),
      ),
    );
  }

  testWidgets('preselects the default location and loads its zone order', (tester) async {
    final fake = repo();
    await tester.pumpWidget(render(fake));
    await tester.pumpAndSettle();

    expect(container.read(gymStateProvider).locationId, 2);
    expect(container.read(gymStateProvider).zoneOrder, order);
    expect(fake.zoneOrderRequests.single.locationId, 2);
    expect(find.text('Zone changes: 2 → 1'), findsOneWidget);
  });

  testWidgets('another location fetches its own order', (tester) async {
    final fake = repo();
    await tester.pumpWidget(render(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('gym-location-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    expect(container.read(gymStateProvider).locationId, 1);
    expect(fake.zoneOrderRequests.last.locationId, 1);
  });

  testWidgets('orders by zone with moveSlot and updates the zone changes', (tester) async {
    await tester.pumpWidget(render(repo()));
    await tester.pumpAndSettle();

    final names = [
      for (final p in container.read(gymStateProvider).pages)
        if (p.type == PageType.set) p.exercises.first.id,
    ];
    expect(names, [exercises[0].id, exercises[1].id, exercises[2].id]);

    await tester.tap(find.byKey(const ValueKey('order-by-zone-button')));
    await tester.pumpAndSettle();

    final state = container.read(gymStateProvider);
    expect(
      [
        for (final p in state.pages)
          if (p.type == PageType.set) p.exercises.first.id,
      ],
      [exercises[0].id, exercises[2].id, exercises[1].id],
    );
    expect(currentZoneChanges(state.pages, order), 1);
    expect(find.text('Zone changes: 1 → 1'), findsOneWidget);
    expect(find.text('The remaining exercises were ordered by zone.'), findsOneWidget);

    // Nothing more to gain: the button is disabled
    final button = tester.widget<FilledButton>(find.byKey(const ValueKey('order-by-zone-button')));
    expect(button.onPressed, isNull);
  });

  testWidgets('warns about missing equipment', (tester) async {
    await tester.pumpWidget(render(repo()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('missing-equipment-warning')), findsOneWidget);
    expect(find.text('Missing equipment at Gym'), findsOneWidget);
    expect(find.textContaining('Bench'), findsOneWidget);
  });

  testWidgets('without locations it offers to set them up and keeps the budget', (tester) async {
    await tester.pumpWidget(render(FakeLocationsRepository()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gym-set-up-locations')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-budget-30')), findsOneWidget);
  });

  group('time budget', () {
    // 3 exercises * 3 sets * (40 s + 60 s) = 900 s = 15 min
    testWidgets('shows the estimate and the chips including the location minutes', (tester) async {
      await tester.pumpWidget(render(repo(minutes: 50)));
      await tester.pumpAndSettle();

      expect(find.text('Estimated duration: 15 min'), findsOneWidget);
      for (final m in [30, 45, 50, 60, 75]) {
        expect(find.byKey(ValueKey('time-budget-$m')), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('time-budget-30')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('budget-fits')), findsOneWidget);
    });

    testWidgets('suggests sets to drop and applies them', (tester) async {
      notifier.state = notifier.state.copyWith(
        routine: getTestRoutineWithSlots([
          slot(0, 10, sets: 6, reps: 20),
          slot(1, 11, sets: 6, reps: 20),
          slot(2, 12, sets: 6, reps: 20),
        ]),
      );
      notifier.calculatePages();

      // 18 sets * (80 + 60) = 2520 s = 42 min
      await tester.pumpWidget(render(repo()));
      await tester.pumpAndSettle();
      expect(find.text('Estimated duration: 42 min'), findsOneWidget);

      container.read(gymStateProvider.notifier).setTimeBudget(30);
      await tester.pumpAndSettle();

      // 1800 s: 5 sets (700 s) have to go
      expect(find.byKey(const ValueKey('budget-suggestion')), findsOneWidget);
      expect(find.textContaining('Drop 6 sets'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('apply-time-budget')));
      await tester.pumpAndSettle();

      final sets = container
          .read(gymStateProvider)
          .pages
          .where((p) => p.type == PageType.set)
          .map((p) => p.slotPages.where((s) => s.type == SlotPageType.log).length);
      expect(sets.fold(0, (a, b) => a + b), 12);
      expect(find.text('Estimated duration: 28 min'), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-fits')), findsOneWidget);
    });
  });

  testWidgets('the zone chip shows the zone and missing equipment', (tester) async {
    notifier.setZoneOrder(order);
    final pages = container.read(gymStateProvider).pages.where((p) => p.type == PageType.set);

    await tester.pumpWidget(
      render(
        repo(),
        child: Column(children: [for (final p in pages) ZoneChip(p)]),
      ),
    );
    await tester.pump();

    expect(find.text('Zone 1'), findsNWidgets(2));
    expect(find.text('Zone 2'), findsOneWidget);
    expect(find.text('Equipment missing'), findsOneWidget);
  });
}
