/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2020 - 2026 wger Team
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

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/colors.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/legend.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/models/nutritional_values.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The goals of the day: a ring for the energy and a bar for each macro nutrient. A
/// value over its goal turns to the surplus color.
class FlNutritionalPlanGoalWidget extends StatelessWidget {
  const FlNutritionalPlanGoalWidget({
    super.key,
    required NutritionalPlan nutritionalPlan,
  }) : _nutritionalPlan = nutritionalPlan;

  final NutritionalPlan _nutritionalPlan;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final goals = _nutritionalPlan.nutritionalGoals;
    final today = _nutritionalPlan.loggedNutritionalValuesToday;

    final energyGoal = goals.energy != null && goals.energy! > 0 ? goals.energy : null;
    final surplus = energyGoal != null && today.energy > energyGoal;

    // A bar that goes over its goal turns to the surplus color
    Widget macro(String label, double value, double? goal, Color color) {
      final over = goal != null && goal > 0 && value > goal;
      return MacroBar(
        label: label,
        value: value,
        target: goal,
        color: over ? COLOR_SURPLUS : color,
        unit: ' ${i18n.g}',
      );
    }

    final macros = [
      macro(i18n.protein, today.protein, goals.protein, atlas.protein),
      macro(i18n.carbohydrates, today.carbohydrates, goals.carbohydrates, atlas.carbs),
      macro(i18n.fat, today.fat, goals.fat, atlas.fat),
      if (goals.fiber != null) macro(i18n.fiber, today.fiber, goals.fiber, atlas.ok),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          label:
              '${i18n.energy}: ${today.energy.toStringAsFixed(0)}'
              '${energyGoal == null ? '' : ' / ${energyGoal.toStringAsFixed(0)}'} ${i18n.kcal}',
          child: ProgressRing(
            size: 96,
            strokeWidth: 9,
            value: energyGoal == null ? 0 : today.energy / energyGoal,
            color: surplus ? COLOR_SURPLUS : theme.colorScheme.onSurface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MonoText(today.energy.toStringAsFixed(0), size: 19),
                Text(
                  energyGoal == null
                      ? i18n.kcal
                      : '/ ${energyGoal.toStringAsFixed(0)} ${i18n.kcal}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: atlas.ink3,
                    fontSize: 10,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, m) in macros.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                m,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The day at a glance: a big ring for the energy and one small ring each for
/// protein, carbohydrates and fat, logged against planned.
class DiaryRings extends StatelessWidget {
  const DiaryRings({
    super.key,
    required this.planned,
    required this.logged,
    this.remaining = false,
  });

  final NutritionalValues planned;
  final NutritionalValues logged;

  /// Show the energy left to eat in the ring ("1847 kcal left") with the
  /// consumed and goal values next to it, instead of the logged energy
  final bool remaining;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;

    double frac(double l, double p) => p > 0 ? l / p : 0;
    final surplus = planned.energy > 0 && logged.energy > planned.energy;

    Widget small(String label, double l, double p, Color color) {
      final over = p > 0 && l > p;
      return Expanded(
        child: Column(
          children: [
            ProgressRing(
              size: 64,
              strokeWidth: 7,
              value: frac(l, p),
              color: over ? COLOR_SURPLUS : color,
              child: MonoText(l.toStringAsFixed(0), size: 14),
            ),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.bodySmall),
            MonoText(
              planned.protein == 0 && p == 0 ? '' : '/ ${p.toStringAsFixed(0)} ${i18n.g}',
              size: 11,
              weight: FontWeight.w500,
              color: atlas.ink3,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            ProgressRing(
              size: 128,
              strokeWidth: 11,
              value: frac(logged.energy, planned.energy),
              color: surplus ? COLOR_SURPLUS : theme.colorScheme.onSurface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MonoText(
                    (remaining ? (planned.energy - logged.energy).abs() : logged.energy)
                        .toStringAsFixed(0),
                    size: 26,
                  ),
                  Text(
                    remaining ? i18n.kcalLeft : i18n.kcal,
                    style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remaining ? i18n.consumed : i18n.logged,
                    style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  ),
                  MonoText(i18n.kcalValue(logged.energy.toStringAsFixed(0)), size: 18),
                  const SizedBox(height: 10),
                  Text(
                    remaining ? i18n.goalToday : i18n.planned,
                    style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  ),
                  MonoText(
                    i18n.kcalValue(planned.energy.toStringAsFixed(0)),
                    size: 18,
                    color: atlas.ink2,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            small(i18n.protein, logged.protein, planned.protein, atlas.protein),
            small(i18n.carbohydrates, logged.carbohydrates, planned.carbohydrates, atlas.carbs),
            small(i18n.fat, logged.fat, planned.fat, atlas.fat),
          ],
        ),
      ],
    );
  }
}

class NutritionData {
  final String name;
  final double value;

  const NutritionData(this.name, this.value);
}

class FlNutritionalPlanPieChartWidget extends StatefulWidget {
  final NutritionalValues nutritionalValues;

  const FlNutritionalPlanPieChartWidget(this.nutritionalValues);

  @override
  State<StatefulWidget> createState() => FlNutritionalPlanPieChartState();
}

class FlNutritionalPlanPieChartState extends State<FlNutritionalPlanPieChartWidget> {
  int touchedIndex = -1;

  /// Shared by the sections and the legend so both stay in sync.
  List<Color> get _macroColors => chartColorPalette(3, Theme.of(context).colorScheme);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(height: 18),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: showingSections(),
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              [
                    (AppLocalizations.of(context).protein, _macroColors[1]),
                    (AppLocalizations.of(context).carbohydrates, _macroColors[0]),
                    (AppLocalizations.of(context).fat, _macroColors[2]),
                  ]
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Indicator(color: e.$2, text: e.$1, isSquare: true),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(width: 28),
      ],
    );
  }

  List<PieChartSectionData> showingSections() {
    return [
      (0, _macroColors[1], widget.nutritionalValues.protein),
      (1, _macroColors[0], widget.nutritionalValues.carbohydrates),
      (2, _macroColors[2], widget.nutritionalValues.fat),
    ].map((e) {
      final isTouched = e.$1 == touchedIndex;
      final radius = isTouched ? 92.0 : 80.0;

      return PieChartSectionData(
        color: e.$2,
        value: e.$3,
        title: '${e.$3.toStringAsFixed(0)}g',
        // Merged onto the ambient style, so only the color is overridden.
        titleStyle: TextStyle(color: onChartColor(e.$2)),
        titlePositionPercentageOffset: 0.5,
        radius: radius,
      );
    }).toList();
  }
}

/// Shows results vs plan of common macros, for today and last 7 days, as barchart
class NutritionalDiaryChartWidgetFl extends StatefulWidget {
  const NutritionalDiaryChartWidgetFl({
    super.key,
    required NutritionalPlan nutritionalPlan,
  }) : _nutritionalPlan = nutritionalPlan;

