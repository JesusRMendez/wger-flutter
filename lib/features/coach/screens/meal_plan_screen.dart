/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
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
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/coach/models/meal_proposal.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/providers/coach_repository.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/features/nutrition/screens/nutritional_plan_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  static const routeName = '/coach-meal-plan';

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  int _meals = 4;
  final Set<String> _diets = {};
  final _kcal = TextEditingController();
  final _prefs = TextEditingController();
  bool _applying = false;
  Object? _applyError;
  MealPlanApplyResult? _result;

  @override
  void dispose() {
    _kcal.dispose();
    _prefs.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() {
      _applyError = null;
      _result = null;
    });
    ref
        .read(mealPlanGeneratorProvider.notifier)
        .generate(
          MealPlanRequest(
            kcalTarget: int.tryParse(_kcal.text.trim()),
            mealsPerDay: _meals,
            preferences: [..._diets, _prefs.text].where((e) => e.trim().isNotEmpty).join(', '),
          ),
        );
  }

  Future<void> _apply(MealProposal proposal) async {
    setState(() {
      _applying = true;
      _applyError = null;
    });
    try {
      final result = await ref.read(coachRepositoryProvider).applyMealPlan(proposal);
      ref.invalidate(nutritionProvider);
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _applyError = e);
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final generated = ref.watch(mealPlanGeneratorProvider);
    final proposal = generated.value;
    final result = _result;

    String n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

    final atlas = context.atlas;
    final diets = {
      'vegetarian': i18n.coachDietVegetarian,
      'lactose free': i18n.coachDietLactoseFree,
      'low budget': i18n.coachDietLowBudget,
      'quick to cook': i18n.coachDietQuick,
    };

    return Scaffold(
      body: WidescreenWrapper(
        child: Column(
          children: [
            AtlasHeader(
              title: i18n.coachMealPlan,
              subtitle: i18n.coachMealPlanHint,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 8,
                      children: [
                        for (final e in diets.entries)
                          PillChip(
                            e.value,
                            key: ValueKey('mp-diet-${e.key}'),
                            height: 40,
                            fontSize: 14,
                            selected: _diets.contains(e.key),
                            onTap: () => setState(() {
                              if (!_diets.remove(e.key)) {
                                _diets.add(e.key);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AtlasCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionEyebrow(i18n.coachMealsPerDay),
                        const SizedBox(height: 10),
                        Wrap(
                          key: const ValueKey('mp-meals'),
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var d = 2; d <= 8; d++)
                              PillChip(
                                '$d',
                                key: ValueKey('mp-meals-$d'),
                                mono: true,
                                height: 44,
                                fontSize: 15,
                                selected: _meals == d,
                                onTap: () => setState(() => _meals = d),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('mp-kcal'),
                          controller: _kcal,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: i18n.coachKcalTarget),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('mp-prefs'),
                          controller: _prefs,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(labelText: i18n.coachPreferences),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (generated.isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(i18n.coachGenerating),
                      ],
                    ),
                  if (generated.hasError) CoachErrorView(generated.error!, onRetry: _generate),
                  if (_applyError != null) CoachErrorView(_applyError!),
                  if (proposal != null) ...[
                    Text(proposal.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(i18n.coachTotals, style: theme.textTheme.titleMedium),
                              MonoText(
                                proposal.kcalTarget == null
                                    ? i18n.kcalValue(n(proposal.totals.kcal))
                                    : i18n.coachMealPlanTarget(
                                        n(proposal.totals.kcal),
                                        proposal.kcalTarget.toString(),
                                      ),
                                size: 15,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SplitBar(
                            values: [
                              proposal.totals.protein.toDouble(),
                              proposal.totals.carbs.toDouble(),
                              proposal.totals.fat.toDouble(),
                            ],
                            colors: [atlas.protein, atlas.carbs, atlas.fat],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              _macro(
                                context,
                                '${n(proposal.totals.protein)} g ${i18n.proteinAbbr}',
                                atlas.protein,
                              ),
                              _macro(
                                context,
                                '${n(proposal.totals.carbs)} g ${i18n.carbsAbbr}',
                                atlas.carbs,
                              ),
                              _macro(
                                context,
                                '${n(proposal.totals.fat)} g ${i18n.fatAbbr}',
                                atlas.fat,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${i18n.kcalValue(n(proposal.totals.kcal))} · '
                            '${i18n.protein} ${n(proposal.totals.protein)} g · '
                            '${i18n.carbohydrates} ${n(proposal.totals.carbs)} g · '
                            '${i18n.fat} ${n(proposal.totals.fat)} g',
                            style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                          ),
                        ],
                      ),
                    ),
                    for (final meal in proposal.meals)
                      AtlasCard(
                        margin: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.time == null ? meal.name : '${meal.name} · ${meal.time}',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            for (final item in meal.items)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: item.isLinked ? null : atlas.ink3,
                                        ),
                                      ),
                                    ),
                                    MonoText(
                                      '${n(item.amountG)} g',
                                      size: 13,
                                      weight: FontWeight.w500,
                                      color: atlas.ink3,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (proposal.unlinkedItems.isNotEmpty && result == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${i18n.coachSkippedItems}: ${proposal.unlinkedItems.map((e) => e.name).join(', ')}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (result == null)
                      FilledButton(
                        key: const ValueKey('mp-apply'),
                        onPressed: _applying ? null : () => _apply(proposal),
                        child: Text(i18n.coachApply),
                      )
                    else ...[
                      Text(i18n.coachPlanApplied, style: theme.textTheme.titleMedium),
                      if (result.skipped.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(i18n.coachSkippedItems, style: theme.textTheme.titleSmall),
                        Text(i18n.coachSkippedItemsExplanation),
                        for (final s in result.skipped) Text('• $s'),
                      ],
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const ValueKey('mp-open'),
                        onPressed: () => unawaited(
                          Navigator.of(context).pushNamed(
                            NutritionalPlanScreen.routeName,
                            arguments: result.nutritionPlanId,
                          ),
                        ),
                        child: Text(i18n.coachOpenPlan),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    key: const ValueKey('mp-generate'),
                    onPressed: generated.isLoading || _applying ? null : _generate,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(i18n.coachGenerate),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(BuildContext context, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        MonoText(text, size: 13, weight: FontWeight.w500, color: context.atlas.ink2),
      ],
    );
  }
}
