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
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/progress_screen.dart';
import 'package:wger/core/widgets/quick_add_sheet.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

class _EmptyRoutines extends RoutinesRiverpod {
  @override
  Stream<RoutinesState> build() => Stream.value(const RoutinesState(routines: []));
}

void main() {
  Widget host(Widget home, {bool online = true}) {
    return ProviderScope(
      overrides: [
        networkStatusProvider.overrideWithValue(online),
        routinesRiverpodProvider.overrideWith(_EmptyRoutines.new),
        bodyWeightCategoryOnlyProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  group('quick add sheet', () {
    testWidgets('lists what can be logged and routes the tab tiles', (tester) async {
      final tabs = <int>[];
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showQuickAddSheet(context, onSelectTab: tabs.add),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Log'), findsOneWidget);
      for (final key in ['workout', 'meal', 'coach', 'weight', 'measurement', 'photo']) {
        expect(find.byKey(ValueKey('quick-add-$key')), findsOneWidget, reason: key);
      }
      // No session scheduled today: the workout tile opens the routines tab
      expect(find.text('Open your routines'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quick-add-meal')));
      await tester.pumpAndSettle();

      expect(tabs, [2]);
      expect(find.text('Log'), findsNothing);
    });

    testWidgets('the photo tile is disabled offline', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showQuickAddSheet(context, onSelectTab: (_) {}),
              child: const Text('open'),
            ),
          ),
          online: false,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('quick-add-photo')), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Still open: the tile did nothing
      expect(find.text('Log'), findsOneWidget);
    });
  });

  testWidgets('the progress tab links the screens it gathers', (tester) async {
    await tester.pumpWidget(host(const ProgressScreen()));
    // The weight card spins until its data arrives, so no pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Progress'), findsOneWidget);
    for (final key in ['weight', 'measurements', 'gallery', 'trophies', 'goals']) {
      expect(
        find.byKey(ValueKey('progress-$key'), skipOffstage: false),
        findsOneWidget,
        reason: key,
      );
    }
  });
}
