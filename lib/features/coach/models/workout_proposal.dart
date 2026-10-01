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

part 'workout_proposal.g.dart';

num? _numFromJson(Object? v) => v is num ? v : (v is String ? num.tryParse(v) : null);

/// Request body of `coach/workout-plan/`
class WorkoutPlanRequest {
  final int? goalId;
  final int daysPerWeek;
  final int minutesPerSession;
  final int? locationId;
  final String? notes;

  const WorkoutPlanRequest({
    this.goalId,
    required this.daysPerWeek,
    required this.minutesPerSession,
    this.locationId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    if (goalId != null) 'goal_id': goalId,
    'days_per_week': daysPerWeek,
    'minutes_per_session': minutesPerSession,
    if (locationId != null) 'location_id': locationId,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

@JsonSerializable()
class ProposalExercise {
  @JsonKey(name: 'exercise_id')
  final int? exerciseId;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: 3)
  final int sets;

  @JsonKey(fromJson: _numFromJson)
  final num? reps;

  @JsonKey(name: 'repetition_unit_id')
  final int? repetitionUnitId;

  @JsonKey(name: 'weight_unit_id')
  final int? weightUnitId;

  @JsonKey(fromJson: _numFromJson)
  final num? weight;

  @JsonKey(name: 'rest_seconds')
  final int? restSeconds;

  final String? zone;
  final String? why;

  const ProposalExercise({
    this.exerciseId,
    this.name = '',
    this.sets = 3,
    this.reps,
    this.repetitionUnitId,
    this.weightUnitId,
    this.weight,
    this.restSeconds,
    this.zone,
    this.why,
  });

  factory ProposalExercise.fromJson(Map<String, dynamic> json) => _$ProposalExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$ProposalExerciseToJson(this);
}

@JsonSerializable()
class ProposalDay {
  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: <ProposalExercise>[])
  final List<ProposalExercise> exercises;

  const ProposalDay({this.name = '', this.exercises = const []});

  factory ProposalDay.fromJson(Map<String, dynamic> json) => _$ProposalDayFromJson(json);

  Map<String, dynamic> toJson() => _$ProposalDayToJson(this);
}

/// A workout plan proposed by the coach, not yet applied.
///
/// The raw JSON is kept so it can be sent back unchanged to
/// `coach/workout-plan/apply/` (the server may carry fields we don't model).
class WorkoutProposal {
  final String name;
  final String description;
  final int? weeks;
  final String orderRationale;
  final List<ProposalDay> days;
  final Map<String, dynamic> raw;

  const WorkoutProposal({
    required this.name,
    this.description = '',
    this.weeks,
    this.orderRationale = '',
    this.days = const [],
    this.raw = const {},
  });

  factory WorkoutProposal.fromJson(Map<String, dynamic> json) {
    return WorkoutProposal(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      weeks: (json['weeks'] as num?)?.toInt(),
      orderRationale: json['order_rationale'] as String? ?? '',
      days: ((json['days'] as List?) ?? const [])
          .map((e) => ProposalDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}
