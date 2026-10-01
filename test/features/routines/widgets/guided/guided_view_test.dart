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
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/routines/logic/guided_engine.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/repetition_unit.dart';
import 'package:wger/features/routines/widgets/guided/guided_view.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/exercises.dart';
import '../../../../../test_data/routines.dart';
import '../gym_mode/timer_harness.dart';

const maxReps = RepetitionUnit(id: 5, name: 'Max Reps');

void main() {
  final exercises = getTestExercises();

  List<GuidedStep> steps() => buildGuidedSteps(
    DayData(
      iteration: 1,
      date: DateTime(2024),
      day: null,
      slots: [
        // timed: 5 s work, 3 s rest
        getTestSlot(
          exercises[0],
          sets: 2,
          repetitions: 5,
          repetitionsUnit: testRepUnitSeconds,
          weight: null,
          restTime: 3,
        ),
        // reps: Done button
        getTestSlot(exercises[1], sets: 1, repetitions: 8, weight: 20, restTime: 3),
        // max reps: asks
        getTestSlot(
          exercises[3],
          sets: 1,
          repetitions: null,
          repetitionsUnit: maxReps,
          weight: null,
          restTime: 3,
        ),
      ],
    ),
  );

  Widget render() => ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: GuidedRoutineView(steps())),
    ),
  );

  Future<void> seconds(WidgetTester tester, int n) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  String phase(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('guided-phase'))).data!;

  testWidgets('runs through countdown, timed work, rest and reps with alerts', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final calls = PlatformCalls.install(tester);

    await tester.pumpWidget(render());

    // 3-2-1
    expect(phase(tester), 'Get ready');
    expect(find.text('0:03'), findsOneWidget);
    expect(find.text(exercises[0].getTranslation('en').name), findsOneWidget);
    expect(find.text('Set 1 of 2'), findsOneWidget);
    await seconds(tester, 3);
    expect(calls.clickSounds, 2);
    expect(calls.alertSounds, 1);

    // Timed work: 5 seconds, last seconds are ticked
    expect(phase(tester), 'Work');
    expect(find.text('0:05'), findsOneWidget);
    expect(find.byKey(const ValueKey('guided-done-button')), findsOneWidget);
    await seconds(tester, 5);

    // Rest: the next exercise is introduced
    expect(phase(tester), 'Rest');
    expect(find.byKey(const ValueKey('guided-next-intro')), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);
    expect(find.text('Set 2 of 2'), findsWidgets);
    await seconds(tester, 3);
    expect(phase(tester), 'Work');
    await seconds(tester, 5);

    // Rest before the exercise with reps: that one is introduced
    expect(phase(tester), 'Rest');
    expect(find.text(exercises[1].getTranslation('en').name), findsOneWidget);
    expect(find.text('8 × 20 kg'), findsOneWidget);
    await seconds(tester, 3);

    // Reps: the user ends the set
    expect(phase(tester), 'Work');
    expect(find.text('0:05'), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(phase(tester), 'Work');
    await tester.tap(find.byKey(const ValueKey('guided-done-button')));
    await tester.pump();
    expect(phase(tester), 'Rest');
    await seconds(tester, 3);

    // Max reps: ask for the count
    expect(phase(tester), 'Work');
    await tester.tap(find.byKey(const ValueKey('guided-done-button')));
    await tester.pump();
    expect(phase(tester), 'How many reps did you do?');
    await tester.enterText(find.byKey(const ValueKey('guided-reps-field')), '17');
    await tester.tap(find.byKey(const ValueKey('guided-reps-confirm')));
    await tester.pump();

    // Last set: no rest, finished
    expect(find.byKey(const ValueKey('guided-finished')), findsOneWidget);
    expect(find.text('17 Reps'), findsOneWidget);
    expect(find.textContaining('4 sets completed'), findsOneWidget);
  });

  testWidgets('pause stops the clock and skip moves on', (tester) async {
    PlatformCalls.install(tester);
    await tester.pumpWidget(render());

    await tester.tap(find.byKey(const ValueKey('guided-pause-button')));
    await tester.pump();
    await seconds(tester, 5);
    expect(find.text('0:03'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guided-pause-button')));
    await tester.tap(find.byKey(const ValueKey('guided-skip-button')));
    await tester.pump();
    expect(phase(tester), 'Work');
  });

  testWidgets('jumping ahead warns, the user can confirm', (tester) async {
    PlatformCalls.install(tester);
    await tester.pumpWidget(render());

    await tester.tap(find.byKey(const ValueKey('guided-overview-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guided-overview')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guided-step-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guided-jump-warning')), findsOneWidget);
    expect(find.textContaining('skipping exercises'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guided-jump-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('8 × 20 kg'), findsOneWidget);
    expect(phase(tester), 'Get ready');
  });

  testWidgets('exercises that are not started can be reordered', (tester) async {
    PlatformCalls.install(tester);
    await tester.pumpWidget(render());

    await tester.tap(find.byKey(const ValueKey('guided-overview-button')));
    await tester.pumpAndSettle();

    // Slot 1 moves above slot 0
    await tester.tap(find.byKey(const ValueKey('guided-move-up-1')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('guided-step-0')),
        matching: find.text('8 × 20 kg'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the help button opens the glossary', (tester) async {
    PlatformCalls.install(tester);
    await tester.pumpWidget(render());
    await tester.tap(find.byKey(const ValueKey('glossary-help-button')));
    await tester.pumpAndSettle();
    expect(find.text('Glossary'), findsOneWidget);
  });
}
