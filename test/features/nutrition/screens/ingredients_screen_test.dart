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
import 'package:wger/features/nutrition/models/log.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/providers/ingredient_notifier.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/screens/ingredients_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../test_data/nutritional_plans.dart';

class _FixedNutrition extends NutritionNotifier {
  _FixedNutrition(this.plan);

  final NutritionalPlan plan;

  @override
  Stream<NutritionState> build() async* {
    yield NutritionState(plans: [plan]);
  }
}

void main() {
  Widget render() {
    // Broccoli cake was eaten (300 g) and then Water (100 g), Burger soup never
    final plan = getNutritionalPlan()
      ..diaryEntries = [
        LogItem(
          planId: 'p',
          ingredientId: 3,
          amount: 300,
          datetime: DateTime(2026, 1, 1),
        )..ingredient = ingredient3,
        LogItem(
          planId: 'p',
          ingredientId: 1,
          amount: 100,
          datetime: DateTime(2026, 1, 2),
        )..ingredient = ingredient1,
      ];

    return ProviderScope(
      overrides: [
        allLocalIngredientsProvider.overrideWith(
          (ref) => Stream.value([ingredient1, ingredient2, ingredient3]),
        ),
        nutritionProvider.overrideWith(() => _FixedNutrition(plan)),
      ],
      child: const MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IngredientsScreen(),
      ),
    );
  }

  testWidgets('lists all the ingredients with their values for 100 g', (tester) async {
    await tester.pumpWidget(render());
    await tester.pumpAndSettle();
    // The "All" chip is selected after the recent ones were looked at
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text(ingredient1.name), findsOneWidget);
    expect(find.text(ingredient2.name), findsOneWidget);
    expect(find.text(ingredient3.name), findsOneWidget);
    expect(find.textContaining('100 g ·'), findsNWidgets(3));
  });

  testWidgets('Recent shows what was logged lately, newest first, at the amount eaten', (
    tester,
  ) async {
    await tester.pumpWidget(render());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();

    // Burger soup was never logged
    expect(find.text(ingredient2.name), findsNothing);
    final water = tester.getTopLeft(find.text(ingredient1.name)).dy;
    final broccoli = tester.getTopLeft(find.text(ingredient3.name)).dy;
    expect(water, lessThan(broccoli));
    expect(find.textContaining('300 g ·'), findsOneWidget);
  });
}
