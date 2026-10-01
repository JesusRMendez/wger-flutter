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

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/theme/atlas.dart';
import 'package:wger/theme/theme.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: wgerDarkTheme,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('Pressable', () {
    testWidgets('scales down while pressed and calls onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(Pressable(onTap: () => taps++, child: const SizedBox(width: 100, height: 50))),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(Pressable)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.97);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('does not scale when animations are disabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Pressable(onTap: () {}, child: const SizedBox(width: 100, height: 50)),
          disableAnimations: true,
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(Pressable)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
    });
  });

  group('PillChip', () {
    testWidgets('is a pill and taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(PillChip('Chest', onTap: () => taps++)));

      final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(
        (box.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(AtlasRadius.pill),
      );

      await tester.tap(find.text('Chest'));
      expect(taps, 1);
    });

    testWidgets('selected flips to the inverse fill', (tester) async {
      await tester.pumpWidget(_wrap(const PillChip('Chest', selected: true)));
      await tester.pump(const Duration(milliseconds: 300));

      final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect((box.decoration! as BoxDecoration).color, wgerDarkTheme.colorScheme.onSurface);
    });
  });

  group('ProgressRing', () {
    testWidgets('clamps the value and shows its child', (tester) async {
      await tester.pumpWidget(_wrap(const ProgressRing(value: 4, child: Text('100'))));
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
      final paint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(ProgressRing), matching: find.byType(CustomPaint)),
      );
      expect(paint.size, const Size.square(88));
    });

    testWidgets('has no animation time when motion is reduced', (tester) async {
      await tester.pumpWidget(
        _wrap(const ProgressRing(value: 0.5), disableAnimations: true),
      );

      // Settles without advancing the clock
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('StatTile and MonoText', () {
    testWidgets('renders eyebrow upper cased, value in mono and the unit', (tester) async {
      await tester.pumpWidget(_wrap(const StatTile(label: 'Weight', value: '78.4', unit: 'kg')));

      expect(find.text('WEIGHT'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      final value = tester.widget<Text>(find.text('78.4'));
      expect(value.style?.fontFamily, 'GeistMono');
      expect(value.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    });
  });

  group('MacroBar', () {
    testWidgets('shows value and target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: MacroBar(label: 'Protein', value: 62, target: 160, color: Colors.blue),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('62/160'), findsOneWidget);
    });
  });
}
