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

part 'ai_provider_config.g.dart';

/// Providers the user can bring their own key for.
const aiProviders = ['openai', 'anthropic', 'none'];

/// Models offered per provider (the user may type another one).
const aiProviderModels = <String, List<String>>{
  'anthropic': ['claude-opus-5-5', 'claude-sonnet-5-5', 'claude-haiku-4-5'],
  'openai': ['gpt-4o', 'gpt-4o-mini'],
  'none': <String>[],
};

/// The user's own AI provider (`ai-provider/`). The API key is write-only: the
/// server only reports whether one is stored and its last four characters.
@JsonSerializable(createToJson: false)
class AiProviderConfig {
  @JsonKey(defaultValue: 'none')
  final String provider;

  @JsonKey(defaultValue: '')
  final String model;

  @JsonKey(name: 'has_api_key', defaultValue: false)
  final bool hasApiKey;

  @JsonKey(name: 'api_key_last4', defaultValue: '')
  final String apiKeyLast4;

  const AiProviderConfig({
    this.provider = 'none',
    this.model = '',
    this.hasApiKey = false,
    this.apiKeyLast4 = '',
  });

  /// The masked key for display, e.g. `••••1234`
  String get maskedKey => hasApiKey ? '••••$apiKeyLast4' : '';

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) => _$AiProviderConfigFromJson(json);
}
