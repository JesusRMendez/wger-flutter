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

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/core/widgets/text_prompt.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/measurements/charts/data.dart';
import 'package:wger/features/measurements/measurements.dart';
import 'package:wger/features/measurements/models/measurement_bucket.dart';
import 'package:wger/features/measurements/models/measurement_category.dart';
import 'package:wger/features/measurements/models/unit_conversion.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/screens/nutritional_plan_screen.dart';
import 'package:wger/features/nutrition/widgets/goal_calculator_card.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class NutritionalPlansList extends riverpod.ConsumerWidget {
  const NutritionalPlansList({super.key});

  /// Builds the weight change information for a nutritional plan period
  Widget _buildWeightChangeInfo(
    BuildContext context,
    riverpod.WidgetRef ref,
    DateTime startDate,
    DateTime? endDate,
  ) {
    final category = ref.watch(bodyWeightCategoryOnlyProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    if (category == null || profile == null) {
      // Not yet loaded, skip the weight-change row entirely. The widget will
      // rebuild with the value once available.
      return const SizedBox.shrink();
    }

    // The whole history rather than the plan's period: the boundary values are
    // interpolated from the readings around it, which can lie outside. One
    // point per day, so several readings on one day count once.
    final buckets = ref
        .watch(
          measurementChartBucketsProvider(
            category.id!,
            null,
            null,
            MeasurementBucketLevel.day,
          ),
        )
        .value;
    if (buckets == null) {
      return const SizedBox.shrink();
    }

    // Normalize mixed-unit entries to the display unit before averaging
    final displayUnit = weightDisplayUnit(profile.isMetric);
    final entriesAll = chartEntriesForBuckets(
      buckets,
      targetUnit: displayUnit,
      categoryUnit: category.unit,
    );
    final average = movingAverage(
      entriesAll,
      days: category.chartSettings.averageWindow ?? ChartSettings.fallbackWindow,
    ).whereDateWithInterpolation(startDate, endDate);
    if (average.length < 2) {
      return const SizedBox.shrink();
    }

    // Calculate weight change
    final firstWeight = average.first;
    final lastWeight = average.last;
    final weightDifference = lastWeight.value - firstWeight.value;

    // Format the weight change text and determine color
    final String weightChangeText;
    final Color weightChangeColor;
    final unit = weightUnit(profile.isMetric, context);

    if (weightDifference > 0) {
      weightChangeText = '+${weightDifference.toStringAsFixed(1)} $unit';
      weightChangeColor = Colors.red;
    } else if (weightDifference < 0) {
      weightChangeText = '${weightDifference.toStringAsFixed(1)} $unit';
      weightChangeColor = Colors.green;
    } else {
      weightChangeText = '0 $unit';
      weightChangeColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Text(
            '${AppLocalizations.of(context).weight} change: ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            weightChangeText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: weightChangeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// The plan that is running today: the latest started one that has not ended
  NutritionalPlan? _activePlan(List<NutritionalPlan> plans) {
    final now = DateTime.now();
    final running =
        plans
            .where(
              (p) =>
                  !p.startDate.isAfter(now) &&
                  (p.endDate == null ||
                      !p.endDate!.isBefore(DateTime(now.year, now.month, now.day))),
            )
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return running.isEmpty ? null : running.first;
  }

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final plansAsync = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;

    return AsyncValueWidget<NutritionState>(
      value: plansAsync,
      loggerName: 'NutritionalPlansList',
      data: (nutritionState) {
        final plans = nutritionState.plans;
        if (plans.isEmpty) {
          return const TextPrompt();
        }
        final active = _activePlan(plans);
        final others = plans.where((p) => p != active).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            if (active != null) ...[
              _ActivePlanCard(plan: active),
              const SizedBox(height: 12),
            ],
            const GoalCalculatorCard(),
            const SizedBox(height: 12),
            if (others.isNotEmpty)
              AtlasCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i18n.otherPlans, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final (i, plan) in others.indexed) ...[
                      if (i > 0) Divider(height: 1, color: atlas.line),
                      _PlanRow(
                        plan: plan,
                        info: _buildWeightChangeInfo(context, ref, plan.startDate, plan.endDate),
                        onDelete: () => showConfirmDeleteDialog(
                          context,
                          itemName: plan.description,
                          onConfirm: () => notifier.deletePlan(plan.id!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.plan});

  final NutritionalPlan plan;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final goals = plan.nutritionalGoals;
    final pct = goals.energyPercentage();
    final onHero = atlas.onHero;

    Widget tile(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: onHero.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: MonoText(value, size: 26, color: onHero),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: onHero.withValues(alpha: 0.7)),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );

    String p(double? v) => (v ?? 0).toStringAsFixed(0);

    return AtlasCard(
      hero: true,
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.of(context).pushNamed(
        NutritionalPlanScreen.routeName,
        arguments: plan.id,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionEyebrow(i18n.planActive, color: onHero.withValues(alpha: 0.65)),
              MonoText(
                i18n.planStartDate(localizedDate(context).format(plan.startDate)),
                size: 13,
                color: onHero,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan.getLabel(context),
            style: theme.textTheme.headlineMedium?.copyWith(color: onHero),
          ),
          const SizedBox(height: 16),
          Row(
            spacing: 10,
            children: [
              tile(
                (goals.energy ?? plan.loggedNutritionalValues7DayAvg.energy).toStringAsFixed(0),
                i18n.kcalGoalPerDay,
              ),
              tile(
                plan.loggedNutritionalValues7DayAvg.energy.toStringAsFixed(0),
                i18n.kcalAverage7Days,
              ),
            ],
          ),
          if (goals.isComplete()) ...[
            const SizedBox(height: 16),
            Text(
              i18n.macroSplit(p(pct.protein), p(pct.carbohydrates), p(pct.fat)),
              style: theme.textTheme.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.75)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, required this.info, required this.onDelete});

  final NutritionalPlan plan;
  final Widget info;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final ended = plan.endDate != null && plan.endDate!.isBefore(now);
    final upcoming = plan.startDate.isAfter(now);

    final dates = plan.endDate != null
        ? 'from ${localizedDate(context).format(plan.startDate)} to ${localizedDate(context).format(plan.endDate!)}'
        : 'from ${localizedDate(context).format(plan.startDate)} (open ended)';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pushNamed(
        NutritionalPlanScreen.routeName,
        arguments: plan.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const IconBadge(Icons.restaurant, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.getLabel(context), style: theme.textTheme.titleSmall),
                  Text(
                    plan.meals.isEmpty && plan.hasAnyGoals ? i18n.planGoalsOnly : dates,
                    style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  ),
                  info,
                ],
              ),
            ),
            if (ended || upcoming) PillChip(ended ? i18n.planArchived : i18n.planUpcoming),
            IconButton(
              icon: const Icon(Icons.delete),
              color: atlas.ink3,
              tooltip: i18n.delete,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
