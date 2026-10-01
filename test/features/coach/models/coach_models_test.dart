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
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/features/coach/models/ai_provider_config.dart';
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/models/coach_memory.dart';
import 'package:wger/features/coach/models/indicators.dart';
import 'package:wger/features/coach/models/meal_proposal.dart';
import 'package:wger/features/coach/models/recommendations.dart';
import 'package:wger/features/coach/models/workout_proposal.dart';
import 'package:wger/features/coach/providers/coach_errors.dart';

import '../fake_coach_repository.dart';

void main() {
  test('CoachAccess parses the effective mode', () {
    final a = CoachAccess.fromJson({
      'id': 1,
      'username': 'u',
      'server_ai_enabled': true,
      'monthly_token_limit': null,
      'memory_enabled': true,
      'effective_mode': 'byo',
    });
    expect(a.effectiveMode, CoachMode.byo);
    expect(a.memoryEnabled, isTrue);
    expect(CoachMode.fromString('???'), CoachMode.none);
  });

  test('CoachUsage computes fraction of the limit', () {
    final u = CoachUsage.fromJson({
      'month': '2026-10',
      'input_tokens': 300,
      'output_tokens': 200,
      'limit': 1000,
      'mode': 'server',
    });
    expect(u.totalTokens, 500);
    expect(u.usedFraction, 0.5);
    expect(const CoachUsage().usedFraction, isNull);
  });

  test('AiProviderConfig masks the key', () {
    final c = AiProviderConfig.fromJson({
      'provider': 'openai',
      'model': 'gpt-4o',
      'has_api_key': true,
      'api_key_last4': 'abcd',
    });
    expect(c.maskedKey, '••••abcd');
    expect(const AiProviderConfig().maskedKey, '');
  });

  test('WorkoutProposal keeps the raw json and parses days', () {
    final p = WorkoutProposal.fromJson(workoutProposalJson);
    expect(p.days.single.exercises.single.sets, 4);
    expect(p.days.single.exercises.single.restSeconds, 180);
    expect(p.toJson(), workoutProposalJson);
  });

  test('WorkoutPlanRequest omits empty optional fields', () {
    final json = const WorkoutPlanRequest(
      daysPerWeek: 3,
      minutesPerSession: 45,
      notes: '  ',
    ).toJson();
    expect(json, {'days_per_week': 3, 'minutes_per_session': 45});
  });

  test('MealProposal finds unlinked items, apply result accepts shapes', () {
    final p = MealProposal.fromJson(mealProposalJson);
    expect(p.totals.kcal, 2260);
    expect(p.unlinkedItems.map((e) => e.name), ['Mystery bar']);

    final r = MealPlanApplyResult.fromJson({
      'nutrition_plan_id': 'x',
      'skipped': [
        {'name': 'A'},
        'B',
      ],
    });
    expect(r.skipped, ['A', 'B']);
  });

  test('CoachGoal parses decimals and omits read-only fields', () {
    final g = CoachGoal.fromJson({
      'id': 1,
      'title': 'Bench 100 kg',
      'kind': 'strength',
      'period': 'monthly',
      'indicator': 'est_1rm',
      'exercise': 192,
      'target_value': '100.00',
      'unit': 'kg',
      'baseline_value': '92.50',
      'current_value': '95.00',
      'progress_pct': 30,
      'start_date': '2026-10-01',
      'end_date': '2026-10-31',
      'status': 'active',
    });
    expect(g.targetValue, 100);
    expect(g.currentValue, 95);
    expect(g.progressFraction, 0.3);
    final out = g.toJson();
    expect(out.containsKey('current_value'), isFalse);
    expect(out.containsKey('progress_pct'), isFalse);
    expect(out['target_value'], '100.0');
  });

  test('Indicators, recommendations and memory parse', () {
    final i = IndicatorsResponse.fromJson({
      'window': 7,
      'indicators': [
        {'key': 'est_1rm', 'label': 'x', 'value': 105.0, 'unit': 'kg', 'exercise_id': 192},
      ],
      'data_quality': {
        'score': 56,
        'missing': [
          {'key': 'rir', 'title': 't', 'detail': 'd', 'action': 'log_rir'},
        ],
      },
    });
    expect(i.indicators.single.exerciseId, 192);
    expect(i.dataQuality!.missing.single.action, 'log_rir');

    final r = PlanRecommendations.fromJson({
      'routine': 7,
      'week': 6,
      'phase': {'key': 'progression', 'name': 'Progression', 'week_from': 5, 'week_to': 8},
      'recommendations': [
        {'key': 'k', 'severity': 'warning', 'title': 't', 'detail': 'd', 'action': null},
      ],
    });
    expect(r.phase!.weekTo, 8);
    expect(r.recommendations.single.severity, 'warning');

    final m = CoachMemory.fromJson({'id': 1, 'text': 'x', 'category': 'injury', 'source': 'ai'});
    expect(m.toJson(), {'id': 1, 'text': 'x', 'category': 'injury'});
  });

  test('coachErrorKind maps the API codes', () {
    WgerHttpException ex(int status, String body) => WgerHttpException(http.Response(body, status));
    expect(
      coachErrorKind(ex(403, '{"detail":"x","code":"ai_not_available"}')),
      CoachErrorKind.notAvailable,
    );
    expect(
      coachErrorKind(ex(429, '{"code":"ai_quota_exceeded"}')),
      CoachErrorKind.quotaExceeded,
    );
    expect(coachErrorKind(ex(500, '{}')), CoachErrorKind.other);
    expect(coachErrorKind(StateError('x')), CoachErrorKind.other);
  });
}
