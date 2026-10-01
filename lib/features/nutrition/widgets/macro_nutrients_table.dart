import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/nutrition/models/nutritional_goals.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class MacronutrientsTable extends StatelessWidget {
  const MacronutrientsTable({
    super.key,
    required this.nutritionalGoals,
    required this.plannedValuesPercentage,
    this.nutritionalGoalsGperKg,
    this.showGperKg = true,
  });

  static const double tablePadding = 7;
  final NutritionalGoals nutritionalGoals;
  final NutritionalGoals plannedValuesPercentage;
  final NutritionalGoals? nutritionalGoalsGperKg;
  final bool showGperKg;

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

    TableRow macroRow(int indent, bool g, String title, double? Function(NutritionalGoals ng) get) {
      final goal = get(nutritionalGoals);
      final pct = get(plannedValuesPercentage);
      final perkg = nutritionalGoalsGperKg == null ? null : get(nutritionalGoalsGperKg!);
      final valFn = g ? loc.gValue : loc.kcalValue;

      return TableRow(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: tablePadding, horizontal: indent * 12),
            child: Text(title),
          ),
          MonoText(
            goal != null ? valFn(goal.toStringAsFixed(0)) : '',
            size: 13.5,
            weight: FontWeight.w500,
            textAlign: TextAlign.right,
          ),
          MonoText(
            pct != null ? pct.toStringAsFixed(1) : '',
            size: 13.5,
            weight: FontWeight.w500,
            color: context.atlas.ink2,
            textAlign: TextAlign.right,
          ),
          if (showGperKg)
            MonoText(
              perkg != null ? perkg.toStringAsFixed(1) : '',
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
      columnWidths: {0: FractionColumnWidth(showGperKg ? 0.26 : 0.4)},
      children: [
        TableRow(
          children: [
            columnHeader(true, loc.macronutrients),
            columnHeader(false, loc.total),
            columnHeader(false, loc.percentEnergy),
            if (showGperKg) columnHeader(false, loc.gPerBodyKg),
          ],
        ),
        macroRow(0, false, loc.energy, (NutritionalGoals ng) => ng.energy),
        macroRow(0, true, loc.protein, (NutritionalGoals ng) => ng.protein),
        macroRow(0, true, loc.carbohydrates, (NutritionalGoals ng) => ng.carbohydrates),
        macroRow(1, true, loc.sugars, (NutritionalGoals ng) => ng.carbohydratesSugar),
        macroRow(0, true, loc.fat, (NutritionalGoals ng) => ng.fat),
        macroRow(1, true, loc.saturatedFat, (NutritionalGoals ng) => ng.fatSaturated),
        macroRow(0, true, loc.fiber, (NutritionalGoals ng) => ng.fiber),
        macroRow(0, true, loc.sodium, (NutritionalGoals ng) => ng.sodium),
      ],
    );
  }
}
