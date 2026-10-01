// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoachGoal _$CoachGoalFromJson(Map<String, dynamic> json) => CoachGoal(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String? ?? '',
  kind: json['kind'] as String? ?? 'strength',
  period: json['period'] as String? ?? 'monthly',
  indicator: json['indicator'] as String?,
  exercise: (json['exercise'] as num?)?.toInt(),
  targetValue: _decimalFromJson(json['target_value']),
  unit: json['unit'] as String? ?? '',
  baselineValue: _decimalFromJson(json['baseline_value']),
  currentValue: _decimalFromJson(json['current_value']),
  progressPct: json['progress_pct'] as num?,
  startDate: json['start_date'] as String?,
  endDate: json['end_date'] as String?,
  status: json['status'] as String? ?? 'active',
);

Map<String, dynamic> _$CoachGoalToJson(CoachGoal instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'kind': instance.kind,
  'period': instance.period,
  'indicator': instance.indicator,
  'exercise': instance.exercise,
  'target_value': _decimalToJson(instance.targetValue),
  'unit': instance.unit,
  'baseline_value': _decimalToJson(instance.baselineValue),
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'status': instance.status,
};
