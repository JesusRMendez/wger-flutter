// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_access.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoachAccess _$CoachAccessFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['id']);
  return CoachAccess(
    id: (json['id'] as num).toInt(),
    username: json['username'] as String? ?? '',
    serverAiEnabled: json['server_ai_enabled'] as bool? ?? false,
    monthlyTokenLimit: (json['monthly_token_limit'] as num?)?.toInt(),
    memoryEnabled: json['memory_enabled'] as bool? ?? false,
    effectiveMode: json['effective_mode'] == null
        ? CoachMode.none
        : CoachMode.fromString(json['effective_mode'] as String?),
  );
}

Map<String, dynamic> _$CoachAccessToJson(CoachAccess instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'server_ai_enabled': instance.serverAiEnabled,
  'monthly_token_limit': instance.monthlyTokenLimit,
  'memory_enabled': instance.memoryEnabled,
  'effective_mode': CoachAccess._modeToJson(instance.effectiveMode),
};

CoachUsage _$CoachUsageFromJson(Map<String, dynamic> json) => CoachUsage(
  month: json['month'] as String? ?? '',
  inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
  outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
  limit: (json['limit'] as num?)?.toInt(),
  mode: json['mode'] == null ? CoachMode.none : CoachMode.fromString(json['mode'] as String?),
);

Map<String, dynamic> _$CoachUsageToJson(CoachUsage instance) => <String, dynamic>{
  'month': instance.month,
  'input_tokens': instance.inputTokens,
  'output_tokens': instance.outputTokens,
  'limit': instance.limit,
  'mode': CoachUsage._modeToJson(instance.mode),
};
