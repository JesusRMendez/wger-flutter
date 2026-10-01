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

part 'coach_goal.g.dart';

const goalKinds = [
  'strength',
  'body_weight',
  'body_fat',
  'habit',
  'nutrition',
  'endurance',
  'steps',
];
const goalPeriods = ['weekly', 'monthly', 'quarterly', 'plan'];
const goalStatuses = ['active', 'achieved', 'missed', 'paused'];
const goalIndicators = [
  'sessions_per_week',
  'weekly_volume_sets',
  'est_1rm',
  'body_weight_avg7',
  'kcal_adherence',
  'protein_avg',
];

String? _decimalToJson(Object? v) => v?.toString();
double? _decimalFromJson(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

@JsonSerializable()
class CoachGoal {
  final int? id;

  @JsonKey(defaultValue: '')
  final String title;

  @JsonKey(defaultValue: 'strength')
  final String kind;

  @JsonKey(defaultValue: 'monthly')
  final String period;

  final String? indicator;

  /// Exercise the goal refers to (strength goals)
  final int? exercise;

  @JsonKey(name: 'target_value', fromJson: _decimalFromJson, toJson: _decimalToJson)
  final double? targetValue;

  @JsonKey(defaultValue: '')
  final String unit;

  @JsonKey(name: 'baseline_value', fromJson: _decimalFromJson, toJson: _decimalToJson)
  final double? baselineValue;

  /// Read-only, computed by the server
  @JsonKey(name: 'current_value', fromJson: _decimalFromJson, includeToJson: false)
  final double? currentValue;

  /// Read-only, computed by the server
  @JsonKey(name: 'progress_pct', includeToJson: false)
  final num? progressPct;

  @JsonKey(name: 'start_date')
  final String? startDate;

  @JsonKey(name: 'end_date')
  final String? endDate;

  @JsonKey(defaultValue: 'active')
  final String status;

  const CoachGoal({
    this.id,
    this.title = '',
    this.kind = 'strength',
    this.period = 'monthly',
    this.indicator,
    this.exercise,
    this.targetValue,
    this.unit = '',
    this.baselineValue,
    this.currentValue,
    this.progressPct,
    this.startDate,
    this.endDate,
    this.status = 'active',
  });

  /// Progress as a 0..1 fraction for progress bars
  double get progressFraction => ((progressPct ?? 0).toDouble() / 100).clamp(0.0, 1.0);

  factory CoachGoal.fromJson(Map<String, dynamic> json) => _$CoachGoalFromJson(json);

  Map<String, dynamic> toJson() => _$CoachGoalToJson(this);
}