  final NutritionalPlan _nutritionalPlan;

  @override
  State<StatefulWidget> createState() => NutritionalDiaryChartWidgetFlState();
}

class NutritionalDiaryChartWidgetFlState extends State<NutritionalDiaryChartWidgetFl> {
  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final String text = switch (value.toInt()) {
      0 => AppLocalizations.of(context).protein,
      1 => AppLocalizations.of(context).carbohydrates,
      2 => AppLocalizations.of(context).sugars,
      3 => AppLocalizations.of(context).fat,
      4 => AppLocalizations.of(context).saturatedFat,
      5 => AppLocalizations.of(context).fiber,
      _ => '',
    };
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        AppLocalizations.of(context).gValue(meta.formattedValue),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planned = widget._nutritionalPlan.nutritionalGoals;
    final loggedToday = widget._nutritionalPlan.loggedNutritionalValuesToday;
    final logged7DayAvg = widget._nutritionalPlan.loggedNutritionalValues7DayAvg;

    final [colorPlanned, colorLoggedToday, colorLogged7Day] = chartColorPalette(
      3,
      Theme.of(context).colorScheme,
    );

    BarChartGroupData barchartGroup(
      int x,
      double barsSpace,
      double barsWidth,
      String prop,
    ) {
      final plan = planned.prop(prop);

      BarChartRodData barChartRodData(double? plan, double val, Color color) {
        // paint a simple bar
        if (plan == null || val == plan) {
          return BarChartRodData(toY: val, color: color, width: barsWidth);
        }

        // paint a surplus
        if (val > plan) {
          return BarChartRodData(
            toY: val,
            color: colorLoggedToday,
            width: barsWidth,
            rodStackItems: [
              BarChartRodStackItem(0, plan, color),
              BarChartRodStackItem(plan, val, COLOR_SURPLUS),
            ],
          );
        }

        // paint a deficit
        return BarChartRodData(
          toY: plan,
          color: colorLoggedToday,
          width: barsWidth,
          rodStackItems: [
            BarChartRodStackItem(0, val, color),
            BarChartRodStackItem(val, plan, colorPlanned),
          ],
        );
      }

      return BarChartGroupData(
        x: x,
        barsSpace: barsSpace,
        barRods: [
          barChartRodData(plan, loggedToday.prop(prop), colorLoggedToday),
          barChartRodData(plan, logged7DayAvg.prop(prop), colorLogged7Day),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final barsSpace = 6.0 * constraints.maxWidth / 400;
        final barsWidth = 12.0 * constraints.maxWidth / 400;
        return Column(
          children: [
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: bottomTitles,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: leftTitles,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    checkToShowHorizontalLine: (value) => value % 10 == 0,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  groupsSpace: 30,
                  barGroups: [
                    barchartGroup(0, barsSpace, barsWidth, 'protein'),
                    barchartGroup(1, barsSpace, barsWidth, 'carbohydrates'),
                    barchartGroup(
                      2,
                      barsSpace,
                      barsWidth,
                      'carbohydratesSugar',
                    ),
                    barchartGroup(3, barsSpace, barsWidth, 'fat'),
                    barchartGroup(4, barsSpace, barsWidth, 'fatSaturated'),
                    if (widget._nutritionalPlan.nutritionalGoals.fiber != null)
                      barchartGroup(5, barsSpace, barsWidth, 'fiber'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 25, right: 25),
              child: Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                alignment: WrapAlignment.center,
                children:
                    [
                          (AppLocalizations.of(context).deficit, colorPlanned),
                          (AppLocalizations.of(context).surplus, COLOR_SURPLUS),
                          (AppLocalizations.of(context).today, colorLoggedToday),
                          (AppLocalizations.of(context).weekAverage, colorLogged7Day),
                        ]
                        .map(
                          (e) => Indicator(
                            text: e.$1,
                            color: e.$2,
                            isSquare: true,
                            marginRight: 0,
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Barchart widget for what's logged today, energy and macros
class MealDiaryBarChartWidget extends StatefulWidget {
  const MealDiaryBarChartWidget({
    super.key,
    required NutritionalValues logged,
    required NutritionalValues planned,
  }) : _logged = logged,
       _planned = planned;

  final NutritionalValues _logged;
  final NutritionalValues _planned;

  @override
  State<StatefulWidget> createState() => MealDiaryBarChartWidgetState();
}

class MealDiaryBarChartWidgetState extends State<MealDiaryBarChartWidget> {
  Widget bottomTitles(double value, TitleMeta meta) {
    final String text = switch (value.toInt()) {
      0 => AppLocalizations.of(context).protein,
      1 => AppLocalizations.of(context).carbohydrates,
      2 => AppLocalizations.of(context).fat,
      3 => AppLocalizations.of(context).energy,
      _ => '',
    };
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) => SideTitleWidget(
    meta: meta,
    child: Text(
      AppLocalizations.of(context).percentValue(value.toStringAsFixed(0)),
      style: const TextStyle(fontSize: 10),
    ),
  );

  double _safePercent(double logged, double planned) {
    if (planned <= 0 || logged <= 0) {
      return 0.0;
    }
    final percent = (logged / planned) * 100;

    if (percent.isNaN || percent.isInfinite) {
      return 0.0;
    }
    return percent;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.5,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barsSpace = 1.0 * constraints.maxWidth / 400;
            final barsWidth = 10.0 * constraints.maxWidth / 400;
            return BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                barTouchData: const BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: bottomTitles,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: leftTitles,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                groupsSpace: 60,
                // groupsSpace: barsSpace,
                barGroups: [
                  BarChartGroupData(
                    x: 3,
                    barsSpace: barsSpace,
                    barRods: [
                      BarChartRodData(
                        toY: _safePercent(widget._logged.energy, widget._planned.energy),
                        color: Theme.of(context).colorScheme.primary,
                        width: barsWidth,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 0,
                    barsSpace: barsSpace,
                    barRods: [
                      BarChartRodData(
                        toY: _safePercent(widget._logged.protein, widget._planned.protein),
                        color: Theme.of(context).colorScheme.primary,
                        width: barsWidth,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barsSpace: barsSpace,
                    barRods: [
                      BarChartRodData(
                        toY: _safePercent(
                          widget._logged.carbohydrates,
                          widget._planned.carbohydrates,
                        ),
                        color: Theme.of(context).colorScheme.primary,
                        width: barsWidth,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barsSpace: barsSpace,
                    barRods: [
                      BarChartRodData(
                        toY: _safePercent(widget._logged.fat, widget._planned.fat),
                        color: Theme.of(context).colorScheme.primary,
                        width: barsWidth,
                      ),
                    ],
                  ),
                ],
                // barGroups: getData(barsWidth, barsSpace),
              ),
            );
          },
        ),
      ),
    );
  }
}
