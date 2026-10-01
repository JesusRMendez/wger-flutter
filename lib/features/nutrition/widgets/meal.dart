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
import 'package:wger/core/consts.dart';
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/snackbar.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/nutrition/models/meal.dart';
import 'package:wger/features/nutrition/models/meal_item.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/screens/log_meal_screen.dart';
import 'package:wger/features/nutrition/widgets/charts.dart';
import 'package:wger/features/nutrition/widgets/forms.dart';
import 'package:wger/features/nutrition/widgets/helpers.dart';
import 'package:wger/features/nutrition/widgets/nutrition_tiles.dart';
import 'package:wger/features/nutrition/widgets/widgets.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

enum ViewMode {
  base, // just highlevel meal info (name, time)
  withIngredients, // + ingredients
  withAllDetails, // + nutritional breakdown of ingredients, + logged today
}

/// Card widget for a single [Meal] on the NutritionalPlanDetailWidget (NutritionalPlanScreen).
class MealWidget extends ConsumerStatefulWidget {
  final Meal _meal;
  final bool popTwice;
  final bool readOnly;

  const MealWidget(
    this._meal,
    this.popTwice,
    this.readOnly,
  );

  @override
  ConsumerState<MealWidget> createState() => _MealWidgetState();
}

class _MealWidgetState extends ConsumerState<MealWidget> {
  var _viewMode = ViewMode.base;
  bool _editing = false;

  void _toggleEditing() {
    setState(() {
      _editing = !_editing;
    });
  }

