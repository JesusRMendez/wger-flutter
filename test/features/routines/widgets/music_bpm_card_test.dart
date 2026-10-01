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
import 'package:wger/features/routines/logic/music_bpm.dart';
import 'package:wger/features/routines/widgets/music_bpm_card.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

void main() {
  final opened = <Uri>[];

  Widget render({MusicPhase phase = MusicPhase.strength}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MusicBpmCard(
        initialPhase: phase,
        launcher: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    ),
  );

  setUp(opened.clear);

  testWidgets('recommends the BPM of the phase', (tester) async {
    await tester.pumpWidget(render());
    expect(find.text('Recommended tempo: 120-140 BPM'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('music-phase-hiit')));
    await tester.pump();
    expect(find.text('Recommended tempo: 150-170 BPM'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('music-phase-rest')));
    await tester.pump();
    expect(find.text('Recommended tempo: 90-110 BPM'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('music-phase-warmUp')));
    await tester.pump();
    expect(find.text('Recommended tempo: 100-120 BPM'), findsOneWidget);
  });

  testWidgets('opens Spotify and YouTube Music for the phase', (tester) async {
    await tester.pumpWidget(render(phase: MusicPhase.hiit));

    await tester.tap(find.byKey(const ValueKey('music-spotify')));
    await tester.tap(find.byKey(const ValueKey('music-youtube')));
    await tester.pump();

    expect(opened, [spotifySearchUri(MusicPhase.hiit), youtubeMusicSearchUri(MusicPhase.hiit)]);
  });

  testWidgets('the BPM abbreviation is explained', (tester) async {
    await tester.pumpWidget(render());
    await tester.tap(find.byKey(const ValueKey('abbreviation-bpm')));
    await tester.pumpAndSettle();
    expect(find.text('Beats per minute'), findsOneWidget);
  });

  testWidgets('a failing launcher does not break the card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MusicBpmCard(launcher: (_) async => throw Exception('no app'))),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('music-spotify')));
    await tester.pump();
    expect(find.byKey(const ValueKey('music-recommendation')), findsOneWidget);
  });
}
