// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanPhase _$PlanPhaseFromJson(Map<String, dynamic> json) => PlanPhase(
  key: json['key'] as String? ?? '',
  name: json['name'] as String? ?? '',
  weekFrom: (json['week_from'] as num?)?.toInt(),
  weekTo: (json['week_to'] as num?)?.toInt(),
);

Recommendation _$RecommendationFromJson(Map<String, dynamic> json) => Recommendation(
  key: json['key'] as String? ?? '',
  severity: json['severity'] as String? ?? 'info',
  title: json['title'] as String? ?? '',
  detail: json['detail'] as String? ?? '',
  action: json['action'] as String?,
);

PlanRecommendations _$PlanRecommendationsFromJson(Map<String, dynamic> json) => PlanRecommendations(
  routine: (json['routine'] as num?)?.toInt(),
  week: (json['week'] as num?)?.toInt(),
  phase: json['phase'] == null ? null : PlanPhase.fromJson(json['phase'] as Map<String, dynamic>),
  recommendations:
      (json['recommendations'] as List<dynamic>?)
          ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
