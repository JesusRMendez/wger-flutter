/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2020 - 2026 wger Team
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

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/workout_menu.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/routines.dart';

void main() {
  late GymStateNotifier notifier;
  late ProviderContainer container;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();

    container = ProviderContainer.test();
    notifier = container.read(gymStateProvider.notifier);
    notifier.state = notifier.state.copyWith(
      showExercisePages: false,
      showTimerPages: false,
      dayId: 1,
      iteration: 1,
      routine: getTestRoutine(),
    );
    notifier.calculatePages();
  });

  Widget renderWidget({locale = 'en'}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProgressionTab(PageController()),
        ),
      ),
    );
  }

  testWidgets(
    'Smoke and golden test',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0; // Ensure correct pixel ratio
      addTearDown(tester.view.reset);

      await tester.pumpWidget(renderWidget());

      if (Platform.isLinux) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/gym_mode_progression_tab.png'),
        );
      }
    },
    tags: ['golden'],
  );

  testWidgets('Opens the exercise swap widget', (WidgetTester tester) async {
    await tester.pumpWidget(renderWidget());

    expect(find.byType(ExerciseSwapWidget), findsNothing);

    await tester.tap(find.byKey(Key('swap-icon-${notifier.state.pages[1].uuid}')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseSwapWidget), findsOne);
  });

  testWidgets('Opens the add exercise widget', (WidgetTester tester) async {
    await tester.pumpWidget(renderWidget());

    expect(find.byType(ExerciseAddWidget), findsNothing);

    await tester.tap(find.byKey(Key('add-icon-${notifier.state.pages[1].uuid}')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseAddWidget), findsOne);
  });

  group('Reordering the exercises', () {
    /// Names of the exercises in the order of the workout
    List<String> order() => notifier.state.pages
        .where((p) => p.type == PageType.set)
        .map((p) => p.exercises.single.getTranslation('en').name)
        .toList();

    testWidgets('the not yet done exercises have buttons to move them', (tester) async {
      await tester.pumpWidget(renderWidget());

      final first = notifier.state.pages[1].uuid;
      final second = notifier.state.pages[2].uuid;

      // The first one can only go down, the last one only up
      expect(tester.widget<IconButton>(find.byKey(Key('move-up-$first'))).onPressed, isNull);
      expect(tester.widget<IconButton>(find.byKey(Key('move-down-$first'))).onPressed, isNotNull);
      expect(tester.widget<IconButton>(find.byKey(Key('move-up-$second'))).onPressed, isNotNull);
      expect(tester.widget<IconButton>(find.byKey(Key('move-down-$second'))).onPressed, isNull);
    });

    testWidgets('moves an exercise and warns that the order may matter', (tester) async {
      await tester.pumpWidget(renderWidget());
      expect(order(), ['Bench press', 'Side raises']);
      expect(find.byKey(const Key('order-changed-warning')), findsNothing);

      await tester.tap(find.byKey(Key('move-down-${notifier.state.pages[1].uuid}')));
      await tester.pumpAndSettle();

      expect(order(), ['Side raises', 'Bench press']);
      expect(find.byKey(const Key('order-changed-warning')), findsOneWidget);
      expect(find.textContaining('planned order may matter'), findsOneWidget);

      // The list shows the new order
      final raisesY = tester.getTopLeft(find.text('Side raises')).dy;
      final benchY = tester.getTopLeft(find.text('Bench press')).dy;
      expect(raisesY, lessThan(benchY));

      await tester.tap(find.byKey(Key('move-up-${notifier.state.pages[2].uuid}')));
      await tester.pumpAndSettle();
      expect(order(), ['Bench press', 'Side raises']);
    });

    testWidgets('finished exercises have no buttons and stay in place', (tester) async {
      final done = notifier.state.pages[1];
      for (final slot in done.slotPages.where((s) => s.type == SlotPageType.log)) {
        notifier.markSlotPageAsDone(slot.uuid, isDone: true);
      }
      await tester.pumpWidget(renderWidget());

      expect(find.byKey(Key('move-up-${done.uuid}')), findsNothing);
      expect(find.byKey(Key('move-down-${done.uuid}')), findsNothing);

      // The last exercise cannot be moved above the finished one
      final last = notifier.state.pages[2].uuid;
      expect(find.byKey(Key('move-up-$last')), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(Key('move-up-$last'))).onPressed, isNull);
      expect(order().first, 'Bench press');
    });

    testWidgets('the page view stays on the page the user is looking at', (tester) async {
      // Looking at the second set of the bench press (pages 1-3 bench, 4-6 raises)
      final controller = PageController(initialPage: 2);
      addTearDown(controller.dispose);
      notifier.state = notifier.state.copyWith(currentPage: 2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: PageView(
                      controller: controller,
                      children: [for (var i = 0; i < 9; i++) Text('page $i')],
                    ),
                  ),
                  Expanded(child: ProgressionTab(controller)),
                ],
              ),
            ),
          ),
        ),
      );
      final benchSlot = notifier.state.getSlotEntryPageByIndex(2)!;

      await tester.tap(find.byKey(Key('move-down-${notifier.state.pages[1].uuid}')));
      await tester.pumpAndSettle();

      final newIndex = notifier.state.getSlotPageByUUID(benchSlot.uuid)!.pageIndex;
      expect(newIndex, 5);
      expect(notifier.state.currentPage, newIndex);
      expect(controller.page, newIndex);
    });
  });

  group('Jumping to an exercise', () {
    final controller = PageController();

    Future<void> openMenu(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => WorkoutMenuDialog(controller),
                      ),
                      child: const Text('open menu'),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: PageView(
                      controller: controller,
                      children: [for (var i = 0; i < 9; i++) Text('page $i')],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open menu'));
      await tester.pumpAndSettle();
    }

    testWidgets('warns when it skips exercises that are not done', (tester) async {
      await openMenu(tester);

      await tester.tap(find.text('Side raises'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutMenuDialog), findsNothing, reason: 'the menu closes');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('skipping ahead'), findsOneWidget);
      expect(controller.page, notifier.state.pages[2].pageIndex);
    });

    testWidgets('does not warn when going to the next exercise in order', (tester) async {
      await openMenu(tester);

      await tester.tap(find.text('Bench press'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('does not warn after the earlier exercises are done', (tester) async {
      for (final slot in notifier.state.pages[1].slotPages) {
        notifier.markSlotPageAsDone(slot.uuid, isDone: true);
      }
      await openMenu(tester);

      await tester.tap(find.text('Side raises'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
