/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/database/powersync/database.dart';
import 'package:wger/features/exercises/models/category.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/providers/exercise_filter_state.dart';
import 'package:wger/features/exercises/providers/exercise_filters_notifier.dart';
import 'package:wger/features/exercises/screens/exercise_screen.dart';
import 'package:wger/features/exercises/screens/exercises_screen.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../test_data/screenshots/exercises.dart';
import '../../../../test_data/screenshots/routines.dart';
import '../../../helpers/fake_connectivity.dart';

class _FakeFilters extends ExerciseListFiltersNotifier {
  _FakeFilters(this.exercises);
  final List<Exercise> exercises;

  @override
  ExerciseFilterState build() {
    final categories = {for (final e in exercises) e.category: false};
    return ExerciseFilterState(
      exercises: exercises,
      filteredExercises: exercises,
      filters: Filters(
        exerciseCategories: FilterCategory<ExerciseCategory>(title: 'Category', items: categories),
      ),
    );
  }
}

class _StubRoutines extends RoutinesRiverpod {
  @override
  Stream<RoutinesState> build() => Stream.value(RoutinesState(routines: [getScreenshotRoutine()]));
}

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    networkStatusProvider.overrideWithValue(true),
    driftPowerSyncDatabase.overrideWithValue(DriftPowersyncDatabase(NativeDatabase.memory())),
    ...overrides,
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  installFakeConnectivity();
  final exercises = getScreenshotExercises();

  testWidgets('exercise list: search hint with the total, category chips and a count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(const ExercisesScreen(), [
        exerciseListFiltersProvider.overrideWith(() => _FakeFilters(exercises)),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search among ${exercises.length} exercises'), findsOneWidget);
    expect(find.text('${exercises.length} exercises'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-chip-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-exercise-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-filter-button')), findsOneWidget);

    // Picking a category narrows the list to it
    final category = exercises.first.category;
    await tester.tap(find.byKey(ValueKey('category-chip-${category.id}')));
    await tester.pumpAndSettle();
    final expected = exercises.where((e) => e.category == category).length;
    expect(find.text('$expected exercise${expected == 1 ? '' : 's'}'), findsOneWidget);

    // "All" clears it again
    await tester.tap(find.byKey(const ValueKey('category-chip-all')));
    await tester.pumpAndSettle();
    expect(find.text('${exercises.length} exercises'), findsOneWidget);
  });

  testWidgets('exercise page: chips, tabs, technique and the own history', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.of(c).push(
              MaterialPageRoute<void>(
                settings: RouteSettings(arguments: exercises.first),
                builder: (_) => const ExerciseDetailScreen(),
              ),
            ),
            child: const SizedBox(),
          ),
        ),
        [routinesRiverpodProvider.overrideWith(_StubRoutines.new)],
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-technique')), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exercise-tab-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-history')), findsOneWidget);
    expect(find.text('SESSIONS'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exercise-tab-alternatives')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-alternatives-empty')), findsOneWidget);

    // Let the pending provider timers run out
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
