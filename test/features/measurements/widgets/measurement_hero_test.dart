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
import 'package:wger/features/measurements/charts/series.dart';
import 'package:wger/features/measurements/widgets/measurement_hero.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

void main() {
  Widget render(double first, double last, {int days = 90}) {
    final end = DateTime(2026, 10, 1);
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MeasurementHero(
          first: MeasurementChartEntry(first, end.subtract(Duration(days: days))),
          last: MeasurementChartEntry(last, end),
          unit: 'kg',
        ),
      ),
    );
  }

  testWidgets('shows the newest value and the loss over the range', (tester) async {
    await tester.pumpWidget(render(80.1, 78.4));

    expect(find.text('78.4'), findsOneWidget);
    expect(find.text('−1.7 kg in 90 days'), findsOneWidget);
  });

  testWidgets('a gain gets a plus', (tester) async {
    await tester.pumpWidget(render(78.4, 79.0, days: 1));

    expect(find.text('+0.6 kg in 1 day'), findsOneWidget);
  });

  testWidgets('a single day has no change to show', (tester) async {
    await tester.pumpWidget(render(78.4, 78.4, days: 0));

    expect(find.text('78.4'), findsOneWidget);
    expect(find.byKey(const ValueKey('measurement-hero-change')), findsNothing);
  });
}
