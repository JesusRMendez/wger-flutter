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
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/screens/coach_screen.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';
import 'package:wger/features/coach/screens/memory_screen.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';

import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

void main() {
  testWidgets('shows mode badge, usage and chats with the coach', (tester) async {
    final repo = FakeCoachRepository();
    await pumpCoach(tester, const CoachScreen(), repo);

    expect(find.text('Server AI'), findsOneWidget);
    expect(find.text('1500 of 10000 tokens used'), findsOneWidget);
    expect(find.text('Ask about your training, nutrition or progress.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('coach-chat-input')), 'How do I deload?');
    await tester.tap(find.byKey(const ValueKey('coach-chat-send')));
    await tester.pumpAndSettle();

    expect(find.text('How do I deload?'), findsOneWidget);
    expect(find.text('Echo: How do I deload?'), findsOneWidget);
    expect(repo.calls, ['chat:How do I deload?:0']);
  });

  testWidgets('a suggestion chip asks the question and the answer carries the disclaimer', (
    tester,
  ) async {
    final repo = FakeCoachRepository();
    await pumpCoach(tester, const CoachScreen(), repo);

    expect(find.byKey(const ValueKey('coach-disclaimer')), findsNothing);
    await tester.tap(find.text('This week I only have 30 min'));
    await tester.pumpAndSettle();

    expect(find.text('Echo: This week I only have 30 min'), findsOneWidget);
    expect(repo.calls, ['chat:This week I only have 30 min:0']);
    expect(
      find.byKey(const ValueKey('coach-disclaimer'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('no suggestions without AI', (tester) async {
    final repo = FakeCoachRepository()
      ..access = const CoachAccess(id: 1, effectiveMode: CoachMode.none);
    await pumpCoach(tester, const CoachScreen(), repo);

    expect(find.byKey(const ValueKey('coach-suggestions')), findsNothing);
  });

  testWidgets('without AI the badge links to My AI and chat is disabled', (tester) async {
    final repo = FakeCoachRepository()
      ..access = const CoachAccess(id: 1, effectiveMode: CoachMode.none);
    final pushed = await pumpCoach(tester, const CoachScreen(), repo);

    expect(find.text('AI unavailable'), findsOneWidget);
    final input = tester.widget<TextField>(find.byKey(const ValueKey('coach-chat-input')));
    expect(input.enabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('coach-mode-badge')));
    await tester.pumpAndSettle();
    expect(pushed, [MyAiScreen.routeName]);
  });

  testWidgets('quota error is shown gracefully', (tester) async {
    final repo = FakeCoachRepository()
      ..aiError = WgerHttpException(http.Response('{"code":"ai_quota_exceeded"}', 429));
    await pumpCoach(tester, const CoachScreen(), repo);

    await tester.enterText(find.byKey(const ValueKey('coach-chat-input')), 'hi');
    await tester.tap(find.byKey(const ValueKey('coach-chat-send')));
    await tester.pumpAndSettle();

    expect(find.textContaining('monthly AI token limit'), findsOneWidget);
  });

  testWidgets('403 ai_not_available offers My AI', (tester) async {
    final repo = FakeCoachRepository()
      ..aiError = WgerHttpException(http.Response('{"code":"ai_not_available"}', 403));
    final pushed = await pumpCoach(tester, const CoachScreen(), repo);

    await tester.enterText(find.byKey(const ValueKey('coach-chat-input')), 'hi');
    await tester.tap(find.byKey(const ValueKey('coach-chat-send')));
    await tester.pumpAndSettle();

    expect(find.textContaining('AI is not available for your account'), findsOneWidget);
    await tester.ensureVisible(find.text('Set up My AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up My AI'));
    await tester.pumpAndSettle();
    expect(pushed, [MyAiScreen.routeName]);
  });

  testWidgets('navigates to plans, goals and memory', (tester) async {
    final repo = FakeCoachRepository();
    final pushed = await pumpCoach(tester, const CoachScreen(), repo);

    await tester.tap(find.text('Goals & indicators'));
    await tester.pumpAndSettle();
    expect(pushed.last, GoalsScreen.routeName);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Coach memory'));
    await tester.pumpAndSettle();
    expect(pushed.last, MemoryScreen.routeName);
  });

  testWidgets('memory entry is hidden when memory is disabled', (tester) async {
    final repo = FakeCoachRepository()
      ..access = const CoachAccess(id: 1, effectiveMode: CoachMode.server);
    await pumpCoach(tester, const CoachScreen(), repo);
    expect(find.byTooltip('Coach memory'), findsNothing);
  });
}
