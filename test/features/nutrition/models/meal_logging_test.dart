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

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/nutrition/models/log.dart';
import 'package:wger/features/nutrition/models/meal.dart';
import 'package:wger/features/nutrition/models/meal_item.dart';

import '../../../../test_data/nutritional_plans.dart';

void main() {
  Meal meal() {
    final item = MealItem(ingredientId: 1, amount: 100)..ingredient = ingredient1;
    final item2 = MealItem(ingredientId: 2, amount: 75)..ingredient = ingredient2;
    return Meal(
      id: 'm1',
      plan: 'p1',
      name: 'Lunch',
      time: const TimeOfDay(hour: 12, minute: 0),
      mealItems: [item, item2],
    );
  }

  LogItem log(int ingredientId, num amount, {DateTime? at, String? mealId = 'm1'}) => LogItem(
    planId: 'p1',
    mealId: mealId,
    ingredientId: ingredientId,
    amount: amount,
    datetime: at ?? DateTime.now(),
  );

  test('an item is logged when today has an entry of the same ingredient and amount', () {
    final m = meal();
    expect(m.loggedEntryFor(m.mealItems[0]), isNull);
    expect(m.isCompletedToday, isFalse);

    m.diaryEntries = [log(1, 100)];
    expect(m.loggedEntryFor(m.mealItems[0]), isNotNull);
    expect(m.loggedEntryFor(m.mealItems[1]), isNull);
    expect(m.isCompletedToday, isFalse);

    m.diaryEntries = [log(1, 100), log(2, 75)];
    expect(m.isCompletedToday, isTrue);
  });

  test('entries of other days, amounts or meals do not count', () {
    final m = meal();
    m.diaryEntries = [
      log(1, 100, at: DateTime.now().subtract(const Duration(days: 1))),
      log(1, 50),
      log(1, 100, mealId: 'other'),
    ];
    expect(m.loggedEntryFor(m.mealItems[0]), isNull);

    // Free entries without a meal still count for the item they match
    m.diaryEntries = [log(1, 100, mealId: null)];
    expect(m.loggedEntryFor(m.mealItems[0]), isNotNull);
  });

  test('a meal without items is never completed', () {
    expect(Meal(id: 'm', plan: 'p', name: 'x').isCompletedToday, isFalse);
  });
}
