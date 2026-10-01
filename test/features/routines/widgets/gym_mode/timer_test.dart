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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/widgets/gym_mode/timer.dart';

import '../../../../../test_data/exercises.dart';
import '../../../../../test_data/routines.dart';
import 'timer_harness.dart';

/// Bench press (rest 30 s) and side raises (rest 45 s), two sets each.
///
/// Pages: 0 start, 1 log, 2 timer, 3 log, 4 timer, 5 log, 6 timer, 7 log,
/// 8 timer, 9 session, 10 summary
Routine testRoutine() {
  final exercises = getTestExercises();
  return getTestRoutineWithSlots([
    getTestSlot(exercises[0], restTime: 30),
    getTestSlot(exercises[5], restTime: 45),
  ]);
}

void main() {
  late TimerHarness harness;
  late PlatformCalls calls;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    harness.dispose();
  });

  Future<void> pumpTimerPage(WidgetTester tester, {int initialPage = 2}) async {
    harness = TimerHarness(testRoutine(), initialPage: initialPage);
    calls = PlatformCalls.install(tester);
    await tester.pumpWidget(harness.build());
  }

  /// Lets the given number of seconds pass, one second at a time
  Future<void> elapse(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  group('Rest countdown alerts', () {
    testWidgets('shows and counts down the rest time of the set', (tester) async {
      await pumpTimerPage(tester);

      expect(find.byType(TimerCountdownWidget), findsOneWidget);
      expect(find.text('0:30'), findsOneWidget);

      await elapse(tester, 10);
      expect(find.text('0:20'), findsOneWidget);
    });

    testWidgets('warns with a double haptic and a sound at 20 seconds', (tester) async {
      await pumpTimerPage(tester);

      await elapse(tester, 9);
      expect(find.text('0:21'), findsOneWidget);
      expect(calls.sounds, isEmpty);
      expect(calls.haptics, isEmpty);

      await elapse(tester, 1);
      expect(find.text('0:20'), findsOneWidget);
      expect(calls.alertSounds, 1);
      expect(calls.hapticCount('mediumImpact'), 1);

      // The second pulse comes right after the first
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls.hapticCount('mediumImpact'), 2);
      expect(calls.alertSounds, 1);

      // ... and only once
      await elapse(tester, 5);
      expect(calls.alertSounds, 1);
      expect(calls.hapticCount('mediumImpact'), 2);
    });

    testWidgets('ticks on each of the last 5 seconds, then plays the end alert', (tester) async {
      await pumpTimerPage(tester);

      // 30 s rest: the remaining 6 seconds are reached after 24 seconds
      await elapse(tester, 24);
      calls.clear();

      for (var remaining = 5; remaining >= 1; remaining--) {
        await elapse(tester, 1);
        expect(find.text('0:0$remaining'), findsOneWidget);
        expect(calls.clickSounds, 6 - remaining, reason: 'tick at $remaining');
        expect(calls.hapticCount('lightImpact'), 6 - remaining);
      }
      expect(calls.alertSounds, 0, reason: 'not before the end');

      await elapse(tester, 1);
      expect(find.text('0:00'), findsOneWidget);
      expect(calls.clickSounds, 5);
      expect(calls.alertSounds, 1);
      expect(calls.hapticCount('mediumImpact'), 1);

      // Nothing happens after the end
      await elapse(tester, 10);
      expect(calls.clickSounds, 5);
      expect(calls.alertSounds, 1);
    });

    testWidgets('plays the whole sequence in order', (tester) async {
      await pumpTimerPage(tester);
      harness.notifier.setAutoAdvanceAfterRest(false);

      await elapse(tester, 31);

      expect(
        calls.sounds,
        [
          'SystemSoundType.alert', // 20 s
          'SystemSoundType.click', // 5, 4, 3, 2, 1
          'SystemSoundType.click',
          'SystemSoundType.click',
          'SystemSoundType.click',
          'SystemSoundType.click',
          'SystemSoundType.alert', // end
        ],
      );
    });

    testWidgets('the 20 second warning can be switched off', (tester) async {
      await pumpTimerPage(tester);
      harness.notifier.setAlertAt20s(false);

      await elapse(tester, 12);

      expect(find.text('0:18'), findsOneWidget);
      expect(calls.sounds, isEmpty);
      expect(calls.haptics, isEmpty);
    });

    testWidgets('the ticks can be switched off', (tester) async {
      await pumpTimerPage(tester);
      harness.notifier.setAlertLast5s(false);
      harness.notifier.setAutoAdvanceAfterRest(false);

      await elapse(tester, 31);

      expect(calls.clickSounds, 0);
      expect(calls.hapticCount('lightImpact'), 0);
      expect(calls.alertSounds, 2, reason: 'the warning and the end are still played');
    });

    testWidgets('the end alert can be switched off', (tester) async {
      await pumpTimerPage(tester);
      harness.notifier.setAlertOnCountdownEnd(false);
      harness.notifier.setAutoAdvanceAfterRest(false);

      await elapse(tester, 31);

      expect(calls.alertSounds, 1, reason: 'only the warning');
      expect(calls.clickSounds, 5);
    });

    testWidgets('a rest of 20 seconds or less gets no warning', (tester) async {
      final exercises = getTestExercises();
      harness = TimerHarness(
        getTestRoutineWithSlots([getTestSlot(exercises[0], restTime: 15)]),
      );
      calls = PlatformCalls.install(tester);
      await tester.pumpWidget(harness.build());
      harness.notifier.setAutoAdvanceAfterRest(false);

      await elapse(tester, 16);

      expect(calls.alertSounds, 1, reason: 'only the end');
      expect(calls.clickSounds, 5);
    });

    testWidgets('nothing is played after the page is gone', (tester) async {
      await pumpTimerPage(tester);
      await elapse(tester, 5);

      await tester.pumpWidget(const SizedBox());
      await elapse(tester, 40);

      expect(calls.sounds, isEmpty);
      expect(calls.haptics, isEmpty);
    });
  });

  group('Auto-advance after rest', () {
    testWidgets('goes to the next page when the countdown ends', (tester) async {
      await pumpTimerPage(tester);
      expect(find.byType(TimerCountdownWidget), findsOneWidget);

      await elapse(tester, 30);
      await tester.pumpAndSettle();

      expect(find.byType(TimerCountdownWidget), findsNothing);
      expect(find.text('page-3'), findsOneWidget);
      expect(harness.state.currentPage, 3);
      expect(calls.alertSounds, 2, reason: 'the end alert is played before moving on');
    });

    testWidgets('does not go anywhere before the end', (tester) async {
      await pumpTimerPage(tester);

      await elapse(tester, 29);
      await tester.pumpAndSettle();

      expect(find.byType(TimerCountdownWidget), findsOneWidget);
      expect(harness.state.currentPage, 2);
    });

    testWidgets('stays on the page if switched off', (tester) async {
      await pumpTimerPage(tester);
      harness.notifier.setAutoAdvanceAfterRest(false);

      await elapse(tester, 35);
      await tester.pumpAndSettle();

      expect(find.byType(TimerCountdownWidget), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      expect(harness.state.currentPage, 2);
    });

    testWidgets('advances only once', (tester) async {
      await pumpTimerPage(tester);

      await elapse(tester, 30);
      await tester.pumpAndSettle();
      await elapse(tester, 60);
      await tester.pumpAndSettle();

      expect(harness.state.currentPage, 3);
    });

    testWidgets('does not advance if the user navigated away in the meantime', (tester) async {
      await pumpTimerPage(tester);
      await elapse(tester, 10);

      // The user swipes on to the next page on their own, the timer page is
      // disposed and its timers are cancelled
      harness.controller.jumpToPage(3);
      await tester.pumpAndSettle();
      expect(find.byType(TimerCountdownWidget), findsNothing);
      expect(harness.state.currentPage, 3);
      calls.clear();

      await elapse(tester, 60);
      await tester.pumpAndSettle();

      expect(harness.state.currentPage, 3, reason: 'no second advance');
      expect(find.text('page-3'), findsOneWidget);
      expect(calls.sounds, isEmpty, reason: 'no alerts for a timer that is gone');
    });

    testWidgets('does not advance if the shown page is not the current one', (tester) async {
      await pumpTimerPage(tester);
      // e.g. the page structure changed: the state says the user is elsewhere
      harness.notifier.state = harness.state.copyWith(currentPage: 5);

      await elapse(tester, 31);
      await tester.pumpAndSettle();

      expect(find.byType(TimerCountdownWidget), findsOneWidget);
      expect(harness.controller.page, 2);
    });

    testWidgets('does not advance while a dialog is open', (tester) async {
      await pumpTimerPage(tester);
      await elapse(tester, 10);

      showDialog<void>(
        context: tester.element(find.byType(TimerCountdownWidget)),
        builder: (_) => const AlertDialog(content: Text('dialog')),
      );
      await tester.pumpAndSettle();

      await elapse(tester, 25);
      await tester.pumpAndSettle();

      expect(find.text('dialog'), findsOneWidget);
      expect(harness.controller.page, 2);
      expect(harness.state.currentPage, 2);
    });

    testWidgets('does not interrupt a swipe that is in progress', (tester) async {
      await pumpTimerPage(tester);
      await elapse(tester, 25);

      // Start dragging back to the previous page and keep the finger down
      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();

      await elapse(tester, 6);
      expect(harness.controller.page, lessThan(2), reason: 'still being dragged');

      // The drag was too short to change the page and nothing moved it on
      await gesture.up();
      await tester.pumpAndSettle();
      expect(harness.state.currentPage, 2);
      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('a rest of zero seconds ends right away', (tester) async {
      final exercises = getTestExercises();
      harness = TimerHarness(
        getTestRoutineWithSlots([getTestSlot(exercises[0], restTime: 0)]),
      );
      calls = PlatformCalls.install(tester);
      await tester.pumpWidget(harness.build());

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(harness.state.currentPage, 3);
    });
  });

  group('Rest after reordering the exercises', () {
    testWidgets('the countdown is still the rest of the set that was just done', (tester) async {
      await pumpTimerPage(tester, initialPage: 2);
      expect(find.text('0:30'), findsOneWidget, reason: 'bench press: 30 s');

      // Side raises (rest 45 s) are moved in front of the bench press
      harness.notifier.moveSlot(harness.state.pages[2].uuid, 1);
      harness.controller.jumpToPage(2);
      await tester.pumpWidget(harness.build());

      // Page 2 is now the rest after the first set of the side raises
      expect(find.text('0:45'), findsOneWidget);

      // ... and after the second set of the bench press it is 30 s again
      harness.controller.jumpToPage(8);
      await tester.pumpWidget(harness.build());
      expect(find.text('0:30'), findsOneWidget);
    });
  });
}
