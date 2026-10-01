// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiProviderConfig _$AiProviderConfigFromJson(Map<String, dynamic> json) => AiProviderConfig(
  provider: json['provider'] as String? ?? 'none',
  model: json['model'] as String? ?? '',
  hasApiKey: json['has_api_key'] as bool? ?? false,
  apiKeyLast4: json['api_key_last4'] as String? ?? '',
);
