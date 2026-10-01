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
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/core/network/base_provider.dart';
import 'package:wger/features/coach/models/chat_message.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/models/workout_proposal.dart';
import 'package:wger/features/coach/providers/coach_repository.dart';

import '../fake_coach_repository.dart';

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) responder;
  late CoachRepository repo;

  setUp(() {
    requests = [];
    responder = (_) => http.Response('{}', 200);
    final client = MockClient((request) async {
      requests.add(request);
      return responder(request);
    });
    repo = CoachRepository(WgerBaseProvider(serverUrl: 'https://example.org', client: client));
  });

  http.Response json200(Object body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  test('fetchAccess picks the record of the username', () async {
    responder = (_) => json200({
      'count': 2,
      'next': null,
      'results': [
        {'id': 1, 'username': 'other', 'effective_mode': 'none'},
        {'id': 2, 'username': 'me', 'effective_mode': 'server'},
      ],
    });
    final a = await repo.fetchAccess(username: 'me');
    expect(a!.id, 2);
    expect(requests.single.url.path, '/api/v2/ai-coach-access/');
  });

  test('chat posts message and history', () async {
    responder = (_) => json200({
      'reply': 'hi',
      'usage': {'input_tokens': 1, 'output_tokens': 2},
    });
    final reply = await repo.chat('hello', [const ChatMessage(role: 'user', content: 'a')]);
    expect(reply.reply, 'hi');
    final body = jsonDecode(requests.single.body);
    expect(body['message'], 'hello');
    expect(body['history'], [
      {'role': 'user', 'content': 'a'},
    ]);
    expect(requests.single.url.path, '/api/v2/coach/chat/');
  });

  test('workout plan generate and apply', () async {
    responder = (r) =>
        r.url.path.endsWith('apply/') ? json200({'routine_id': 9}) : json200(workoutProposalJson);
    final p = await repo.generateWorkoutPlan(
      const WorkoutPlanRequest(daysPerWeek: 3, minutesPerSession: 60, locationId: 2),
    );
    expect(jsonDecode(requests.last.body)['location_id'], 2);
    final id = await repo.applyWorkoutPlan(p);
    expect(id, 9);
    expect(jsonDecode(requests.last.body)['proposal']['name'], 'Push Pull');
    expect(requests.last.url.path, '/api/v2/coach/workout-plan/apply/');
  });

  test('saveAiProvider only sends the key when given', () async {
    responder = (_) => json200({
      'provider': 'openai',
      'model': 'm',
      'has_api_key': true,
      'api_key_last4': '1234',
    });
    await repo.saveAiProvider(provider: 'openai', model: 'm');
    expect(jsonDecode(requests.last.body).containsKey('api_key'), isFalse);
    await repo.saveAiProvider(provider: 'openai', model: 'm', apiKey: 'sk-1234');
    expect(jsonDecode(requests.last.body)['api_key'], 'sk-1234');
    expect(requests.last.method, 'PATCH');
  });

  test('indicators use the window query', () async {
    responder = (_) => json200({'window': 90, 'indicators': []});
    await repo.fetchIndicators(90);
    expect(requests.single.url.queryParameters['window'], '90');
  });

  test('403 ai_not_available surfaces as WgerHttpException', () async {
    responder = (_) => http.Response('{"detail":"no","code":"ai_not_available"}', 403);
    expect(
      repo.chat('x', const []),
      throwsA(isA<WgerHttpException>().having((e) => e.statusCode, 'status', 403)),
    );
  });

  test('goal CRUD hits the right urls', () async {
    responder = (r) => r.method == 'DELETE'
        ? http.Response('', 204)
        : json200({'id': 3, 'title': 'x', 'period': 'weekly'});
    await repo.addGoal(const CoachGoal(id: 3, title: 'x', period: 'weekly'));
    await repo.editGoal(const CoachGoal(id: 3, title: 'x', period: 'weekly'));
    await repo.deleteGoal(3);
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'POST /api/v2/coach-goal/',
      'PATCH /api/v2/coach-goal/3/',
      'DELETE /api/v2/coach-goal/3/',
    ]);
  });
}
