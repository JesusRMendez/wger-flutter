// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicators.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Indicator _$IndicatorFromJson(Map<String, dynamic> json) => Indicator(
  key: json['key'] as String? ?? '',
  label: json['label'] as String? ?? '',
  value: json['value'] as num,
  unit: json['unit'] as String? ?? '',
  trend: json['trend'] as String?,
  target: json['target'] as num?,
  exerciseId: (json['exercise_id'] as num?)?.toInt(),
);

MissingData _$MissingDataFromJson(Map<String, dynamic> json) => MissingData(
  key: json['key'] as String? ?? '',
  title: json['title'] as String? ?? '',
  detail: json['detail'] as String? ?? '',
  action: json['action'] as String?,
);

DataQuality _$DataQualityFromJson(Map<String, dynamic> json) => DataQuality(
  score: (json['score'] as num?)?.toInt() ?? 0,
  missing:
      (json['missing'] as List<dynamic>?)
          ?.map((e) => MissingData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

IndicatorsResponse _$IndicatorsResponseFromJson(Map<String, dynamic> json) => IndicatorsResponse(
  window: (json['window'] as num?)?.toInt() ?? 28,
  indicators:
      (json['indicators'] as List<dynamic>?)
          ?.map((e) => Indicator.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  dataQuality: json['data_quality'] == null
      ? null
      : DataQuality.fromJson(json['data_quality'] as Map<String, dynamic>),
);
