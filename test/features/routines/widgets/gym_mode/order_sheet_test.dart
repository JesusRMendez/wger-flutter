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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/order_sheet.dart';
import 'package:wger/features/routines/widgets/gym_mode/settings_sheet.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/routines.dart';

void main() {
  late GymStateNotifier notifier;
  late ProviderContainer container;
  late PageController controller;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    container = ProviderContainer.test();
    controller = PageController();
    notifier = container.read(gymStateProvider.notifier);
    notifier.state = notifier.state.copyWith(
      showExercisePages: false,
      showTimerPages: true,
      dayId: 1,
      iteration: 1,
      routine: getTestRoutine(),
    );
    notifier.calculatePages();
  });

  tearDown(() => controller.dispose());

  Future<void> open(WidgetTester tester, Future<void> Function(BuildContext) show) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                PageView(
                  controller: controller,
                  children: [for (var i = 0; i < 12; i++) Text('page $i')],
                ),
                Builder(
                  builder: (context) =>
                      TextButton(onPressed: () => show(context), child: const Text('open')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  List<String> order() => notifier.state.pages
      .where((p) => p.type == PageType.set)
      .map((p) => p.exercises.single.getTranslation('en').name)
      .toList();

  group('Session order sheet', () {
    testWidgets('lists the exercises in order and marks the current one', (tester) async {
      await open(tester, (c) => showSessionOrderSheet(c, controller));

      expect(find.text('Session order'), findsOneWidget);
      final names = order();
      for (final name in names) {
        expect(find.text(name), findsOneWidget);
      }
      // The page the workout is on is the first exercise
      expect(find.text('Now'), findsNothing, reason: 'the start page is current, not a set');
      expect(find.text('Go now'), findsNWidgets(names.length));
      expect(find.textContaining(' sets'), findsWidgets);
    });

    testWidgets('moves an exercise that is not started', (tester) async {
      await open(tester, (c) => showSessionOrderSheet(c, controller));
      final before = order();

      final first = notifier.state.pages.firstWhere((p) => p.type == PageType.set);
      await tester.tap(find.byKey(ValueKey('order-down-${first.uuid}')));
      await tester.pumpAndSettle();

      expect(order(), [before[1], before[0], ...before.skip(2)]);
    });

    testWidgets('Go now jumps to the exercise and closes the sheet', (tester) async {
      await open(tester, (c) => showSessionOrderSheet(c, controller));

      final second = notifier.state.pages.where((p) => p.type == PageType.set).elementAt(1);
      await tester.tap(find.byKey(ValueKey('order-go-${second.uuid}')));
      await tester.pumpAndSettle();

      expect(find.text('Session order'), findsNothing);
      expect(controller.page, second.pageIndex);
      // The exercise before it is not done: the user is told
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('End workout goes to the end', (tester) async {
      await open(tester, (c) => showSessionOrderSheet(c, controller));

      await tester.ensureVisible(find.byKey(const ValueKey('order-sheet-end')));
      await tester.tap(find.byKey(const ValueKey('order-sheet-end')));
      await tester.pumpAndSettle();

      expect(controller.page, 11);
    });
  });

  group('Gym settings sheet', () {
    testWidgets('toggles the alerts of the rest timer', (tester) async {
      await open(tester, (c) => showGymSettingsSheet(c));

      expect(notifier.state.alertAt20s, isTrue);
      await tester.tap(find.byKey(const ValueKey('gym-sheet-alert-at-20s')));
      await tester.pumpAndSettle();
      expect(container.read(gymStateProvider).alertAt20s, isFalse);

      await tester.tap(find.byKey(const ValueKey('gym-sheet-show-duration')));
      await tester.pumpAndSettle();
      expect(container.read(gymStateProvider).showWorkoutDuration, isFalse);

      await tester.tap(find.byKey(const ValueKey('gym-sheet-done')));
      await tester.pumpAndSettle();
      expect(find.text('Sound, alerts and countdown'), findsNothing);
    });

    testWidgets('the alerts are disabled while the timer pages are off', (tester) async {
      notifier.setShowTimerPages(false);
      await open(tester, (c) => showGymSettingsSheet(c));

      final tile = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('gym-sheet-alert-at-20s')),
      );
      expect(tile.onChanged, isNull);
    });
  });
}
