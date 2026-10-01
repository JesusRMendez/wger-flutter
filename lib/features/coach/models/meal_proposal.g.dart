// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_proposal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProposalMealItem _$ProposalMealItemFromJson(Map<String, dynamic> json) => ProposalMealItem(
  ingredientId: (json['ingredient_id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  amountG: json['amount_g'] == null ? 0 : _num(json['amount_g']),
);

Map<String, dynamic> _$ProposalMealItemToJson(ProposalMealItem instance) => <String, dynamic>{
  'ingredient_id': instance.ingredientId,
  'name': instance.name,
  'amount_g': instance.amountG,
};

ProposalMeal _$ProposalMealFromJson(Map<String, dynamic> json) => ProposalMeal(
  name: json['name'] as String? ?? '',
  time: json['time'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ProposalMealItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$ProposalMealToJson(ProposalMeal instance) => <String, dynamic>{
  'name': instance.name,
  'time': instance.time,
  'items': instance.items,
};

MealTotals _$MealTotalsFromJson(Map<String, dynamic> json) => MealTotals(
  kcal: json['kcal'] == null ? 0 : _num(json['kcal']),
  protein: json['protein'] == null ? 0 : _num(json['protein']),
  carbs: json['carbs'] == null ? 0 : _num(json['carbs']),
  fat: json['fat'] == null ? 0 : _num(json['fat']),
);

Map<String, dynamic> _$MealTotalsToJson(MealTotals instance) => <String, dynamic>{
  'kcal': instance.kcal,
  'protein': instance.protein,
  'carbs': instance.carbs,
  'fat': instance.fat,
};
