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
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/models/coach_memory.dart';
import 'package:wger/features/coach/screens/memory_screen.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';

import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

void main() {
  testWidgets('lists memories with category and source', (tester) async {
    final repo = FakeCoachRepository()
      ..memories = [
        const CoachMemory(id: 1, text: 'Bad left knee', category: 'injury', source: 'ai'),
        const CoachMemory(id: 2, text: 'Prefers mornings'),
      ];
    await pumpCoach(tester, const MemoryScreen(), repo);

    expect(find.text('Bad left knee'), findsOneWidget);
    expect(find.text('Injury · Coach'), findsOneWidget);
    expect(find.text('Preference · You'), findsOneWidget);
  });

  testWidgets('adds and deletes a memory', (tester) async {
    final repo = FakeCoachRepository()
      ..memories = [const CoachMemory(id: 2, text: 'Prefers mornings')];
    await pumpCoach(tester, const MemoryScreen(), repo);

    await tester.tap(find.byKey(const ValueKey('memory-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('memory-text')), 'No barbell squats');
    await tester.tap(find.byKey(const ValueKey('memory-save')));
    await tester.pumpAndSettle();
    expect(repo.calls, ['add-memory:No barbell squats']);
    expect(find.text('No barbell squats'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-button')));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'delete-memory:2');
    expect(find.text('Prefers mornings'), findsNothing);
  });

  testWidgets('disabled memory explains how to turn it on', (tester) async {
    final repo = FakeCoachRepository()
      ..access = const CoachAccess(id: 1, effectiveMode: CoachMode.server);
    final pushed = await pumpCoach(tester, const MemoryScreen(), repo);

    expect(find.textContaining('Memory is turned off'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory-add')), findsNothing);
    await tester.tap(find.text('My AI'));
    await tester.pumpAndSettle();
    expect(pushed, [MyAiScreen.routeName]);
  });

  testWidgets('empty list shows a hint', (tester) async {
    await pumpCoach(tester, const MemoryScreen(), FakeCoachRepository());
    expect(find.text('The coach has not stored anything about you yet.'), findsOneWidget);
  });
}
