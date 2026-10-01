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
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/models/coach_location.dart';
import 'package:wger/features/coach/screens/workout_plan_screen.dart';
import 'package:wger/features/routines/models/repetition_unit.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/models/weight_unit.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/routine_screen.dart';

import '../../../helpers/fake_auth_environment.dart';
import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

class _FakeRoutines extends RoutinesRiverpod {
  static int builds = 0;
  static final fetched = <int>[];

  @override
  Stream<RoutinesState> build() {
    builds++;
    return Stream.value(RoutinesState(routines: [Routine(id: 7, name: 'Push Pull')]));
  }

  @override
  Future<Routine> fetchAndSetRoutineFull(int routineId) async {
    fetched.add(routineId);
    return Routine(id: routineId, name: 'Push Pull');
  }
}

void main() {
  installFakeAuthEnvironment();
  routineSyncTimeout = Duration.zero;

  final overrides = [
    routineRepetitionUnitProvider.overrideWith(
      (ref) => Stream.value([const RepetitionUnit(id: 1, name: 'Repetitions')]),
    ),
    routineWeightUnitProvider.overrideWith(
      (ref) => Stream.value([const WeightUnit(id: 1, name: 'kg')]),
    ),
    routinesRiverpodProvider.overrideWith(_FakeRoutines.new),
  ];

  setUp(() {
    _FakeRoutines.builds = 0;
    _FakeRoutines.fetched.clear();
  });

  testWidgets('sends the days chosen as chips and the minutes of the slider', (tester) async {
    final repo = FakeCoachRepository();
    await pumpCoach(tester, const WorkoutPlanScreen(), repo, overrides: overrides);

    expect(find.text('60 min'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wp-days-5')));
    await tester.pumpAndSettle();
    // Left of the slider's end is the shortest session
    await tester.drag(find.byKey(const ValueKey('wp-minutes')), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    expect(find.text('20 min'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wp-generate')));
    await tester.pumpAndSettle();

    expect(repo.lastWorkoutRequest!.daysPerWeek, 5);
    expect(repo.lastWorkoutRequest!.minutesPerSession, 20);
  });

  testWidgets('generates a proposal and shows days, volume, rest, zone and rationale', (
    tester,
  ) async {
    final repo = FakeCoachRepository()
      ..locations = const [
        CoachLocation(id: 3, name: 'Gym centro', isDefault: true, availableMinutes: 45),
      ]
      ..goals = [const CoachGoal(id: 5, title: 'Bench 100 kg')];
    await pumpCoach(tester, const WorkoutPlanScreen(), repo, overrides: overrides);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wp-notes')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const ValueKey('wp-notes')), 'bad knee');
    await tester.tap(find.text('Gym centro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wp-generate')));
    await tester.pumpAndSettle();

    expect(repo.lastWorkoutRequest!.locationId, 3);
    expect(repo.lastWorkoutRequest!.minutesPerSession, 45);
    expect(repo.lastWorkoutRequest!.notes, 'bad knee');

    expect(find.text('Push Pull'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('4 × 8 Repetitions'), findsOneWidget);
    expect(find.text('Rest 180 s'), findsOneWidget);
    expect(find.text('Zone: Rack'), findsOneWidget);
    expect(find.text('Main chest lift'), findsOneWidget);
    expect(find.text('Heavy compounds first while you are fresh'), findsOneWidget);
  });

  testWidgets('apply refreshes the routines and opens the routine', (tester) async {
    final repo = FakeCoachRepository();
    final pushed = await pumpCoach(tester, const WorkoutPlanScreen(), repo, overrides: overrides);

    await tester.tap(find.byKey(const ValueKey('wp-generate')));
    await tester.pumpAndSettle();
    final buildsBefore = _FakeRoutines.builds;

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wp-apply')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('wp-apply')));
    await tester.pumpAndSettle();

    expect(repo.calls, ['apply-workout']);
    expect(_FakeRoutines.builds, greaterThan(buildsBefore));
    expect(_FakeRoutines.fetched, [7]);
    expect(pushed, [RoutineScreen.routeName]);
  });

  testWidgets('quota error is shown instead of a proposal', (tester) async {
    final repo = FakeCoachRepository()
      ..aiError = WgerHttpException(http.Response('{"code":"ai_quota_exceeded"}', 429));
    await pumpCoach(tester, const WorkoutPlanScreen(), repo, overrides: overrides);

    await tester.tap(find.byKey(const ValueKey('wp-generate')));
    await tester.pumpAndSettle();

    expect(find.textContaining('monthly AI token limit'), findsOneWidget);
    expect(find.byKey(const ValueKey('wp-apply')), findsNothing);
  });

  testWidgets('403 shows the not available message', (tester) async {
    final repo = FakeCoachRepository()
      ..aiError = WgerHttpException(http.Response('{"code":"ai_not_available"}', 403));
    await pumpCoach(tester, const WorkoutPlanScreen(), repo, overrides: overrides);

    await tester.tap(find.byKey(const ValueKey('wp-generate')));
    await tester.pumpAndSettle();

    expect(find.textContaining('AI is not available'), findsOneWidget);
  });
}
