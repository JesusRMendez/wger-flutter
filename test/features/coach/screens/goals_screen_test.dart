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
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/models/indicators.dart';
import 'package:wger/features/coach/models/recommendations.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';

import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

FakeCoachRepository _repo() {
  return FakeCoachRepository()
    ..goals = [
      CoachGoal.fromJson({
        'id': 1,
        'title': 'Bench 100 kg',
        'kind': 'strength',
        'period': 'monthly',
        'target_value': '100.00',
        'unit': 'kg',
        'current_value': '95.00',
        'progress_pct': 30,
        'status': 'active',
      }),
      const CoachGoal(id: 2, title: 'Walk daily', kind: 'steps', period: 'weekly'),
    ]
    ..indicators = IndicatorsResponse.fromJson({
      'window': 28,
      'indicators': [
        {
          'key': 'sessions_per_week',
          'label': 'Sessions / week',
          'value': 3.5,
          'trend': 'up',
          'target': 4,
        },
        {'key': 'est_1rm', 'label': 'e1RM', 'value': 105.0, 'unit': 'kg', 'trend': 'down'},
      ],
      'data_quality': {
        'score': 56,
        'missing': [
          {
            'key': 'weight_logs',
            'title': 'Weigh in 3×/week',
            'detail': 'Log more',
            'action': 'log_weight',
          },
        ],
      },
    })
    ..recommendations = PlanRecommendations.fromJson({
      'routine': 7,
      'week': 6,
      'phase': {'key': 'progression', 'name': 'Progression', 'week_from': 5, 'week_to': 8},
      'recommendations': [
        {
          'key': 'deload_soon',
          'severity': 'info',
          'title': 'Deload soon',
          'detail': 'Week 9 is a deload',
        },
      ],
    });
}

void main() {
  testWidgets('shows goals of the selected period with progress', (tester) async {
    await pumpCoach(tester, const GoalsScreen(), _repo());

    // Default tab is weekly
    expect(find.text('Walk daily'), findsOneWidget);
    expect(find.text('Bench 100 kg'), findsNothing);

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('Bench 100 kg'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('Now 95 of 100 kg'), findsOneWidget);
    expect(find.text('Walk daily'), findsNothing);

    await tester.tap(find.text('Quarterly'));
    await tester.pumpAndSettle();
    expect(find.text('No goals for this period yet.'), findsOneWidget);
  });

  testWidgets('indicators with trends, window selector and data quality', (tester) async {
    final repo = _repo();
    await pumpCoach(tester, const GoalsScreen(), repo);

    await tester.scrollUntilVisible(find.text('Sessions per week'), 200);
    expect(find.text('3.5'), findsOneWidget);
    expect(find.text('Target: 4'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(find.byIcon(Icons.trending_down), findsOneWidget);
    expect(find.text('105 kg'), findsOneWidget);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(repo.indicatorWindowsRequested, containsAllInOrder([28, 7]));

    await tester.scrollUntilVisible(find.text('56 / 100'), 200);
    expect(find.text('Weigh in 3×/week'), findsOneWidget);
    expect(find.text('Log weight'), findsOneWidget);
  });

  testWidgets('plan phase timeline and recommendations', (tester) async {
    await pumpCoach(tester, const GoalsScreen(), _repo());

    await tester.scrollUntilVisible(find.byKey(const ValueKey('phase-timeline')), 300);
    expect(find.text('Week 6'), findsOneWidget);
    for (final p in ['Adaptation', 'Progression', 'Deload', 'Consolidation']) {
      expect(find.text(p), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Deload soon'), 200);
    expect(find.text('Week 9 is a deload'), findsOneWidget);
  });

  testWidgets('adds, edits and deletes a goal', (tester) async {
    final repo = _repo();
    await pumpCoach(tester, const GoalsScreen(), repo);

    // Add (the dialog defaults to the selected weekly period)
    await tester.tap(find.byKey(const ValueKey('goal-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal-save')));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty, reason: 'validation blocks an empty form');

    await tester.enterText(find.byKey(const ValueKey('goal-title')), 'Run 5k');
    await tester.enterText(find.byKey(const ValueKey('goal-target')), '5');
    await tester.tap(find.byKey(const ValueKey('goal-save')));
    await tester.pumpAndSettle();
    expect(repo.calls, ['add-goal:Run 5k']);
    expect(find.text('Run 5k'), findsOneWidget);

    // Delete
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-button')));
    await tester.pumpAndSettle();
    expect(repo.calls.last, startsWith('delete-goal:'));
  });

  testWidgets('edit sends the changed goal', (tester) async {
    final repo = _repo();
    await pumpCoach(tester, const GoalsScreen(), repo);

    await tester.tap(find.byTooltip('Edit').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('goal-title')), 'Walk more');
    await tester.enterText(find.byKey(const ValueKey('goal-target')), '70000');
    await tester.tap(find.byKey(const ValueKey('goal-save')));
    await tester.pumpAndSettle();

    expect(repo.calls, ['edit-goal:2']);
    expect(find.text('Walk more'), findsOneWidget);
  });

  group('goal health', () {
    CoachGoal goal(Map<String, dynamic> json) => CoachGoal.fromJson({'title': 't', ...json});

    test('achieved, missed and paused follow the status', () {
      expect(goalHealth(goal({'status': 'achieved'})), GoalHealth.achieved);
      expect(goalHealth(goal({'status': 'missed'})), GoalHealth.missed);
      expect(goalHealth(goal({'status': 'paused'})), GoalHealth.paused);
    });

    test('without dates an active goal is on track from 40 %', () {
      expect(goalHealth(goal({'status': 'active', 'progress_pct': 40})), GoalHealth.onTrack);
      expect(goalHealth(goal({'status': 'active', 'progress_pct': 10})), GoalHealth.watch);
    });

    test('with dates it is compared with the share of the period that has passed', () {
      final now = DateTime.now();
      String d(DateTime t) => t.toIso8601String().substring(0, 10);
      final dates = {
        'start_date': d(now.subtract(const Duration(days: 10))),
        'end_date': d(now.add(const Duration(days: 10))),
      };
      // Half of the period is over: 50 % is on track, 20 % is behind
      expect(
        goalHealth(goal({'status': 'active', 'progress_pct': 50, ...dates})),
        GoalHealth.onTrack,
      );
      expect(
        goalHealth(goal({'status': 'active', 'progress_pct': 20, ...dates})),
        GoalHealth.watch,
      );
    });
  });

  testWidgets('shows the goal of the plan as the final goal and the status chips', (
    tester,
  ) async {
    final repo = _repo()
      ..goals = [
        CoachGoal.fromJson({
          'id': 9,
          'title': 'Lose 4 kg without losing strength',
          'kind': 'body_weight',
          'period': 'plan',
          'target_value': '74.40',
          'unit': 'kg',
          'current_value': '77.00',
          'progress_pct': 33,
          'status': 'active',
        }),
        CoachGoal.fromJson({
          'id': 1,
          'title': 'Bench 100 kg',
          'kind': 'strength',
          'period': 'weekly',
          'progress_pct': 80,
          'status': 'active',
        }),
      ];
    await pumpCoach(tester, const GoalsScreen(), repo);

    // The hero repeats nothing from the weekly tab, the plan goal is only there
    expect(find.text('FINAL GOAL'), findsOneWidget);
    expect(find.text('Lose 4 kg without losing strength'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    // Now also in the list of the tab
    expect(find.text('Lose 4 kg without losing strength'), findsNWidgets(2));
  });
}
