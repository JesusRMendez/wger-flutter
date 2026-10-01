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
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/nutrition/models/ingredient.dart';
import 'package:wger/features/nutrition/providers/ingredient_notifier.dart';
import 'package:wger/features/nutrition/widgets/ingredient_dialogs.dart';

class IngredientDetailScreen extends ConsumerWidget {
  static const routeName = '/ingredient-detail';

  const IngredientDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    if (id == null) {
      return const Scaffold(body: Center(child: CenteredProgressIndicator()));
    }

    final async = ref.watch(ingredientByIdStreamProvider(id));
    return Scaffold(
      body: AsyncValueWidget<Ingredient?>(
        value: async,
        loggerName: 'IngredientDetailScreen',
        data: (ingredient) {
          if (ingredient == null) {
            // No matching row yet (sync hasn't pulled it down, or the id
            // points at something that has since been deleted upstream).
            return const Center(child: Icon(Icons.help_outline, size: 48));
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.chevron_left,
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  IngredientDetails(ingredient),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
