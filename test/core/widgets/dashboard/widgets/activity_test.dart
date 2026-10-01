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
import 'package:wger/core/widgets/dashboard/widgets/activity.dart';
import 'package:wger/features/account/models/user_profile.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/measurements/models/measurement_category.dart';
import 'package:wger/features/measurements/models/measurement_entry.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/routines/models/session.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../../../../test_data/routines.dart';

class _StubUserProfileNotifier extends UserProfileNotifier {
  @override
  Stream<UserProfile?> build() => Stream.value(UserProfile(id: 1, weightUnitStr: 'kg'));
}

class _StubRoutinesRiverpod extends RoutinesRiverpod {
  _StubRoutinesRiverpod(this._sessions);

  final List<WorkoutSession> _sessions;

  @override
  Stream<RoutinesState> build() =>
      Stream.value(RoutinesState(routines: [getTestRoutine()..sessions = _sessions]));
}

void main() {
  // A Thursday
  final now = DateTime(2026, 10, 1, 9);

  group('weeklyStreak', () {
    test('counts consecutive weeks with a session, the current one included', () {
      final days = [DateTime(2026, 9, 29), DateTime(2026, 9, 22), DateTime(2026, 9, 10)];
      // Weeks of 28.9. and 21.9. are linked, the week of 7.9. is cut off by 14.9.
      expect(weeklyStreak(days, now), 2);
    });

    test('an empty current week does not break the streak yet', () {
      final days = [DateTime(2026, 9, 24), DateTime(2026, 9, 17)];
      expect(weeklyStreak(days, now), 2);
    });

    test('is 0 without a session this or last week', () {
      expect(weeklyStreak([DateTime(2026, 9, 1)], now), 0);
      expect(weeklyStreak(const [], now), 0);
    });
  });

  test('startOfWeek is the Monday at midnight', () {
    expect(startOfWeek(DateTime(2026, 10, 4, 23, 59)), DateTime(2026, 9, 28));
    expect(startOfWeek(DateTime(2026, 9, 28)), DateTime(2026, 9, 28));
  });

  test('eight hours of sleep are a full readiness score', () {
    expect(readinessScore(480), 100);
    expect(readinessScore(600), 100);
    expect(readinessScore(240), 50);
    expect(readinessScore(0), 0);
  });

  Widget render({
    List<WorkoutSession> sessions = const [],
    List<MeasurementCategory> categories = const [],
    Map<String, MeasurementEntry> latest = const {},
  }) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(_StubUserProfileNotifier.new),
        routinesRiverpodProvider.overrideWith(() => _StubRoutinesRiverpod(sessions)),
        measurementCategoriesProvider.overrideWith((ref) => Stream.value(categories)),
        latestMeasurementEntriesProvider.overrideWith((ref) => Stream.value(latest)),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: DashboardActivityWidget())),
      ),
    );
  }

  testWidgets('shows the week, the streak and a hint while there is no sleep data', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await tester.pumpWidget(
        render(
          sessions: [
            WorkoutSession(id: 's1', routineId: 1, datetimeStart: DateTime(2026, 9, 29, 18)),
          ],
        ),
      );
      await tester.pumpAndSettle();
    });

    // Monday 28th to Sunday 4th
    for (final d in [28, 29, 30, 2, 3, 4]) {
      expect(find.text('$d'), findsOneWidget);
    }
    // The 1st and the streak
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('week in a row'), findsOneWidget);
    expect(find.text('Log your sleep or sync it from Health to see your readiness.'), findsOne);
  });

  testWidgets('rates last night of sleep as readiness', (tester) async {
    final sleep = MeasurementCategory(
      id: 'sleep',
      name: 'Sleep',
      unit: 'min',
      metricType: MetricType.sleep,
    );
    await withClock(Clock.fixed(now), () async {
      await tester.pumpWidget(
        render(
          categories: [sleep],
          latest: {
            'sleep': MeasurementEntry(
              categoryId: 'sleep',
              date: DateTime(2026, 10, 1, 7),
              value: 460,
              notes: '',
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
    });

    expect(find.text('96'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Sleep 7 h 40'), findsOneWidget);
  });
}
