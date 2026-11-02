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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/snackbar.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/core/widgets/datetime_input.dart';
import 'package:wger/features/nutrition/models/meal.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/widgets/meal.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class LogMealArguments {
  final Meal meal;
  final bool popTwice;

  const LogMealArguments(this.meal, this.popTwice);
}

class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen();

  static const routeName = '/log-meal';

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  double portionPct = 100;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    final args = ModalRoute.of(context)!.settings.arguments as LogMealArguments;
    final meal = args.meal.copyWith(
      mealItems: args.meal.mealItems
          .map((mealItem) => mealItem.copyWith(amount: mealItem.amount * portionPct / 100))
          .toList(),
    );

    final atlas = context.atlas;
    final theme = Theme.of(context);
    final totals = meal.plannedNutritionalValues;

    Future<void> save() async {
      final loggedDate = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      await ref.read(nutritionProvider.notifier).logMealToDiary(meal, loggedDate);

      if (context.mounted) {
        showSnackbar(context, i18n.mealLogged, center: true);

        Navigator.of(context).pop();
        if (args.popTwice) {
          Navigator.of(context).pop();
        }
      }
    }

    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          ref.watch(nutritionProvider);
          return Column(
            children: [
              AtlasHeader(
                showBack: false,
                eyebrow: i18n.logMeal,
                title: meal.name,
                actions: [
                  RoundIconButton(
                    icon: Icons.close,
                    tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meal.mealItems.isEmpty)
                        AtlasCard(child: Text(i18n.noIngredientsDefined))
                      else ...[
                        AtlasCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (final (i, item) in meal.mealItems.indexed) ...[
                                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                                MealItemEditableFullTile(item, ViewMode.base, false),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AtlasCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(i18n.portion, style: theme.textTheme.titleMedium),
                                        MonoText(
                                          i18n.kcalValue(totals.energy.toStringAsFixed(0)),
                                          size: 13,
                                          weight: FontWeight.w500,
                                          color: atlas.ink3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StepButton(
                                    icon: Icons.remove,
                                    tooltip: '-10 %',
                                    onPressed: portionPct > 0
                                        ? () => setState(
                                            () => portionPct = (portionPct - 10).clamp(0, 150),
                                          )
                                        : null,
                                  ),
                                  SizedBox(
                                    width: 78,
                                    child: Center(
                                      child: MonoText(
                                        '${portionPct.round()} %',
                                        size: 22,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  StepButton(
                                    icon: Icons.add,
                                    tooltip: '+10 %',
                                    onPressed: portionPct < 150
                                        ? () => setState(
                                            () => portionPct = (portionPct + 10).clamp(0, 150),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                              Slider.adaptive(
                                min: 0,
                                max: 150,
                                divisions: 30,
                                onChanged: (value) => setState(() => portionPct = value),
                                value: portionPct,
                              ),
                              Row(
                                spacing: 8,
                                children: [
                                  Expanded(
                                    child: MacroTile(
                                      value: totals.protein.toStringAsFixed(0),
                                      unit: ' g',
                                      label: i18n.proteinAbbr,
                                      color: atlas.protein,
                                    ),
                                  ),
                                  Expanded(
                                    child: MacroTile(
                                      value: totals.carbohydrates.toStringAsFixed(0),
                                      unit: ' g',
                                      label: i18n.carbsAbbr,
                                      color: atlas.carbs,
                                    ),
                                  ),
                                  Expanded(
                                    child: MacroTile(
                                      value: totals.fat.toStringAsFixed(0),
                                      unit: ' g',
                                      label: i18n.fatAbbr,
                                      color: atlas.fat,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      AtlasCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: DateInputWidget(
                                key: const ValueKey('field-date'),
                                value: _date,
                                labelText: i18n.date,
                                firstDate: DateTime.now().subtract(const Duration(days: 3000)),
                                lastDate: DateTime.now(),
                                onChanged: (date) => _date = date,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TimeInputWidget(
                                key: const ValueKey('field-time'),
                                value: _time,
                                labelText: i18n.time,
                                onChanged: (time) => _time = time,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (meal.mealItems.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: save,
                        child: Text(i18n.save),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
