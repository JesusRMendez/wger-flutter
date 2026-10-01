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
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/coach/models/meal_proposal.dart';
import 'package:wger/features/coach/screens/meal_plan_screen.dart';
import 'package:wger/features/nutrition/screens/nutritional_plan_screen.dart';

import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

void main() {
  testWidgets('generates a plan with meals, totals and unlinked items', (tester) async {
    final repo = FakeCoachRepository();
    await pumpCoach(tester, const MealPlanScreen(), repo);

    await tester.enterText(find.byKey(const ValueKey('mp-kcal')), '2250');
    await tester.tap(find.byKey(const ValueKey('mp-generate')));
    await tester.pumpAndSettle();

    expect(find.text('Cut plan'), findsOneWidget);
    expect(find.text('Breakfast · 08:00'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);
    expect(find.text('80 g'), findsOneWidget);
    expect(find.textContaining('2260 kcal'), findsOneWidget);
    expect(find.textContaining('Skipped items: Mystery bar'), findsOneWidget);
  });

  testWidgets('apply lists skipped items and opens the plan', (tester) async {
    final repo = FakeCoachRepository()
      ..mealApplyResult = const MealPlanApplyResult(
        nutritionPlanId: 'plan-1',
        skipped: ['Mystery bar'],
      );
    final pushed = await pumpCoach(tester, const MealPlanScreen(), repo);

    await tester.tap(find.byKey(const ValueKey('mp-generate')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mp-apply')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('mp-apply')));
    await tester.pumpAndSettle();

    expect(repo.calls, ['apply-meal']);
    await tester.scrollUntilVisible(
      find.text('• Mystery bar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('• Mystery bar'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mp-open')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('mp-open')));
    await tester.pumpAndSettle();
    expect(pushed, [NutritionalPlanScreen.routeName]);
  });
}
