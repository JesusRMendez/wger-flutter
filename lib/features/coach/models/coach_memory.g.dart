// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_memory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoachMemory _$CoachMemoryFromJson(Map<String, dynamic> json) => CoachMemory(
  id: (json['id'] as num?)?.toInt(),
  text: json['text'] as String? ?? '',
  category: json['category'] as String? ?? 'preference',
  source: json['source'] as String? ?? 'user',
  created: json['created'] as String?,
);

Map<String, dynamic> _$CoachMemoryToJson(CoachMemory instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'category': instance.category,
};
