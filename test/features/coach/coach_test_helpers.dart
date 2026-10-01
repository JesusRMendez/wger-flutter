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
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/providers/coach_repository.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import 'fake_coach_repository.dart';

/// Pumps [child] as a route with the fake repository, extra [overrides] and a
/// navigator observer that records pushed route names.
Future<List<String>> pumpCoach(
  WidgetTester tester,
  Widget child,
  FakeCoachRepository repo, {
  List<Override> overrides = const [],
}) async {
  final pushed = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coachRepositoryProvider.overrideWithValue(repo),
        // The real one also asks the account provider for the username
        coachAccessProvider.overrideWith((ref) async => repo.access),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [_Observer(pushed)],
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(body: Text('route:${settings.name}')),
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return pushed;
}

class _Observer extends NavigatorObserver {
  final List<String> pushed;

  _Observer(this.pushed);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null && route.settings.name != '/') {
      pushed.add(route.settings.name!);
    }
  }
}
