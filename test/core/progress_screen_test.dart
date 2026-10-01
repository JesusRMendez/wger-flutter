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
import 'package:mockito/mockito.dart';
import 'package:wger/core/progress_screen.dart';
import 'package:wger/features/account/providers/user_profile_repository.dart';
import 'package:wger/features/coach/screens/follow_up_screen.dart';
import 'package:wger/features/measurements/models/measurement_entry.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/measurements/providers/measurement_repository.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';

import '../../test_data/body_weight.dart';
import '../../test_data/profile.dart';
import '../features/measurements/screens/weight_screen_test.mocks.dart';
import '../helpers/measurement_chart_buckets.dart';
import '../helpers/measurement_repository_stubs.dart';

void main() {
  late MockMeasurementRepository repo;
  late MockUserProfileRepository profileRepo;
  late Map<String, List<MeasurementEntry>> entries;

  setUp(() {
    profileRepo = MockUserProfileRepository();
    when(profileRepo.watchDrift()).thenAnswer((_) => Stream.value(tUserProfile1));
    repo = MockMeasurementRepository();
    entries = bodyWeightEntries();
    stubMeasurementReads(repo, [getBodyWeightCategory()], entries);
  });

  Widget render(List<String> pushed) {
    return ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(repo),
        userProfileRepositoryProvider.overrideWithValue(profileRepo),
        measurementChartBucketsProvider.overrideWith(chartBucketsFrom(entries)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          pushed.add(settings.name!);
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('pushed')));
        },
        home: const ProgressScreen(),
      ),
    );
  }

  testWidgets('shows the latest weight with the add button in the header', (tester) async {
    await tester.pumpWidget(render([]));
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.byTooltip('New entry'), findsOneWidget);
  });

  testWidgets('the weekly follow-up row opens the follow-up screen', (tester) async {
    final pushed = <String>[];
    await tester.pumpWidget(render(pushed));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(const ValueKey('progress-follow-up')), 200);
    await tester.tap(find.byKey(const ValueKey('progress-follow-up')));
    await tester.pumpAndSettle();
    expect(pushed, [FollowUpScreen.routeName]);
  });
}
