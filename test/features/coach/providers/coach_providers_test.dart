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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/models/workout_proposal.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/providers/coach_repository.dart';

import '../fake_coach_repository.dart';

void main() {
  late FakeCoachRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeCoachRepository();
    container = ProviderContainer(
      overrides: [coachRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('coachMode follows the effective mode of the access record', () async {
    expect(await container.read(coachModeProvider.future), CoachMode.server);
  });

  test('chat appends the reply and sends the history', () async {
    final chat = container.read(coachChatProvider.notifier);
    await chat.send('hi');
    await chat.send('again');

    final state = container.read(coachChatProvider);
    expect(state.messages.map((m) => m.content), ['hi', 'Echo: hi', 'again', 'Echo: again']);
    expect(repo.calls, ['chat:hi:0', 'chat:again:2']);
    expect(state.sending, isFalse);
    expect(state.error, isNull);
  });

  test('chat keeps the message and stores the error on 429', () async {
    repo.aiError = WgerHttpException(http.Response('{"code":"ai_quota_exceeded"}', 429));
    await container.read(coachChatProvider.notifier).send('hi');

    final state = container.read(coachChatProvider);
    expect(state.messages, hasLength(1));
    expect(state.error, isA<WgerHttpException>());
    expect(state.sending, isFalse);
  });

  test('workout generator exposes the proposal or the error', () async {
    final notifier = container.read(workoutPlanGeneratorProvider.notifier);
    await notifier.generate(const WorkoutPlanRequest(daysPerWeek: 3, minutesPerSession: 45));
    expect(container.read(workoutPlanGeneratorProvider).value!.name, 'Push Pull');
    expect(repo.lastWorkoutRequest!.daysPerWeek, 3);

    repo.aiError = WgerHttpException(http.Response('{"code":"ai_not_available"}', 403));
    await notifier.generate(const WorkoutPlanRequest(daysPerWeek: 3, minutesPerSession: 45));
    expect(container.read(workoutPlanGeneratorProvider).hasError, isTrue);
  });

  test('goals notifier adds, edits and deletes', () async {
    await container.read(coachGoalsProvider.future);
    final notifier = container.read(coachGoalsProvider.notifier);

    await notifier.addGoal(const CoachGoal(title: 'A', period: 'weekly'));
    expect(container.read(coachGoalsProvider).value!.single.title, 'A');
    final id = container.read(coachGoalsProvider).value!.single.id!;

    await notifier.editGoal(CoachGoal(id: id, title: 'B', period: 'weekly'));
    expect(container.read(coachGoalsProvider).value!.single.title, 'B');

    await notifier.deleteGoal(id);
    expect(container.read(coachGoalsProvider).value, isEmpty);
  });

  test('saving the AI provider updates the state; clearKey sends empty key', () async {
    await container.read(aiProviderSettingsProvider.future);
    final notifier = container.read(aiProviderSettingsProvider.notifier);

    await notifier.save(provider: 'anthropic', model: 'claude-sonnet-5-5', apiKey: 'sk-abcd');
    var cfg = container.read(aiProviderSettingsProvider).value!;
    expect(cfg.maskedKey, '••••abcd');

    await notifier.clearKey();
    cfg = container.read(aiProviderSettingsProvider).value!;
    expect(repo.lastSavedProvider!['api_key'], '');
    expect(cfg.hasApiKey, isFalse);
    expect(cfg.provider, 'anthropic');
  });

  test('indicators are fetched per window', () async {
    await container.read(coachIndicatorsProvider(7).future);
    await container.read(coachIndicatorsProvider(90).future);
    expect(repo.indicatorWindowsRequested, [7, 90]);
  });
}
