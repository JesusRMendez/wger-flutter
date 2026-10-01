// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_proposal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProposalExercise _$ProposalExerciseFromJson(Map<String, dynamic> json) => ProposalExercise(
  exerciseId: (json['exercise_id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  sets: (json['sets'] as num?)?.toInt() ?? 3,
  reps: _numFromJson(json['reps']),
  repetitionUnitId: (json['repetition_unit_id'] as num?)?.toInt(),
  weightUnitId: (json['weight_unit_id'] as num?)?.toInt(),
  weight: _numFromJson(json['weight']),
  restSeconds: (json['rest_seconds'] as num?)?.toInt(),
  zone: json['zone'] as String?,
  why: json['why'] as String?,
);

Map<String, dynamic> _$ProposalExerciseToJson(ProposalExercise instance) => <String, dynamic>{
  'exercise_id': instance.exerciseId,
  'name': instance.name,
  'sets': instance.sets,
  'reps': instance.reps,
  'repetition_unit_id': instance.repetitionUnitId,
  'weight_unit_id': instance.weightUnitId,
  'weight': instance.weight,
  'rest_seconds': instance.restSeconds,
  'zone': instance.zone,
  'why': instance.why,
};

ProposalDay _$ProposalDayFromJson(Map<String, dynamic> json) => ProposalDay(
  name: json['name'] as String? ?? '',
  exercises:
      (json['exercises'] as List<dynamic>?)
          ?.map((e) => ProposalExercise.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$ProposalDayToJson(ProposalDay instance) => <String, dynamic>{
  'name': instance.name,
  'exercises': instance.exercises,
};
