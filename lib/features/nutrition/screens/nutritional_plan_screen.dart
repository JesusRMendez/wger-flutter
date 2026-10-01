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

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/core/widgets/object_gone_redirect.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/core/widgets/svg_icon.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/screens/log_meals_screen.dart';
import 'package:wger/features/nutrition/widgets/forms.dart';
import 'package:wger/features/nutrition/widgets/nutritional_plan_detail.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

enum NutritionalPlanOptions {
  edit,
  delete,
}

String _dateRange(BuildContext context, NutritionalPlan plan) {
  final i18n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).languageCode;
  final start = DateFormat.yMd(locale).format(plan.startDate);
  if (plan.endDate != null) {
    return i18n.planDateRange(start, DateFormat.yMd(locale).format(plan.endDate!));
  }
  return '${i18n.planStartDate(start)} (${i18n.openEnded})';
}

class NutritionalPlanScreen extends ConsumerWidget {
  const NutritionalPlanScreen();

  static const routeName = '/nutritional-plan-detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planId = ModalRoute.of(context)!.settings.arguments as String;

    // Wait for the catalogue to stream in, then resolve the plan by id. A loaded
    // state that no longer has it means the plan was deleted (here or on another
    // device): leave, rather than render a phantom plan whose meal/diary writes
    // would orphan against a missing plan.
    final state = ref.watch(nutritionProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: BoxedProgressIndicator()));
    }
    final nutritionalPlan = state.findByIdOrNull(planId);
    if (nutritionalPlan == null) {
      return objectGoneRedirect(context);
    }
    return Scaffold(
      //appBar: getAppBar(nutritionalPlan),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: null,
            tooltip: AppLocalizations.of(context).logIngredient,
            onPressed: () {
              Navigator.pushNamed(
                context,
                FormScreen.routeName,
                arguments: FormScreenArguments(
                  AppLocalizations.of(context).logIngredient,
                  getIngredientLogForm(nutritionalPlan),
                  hasListView: true,
                ),
              );
            },
            child: const SvgIcon('assets/icons/ingredient-diary.svg', color: Colors.white),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: null,
            tooltip: AppLocalizations.of(context).logMeal,
            onPressed: () {
              Navigator.of(context).pushNamed(
                LogMealsScreen.routeName,
                arguments: nutritionalPlan,
              );
            },
            child: const SvgIcon('assets/icons/meal-diary.svg', color: Colors.white),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AtlasHeader(
              eyebrow: DateFormat.MMMMEEEEd(
                Localizations.localeOf(context).languageCode,
              ).format(clock.now()),
              title: nutritionalPlan.getLabel(context),
              subtitle: _dateRange(context, nutritionalPlan),
              actions: [
                if (!nutritionalPlan.onlyLogging)
                  RoundIconButton(
                    icon: Icons.add,
                    tooltip: AppLocalizations.of(context).addMeal,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        FormScreen.routeName,
                        arguments: FormScreenArguments(
                          AppLocalizations.of(context).addMeal,
                          MealForm(nutritionalPlan.id!),
                        ),
                      );
                    },
                  ),
                PopupMenuButton<NutritionalPlanOptions>(
                  tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.atlas.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.atlas.line),
                    ),
                    child: const Icon(Icons.more_vert, size: 20),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case NutritionalPlanOptions.edit:
                        Navigator.pushNamed(
                          context,
                          FormScreen.routeName,
                          arguments: FormScreenArguments(
                            AppLocalizations.of(context).edit,
                            PlanForm(nutritionalPlan),
                            hasListView: true,
                          ),
                        );
                        break;
                      case NutritionalPlanOptions.delete:
                        ref.read(nutritionProvider.notifier).deletePlan(nutritionalPlan.id!);
                        Navigator.of(context).pop();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<NutritionalPlanOptions>(
                        value: NutritionalPlanOptions.edit,
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: Text(AppLocalizations.of(context).edit),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<NutritionalPlanOptions>(
                        value: NutritionalPlanOptions.delete,
                        child: ListTile(
                          leading: const Icon(Icons.delete),
                          title: Text(AppLocalizations.of(context).delete),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
          NutritionalPlanDetailWidget(nutritionalPlan),
        ],
      ),
    );
  }
}
