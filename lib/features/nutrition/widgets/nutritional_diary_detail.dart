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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/models/nutritional_values.dart';
import 'package:wger/features/nutrition/widgets/charts.dart';
import 'package:wger/features/nutrition/widgets/nutrition_tiles.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class NutritionalDiaryDetailWidget extends StatelessWidget {
  final NutritionalPlan _nutritionalPlan;
  final DateTime _date;

  const NutritionalDiaryDetailWidget(this._nutritionalPlan, this._date);

  @override
  Widget build(BuildContext context) {
    final nutritionalGoals = _nutritionalPlan.nutritionalGoals;
    final valuesLogged = _nutritionalPlan.getValuesForDate(_date);
    final logs = _nutritionalPlan.getLogsForDate(_date);

    if (valuesLogged == null) {
      return const Text('');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtlasCard(
          child: DiaryRings(planned: nutritionalGoals.toValues(), logged: valuesLogged),
        ),
        const SizedBox(height: 12),
        AtlasCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: NutritionDiaryTable(
            planned: nutritionalGoals.toValues(),
            logged: valuesLogged,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: SectionEyebrow(AppLocalizations.of(context).logged),
        ),
        AtlasCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              for (final (i, e) in logs.indexed) ...[
                if (i > 0) Divider(color: context.atlas.line),
                DiaryEntryTile(diaryEntry: e, nutritionalPlan: _nutritionalPlan),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class NutritionDiaryTable extends StatelessWidget {
  const NutritionDiaryTable({
    super.key,
    required this.planned,
    required this.logged,
  });

  static const double tablePadding = 7;
  final NutritionalValues planned;
  final NutritionalValues logged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    Widget columnHeader(bool left, String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: tablePadding),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.atlas.ink3,
          letterSpacing: 0.6,
        ),
        textAlign: left ? TextAlign.left : TextAlign.right,
      ),
    );

    TableRow macroRow(int indent, bool g, String title, double Function(NutritionalValues nv) get) {
      final valFn = g ? loc.gValue : loc.kcalValue;
      return TableRow(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: tablePadding, horizontal: indent * 12),
            child: Text(title),
          ),
          MonoText(
            valFn(get(planned).toStringAsFixed(0)),
            size: 13.5,
            weight: FontWeight.w500,
            textAlign: TextAlign.right,
          ),
          MonoText(
            valFn(get(logged).toStringAsFixed(0)),
            size: 13.5,
            weight: FontWeight.w500,
            textAlign: TextAlign.right,
          ),
          MonoText(
            (get(logged) - get(planned)).toStringAsFixed(0),
            size: 13.5,
            weight: FontWeight.w500,
            color: context.atlas.ink2,
            textAlign: TextAlign.right,
          ),
        ],
      );
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(width: 1, color: context.atlas.line),
      ),
      columnWidths: const {0: FractionColumnWidth(0.32)},
      children: [
        TableRow(
          children: [
            columnHeader(true, loc.macronutrients),
            columnHeader(false, loc.planned),
            columnHeader(false, loc.logged),
            columnHeader(false, loc.difference),
          ],
        ),
        macroRow(0, false, loc.energy, (NutritionalValues nv) => nv.energy),
        macroRow(0, true, loc.protein, (NutritionalValues nv) => nv.protein),
        macroRow(0, true, loc.carbohydrates, (NutritionalValues nv) => nv.carbohydrates),
        macroRow(1, true, loc.sugars, (NutritionalValues nv) => nv.carbohydratesSugar),
        macroRow(0, true, loc.fat, (NutritionalValues nv) => nv.fat),
        macroRow(1, true, loc.saturatedFat, (NutritionalValues nv) => nv.fatSaturated),
        macroRow(0, true, loc.fiber, (NutritionalValues nv) => nv.fiber),
        macroRow(0, true, loc.sodium, (NutritionalValues nv) => nv.sodium),
      ],
    );
  }
}
