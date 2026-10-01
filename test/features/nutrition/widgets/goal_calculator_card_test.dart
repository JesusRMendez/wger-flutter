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
import 'package:wger/features/nutrition/widgets/goal_calculator_card.dart';

void main() {
  group('CalorieEstimate', () {
    test('maintenance is about 33 kcal per kg and the macros add up to the energy', () {
      final e = CalorieEstimate.from(80, CalorieGoal.maintain);
      expect(e.energy, 2640);
      expect(e.deltaPercent, 0);
      expect(e.kgPerWeek, closeTo(0, 0.01));
      final macros = e.protein * 4 + e.carbohydrates * 4 + e.fat * 9;
      expect(macros, closeTo(e.energy, 60));
    });

    test('losing fat is a 15 % deficit with the weekly loss it implies', () {
      final e = CalorieEstimate.from(80, CalorieGoal.loseFat);
      expect(e.energy, 2240);
      expect(e.deltaPercent, -15);
      expect(e.kgPerWeek, closeTo(-0.36, 0.02));
      // More protein than at maintenance
      expect(e.protein, greaterThan(CalorieEstimate.from(80, CalorieGoal.maintain).protein));
    });

    test('gaining muscle is a 10 % surplus', () {
      final e = CalorieEstimate.from(80, CalorieGoal.gainMuscle);
      expect(e.energy, 2900);
      expect(e.deltaPercent, 10);
      expect(e.kgPerWeek, greaterThan(0));
    });

    test('carbohydrates never go negative for a tiny energy budget', () {
      expect(CalorieEstimate.from(30, CalorieGoal.loseFat).carbohydrates, greaterThanOrEqualTo(0));
    });
  });
}
