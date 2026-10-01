// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoachLocation _$CoachLocationFromJson(Map<String, dynamic> json) => CoachLocation(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String? ?? '',
  isDefault: json['is_default'] as bool? ?? false,
  availableMinutes: (json['available_minutes'] as num?)?.toInt(),
);
