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
import 'package:wger/features/glossary/glossary_term.dart';
import 'package:wger/features/glossary/screens/glossary_screen.dart';
import 'package:wger/features/glossary/widgets/glossary_widgets.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

Widget wrap(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  test('every term has a complete explanation', () async {
    final i18n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(GlossaryTerm.values, hasLength(17));
    for (final term in GlossaryTerm.values) {
      expect(term.abbreviation(i18n), isNotEmpty, reason: term.name);
      expect(term.fullName(i18n), isNotEmpty, reason: term.name);
      expect(term.what(i18n).length, greaterThan(20), reason: term.name);
      expect(term.how(i18n).length, greaterThan(20), reason: term.name);
      expect(term.example(i18n).length, greaterThan(20), reason: term.name);
    }
    expect(GlossaryTerm.oneRm.abbreviation(i18n), '1RM');
  });

  testWidgets('the chip opens a sheet with what / how / example', (tester) async {
    await tester.pumpWidget(wrap(const AbbreviationChip(GlossaryTerm.rir)));
    expect(find.text('RIR'), findsOneWidget);

    await tester.tap(find.byType(AbbreviationChip));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('glossary-sheet')), findsOneWidget);
    expect(find.text('Reps in reserve'), findsOneWidget);
    expect(find.text('What it is'), findsOneWidget);
    expect(find.text('How it helps your goal'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
    expect(find.byKey(const ValueKey('glossary-what')), findsOneWidget);
    expect(find.byKey(const ValueKey('glossary-example')), findsOneWidget);
  });

  testWidgets('the chip can show another label', (tester) async {
    await tester.pumpWidget(wrap(const AbbreviationChip(GlossaryTerm.rir, label: 'RiR')));
    expect(find.text('RiR'), findsOneWidget);
  });

  testWidgets('the sheet leads to the full glossary', (tester) async {
    await tester.pumpWidget(wrap(const AbbreviationChip(GlossaryTerm.bpm)));
    await tester.tap(find.byType(AbbreviationChip));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('glossary-open-all')));
    await tester.pumpAndSettle();

    expect(find.byType(GlossaryScreen), findsOneWidget);
    // The term is expanded
    expect(find.byKey(const ValueKey('glossary-what')), findsNothing);
    expect(find.textContaining('tempo of a song'), findsOneWidget);
  });

  testWidgets('the help button opens the glossary', (tester) async {
    await tester.pumpWidget(wrap(const GlossaryHelpButton()));
    await tester.tap(find.byKey(const ValueKey('glossary-help-button')));
    await tester.pumpAndSettle();
    expect(find.byType(GlossaryScreen), findsOneWidget);
  });

  testWidgets('the glossary screen lists the terms and filters them', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const GlossaryScreen()));
    expect(find.byType(ExpansionTile), findsNWidgets(GlossaryTerm.values.length));

    await tester.enterText(find.byKey(const ValueKey('glossary-search')), 'deload');
    await tester.pump();
    expect(find.byType(ExpansionTile), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('glossary-deload')));
    await tester.pumpAndSettle();
    expect(find.text('How it helps your goal'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('glossary-search')), 'zzz');
    await tester.pump();
    expect(find.byType(ExpansionTile), findsNothing);
  });
}
