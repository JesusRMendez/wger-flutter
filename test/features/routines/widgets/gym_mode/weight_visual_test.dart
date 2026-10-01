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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/features/exercises/models/equipment.dart';
import 'package:wger/features/routines/widgets/gym_mode/weight_visual.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/l10n/localizations_delegates.dart';
import 'package:wger/theme/theme.dart';

import '../../../../../test_data/exercises.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  final base = getTestExercises().first;
  final barbell = base.copyWith(
    equipment: const [Equipment(id: ID_EQUIPMENT_BARBELL, name: 'Barbell')],
  );
  final dumbbell = base.copyWith(
    equipment: const [Equipment(id: ID_EQUIPMENT_DUMBBELL, name: 'Dumbbell')],
  );
  final bodyweight = base.copyWith(equipment: const []);

  test('picks the visual from the equipment', () {
    expect(weightVisualKindFor(barbell, 80), WeightVisualKind.barbell);
    expect(weightVisualKindFor(dumbbell, 20), WeightVisualKind.dumbbell);
    expect(weightVisualKindFor(bodyweight, null), WeightVisualKind.bodyweight);
    expect(weightVisualKindFor(bodyweight, 10), WeightVisualKind.other);
  });

  Future<void> pump(WidgetTester tester, WeightVisual visual) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: wgerDarkTheme,
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SizedBox(height: 300, child: visual)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a barbell shows the plates of one side', (tester) async {
    await pump(tester, WeightVisual(exercise: barbell, weight: 80));

    // 80 kg on a 20 kg bar: 25 + 5 per side
    expect(find.text('25'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Bar weight 20'), findsOneWidget);
  });

  testWidgets('a weight that cannot be loaded says so', (tester) async {
    await pump(tester, WeightVisual(exercise: barbell, weight: 81));

    expect(find.text('Not possible to reach weight with available plates'), findsOneWidget);
  });

  testWidgets('a dumbbell and the body have their own drawing', (tester) async {
    await pump(tester, WeightVisual(exercise: dumbbell, weight: 20));
    expect(find.byKey(const ValueKey('visual-dumbbell')), findsOneWidget);

    await pump(tester, WeightVisual(exercise: bodyweight, weight: null));
    expect(find.byKey(const ValueKey('visual-body')), findsOneWidget);
  });
}
