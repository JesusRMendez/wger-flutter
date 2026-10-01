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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/nutrition/models/ingredient.dart';
import 'package:wger/features/nutrition/models/ingredient_weight_unit.dart';
import 'package:wger/features/nutrition/screens/ingredient_detail_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class IngredientListTile extends StatelessWidget {
  const IngredientListTile({super.key, required this.ingredient, this.amount, this.weightUnit});

  final Ingredient ingredient;

  /// Amount the ingredient was last eaten at (in grams, or in [weightUnit]),
  /// the values are then shown for it instead of for 100 g
  final num? amount;
  final IngredientWeightUnit? weightUnit;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);

    final grams = amount == null
        ? 100.0
        : (weightUnit == null ? amount! : amount! * weightUnit!.grams).toDouble();
    final values = ingredient.nutritionalValues / (grams > 0 ? 100 / grams : double.infinity);
    final amountText = amount == null
        ? i18n.gValue('100')
        : weightUnit == null
        ? i18n.gValue(amount!.toStringAsFixed(0))
        : '${amount!.toStringAsFixed(0)} × ${weightUnit!.name} · ${i18n.gValue(grams.toStringAsFixed(0))}';

    void open() => Navigator.pushNamed(
      context,
      IngredientDetailScreen.routeName,
      arguments: ingredient.id,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  MonoText(
                    '$amountText · ${i18n.kcalValue(values.energy.toStringAsFixed(0))} · '
                    '${values.protein.toStringAsFixed(0)} ${i18n.g} ${i18n.proteinAbbr}',
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: atlas.ink3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: atlas.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: atlas.line),
              ),
              child: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
