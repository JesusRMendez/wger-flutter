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

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/measurements/models/unit_conversion.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/nutrition/models/meal.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/widgets/charts.dart';
import 'package:wger/features/nutrition/widgets/macro_nutrients_table.dart';
import 'package:wger/features/nutrition/widgets/meal.dart';
import 'package:wger/features/nutrition/widgets/nutritional_diary_table.dart';
import 'package:wger/features/nutrition/widgets/plan_weight_chart.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class NutritionalPlanDetailWidget extends riverpod.ConsumerWidget {
  final NutritionalPlan _nutritionalPlan;

  const NutritionalPlanDetailWidget(this._nutritionalPlan);

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final nutritionalGoals = _nutritionalPlan.nutritionalGoals;
    final category = ref.watch(bodyWeightCategoryOnlyProvider).value;
    // Only the last known weight is needed, which has its own query: reading a
    // range wide enough to be sure to contain it would materialise everything
    // in between
    final lastWeightEntry = category == null
        ? null
        : ref.watch(latestMeasurementEntriesProvider).value?[category.id];
    // Goals are per kilogram, so the weight must be normalized to kg no matter
    // which unit it was entered in
    final nutritionalGoalsGperKg = lastWeightEntry != null
        ? nutritionalGoals / lastWeightEntry.valueIn('kg', categoryUnit: category!.unit)
        : null;

    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final next = _nextMeal(context);

    Widget banner(IconData icon, String text) => Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: atlas.brandSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AtlasCard(
              child: Column(
                children: [
                  DiaryRings(
                    planned: nutritionalGoals.toValues(),
                    logged: _nutritionalPlan.loggedNutritionalValuesToday,
                    remaining: true,
                  ),
                  if (next != null)
                    banner(
                      Icons.bolt,
                      i18n.nextMealBanner(
                        next.name,
                        next.time!.format(context),
                        next.plannedNutritionalValues.energy.toStringAsFixed(0),
                      ),
                    )
                  else if (_nutritionalPlan.meals.isNotEmpty &&
                      _nutritionalPlan.meals.every((m) => m.isCompletedToday))
                    banner(Icons.check_circle_outline, i18n.allMealsLogged),
                ],
              ),
            ),
          ),
          ..._nutritionalPlan.meals.map(
            (meal) => MealWidget(
              meal,
              false,
              false,
            ),
          ),
          MealWidget(
            _nutritionalPlan.pseudoMealOthers(i18n.otherLogs),
            false,
            true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SectionEyebrow(i18n.planDetails),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AtlasCard(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: MacronutrientsTable(
                nutritionalGoals: nutritionalGoals,
                plannedValuesPercentage: nutritionalGoals.energyPercentage(),
                nutritionalGoalsGperKg: nutritionalGoalsGperKg,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: SectionEyebrow(i18n.logged),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AtlasCard(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: SizedBox(
                height: 300,
                child: NutritionalDiaryChartWidgetFl(
                  nutritionalPlan: _nutritionalPlan,
                ),
              ),
            ),
          ),
          if (_nutritionalPlan.logEntriesValues.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: SectionEyebrow(i18n.nutritionalDiary),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AtlasCard(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: NutritionalDiaryTable(
                      nutritionalPlan: _nutritionalPlan,
                    ),
                  ),
                ),
              ),
            ),
          ],
          PlanWeightChart(_nutritionalPlan),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  /// The meal to eat next: the first one still to log whose time is not past,
  /// or else the first one still to log.
  Meal? _nextMeal(BuildContext context) {
    final open = _nutritionalPlan.meals.where((m) => m.time != null && !m.isCompletedToday).toList()
      ..sort((a, b) => (a.time!.hour * 60 + a.time!.minute) - (b.time!.hour * 60 + b.time!.minute));
    if (open.isEmpty) {
      return null;
    }
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    return open.firstWhere(
      (m) => m.time!.hour * 60 + m.time!.minute >= nowMin,
      orElse: () => open.first,
    );
  }
}
