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
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wger/features/account/providers/account_notifier.dart';
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

part 'coach_providers.g.dart';

/// The coach talks to the server on demand, a failing request is shown to the
/// user with a retry button instead of being retried in the background.
Duration? coachNoRetry(int retryCount, Object error) => null;

@Riverpod(retry: coachNoRetry)
Future<CoachAccess?> coachAccess(Ref ref) async {
  String? username;
  try {
    username = (await ref.watch(accountProvider.future))?.username;
  } catch (_) {
    // Not needed for normal users, they only receive their own record
  }
  return ref.read(coachRepositoryProvider).fetchAccess(username: username);
}

@Riverpod(retry: coachNoRetry)
Future<CoachUsage> coachUsage(Ref ref) {
  return ref.read(coachRepositoryProvider).fetchUsage();
}

/// The effective AI mode. Unknown (loading, or the server does not offer the
/// coach) counts as [CoachMode.none].
@Riverpod(retry: coachNoRetry)
Future<CoachMode> coachMode(Ref ref) async {
  final access = await ref.watch(coachAccessProvider.future);
  return access?.effectiveMode ?? CoachMode.none;
}

@Riverpod(retry: coachNoRetry)
Future<List<CoachLocation>> coachLocations(Ref ref) {
  return ref.read(coachRepositoryProvider).fetchLocations();
}

/// The user's own AI provider settings
@Riverpod(retry: coachNoRetry)
class AiProviderSettings extends _$AiProviderSettings {
  @override
  Future<AiProviderConfig> build() => ref.read(coachRepositoryProvider).fetchAiProvider();

  /// Saves provider and model. [apiKey] null keeps the stored key, an empty
  /// string clears it.
  Future<void> save({required String provider, required String model, String? apiKey}) async {
    final saved = await ref
        .read(coachRepositoryProvider)
        .saveAiProvider(provider: provider, model: model, apiKey: apiKey);
    state = AsyncData(saved);
    // The effective mode may have changed
    ref.invalidate(coachAccessProvider);
    ref.invalidate(coachUsageProvider);
  }

  Future<void> clearKey() async {
    final current = state.value;
    await save(provider: current?.provider ?? 'none', model: current?.model ?? '', apiKey: '');
  }
}

/*
 * Chat
 */
class ChatState {
  final List<ChatMessage> messages;
  final bool sending;

  /// The error of the last send, the message stays in [messages]
  final Object? error;

  const ChatState({this.messages = const [], this.sending = false, this.error});

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    Object? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class CoachChat extends _$CoachChat {
  @override
  ChatState build() => const ChatState();

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.sending) {
      return;
    }

    final history = state.messages;
    state = state.copyWith(
      messages: [
        ...history,
        ChatMessage(role: 'user', content: message),
      ],
      sending: true,
      clearError: true,
    );

    try {
      final reply = await ref.read(coachRepositoryProvider).chat(message, history);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: 'assistant', content: reply.reply),
        ],
        sending: false,
      );
      ref.invalidate(coachUsageProvider);
    } catch (e) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(sending: false, error: e);
      // A quota error changes what the usage card shows
      ref.invalidate(coachUsageProvider);
    }
  }

  void clear() => state = const ChatState();
}

/*
 * Plan generators
 */
@riverpod
class WorkoutPlanGenerator extends _$WorkoutPlanGenerator {
  @override
  AsyncValue<WorkoutProposal?> build() => const AsyncData(null);

  Future<void> generate(WorkoutPlanRequest request) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(coachRepositoryProvider).generateWorkoutPlan(request),
    );
    if (ref.mounted) {
      state = result;
      ref.invalidate(coachUsageProvider);
    }
  }

  void reset() => state = const AsyncData(null);
}

@riverpod
class MealPlanGenerator extends _$MealPlanGenerator {
  @override
  AsyncValue<MealProposal?> build() => const AsyncData(null);

  Future<void> generate(MealPlanRequest request) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(coachRepositoryProvider).generateMealPlan(request),
    );
    if (ref.mounted) {
      state = result;
      ref.invalidate(coachUsageProvider);
    }
  }

  void reset() => state = const AsyncData(null);
}

/*
 * Goals, indicators, recommendations
 */
@Riverpod(retry: coachNoRetry)
class CoachGoals extends _$CoachGoals {
  @override
  Future<List<CoachGoal>> build() => ref.read(coachRepositoryProvider).fetchGoals();

  Future<void> addGoal(CoachGoal goal) async {
    await ref.read(coachRepositoryProvider).addGoal(goal);
    ref.invalidateSelf();
    await future;
  }

  Future<void> editGoal(CoachGoal goal) async {
    await ref.read(coachRepositoryProvider).editGoal(goal);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteGoal(int id) async {
    await ref.read(coachRepositoryProvider).deleteGoal(id);
    ref.invalidateSelf();
    await future;
  }
}

@Riverpod(retry: coachNoRetry)
Future<IndicatorsResponse> coachIndicators(Ref ref, int window) {
  return ref.read(coachRepositoryProvider).fetchIndicators(window);
}

@Riverpod(retry: coachNoRetry)
Future<PlanRecommendations> planRecommendations(Ref ref) {
  return ref.read(coachRepositoryProvider).fetchRecommendations();
}

/*
 * Memory
 */
@Riverpod(retry: coachNoRetry)
class CoachMemoryList extends _$CoachMemoryList {
  @override
  Future<List<CoachMemory>> build() => ref.read(coachRepositoryProvider).fetchMemory();

  Future<void> addMemory(CoachMemory memory) async {
    await ref.read(coachRepositoryProvider).addMemory(memory);
    ref.invalidateSelf();
    await future;
  }

  Future<void> editMemory(CoachMemory memory) async {
    await ref.read(coachRepositoryProvider).editMemory(memory);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteMemory(int id) async {
    await ref.read(coachRepositoryProvider).deleteMemory(id);
    ref.invalidateSelf();
    await future;
  }
}
