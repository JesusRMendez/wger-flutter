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
import 'package:wger/core/widgets/dashboard/widgets/coach.dart';
import 'package:wger/features/coach/screens/coach_screen.dart';

import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

void main() {
  testWidgets('dashboard card opens the coach', (tester) async {
    final pushed = await pumpCoach(
      tester,
      const Scaffold(body: DashboardCoachWidget()),
      FakeCoachRepository(),
    );
    expect(find.text('Coach'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dashboard-coach')));
    await tester.pumpAndSettle();
    expect(pushed, [CoachScreen.routeName]);
  });
}
