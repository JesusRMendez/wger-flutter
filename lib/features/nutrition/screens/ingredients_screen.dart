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
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/nutrition/models/ingredient.dart';
import 'package:wger/features/nutrition/models/ingredient_weight_unit.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/providers/ingredient_filters_notifier.dart';
import 'package:wger/features/nutrition/providers/ingredient_notifier.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/widgets/ingredient_filter_row.dart';
import 'package:wger/features/nutrition/widgets/ingredient_list_tile.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  static const routeName = '/ingredients';

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  /// Show what was eaten lately instead of the whole catalogue
  bool _recent = false;

  /// Ingredients of the diary entries across all plans, newest first, one per
  /// ingredient and with the amount it was last eaten at
  List<(Ingredient, num, IngredientWeightUnit?)> _recentFromDiary() {
    final plans = ref.watch(nutritionProvider).value?.plans ?? const <NutritionalPlan>[];
    final entries = [for (final p in plans) ...p.diaryEntries]
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    final seen = <int>{};
    final out = <(Ingredient, num, IngredientWeightUnit?)>[];
    for (final e in entries) {
      final ingredient = e.ingredient;
      if (ingredient != null && seen.add(ingredient.id)) {
        out.add((ingredient, e.amount, e.weightUnitObj));
      }
      if (out.length >= 30) {
        break;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    // With no search term the overview shows the full locally-synced list
    // (reactive Drift stream); once the user types, it switches to the
    // online/offline search results.
    final hasSearchTerm = ref.watch(
      ingredientFiltersSyncProvider.select((f) => f.searchTerm.isNotEmpty),
    );
    final AsyncValue<List<Ingredient>> ingredientsAsync = hasSearchTerm
        ? ref.watch(searchedIngredientsProvider)
        : ref.watch(allLocalIngredientsProvider);
    final i18n = AppLocalizations.of(context);
    final showRecent = _recent && !hasSearchTerm;
    final recent = showRecent ? _recentFromDiary() : const [];

    return Scaffold(
      body: WidescreenWrapper(
        child: Column(
          children: [
            AtlasHeader(title: i18n.ingredients),
            const IngredientFilterRow(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    PillChip(
                      i18n.recents,
                      selected: _recent,
                      height: 36,
                      fontSize: 14,
                      onTap: () => setState(() => _recent = true),
                    ),
                    PillChip(
                      i18n.allIngredients,
                      selected: !_recent,
                      height: 36,
                      fontSize: 14,
                      onTap: () => setState(() => _recent = false),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: showRecent
                  ? _IngredientsList(
                      ingredientList: [for (final r in recent) r.$1],
                      amounts: {for (final r in recent) r.$1.id: (r.$2, r.$3)},
                    )
                  : ingredientsAsync.when(
                      data: (list) => _IngredientsList(
                        ingredientList: list,
                      ),

                      loading: () => const Center(child: CenteredProgressIndicator()),
                      error: (e, st) => Center(child: Text('Error: $e')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientsList extends StatelessWidget {
  const _IngredientsList({required this.ingredientList, this.amounts = const {}});

  final List<Ingredient> ingredientList;
  final Map<int, (num, IngredientWeightUnit?)> amounts;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: AtlasCard(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            for (final (i, ingredient) in ingredientList.indexed) ...[
              if (i > 0) Divider(height: 1, color: atlas.line),
              IngredientListTile(
                ingredient: ingredient,
                amount: amounts[ingredient.id]?.$1,
                weightUnit: amounts[ingredient.id]?.$2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
