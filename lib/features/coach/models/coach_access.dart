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

part 'coach_access.g.dart';

/// Which AI backs the coach for the user (`effective_mode` of the server).
enum CoachMode {
  /// The server's own key and configuration
  server,

  /// The user's own provider and key ("bring your own")
  byo,

  /// No AI available
  none;

  static CoachMode fromString(String? value) {
    return CoachMode.values.firstWhere((m) => m.name == value, orElse: () => CoachMode.none);
  }
}

/// The user's own `ai-coach-access` record.
@JsonSerializable()
class CoachAccess {
  @JsonKey(required: true)
  final int id;

  @JsonKey(defaultValue: '')
  final String username;

  @JsonKey(name: 'server_ai_enabled', defaultValue: false)
  final bool serverAiEnabled;

  @JsonKey(name: 'monthly_token_limit')
  final int? monthlyTokenLimit;

  @JsonKey(name: 'memory_enabled', defaultValue: false)
  final bool memoryEnabled;

  @JsonKey(name: 'effective_mode', fromJson: CoachMode.fromString, toJson: _modeToJson)
  final CoachMode effectiveMode;

  const CoachAccess({
    required this.id,
    this.username = '',
    this.serverAiEnabled = false,
    this.monthlyTokenLimit,
    this.memoryEnabled = false,
    this.effectiveMode = CoachMode.none,
  });

  factory CoachAccess.fromJson(Map<String, dynamic> json) => _$CoachAccessFromJson(json);

  Map<String, dynamic> toJson() => _$CoachAccessToJson(this);

  static String _modeToJson(CoachMode m) => m.name;
}

/// Response of `coach/usage/`.
@JsonSerializable()
class CoachUsage {
  @JsonKey(defaultValue: '')
  final String month;

  @JsonKey(name: 'input_tokens', defaultValue: 0)
  final int inputTokens;

  @JsonKey(name: 'output_tokens', defaultValue: 0)
  final int outputTokens;

  /// Monthly token limit, null when unlimited
  final int? limit;

  @JsonKey(fromJson: CoachMode.fromString, toJson: _modeToJson)
  final CoachMode mode;

  const CoachUsage({
    this.month = '',
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.limit,
    this.mode = CoachMode.none,
  });

  int get totalTokens => inputTokens + outputTokens;

  /// Fraction of the limit that has been used, null without a limit
  double? get usedFraction {
    final l = limit;
    if (l == null || l <= 0) {
      return null;
    }
    return (totalTokens / l).clamp(0.0, 1.0);
  }

  factory CoachUsage.fromJson(Map<String, dynamic> json) => _$CoachUsageFromJson(json);

  Map<String, dynamic> toJson() => _$CoachUsageToJson(this);

  static String _modeToJson(CoachMode m) => m.name;
}