  void _toggleDetails() {
    setState(() {
      if (widget._meal.isRealMeal) {
        _viewMode = switch (_viewMode) {
          ViewMode.base => ViewMode.withIngredients,
          ViewMode.withIngredients => ViewMode.withAllDetails,
          ViewMode.withAllDetails => ViewMode.base,
        };
      } else {
        // the "other logs" fake meal doesn't have ingredients to show
        _viewMode = switch (_viewMode) {
          ViewMode.base => ViewMode.withAllDetails,
          _ => ViewMode.base,
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AtlasCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MealHeader(
              editing: _editing,
              toggleEditing: _toggleEditing,
              popTwice: widget.popTwice,
              readOnly: widget.readOnly,
              viewMode: _viewMode,
              toggleViewMode: _toggleDetails,
              meal: widget._meal,
            ),
            MealIngredientsSection(
              meal: widget._meal,
              editing: _editing,
              viewMode: _viewMode,
            ),
            if (_viewMode == ViewMode.withAllDetails)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(height: 1, color: context.atlas.line),
                    const SizedBox(height: 12),
                    SectionEyebrow(AppLocalizations.of(context).loggedToday),
                    if (widget._meal.plannedNutritionalValues.energy != 0)
                      MealDiaryBarChartWidget(
                        planned: widget._meal.plannedNutritionalValues,
                        logged: widget._meal.loggedNutritionalValuesToday,
                      ),
                    ...widget._meal.diaryEntriesToday.map(
                      (item) => DiaryEntryTile(diaryEntry: item),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A row of a meal: name, "amount · kcal" in mono and a check button that logs
/// the item to the diary (and takes the entry back out when pressed again).
/// While [_editing] the check is replaced by a delete button.
class MealItemEditableFullTile extends ConsumerWidget {
  final bool _editing;
  final ViewMode _viewMode;
  final MealItem _item;

  /// Set to show the check button: the meal the item belongs to
  final Meal? meal;

  const MealItemEditableFullTile(this._item, this._viewMode, this._editing, {this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = _item.nutritionalValues;
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);

    final String amountText = _item.weightUnitObj != null
        ? '${_item.amount.toStringAsFixed(0)} × ${_item.weightUnitObj!.name}'
        : i18n.gValue(_item.amount.toStringAsFixed(0));

    // ingredient is null briefly between local insert and PowerSync
    // downloading the row, show a placeholder rather than crashing.
    final ingredient = _item.ingredient;

    final logged = meal?.loggedEntryFor(_item);

    Widget? trailing;
    if (_editing) {
      trailing = IconButton(
        icon: const Icon(Icons.delete_outline, size: ICON_SIZE_SMALL),
        tooltip: i18n.delete,
        iconSize: ICON_SIZE_SMALL,
        onPressed: () {
          // Delete the meal item, goes through PowerSync, so offline is fine.
          ref.read(nutritionProvider.notifier).deleteMealItem(_item);

          // and inform the user
          showSnackbar(context, i18n.successfullyDeleted, center: true);
        },
      );
    } else if (meal != null) {
      trailing = CheckCircle(
        checked: logged != null,
        semanticLabel: i18n.logMeal,
        onTap: () {
          final notifier = ref.read(nutritionProvider.notifier);
          if (logged != null) {
            notifier.deleteLog(logged.id!);
          } else {
            notifier.logIngredientToDiary(_item, meal!.planId, DateTime.now(), meal!.id);
          }
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          if (_viewMode == ViewMode.withAllDetails && ingredient != null) ...[
            IngredientAvatar(ingredient: ingredient),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient?.name ?? '…',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                MonoText(
                  '$amountText · ${i18n.kcalValue(values.energy.toStringAsFixed(0))}',
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: atlas.ink3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_viewMode != ViewMode.base)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 10,
                      children: [
                        _macro('P', values.protein, atlas.protein),
                        _macro('C', values.carbohydrates, atlas.carbs),
                        _macro('F', values.fat, atlas.fat),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _macro(String letter, double grams, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        MonoText('$letter ${grams.toStringAsFixed(0)}', size: 11.5, weight: FontWeight.w500),
      ],
    );
  }
}

class MealHeader extends StatelessWidget {
  final Meal _meal;
  final bool _editing;
  final bool popTwice;
  final bool readOnly;
  final ViewMode _viewMode;
  final Function() _toggleEditing;
  final Function() _toggleViewMode;

  const MealHeader({
    required Meal meal,
    required bool editing,
    this.popTwice = false,
    this.readOnly = false,
    required ViewMode viewMode,
    required Function() toggleEditing,
    required Function() toggleViewMode,
  }) : _meal = meal,
       _editing = editing,
       _viewMode = viewMode,
       _toggleViewMode = toggleViewMode,
       _toggleEditing = toggleEditing;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final subtitleTime = _meal.time != null ? '${_meal.time!.format(context)} · ' : '';
    final subtitleCalories = _meal.isRealMeal
        ? getKcalConsumedVsPlanned(_meal, context)
        : getKcalConsumed(_meal, context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _meal.name,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                MonoText(
                  '$subtitleTime$subtitleCalories',
                  size: 13,
                  weight: FontWeight.w500,
                  color: atlas.ink3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _viewMode == ViewMode.base ? Icons.info_outline : Icons.info,
              size: 20,
              color: atlas.ink3,
            ),
            onPressed: _toggleViewMode,
            tooltip: i18n.toggleDetails,
          ),
          if (_meal.isRealMeal && !readOnly)
            IconButton(
              icon: Icon(_editing ? Icons.done : Icons.edit, size: 20, color: atlas.ink3),
              tooltip: _editing ? i18n.done : i18n.edit,
              onPressed: _toggleEditing,
            ),
          if (_meal.isRealMeal)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: RoundIconButton(
                icon: Icons.add,
                size: 38,
                tooltip: i18n.logMeal,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    LogMealScreen.routeName,
                    arguments: LogMealArguments(_meal, popTwice),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class MealIngredientsSection extends ConsumerWidget {
  const MealIngredientsSection({
    super.key,
    required this.meal,
    required this.editing,
    required this.viewMode,
  });
  final Meal meal;
  final bool editing;
  final ViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atlas = context.atlas;
    if (!meal.isRealMeal) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (editing)
          MealEditingToolbar(
            meal: meal,
          ),
        if (meal.mealItems.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context).noIngredientsDefined,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: atlas.ink3),
              ),
            ),
          )
        else
          for (final item in meal.mealItems) ...[
            Divider(height: 1, indent: 16, endIndent: 16, color: atlas.line),
            MealItemEditableFullTile(item, viewMode, editing, meal: meal),
          ],
      ],
    );
  }
}

class MealEditingToolbar extends ConsumerWidget {
  final Meal meal;
  const MealEditingToolbar({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionProvider).value;
    if (state == null) {
      return const Center(child: BoxedProgressIndicator());
    }
    final recentMealItems = state.recentMealItemsInPlan(meal.planId) ?? const <MealItem>[];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context).addIngredient),
            onPressed: () {
              Navigator.pushNamed(
                context,
                FormScreen.routeName,
                arguments: FormScreenArguments(
                  AppLocalizations.of(context).addIngredient,
                  getMealItemForm(meal, recentMealItems),
                  hasListView: true,
                ),
              );
            },
          ),
          TextButton.icon(
            label: Text(AppLocalizations.of(context).edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                FormScreen.routeName,
                arguments: FormScreenArguments(
                  AppLocalizations.of(context).edit,
                  MealForm(meal.planId, meal),
                ),
              );
            },
            icon: const Icon(Icons.timer),
          ),
          TextButton.icon(
            onPressed: () {
              // Delete the meal
              ref.read(nutritionProvider.notifier).deleteMeal(meal);

              // and inform the user
              showSnackbar(context, AppLocalizations.of(context).successfullyDeleted, center: true);
            },
            label: Text(AppLocalizations.of(context).delete),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}
