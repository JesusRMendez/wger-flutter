import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/nutrition/models/ingredient.dart';
import 'package:wger/features/nutrition/models/log.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/models/nutritional_values.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/widgets/helpers.dart';
import 'package:wger/features/nutrition/widgets/nutrition_tile.dart';
import 'package:wger/features/nutrition/widgets/widgets.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// a NutritionTitle showing an ingredient, with its
/// avatar, nutritional values and button to popup its details
class MealItemValuesTile extends ConsumerWidget {
  final Ingredient ingredient;
  final NutritionalValues nutritionalValues;

  const MealItemValuesTile({
    super.key,
    required this.ingredient,
    required this.nutritionalValues,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NutritionTile(
      leading: IngredientAvatar(ingredient: ingredient),
      title: Text(getShortNutritionValues(nutritionalValues, context)),
      trailing: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () {
          showIngredientDetails(context, ref, ingredient);
        },
      ),
    );
  }
}

/// a NutritionTitle showing the header for the diary
class DiaryheaderTile extends StatelessWidget {
  final Widget? leading;

  const DiaryheaderTile({this.leading});

  @override
  Widget build(BuildContext context) {
    return NutritionTile(title: getNutritionRow(context, muted(getNutritionColumnNames(context))));
  }
}

/// a NutritionTitle showing diary entries
class DiaryEntryTile extends ConsumerWidget {
  const DiaryEntryTile({
    super.key,
    required this.diaryEntry,
    this.nutritionalPlan,
  });

  final LogItem diaryEntry;
  final NutritionalPlan? nutritionalPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final i18n = AppLocalizations.of(context);
    final values = diaryEntry.nutritionalValues;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: MonoText(
              DateFormat.Hm(Localizations.localeOf(context).languageCode).format(
                diaryEntry.datetime,
              ),
              size: 13,
              color: atlas.ink3,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Ingredient is null briefly between local insert and PowerSync
                  // pulling the row down, show an ellipsis placeholder.
                  diaryEntry.weightUnitObj != null
                      ? '${diaryEntry.amount.toStringAsFixed(0)} × ${diaryEntry.weightUnitObj!.name} ${diaryEntry.ingredient?.name ?? '…'}'
                      : '${i18n.gValue(diaryEntry.amount.toStringAsFixed(0))} ${diaryEntry.ingredient?.name ?? '…'}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 10,
                  children: [
                    MonoText(
                      i18n.kcalValue(values.energy.toStringAsFixed(0)),
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: atlas.ink2,
                    ),
                    _macro('P', values.protein, atlas.protein),
                    _macro('C', values.carbohydrates, atlas.carbs),
                    _macro('F', values.fat, atlas.fat),
                  ],
                ),
              ],
            ),
          ),
          if (nutritionalPlan != null)
            IconButton(
              tooltip: i18n.delete,
              onPressed: () {
                ref.read(nutritionProvider.notifier).deleteLog(diaryEntry.id!);
              },
              icon: const Icon(Icons.delete_outline),
              color: atlas.ink3,
              iconSize: ICON_SIZE_SMALL,
            ),
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
