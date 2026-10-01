/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/network/base_provider.dart';
import 'package:wger/core/network/wger_base.dart';
import 'package:wger/features/coach/models/ai_provider_config.dart';
import 'package:wger/features/coach/models/chat_message.dart';
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/models/coach_location.dart';
import 'package:wger/features/coach/models/coach_memory.dart';
import 'package:wger/features/coach/models/indicators.dart';
import 'package:wger/features/coach/models/meal_proposal.dart';
import 'package:wger/features/coach/models/recommendations.dart';
import 'package:wger/features/coach/models/workout_proposal.dart';

part 'coach_repository.g.dart';

const _accessPath = 'ai-coach-access';
const _providerPath = 'ai-provider';
const _usagePath = 'coach/usage';
const _chatPath = 'coach/chat';
const _workoutPlanPath = 'coach/workout-plan';
const _workoutPlanApplyPath = 'coach/workout-plan/apply';
const _mealPlanPath = 'coach/meal-plan';
const _mealPlanApplyPath = 'coach/meal-plan/apply';
const _goalPath = 'coach-goal';
const _indicatorsPath = 'coach-indicators';
const _recommendationsPath = 'coach-recommendations';
const _memoryPath = 'coach-memory';
const _locationPath = 'training-location';

@riverpod
CoachRepository coachRepository(Ref ref) {
  return CoachRepository(ref.read(wgerBaseProvider));
}

/// REST data access for the AI coach. Errors surface as `WgerHttpException`,
/// see `coachErrorKind` for the 403 / 429 cases.
class CoachRepository {
  final _logger = Logger('CoachRepository');

  final WgerBaseProvider base;

  CoachRepository(this.base);

  /// The user's own access record. Managers receive the records of all users,
  /// so the one of [username] is picked when given.
  Future<CoachAccess?> fetchAccess({String? username}) async {
    final url = base.makeUrl(_accessPath, query: {'limit': API_MAX_PAGE_SIZE});
    final data = await base.fetchPaginated(url);
    final all = data.map((e) => CoachAccess.fromJson(e as Map<String, dynamic>)).toList();
    if (all.isEmpty) {
      return null;
    }
    return all.firstWhere((a) => a.username == username, orElse: () => all.first);
  }

  Future<CoachAccess> setMemoryEnabled(int accessId, bool enabled) async {
    final data = await base.patch(
      {'memory_enabled': enabled},
      base.makeUrl(_accessPath, id: accessId),
    );
    return CoachAccess.fromJson(data);
  }

  Future<CoachUsage> fetchUsage() async {
    final data = await base.fetch(base.makeUrl(_usagePath));
    return CoachUsage.fromJson(data as Map<String, dynamic>);
  }

  /*
   * Own AI provider
   */
  Future<AiProviderConfig> fetchAiProvider() async {
    final data = await base.fetch(base.makeUrl(_providerPath));
    return AiProviderConfig.fromJson(data as Map<String, dynamic>);
  }

  /// Saves the provider. [apiKey] is only sent when not null: an empty string
  /// clears the stored key, null leaves it untouched.
  Future<AiProviderConfig> saveAiProvider({
    required String provider,
    required String model,
    String? apiKey,
  }) async {
    final data = await base.patch(
      {'provider': provider, 'model': model, 'api_key': ?apiKey},
      base.makeUrl(_providerPath),
    );
    return AiProviderConfig.fromJson(data);
  }

  /*
   * Chat and plans
   */
  Future<ChatReply> chat(String message, List<ChatMessage> history) async {
    final data = await base.post(
      {'message': message, 'history': history.map((e) => e.toJson()).toList()},
      base.makeUrl(_chatPath),
    );
    return ChatReply.fromJson(data);
  }

  Future<WorkoutProposal> generateWorkoutPlan(WorkoutPlanRequest request) async {
    final data = await base.post(request.toJson(), base.makeUrl(_workoutPlanPath));
    return WorkoutProposal.fromJson(data);
  }

  /// Applies the proposal and returns the id of the created routine.
  Future<int> applyWorkoutPlan(WorkoutProposal proposal) async {
    _logger.fine('Applying workout plan ${proposal.name}');
    final data = await base.post({
      'proposal': proposal.toJson(),
    }, base.makeUrl(_workoutPlanApplyPath));
    return (data['routine_id'] as num).toInt();
  }

  Future<MealProposal> generateMealPlan(MealPlanRequest request) async {
    final data = await base.post(request.toJson(), base.makeUrl(_mealPlanPath));
    return MealProposal.fromJson(data);
  }

  Future<MealPlanApplyResult> applyMealPlan(MealProposal proposal) async {
    _logger.fine('Applying meal plan ${proposal.name}');
    final data = await base.post({'proposal': proposal.toJson()}, base.makeUrl(_mealPlanApplyPath));
    return MealPlanApplyResult.fromJson(data);
  }

  /*
   * Locations (read only, for the generator)
   */
  Future<List<CoachLocation>> fetchLocations() async {
    final url = base.makeUrl(_locationPath, query: {'limit': API_MAX_PAGE_SIZE});
    final data = await base.fetchPaginated(url);
    return data.map((e) => CoachLocation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /*
   * Goals
   */
  Future<List<CoachGoal>> fetchGoals() async {
    final url = base.makeUrl(_goalPath, query: {'limit': API_MAX_PAGE_SIZE});
    final data = await base.fetchPaginated(url);
    return data.map((e) => CoachGoal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CoachGoal> addGoal(CoachGoal goal) async {
    final data = await base.post(goal.toJson(), base.makeUrl(_goalPath));
    return CoachGoal.fromJson(data);
  }

  Future<CoachGoal> editGoal(CoachGoal goal) async {
    final data = await base.patch(goal.toJson(), base.makeUrl(_goalPath, id: goal.id));
    return CoachGoal.fromJson(data);
  }

  Future<void> deleteGoal(int id) async {
    await base.deleteRequest(_goalPath, id);
  }

  /*
   * Indicators and recommendations
   */
  Future<IndicatorsResponse> fetchIndicators(int window) async {
    final data = await base.fetch(base.makeUrl(_indicatorsPath, query: {'window': '$window'}));
    return IndicatorsResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<PlanRecommendations> fetchRecommendations({int? routineId}) async {
    final query = routineId == null ? null : {'routine': '$routineId'};
    final data = await base.fetch(base.makeUrl(_recommendationsPath, query: query));
    return PlanRecommendations.fromJson(data as Map<String, dynamic>);
  }

  /*
   * Memory
   */
  Future<List<CoachMemory>> fetchMemory() async {
    final url = base.makeUrl(_memoryPath, query: {'limit': API_MAX_PAGE_SIZE});
    final data = await base.fetchPaginated(url);
    return data.map((e) => CoachMemory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CoachMemory> addMemory(CoachMemory memory) async {
    final data = await base.post(memory.toJson(), base.makeUrl(_memoryPath));
    return CoachMemory.fromJson(data);
  }

  Future<CoachMemory> editMemory(CoachMemory memory) async {
    final data = await base.patch(memory.toJson(), base.makeUrl(_memoryPath, id: memory.id));
    return CoachMemory.fromJson(data);
  }

  Future<void> deleteMemory(int id) async {
    await base.deleteRequest(_memoryPath, id);
  }
}
