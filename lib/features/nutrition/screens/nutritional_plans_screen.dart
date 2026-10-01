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
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/nutrition/screens/ingredients_screen.dart';
import 'package:wger/features/nutrition/widgets/forms.dart';
import 'package:wger/features/nutrition/widgets/nutritional_plans_list.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class NutritionalPlansScreen extends ConsumerWidget {
  const NutritionalPlansScreen();

  static const routeName = '/nutrition';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AtlasHeader(
            title: i18n.nutritionalPlans,
            showBack: false,
            actions: [
              RoundIconButton(
                icon: Icons.restaurant_menu,
                tooltip: i18n.ingredients,
                onPressed: () => Navigator.of(context).pushNamed(IngredientsScreen.routeName),
              ),
            ],
          ),
          const Expanded(child: WidescreenWrapper(child: NutritionalPlansList())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            FormScreen.routeName,
            arguments: FormScreenArguments(
              AppLocalizations.of(context).newNutritionalPlan,
              hasListView: true,
              PlanForm(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
