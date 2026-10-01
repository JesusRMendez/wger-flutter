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

import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/misc.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/core/widgets/wger_image.dart';
import 'package:wger/features/nutrition/models/ingredient.dart';
import 'package:wger/features/nutrition/widgets/macro_nutrients_table.dart';
import 'package:wger/features/nutrition/widgets/nutri_score_badge.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class IngredientImageHeader extends StatelessWidget {
  const IngredientImageHeader({super.key, required this.mediaPath});

  /// Path relative to MEDIA_ROOT (as stored on `IngredientImage.image`),
  /// or `null` to render the placeholder `WgerImage` falls back to.
  final String? mediaPath;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final smallest = size.shortestSide;
    final radius = smallest > 400 ? smallest / 2.5 : 100.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: radius,
          width: size.width,
          child: Stack(
            children: [
              WgerImage(
                mediaPath: mediaPath,
                height: radius,
                width: size.width,
                fit: BoxFit.cover,
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
                child: SizedBox(height: radius, width: size.width),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: WgerImage(
                      mediaPath: mediaPath,
                      height: radius,
                      width: size.width,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IngredientDetailsDialog extends StatelessWidget {
  final Ingredient ingredient;
  final void Function()? onSelect;

  const IngredientDetailsDialog(this.ingredient, {super.key, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ingredient.name),
          if (ingredient.brand case final brand? when brand.isNotEmpty)
            Text(
              brand,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 400),
            child: IngredientDetails(ingredient, onSelect: onSelect, showHeader: false),
          ),
        ),
      ),
      actions: [
        if (onSelect != null)
          TextButton(
            key: const Key('ingredient-details-continue-button'),
            child: Text(MaterialLocalizations.of(context).continueButtonLabel),
            onPressed: () {
              onSelect!();
              Navigator.of(context).pop();
            },
          ),
        TextButton(
          key: const Key('ingredient-details-close-button'),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class IngredientDetails extends StatefulWidget {
  final Ingredient ingredient;
  final void Function()? onSelect;

  /// Show the name, brand and source on top. The dialog has its own title.
  final bool showHeader;

  const IngredientDetails(this.ingredient, {super.key, this.onSelect, this.showHeader = true});

  @override
  State<IngredientDetails> createState() => _IngredientDetailsState();
}

class _IngredientDetailsState extends State<IngredientDetails> {
  /// Reference amount in grams the portion card and the table show
  double _amount = 100;

  @override
  Widget build(BuildContext context) {
    final ingredient = widget.ingredient;
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final source = ingredient.sourceName ?? 'unknown';
    final values = ingredient.nutritionalValues / (_amount > 0 ? 100 / _amount : double.infinity);
    final goals = values.toGoals();
    final amountText = i18n.gValue(_amount.round().toString());

    final brand = ingredient.brand;
    final headerSub = [
      if (brand != null && brand.isNotEmpty) brand,
      source,
    ].join(' · ');

    final sourceWidget = ingredient.licenseObjectURl == null
        ? Center(child: Text('Source: $source'))
        : Center(
            child: InkWell(
              child: Text(
                'Source: $source',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () => launchURL(ingredient.licenseObjectURl!, context),
            ),
          );

    final energyKcal =
        values.protein * ENERGY_PROTEIN +
        values.carbohydrates * ENERGY_CARBOHYDRATES +
        values.fat * ENERGY_FAT;
    String pct(double v) => energyKcal > 0 ? (100 * v / energyKcal).round().toString() : '0';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        if (widget.showHeader)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 72,
                  height: 72,
                  color: atlas.surface2,
                  alignment: Alignment.center,
                  child: ingredient.image?.image != null
                      ? WgerImage(
                          mediaPath: ingredient.image!.image,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          _initials(ingredient.name),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: theme.textTheme.headlineMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headerSub,
                      style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
            ],
          )
        else if (ingredient.image?.image != null)
          IngredientImageHeader(mediaPath: ingredient.image!.image),

        DietaryInfoSection(ingredient: ingredient),

        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 8,
                  children: [
                    PillChip(
                      i18n.gValue('100'),
                      selected: _amount == 100,
                      onTap: () => setState(() => _amount = 100),
                      height: 34,
                      fontSize: 13,
                    ),
                    for (final unit in ingredient.weightUnits)
                      PillChip(
                        '${unit.name} · ${i18n.gValue(unit.grams.toString())}',
                        selected: _amount == unit.grams,
                        onTap: () => setState(() => _amount = unit.grams.toDouble()),
                        height: 34,
                        fontSize: 13,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    i18n.amount,
                    style: theme.textTheme.bodyLarge?.copyWith(color: atlas.ink3),
                  ),
                  const Spacer(),
                  MonoText(
                    _amount.round().toString(),
                    size: 40,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(i18n.g, style: theme.textTheme.titleMedium?.copyWith(color: atlas.ink3)),
                ],
              ),
              Slider(
                min: 5,
                max: _amount > 500 ? _amount : 500,
                value: _amount.clamp(5, _amount > 500 ? _amount : 500),
                onChanged: (v) => setState(() => _amount = v.roundToDouble()),
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: MacroTile(
                      value: values.energy.toStringAsFixed(0),
                      label: i18n.kcal,
                      color: atlas.ink3,
                    ),
                  ),
                  Expanded(
                    child: MacroTile(
                      value: values.protein.toStringAsFixed(1),
                      label: i18n.proteinAbbr,
                      color: atlas.protein,
                    ),
                  ),
                  Expanded(
                    child: MacroTile(
                      value: values.carbohydrates.toStringAsFixed(1),
                      label: i18n.carbsAbbr,
                      color: atlas.carbs,
                    ),
                  ),
                  Expanded(
                    child: MacroTile(
                      value: values.fat.toStringAsFixed(1),
                      label: i18n.fatAbbr,
                      color: atlas.fat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SplitBar(
                values: [
                  values.protein * ENERGY_PROTEIN,
                  values.carbohydrates * ENERGY_CARBOHYDRATES,
                  values.fat * ENERGY_FAT,
                ],
                colors: [atlas.protein, atlas.carbs, atlas.fat],
              ),
              const SizedBox(height: 10),
              Text(
                i18n.calorieSplit(
                  pct(values.protein * ENERGY_PROTEIN),
                  pct(values.carbohydrates * ENERGY_CARBOHYDRATES),
                  pct(values.fat * ENERGY_FAT),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
              ),
            ],
          ),
        ),

        AtlasCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(i18n.nutritionalInformation, style: theme.textTheme.titleMedium),
                  MonoText(
                    i18n.perAmount(amountText),
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: atlas.ink3,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              MacronutrientsTable(
                nutritionalGoals: goals,
                plannedValuesPercentage: goals.energyPercentage(),
                showGperKg: false,
              ),
            ],
          ),
        ),

        sourceWidget,
      ],
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return '';
    }
    final first = words.first.substring(0, 1);
    final second = words.length > 1 ? words[1].substring(0, 1) : '';
    return (first + second).toUpperCase();
  }
}

class IngredientScanResultDialog extends StatelessWidget {
  final AsyncSnapshot<Ingredient?> snapshot;
  final String barcode;
  final Function(Ingredient ingredient, num? amount) onSelectIngredient;

  const IngredientScanResultDialog(
    this.snapshot,
    this.barcode,
    this.onSelectIngredient, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    // Scan still running: show a spinner.
    if (snapshot.connectionState != ConnectionState.done) {
      return AlertDialog(
        key: const Key('ingredient-scan-result-dialog'),
        content: const BoxedProgressIndicator(),
        actions: [_closeButton(context)],
      );
    }

    // Scan threw: surface the error with the shared indicator.
    if (snapshot.hasError) {
      return AlertDialog(
        key: const Key('ingredient-scan-result-dialog'),
        content: StreamErrorIndicator(snapshot.error!, stacktrace: snapshot.stackTrace),
        actions: [_closeButton(context)],
      );
    }

    final ingredient = snapshot.data;

    // No product matched the barcode, offer the user to add it to OFF.
    if (ingredient == null) {
      return AlertDialog(
        key: const Key('ingredient-scan-result-dialog'),
        title: Text(i18n.productNotFound),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(i18n.productNotFoundDescription(barcode)),
              const SizedBox(height: 8),
              Text(i18n.productNotFoundOpenFoodFacts),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            key: const Key('ingredient-scan-result-dialog-open-food-facts-button'),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(i18n.addToOpenFoodFacts),
            onPressed: () {
              launchURL('https://world.openfoodfacts.org/cgi/product.pl', context);
              Navigator.of(context).pop();
            },
          ),
          _closeButton(context),
        ],
      );
    }

    // Product found, render details + confirm button.
    final goals = ingredient.nutritionalValues.toGoals();
    final source = ingredient.sourceName ?? 'unknown';
    return AlertDialog(
      key: const Key('ingredient-scan-result-dialog'),
      title: Text(i18n.productFound),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(i18n.productFoundDescription(ingredient.name)),
              ),
              if (ingredient.image?.image != null)
                IngredientImageHeader(mediaPath: ingredient.image!.image),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 400),
                child: MacronutrientsTable(
                  nutritionalGoals: goals,
                  plannedValuesPercentage: goals.energyPercentage(),
                  showGperKg: false,
                ),
              ),
              if (ingredient.licenseObjectURl == null)
                Text('Source: $source')
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: InkWell(
                    child: Text('Source: $source'),
                    onTap: () => launchURL(ingredient.licenseObjectURl!, context),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('ingredient-scan-result-dialog-confirm-button'),
          child: Text(MaterialLocalizations.of(context).continueButtonLabel),
          onPressed: () {
            onSelectIngredient(ingredient, null);
            Navigator.of(context).pop();
          },
        ),
        _closeButton(context),
      ],
    );
  }

  Widget _closeButton(BuildContext context) => TextButton(
    key: const Key('ingredient-scan-result-dialog-close-button'),
    child: Text(MaterialLocalizations.of(context).closeButtonLabel),
    onPressed: () => Navigator.of(context).pop(),
  );
}

class DietaryInfoSection extends StatelessWidget {
  final Ingredient ingredient;

  const DietaryInfoSection({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);

    PillChip chip(String label, bool? value) => PillChip(
      value == null ? '$label · N/A' : label,
      icon: value == null
          ? null
          : value
          ? Icons.eco
          : Icons.block,
      tone: value == null
          ? ChipTone.neutral
          : value
          ? ChipTone.ok
          : ChipTone.accent,
    );

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.dietaryInformation,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text('Nutri-Score', style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3)),
          const SizedBox(height: 8),
          if (ingredient.nutriscore != null)
            NutriScoreStrip(score: ingredient.nutriscore!)
          else
            Text('N/A', style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(i18n.isVegan, ingredient.isVegan),
              chip(i18n.isVegetarian, ingredient.isVegetarian),
            ],
          ),
        ],
      ),
    );
  }
}
