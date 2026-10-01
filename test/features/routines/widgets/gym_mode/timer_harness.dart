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

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/timer.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

/// Records the sounds and haptic feedback requested through the platform channel
class PlatformCalls {
  final List<String> sounds = [];
  final List<String> haptics = [];

  int get alertSounds => sounds.where((s) => s == 'SystemSoundType.alert').length;
  int get clickSounds => sounds.where((s) => s == 'SystemSoundType.click').length;
  int hapticCount(String type) => haptics.where((h) => h == 'HapticFeedbackType.$type').length;

  void clear() {
    sounds.clear();
    haptics.clear();
  }

  /// Starts recording, stopped again when the test ends
  static PlatformCalls install(WidgetTester tester) {
    final calls = PlatformCalls();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'SystemSound.play') {
        calls.sounds.add(call.arguments as String);
      } else if (call.method == 'HapticFeedback.vibrate') {
        calls.haptics.add(call.arguments as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return calls;
  }
}

/// Shows a PageView like the gym mode does, but with placeholders instead of
/// everything that is not a countdown timer. Each page has the key
/// `page-<index>` or is a [TimerCountdownWidget].
class TimerHarness {
  final ProviderContainer container = ProviderContainer.test();
  final PageController controller;

  TimerHarness(Routine routine, {int initialPage = 2, bool showExercisePages = false})
    : controller = PageController(initialPage: initialPage) {
    final notifier = container.read(gymStateProvider.notifier);
    notifier.state = notifier.state.copyWith(
      showExercisePages: showExercisePages,
      showTimerPages: true,
      useCountdownBetweenSets: true,
      dayId: 1,
      iteration: 1,
      routine: routine,
      currentPage: initialPage,
    );
    notifier.calculatePages();
  }

  GymStateNotifier get notifier => container.read(gymStateProvider.notifier);

  GymModeState get state => container.read(gymStateProvider);

  Widget build() {
    final children = <Widget>[];
    for (var i = 0; i < state.totalPages; i++) {
      final slot = state.getSlotEntryPageByIndex(i);
      if (slot != null && slot.type == SlotPageType.timer) {
        children.add(
          TimerCountdownWidget(
            controller,
            (slot.setConfigData!.restTime ?? state.countdownDuration.inSeconds).toInt(),
            slotUuid: slot.uuid,
            key: ValueKey('timer-${slot.uuid}'),
          ),
        );
      } else {
        children.add(Center(key: ValueKey('page-$i'), child: Text('page-$i')));
      }
    }

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PageView(
            controller: controller,
            onPageChanged: (page) => notifier.setCurrentPage(page),
            children: children,
          ),
        ),
      ),
    );
  }

  void dispose() {
    controller.dispose();
    container.dispose();
  }
}
