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

part 'recommendations.g.dart';

@JsonSerializable(createToJson: false)
class PlanPhase {
  @JsonKey(defaultValue: '')
  final String key;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(name: 'week_from')
  final int? weekFrom;

  @JsonKey(name: 'week_to')
  final int? weekTo;

  const PlanPhase({required this.key, this.name = '', this.weekFrom, this.weekTo});

  factory PlanPhase.fromJson(Map<String, dynamic> json) => _$PlanPhaseFromJson(json);
}

@JsonSerializable(createToJson: false)
class Recommendation {
  @JsonKey(defaultValue: '')
  final String key;

  /// `info`, `warning` or `success`
  @JsonKey(defaultValue: 'info')
  final String severity;

  @JsonKey(defaultValue: '')
  final String title;

  @JsonKey(defaultValue: '')
  final String detail;

  /// e.g. `open_routine`
  final String? action;

  const Recommendation({
    required this.key,
    this.severity = 'info',
    this.title = '',
    this.detail = '',
    this.action,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);
}

/// Response of `coach-recommendations/`
@JsonSerializable(createToJson: false)
class PlanRecommendations {
  final int? routine;
  final int? week;
  final PlanPhase? phase;

  @JsonKey(defaultValue: <Recommendation>[])
  final List<Recommendation> recommendations;

  const PlanRecommendations({
    this.routine,
    this.week,
    this.phase,
    this.recommendations = const [],
  });

  factory PlanRecommendations.fromJson(Map<String, dynamic> json) =>
      _$PlanRecommendationsFromJson(json);
}

/// The deterministic phases of a plan, used for the timeline.
const planPhaseOrder = ['adaptation', 'progression', 'deload', 'consolidation'];
