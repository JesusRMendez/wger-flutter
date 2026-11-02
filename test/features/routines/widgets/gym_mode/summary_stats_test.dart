import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/database/powersync/database.dart';
import 'package:wger/features/routines/widgets/gym_mode/summary.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/screenshots/routines.dart';

void main() {
  Widget render(Widget child) => ProviderScope(
    overrides: [
      driftPowerSyncDatabase.overrideWithValue(DriftPowersyncDatabase(NativeDatabase.memory())),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('shows the totals, the volume change and the records of the session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = getScreenshotRoutine().sessions.first;
    final earlier = session.copyWith(
      id: 'earlier',
      datetimeStart: session.datetimeStart.subtract(const Duration(days: 7)),
      datetimeEnd: session.datetimeEnd!.subtract(const Duration(days: 7)),
      logs: [for (final l in session.logs) l.copyWith(weight: l.weight! - 2.5)],
    );

    await tester.pumpWidget(
      render(
        WorkoutSessionStats(
          session,
          const [],
          previousSessions: [session, earlier],
          plannedSets: 8,
          subtitle: 'Push day',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workout completed'), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('1:12:00'), findsOneWidget, reason: 'duration as a clock');
    expect(find.text('7/8'), findsOneWidget, reason: 'sets done of planned');
    expect(find.byKey(const ValueKey('volume-change')), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-records')), findsOneWidget);
    expect(find.text('2 new records (PR)'), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-muscles')), findsOneWidget);
  });

  testWidgets('without earlier sessions there is no change chip and no record card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      render(WorkoutSessionStats(getScreenshotRoutine().sessions.first, const [])),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('volume-change')), findsNothing);
    expect(find.byKey(const ValueKey('summary-records')), findsNothing);
  });

  test('clock text', () {
    expect(WorkoutSessionStats.clockText(const Duration(minutes: 52, seconds: 14)), '52:14');
    expect(WorkoutSessionStats.clockText(const Duration(hours: 1, minutes: 2)), '1:02:00');
  });
}
