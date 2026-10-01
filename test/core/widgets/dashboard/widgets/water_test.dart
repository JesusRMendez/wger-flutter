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

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/core/app_settings_notifier.dart';
import 'package:wger/core/widgets/dashboard/widgets/water.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  Widget render() {
    return ProviderScope(
      overrides: [appSettingsPrefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DashboardWaterWidget()),
      ),
    );
  }

  testWidgets('adds a glass per tap, 250 ml each, and keeps the count for the day', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime(2026, 10, 1, 9)), () async {
      await tester.pumpWidget(render());
      await tester.pumpAndSettle();
      expect(find.text('0 / 2.5 L'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('water-add')));
      await tester.tap(find.byKey(const ValueKey('water-add')));
      await tester.tap(find.byKey(const ValueKey('water-add')));
      await tester.pumpAndSettle();
      expect(find.text('0.75 / 2.5 L'), findsOneWidget);

      expect(await prefs.getInt('water-2026-10-01'), 3);

      // A new widget tree on the same day starts from what was drunk
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(render());
      await tester.pumpAndSettle();
      expect(find.text('0.75 / 2.5 L'), findsOneWidget);
    });
  });

  testWidgets('a new day starts at zero', (tester) async {
    await prefs.setInt('water-2026-10-01', 6);

    await withClock(Clock.fixed(DateTime(2026, 10, 2, 9)), () async {
      await tester.pumpWidget(render());
      await tester.pumpAndSettle();
    });

    expect(find.text('0 / 2.5 L'), findsOneWidget);
  });

  testWidgets('a long press takes a glass back, never below zero', (tester) async {
    await prefs.setInt('water-2026-10-01', 1);

    await withClock(Clock.fixed(DateTime(2026, 10, 1, 9)), () async {
      await tester.pumpWidget(render());
      await tester.pumpAndSettle();
      expect(find.text('0.25 / 2.5 L'), findsOneWidget);

      await tester.longPress(find.byKey(const ValueKey('water-add')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('water-add')));
      await tester.pumpAndSettle();
    });

    expect(find.text('0 / 2.5 L'), findsOneWidget);
  });
}
