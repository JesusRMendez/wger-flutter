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
import 'package:wger/core/network/base_provider.dart';
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
import 'package:wger/features/coach/providers/coach_repository.dart';

const workoutProposalJson = {
  'name': 'Push Pull',
  'description': 'Two day split',
  'weeks': 8,
  'order_rationale': 'Heavy compounds first while you are fresh',
  'days': [
    {
      'name': 'Push',
      'exercises': [
        {
          'exercise_id': 192,
          'name': 'Bench press',
          'sets': 4,
          'reps': 8,
          'repetition_unit_id': 1,
          'weight_unit_id': 1,
          'weight': null,
          'rest_seconds': 180,
          'zone': 'Rack',
          'why': 'Main chest lift',
        },
      ],
    },
  ],
};

const mealProposalJson = {
  'name': 'Cut plan',
  'kcal_target': 2250,
  'meals': [
    {
      'name': 'Breakfast',
      'time': '08:00',
      'items': [
        {'ingredient_id': 123, 'name': 'Oats', 'amount_g': 80},
        {'ingredient_id': null, 'name': 'Mystery bar', 'amount_g': 40},
      ],
    },
  ],
  'totals': {'kcal': 2260, 'protein': 160, 'carbs': 250, 'fat': 70},
};

/// In-memory stand-in for the coach REST repository
class FakeCoachRepository extends CoachRepository {
  FakeCoachRepository() : super(WgerBaseProvider(serverUrl: 'https://example.org'));

  CoachAccess access = const CoachAccess(
    id: 1,
    username: 'tester',
    effectiveMode: CoachMode.server,
    memoryEnabled: true,
  );
  CoachUsage usage = const CoachUsage(
    month: '2026-10',
    inputTokens: 1000,
    outputTokens: 500,
    limit: 10000,
    mode: CoachMode.server,
  );
  AiProviderConfig provider = const AiProviderConfig();
  List<CoachLocation> locations = const [];
  List<CoachGoal> goals = [];
  List<CoachMemory> memories = [];
  IndicatorsResponse indicators = const IndicatorsResponse();
  PlanRecommendations recommendations = const PlanRecommendations();

  /// Thrown by the AI calls when set
  Object? aiError;

  final List<String> calls = [];
  final List<int> indicatorWindowsRequested = [];
  int applyWorkoutId = 7;
  MealPlanApplyResult mealApplyResult = const MealPlanApplyResult(nutritionPlanId: 'abc');
  Map<String, dynamic>? lastSavedProvider;
  WorkoutPlanRequest? lastWorkoutRequest;

  @override
  Future<CoachAccess?> fetchAccess({String? username}) async => access;

  @override
  Future<CoachAccess> setMemoryEnabled(int accessId, bool enabled) async {
    calls.add('memory:$enabled');
    access = CoachAccess(
      id: access.id,
      username: access.username,
      effectiveMode: access.effectiveMode,
      memoryEnabled: enabled,
    );
    return access;
  }

  @override
  Future<CoachUsage> fetchUsage() async => usage;

  @override
  Future<AiProviderConfig> fetchAiProvider() async => provider;

  @override
  Future<AiProviderConfig> saveAiProvider({
    required String provider,
    required String model,
    String? apiKey,
  }) async {
    lastSavedProvider = {'provider': provider, 'model': model, 'api_key': apiKey};
    final hasKey = apiKey == null ? this.provider.hasApiKey : apiKey.isNotEmpty;
    this.provider = AiProviderConfig(
      provider: provider,
      model: model,
      hasApiKey: hasKey,
      apiKeyLast4: !hasKey
          ? ''
          : (apiKey == null ? this.provider.apiKeyLast4 : apiKey.substring(apiKey.length - 4)),
    );
    return this.provider;
  }

  @override
  Future<ChatReply> chat(String message, List<ChatMessage> history) async {
    calls.add('chat:$message:${history.length}');
    if (aiError != null) {
      throw aiError!;
    }
    return ChatReply(reply: 'Echo: $message');
  }

  @override
  Future<WorkoutProposal> generateWorkoutPlan(WorkoutPlanRequest request) async {
    lastWorkoutRequest = request;
    if (aiError != null) {
      throw aiError!;
    }
    return WorkoutProposal.fromJson(workoutProposalJson);
  }

  @override
  Future<int> applyWorkoutPlan(WorkoutProposal proposal) async {
    calls.add('apply-workout');
    return applyWorkoutId;
  }

  @override
  Future<MealProposal> generateMealPlan(MealPlanRequest request) async {
    if (aiError != null) {
      throw aiError!;
    }
    return MealProposal.fromJson(mealProposalJson);
  }

  @override
  Future<MealPlanApplyResult> applyMealPlan(MealProposal proposal) async {
    calls.add('apply-meal');
    return mealApplyResult;
  }

  @override
  Future<List<CoachLocation>> fetchLocations() async => locations;

  @override
  Future<List<CoachGoal>> fetchGoals() async => List.of(goals);

  @override
  Future<CoachGoal> addGoal(CoachGoal goal) async {
    calls.add('add-goal:${goal.title}');
    goals.add(CoachGoal.fromJson({...goal.toJson(), 'id': goals.length + 100}));
    return goals.last;
  }

  @override
  Future<CoachGoal> editGoal(CoachGoal goal) async {
    calls.add('edit-goal:${goal.id}');
    goals = goals.map((g) => g.id == goal.id ? goal : g).toList();
    return goal;
  }

  @override
  Future<void> deleteGoal(int id) async {
    calls.add('delete-goal:$id');
    goals = goals.where((g) => g.id != id).toList();
  }

  @override
  Future<IndicatorsResponse> fetchIndicators(int window) async {
    indicatorWindowsRequested.add(window);
    return indicators;
  }

  @override
  Future<PlanRecommendations> fetchRecommendations({int? routineId}) async => recommendations;

  @override
  Future<List<CoachMemory>> fetchMemory() async => List.of(memories);

  @override
  Future<CoachMemory> addMemory(CoachMemory memory) async {
    calls.add('add-memory:${memory.text}');
    memories.add(CoachMemory(id: 50, text: memory.text, category: memory.category));
    return memories.last;
  }

  @override
  Future<CoachMemory> editMemory(CoachMemory memory) async => memory;

  @override
  Future<void> deleteMemory(int id) async {
    calls.add('delete-memory:$id');
    memories = memories.where((m) => m.id != id).toList();
  }
}
