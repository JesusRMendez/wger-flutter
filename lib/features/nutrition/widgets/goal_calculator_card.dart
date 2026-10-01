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
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/coach/screens/meal_plan_screen.dart';
import 'package:wger/features/measurements/models/unit_conversion.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

enum CalorieGoal { loseFat, maintain, gainMuscle }

/// Rough daily energy and macro targets for a body weight: maintenance at
/// about 33 kcal per kg for a moderately active week, -15 % to lose fat and
/// +10 % to gain muscle, protein and fat per kg of body weight and the rest
/// as carbohydrates.
class CalorieEstimate {
  const CalorieEstimate({
    required this.energy,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.deltaPercent,
    required this.kgPerWeek,
  });

  final int energy;
  final int protein;
  final int carbohydrates;
  final int fat;

  /// Change against maintenance in percent (negative for a deficit)
  final int deltaPercent;

  /// Expected change of the body weight per week in kg (negative for a loss)
  final double kgPerWeek;

  factory CalorieEstimate.from(double weightKg, CalorieGoal goal) {
    final maintenance = weightKg * 33;
    final factor = switch (goal) {
      CalorieGoal.loseFat => 0.85,
      CalorieGoal.maintain => 1.0,
      CalorieGoal.gainMuscle => 1.10,
    };
    final energy = (maintenance * factor / 10).round() * 10;
    final protein = (weightKg * (goal == CalorieGoal.maintain ? 1.8 : 2.2) / 5).round() * 5;
    final fat = (weightKg * 0.9 / 5).round() * 5;
    final carbs = ((energy - protein * 4 - fat * 9) / 4 / 5).round() * 5;
    final delta = energy - maintenance;
    return CalorieEstimate(
      energy: energy,
      protein: protein,
      carbohydrates: carbs < 0 ? 0 : carbs,
      fat: fat,
      deltaPercent: ((factor - 1) * 100).round(),
      kgPerWeek: delta * 7 / 7700,
    );
  }
}

/// Card of the plans screen that estimates goals from the last weight entry.
class GoalCalculatorCard extends ConsumerStatefulWidget {
  const GoalCalculatorCard({super.key});

  @override
  ConsumerState<GoalCalculatorCard> createState() => _GoalCalculatorCardState();
}

class _GoalCalculatorCardState extends ConsumerState<GoalCalculatorCard> {
  CalorieGoal _goal = CalorieGoal.loseFat;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;

    final category = ref.watch(bodyWeightCategoryOnlyProvider).value;
    final latest = category == null
        ? null
        : ref.watch(latestMeasurementEntriesProvider).value?[category.id];
    final weight = latest?.valueIn('kg', categoryUnit: category!.unit);
    final estimate = weight == null ? null : CalorieEstimate.from(weight, _goal);

    final labels = {
      CalorieGoal.loseFat: i18n.goalLoseFat,
      CalorieGoal.maintain: i18n.goalMaintain,
      CalorieGoal.gainMuscle: i18n.goalGainMuscle,
    };

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: Text(i18n.calcTitle, style: theme.textTheme.titleMedium)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: atlas.accent,
                  borderRadius: BorderRadius.circular(AtlasRadius.pill),
                ),
                child: Text(
                  i18n.newBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: atlas.onHero,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<CalorieGoal>(
              showSelectedIcon: false,
              segments: [
                for (final g in CalorieGoal.values)
                  ButtonSegment(
                    value: g,
                    label: Text(labels[g]!, textAlign: TextAlign.center, maxLines: 2),
                  ),
              ],
              selected: {_goal},
              onSelectionChanged: (s) => setState(() => _goal = s.first),
            ),
          ),
          const SizedBox(height: 14),
          if (estimate == null)
            Text(
              i18n.calcNoWeight,
              style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
            )
          else ...[
            Text(
              i18n.calcBasedOn('${weight!.toStringAsFixed(1)} kg'),
              style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MonoText(
                  '${estimate.energy}',
                  size: 40,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  i18n.kcalPerDay,
                  style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MacroTile(
                    value: '${estimate.protein}',
                    unit: ' g',
                    label: i18n.proteinAbbr,
                    color: atlas.protein,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MacroTile(
                    value: '${estimate.carbohydrates}',
                    unit: ' g',
                    label: i18n.carbsAbbr,
                    color: atlas.carbs,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MacroTile(
                    value: '${estimate.fat}',
                    unit: ' g',
                    label: i18n.fatAbbr,
                    color: atlas.fat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              switch (_goal) {
                CalorieGoal.loseFat => i18n.calcDeficit(
                  estimate.deltaPercent.abs().toString(),
                  estimate.kgPerWeek.abs().toStringAsFixed(1),
                ),
                CalorieGoal.maintain => i18n.calcMaintenance,
                CalorieGoal.gainMuscle => i18n.calcSurplus(
                  estimate.deltaPercent.abs().toString(),
                  estimate.kgPerWeek.abs().toStringAsFixed(1),
                ),
              },
              style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
            ),
          ],
          const SizedBox(height: 14),
          Pressable(
            onTap: () => Navigator.of(context).pushNamed(MealPlanScreen.routeName),
            borderRadius: BorderRadius.circular(AtlasRadius.control),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: atlas.surface2,
                borderRadius: BorderRadius.circular(AtlasRadius.control),
                border: Border.all(color: atlas.line2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    i18n.generateMealsAi,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
