/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
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

import 'package:json_annotation/json_annotation.dart';

part 'meal_proposal.g.dart';

num _num(Object? v) => v is num ? v : (v is String ? num.tryParse(v) ?? 0 : 0);

/// Request body of `coach/meal-plan/`
class MealPlanRequest {
  final int? kcalTarget;
  final int mealsPerDay;
  final String? preferences;

  const MealPlanRequest({this.kcalTarget, required this.mealsPerDay, this.preferences});

  Map<String, dynamic> toJson() => {
    if (kcalTarget != null) 'kcal_target': kcalTarget,
    'meals_per_day': mealsPerDay,
    if (preferences != null && preferences!.trim().isNotEmpty) 'preferences': preferences!.trim(),
  };
}

@JsonSerializable()
class ProposalMealItem {
  @JsonKey(name: 'ingredient_id')
  final int? ingredientId;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(name: 'amount_g', fromJson: _num, defaultValue: 0)
  final num amountG;

  const ProposalMealItem({this.ingredientId, this.name = '', this.amountG = 0});

  /// Items without an ingredient are skipped when applying the plan
  bool get isLinked => ingredientId != null;

  factory ProposalMealItem.fromJson(Map<String, dynamic> json) => _$ProposalMealItemFromJson(json);

  Map<String, dynamic> toJson() => _$ProposalMealItemToJson(this);
}

@JsonSerializable()
class ProposalMeal {
  @JsonKey(defaultValue: '')
  final String name;
  final String? time;

  @JsonKey(defaultValue: <ProposalMealItem>[])
  final List<ProposalMealItem> items;

  const ProposalMeal({this.name = '', this.time, this.items = const []});

  factory ProposalMeal.fromJson(Map<String, dynamic> json) => _$ProposalMealFromJson(json);

  Map<String, dynamic> toJson() => _$ProposalMealToJson(this);
}

@JsonSerializable()
class MealTotals {
  @JsonKey(fromJson: _num, defaultValue: 0)
  final num kcal;
  @JsonKey(fromJson: _num, defaultValue: 0)
  final num protein;
  @JsonKey(fromJson: _num, defaultValue: 0)
  final num carbs;
  @JsonKey(fromJson: _num, defaultValue: 0)
  final num fat;

  const MealTotals({this.kcal = 0, this.protein = 0, this.carbs = 0, this.fat = 0});

  factory MealTotals.fromJson(Map<String, dynamic> json) => _$MealTotalsFromJson(json);

  Map<String, dynamic> toJson() => _$MealTotalsToJson(this);
}

/// A meal plan proposed by the coach, not yet applied. Keeps the raw JSON to
/// send it back to `coach/meal-plan/apply/` unchanged.
class MealProposal {
  final String name;
  final int? kcalTarget;
  final List<ProposalMeal> meals;
  final MealTotals totals;
  final Map<String, dynamic> raw;

  const MealProposal({
    required this.name,
    this.kcalTarget,
    this.meals = const [],
    this.totals = const MealTotals(),
    this.raw = const {},
  });

  factory MealProposal.fromJson(Map<String, dynamic> json) {
    return MealProposal(
      name: json['name'] as String? ?? '',
      kcalTarget: (json['kcal_target'] as num?)?.toInt(),
      meals: ((json['meals'] as List?) ?? const [])
          .map((e) => ProposalMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: json['totals'] is Map<String, dynamic>
          ? MealTotals.fromJson(json['totals'] as Map<String, dynamic>)
          : const MealTotals(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;

  /// Items that cannot be applied because they have no ingredient
  List<ProposalMealItem> get unlinkedItems =>
      meals.expand((m) => m.items).where((i) => !i.isLinked).toList();
}

/// Response of `coach/meal-plan/apply/`
class MealPlanApplyResult {
  final String nutritionPlanId;

  /// Names of the items the server skipped (no ingredient id)
  final List<String> skipped;

  const MealPlanApplyResult({required this.nutritionPlanId, this.skipped = const []});

  factory MealPlanApplyResult.fromJson(Map<String, dynamic> json) {
    // The contract says "skipped items are listed in the response" without
    // fixing the shape: accept plain names or objects with a name.
    final raw = (json['skipped'] ?? json['skipped_items'] ?? const []) as List;
    return MealPlanApplyResult(
      nutritionPlanId: '${json['nutrition_plan_id']}',
      skipped: raw.map((e) => e is Map ? (e['name'] ?? '').toString() : e.toString()).toList(),
    );
  }
}
