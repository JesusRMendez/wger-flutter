/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
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
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/features/nutrition/models/log.dart';
import 'package:wger/features/nutrition/models/meal.dart';
import 'package:wger/features/nutrition/models/meal_item.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/widgets/meal.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../test_data/nutritional_plans.dart';

class _StubNutritionNotifier extends NutritionNotifier {
  @override
  Stream<NutritionState> build() async* {
    yield const NutritionState();
  }
}

/// Records what the check buttons of a meal ask for
class _RecordingNotifier extends NutritionNotifier {
  static final calls = <String>[];

  @override
  Stream<NutritionState> build() async* {
    yield const NutritionState();
  }

  @override
  Future<void> logIngredientToDiary(
    MealItem mealItem,
    String planId, [
    DateTime? dateTime,
    String? mealId,
  ]) async {
    calls.add('log:${mealItem.ingredientId}:$planId:$mealId');
  }

  @override
  Future<void> deleteLog(String logId) async {
    calls.add('delete:$logId');
  }
}

void main() {
  Meal buildMeal() => Meal(
    id: 'aa000000-0000-4000-8000-000000000001',
    plan: 'bb000000-0000-4000-8000-000000000001',
    name: 'Breakfast',
    time: const TimeOfDay(hour: 8, minute: 0),
  );

  Widget renderMeal({bool isOnline = true}) {
    return ProviderScope(
      // The meal widget does not gate its actions on connectivity. Pinning the
      // network status to offline makes a re-introduced connectivity gate fail
      // this test.
      overrides: [
        networkStatusProvider.overrideWithValue(isOnline),
        nutritionProvider.overrideWith(() => _StubNutritionNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealWidget(buildMeal(), false, false),
          ),
        ),
      ),
    );
  }

  testWidgets('Add-ingredient button stays enabled when offline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(renderMeal(isOnline: false));
    await tester.pumpAndSettle();

    // Reveal the meal action buttons by entering editing mode.
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    final addButton = tester.widget<TextButton>(
      find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(TextButton),
      ),
    );

    expect(addButton.onPressed, isNotNull);
  });

  group('check buttons', () {
    Meal mealWithItem({bool logged = false}) {
      final item = MealItem(ingredientId: 1, amount: 100)..ingredient = ingredient1;
      return Meal(
        id: 'aa000000-0000-4000-8000-000000000001',
        plan: 'bb000000-0000-4000-8000-000000000001',
        name: 'Lunch',
        time: const TimeOfDay(hour: 12, minute: 0),
        mealItems: [item],
        diaryEntries: [
          if (logged)
            LogItem(
              id: 'log-1',
              planId: 'bb000000-0000-4000-8000-000000000001',
              mealId: 'aa000000-0000-4000-8000-000000000001',
              ingredientId: 1,
              amount: 100,
              datetime: DateTime.now(),
            ),
        ],
      );
    }

    Widget render(Meal meal) => ProviderScope(
      overrides: [nutritionProvider.overrideWith(() => _RecordingNotifier())],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: MealWidget(meal, false, false))),
      ),
    );

    setUp(_RecordingNotifier.calls.clear);

    testWidgets('lists the items with amount and energy and logs one when checked', (
      tester,
    ) async {
      await tester.pumpWidget(render(mealWithItem()));
      await tester.pumpAndSettle();

      expect(find.text('Water'), findsOneWidget);
      expect(find.textContaining('100 g ·'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(_RecordingNotifier.calls, [
        'log:1:bb000000-0000-4000-8000-000000000001:aa000000-0000-4000-8000-000000000001',
      ]);
    });

    testWidgets('an item logged today shows as checked and takes the entry back out', (
      tester,
    ) async {
      await tester.pumpWidget(render(mealWithItem(logged: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(_RecordingNotifier.calls, ['delete:log-1']);
    });
  });
}
