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
import 'package:wger/features/coach/models/ai_provider_config.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';

import '../coach_test_helpers.dart';
import '../fake_coach_repository.dart';

void main() {
  testWidgets('shows the masked key and clears it', (tester) async {
    final repo = FakeCoachRepository()
      ..provider = const AiProviderConfig(
        provider: 'openai',
        model: 'gpt-4o',
        hasApiKey: true,
        apiKeyLast4: '9f2a',
      );
    await pumpCoach(tester, const MyAiScreen(), repo);

    expect(find.text('Stored key: ••••9f2a'), findsOneWidget);
    // The key is never prefilled
    final field = tester.widget<TextFormField>(find.byKey(const ValueKey('my-ai-key')));
    expect(field.controller!.text, isEmpty);

    await tester.tap(find.byKey(const ValueKey('my-ai-clear')));
    await tester.pumpAndSettle();

    expect(repo.lastSavedProvider!['api_key'], '');
    expect(find.textContaining('Stored key'), findsNothing);
  });

  testWidgets('saves provider, model and a new key', (tester) async {
    final repo = FakeCoachRepository();
    await pumpCoach(tester, const MyAiScreen(), repo);

    await tester.tap(find.byKey(const ValueKey('my-ai-provider')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anthropic').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('claude-sonnet-5-5'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('my-ai-key')), 'sk-secret-wxyz');
    await tester.ensureVisible(find.byKey(const ValueKey('my-ai-save')));
    await tester.tap(find.byKey(const ValueKey('my-ai-save')));
    await tester.pumpAndSettle();

    expect(repo.lastSavedProvider, {
      'provider': 'anthropic',
      'model': 'claude-sonnet-5-5',
      'api_key': 'sk-secret-wxyz',
    });
    expect(find.text('Stored key: ••••wxyz'), findsOneWidget);
  });

  testWidgets('saving without typing a key keeps the stored one', (tester) async {
    final repo = FakeCoachRepository()
      ..provider = const AiProviderConfig(
        provider: 'openai',
        model: 'gpt-4o',
        hasApiKey: true,
        apiKeyLast4: '1111',
      );
    await pumpCoach(tester, const MyAiScreen(), repo);
    await tester.ensureVisible(find.byKey(const ValueKey('my-ai-save')));
    await tester.tap(find.byKey(const ValueKey('my-ai-save')));
    await tester.pumpAndSettle();
    expect(repo.lastSavedProvider!['api_key'], isNull);
  });

  testWidgets('memory switch updates the access record', (tester) async {
    final repo = FakeCoachRepository();
    await pumpCoach(tester, const MyAiScreen(), repo);
    await tester.ensureVisible(find.byKey(const ValueKey('my-ai-memory')));
    await tester.tap(find.byKey(const ValueKey('my-ai-memory')));
    await tester.pumpAndSettle();
    expect(repo.calls, ['memory:false']);
  });
}
