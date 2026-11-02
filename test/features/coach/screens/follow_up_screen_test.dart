/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
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
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/coach/models/indicators.dart';
import 'package:wger/features/coach/models/recommendations.dart';
import 'package:wger/features/coach/screens/data_quality_screen.dart';
import 'package:wger/features/coach/screens/follow_up_screen.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';

import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

FakeCoachRepository _repo({bool warning = false, int? week = 6}) {
  return FakeCoachRepository()
    ..indicators = IndicatorsResponse.fromJson({
      'window': 7,
      'indicators': [
        {
          'key': 'sessions_per_week',
          'label': 'Sessions / week',
          'value': 3,
          'trend': 'up',
          'target': 4,
        },
        {'key': 'est_1rm', 'label': 'e1RM', 'value': 105.0, 'unit': 'kg', 'trend': 'down'},
      ],
      'data_quality': {
        'score': 30,
        'missing': [
          {'key': 'a', 'title': 'Weigh in', 'detail': 'Log more', 'action': 'log_weight'},
        ],
      },
    })
    ..recommendations = PlanRecommendations.fromJson({
      'routine': 7,
      'week': week,
      'phase': {'key': 'progression', 'name': 'Progression', 'week_from': 5, 'week_to': 8},
      'recommendations': [
        {
          'key': 'deload_soon',
          'severity': warning ? 'warning' : 'info',
          'title': 'Deload soon',
          'detail': 'Week 9 is a deload',
          'action': 'open_routine',
        },
      ],
    });
}

void main() {
  testWidgets('shows the week, indicators with trends, recommendations and data quality', (
    tester,
  ) async {
    final repo = _repo();
    await pumpCoach(tester, const FollowUpScreen(), repo);

    expect(find.text('Weekly follow-up'), findsOneWidget);
    expect(find.text('WEEK 6 · PROGRESSION'), findsOneWidget);
    // 3 of 4 sessions is below 80 % of the target: needs attention
    expect(find.text('A few things need attention'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);

    expect(find.text('Deload soon'), findsOneWidget);
    expect(find.text('1 pending'), findsOneWidget);
    expect(find.text('Open routine'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Estimated 1RM'), 200);
    expect(find.byIcon(Icons.trending_up, skipOffstage: false), findsOneWidget);
    expect(find.byIcon(Icons.trending_down, skipOffstage: false), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Weigh in'), 200);
    expect(find.text('30 / 100'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
  });

  testWidgets('the window selector reloads the indicators', (tester) async {
    final repo = _repo();
    await pumpCoach(tester, const FollowUpScreen(), repo);

    await tester.tap(find.text('28 days'));
    await tester.pumpAndSettle();
    expect(repo.indicatorWindowsRequested, containsAllInOrder([7, 28]));
  });

  testWidgets('says the plan is on track without warnings and links to goals and data', (
    tester,
  ) async {
    final repo = _repo();
    repo.indicators = IndicatorsResponse.fromJson({
      'window': 7,
      'indicators': [
        {'key': 'sessions_per_week', 'label': 'x', 'value': 4, 'target': 4},
      ],
      'data_quality': {'score': 90, 'missing': []},
    });
    final pushed = await pumpCoach(tester, const FollowUpScreen(), repo);
    expect(find.text('You are on plan'), findsOneWidget);

    await tester.tap(find.byTooltip('Goals & indicators'));
    await tester.pumpAndSettle();
    expect(pushed.last, GoalsScreen.routeName);
  });

  testWidgets('without a plan it explains how to get started', (tester) async {
    final repo = FakeCoachRepository()
      ..recommendations = PlanRecommendations.fromJson({'routine': null, 'recommendations': []});
    await pumpCoach(tester, const FollowUpScreen(), repo);
    expect(find.textContaining('No plan data yet'), findsOneWidget);
  });

  testWidgets('the data quality screen lists what is missing', (tester) async {
    await pumpCoach(tester, const DataQualityScreen(), _repo());
    expect(find.text('Data for your coach'), findsOneWidget);
    expect(find.text('Weigh in'), findsOneWidget);
    expect(find.text('Log weight'), findsOneWidget);
    expect(find.text('To do'), findsOneWidget);
  });
}
