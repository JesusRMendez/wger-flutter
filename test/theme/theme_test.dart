/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
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

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/theme/atlas.dart';
import 'package:wger/theme/theme.dart';

void main() {
  group('wgerThemeFromSeed', () {
    const seed = Color(0xFF6750A4);

    test('applies the requested brightness', () {
      expect(wgerThemeFromSeed(seed, Brightness.light).brightness, Brightness.light);
      expect(wgerThemeFromSeed(seed, Brightness.dark).brightness, Brightness.dark);
    });

    test('derives the palette from the seed hue', () {
      final scheme = wgerThemeFromSeed(seed, Brightness.light).colorScheme;

      expect(
        Hct.fromInt(scheme.primary.toARGB32()).hue,
        closeTo(Hct.fromInt(seed.toARGB32()).hue, 5),
      );
    });

    test('generates a distinct surface container ramp', () {
      // A platform scheme used as-is leaves these unset, which flattens every
      // elevated surface onto the scaffold color.
      for (final brightness in Brightness.values) {
        final scheme = wgerThemeFromSeed(seed, brightness).colorScheme;

        expect(
          {
            scheme.surface,
            scheme.surfaceContainerLowest,
            scheme.surfaceContainerLow,
            scheme.surfaceContainer,
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerHighest,
          },
          hasLength(6),
          reason: 'surface tones collapsed in $brightness',
        );
      }
    });

    test('high contrast spreads the palette further apart', () {
      double contrast(Color a, Color b) {
        final values = [a.computeLuminance(), b.computeLuminance()]..sort();

        return (values.last + 0.05) / (values.first + 0.05);
      }

      for (final brightness in Brightness.values) {
        final normal = wgerThemeFromSeed(seed, brightness).colorScheme;
        final hc = wgerThemeFromSeed(seed, brightness, highContrast: true).colorScheme;

        expect(
          contrast(hc.onSurface, hc.surface),
          greaterThan(contrast(normal.onSurface, normal.surface)),
          reason: 'no extra contrast in $brightness',
        );
      }
    });

    test('uses Geist for the UI and keeps the Atlas tokens', () {
      final theme = wgerThemeFromSeed(seed, Brightness.light);

      expect(theme.textTheme.headlineLarge?.fontFamily, 'Geist');
    });
  });
  group('Atlas themes', () {
    test('dark theme uses the app tokens', () {
      expect(wgerDarkTheme.scaffoldBackgroundColor, const Color(0xFF0A0F1C));
      expect(wgerDarkTheme.colorScheme.primary, const Color(0xFF8DB2F0));
      expect(wgerDarkTheme.extension<AtlasColors>(), AtlasColors.dark);
    });

    test('light theme uses the web tokens', () {
      expect(wgerLightTheme.scaffoldBackgroundColor, const Color(0xFFF3F4F6));
      expect(wgerLightTheme.colorScheme.primary, const Color(0xFF2A4C7D));
      expect(wgerLightTheme.extension<AtlasColors>(), AtlasColors.light);
    });

    test('cards are flat, 16 radius and outlined with the line color', () {
      final card = wgerDarkTheme.cardTheme;
      final shape = card.shape! as RoundedRectangleBorder;

      expect(card.elevation, 0);
      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(shape.side.color, AtlasColors.dark.line);
    });

    test('figures use tabular Geist Mono', () {
      final style = AtlasText.mono(const TextStyle(fontSize: 20));

      expect(style.fontFamily, 'GeistMono');
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('seeded themes keep the Atlas shapes', () {
      final theme = wgerThemeFromSeed(const Color(0xFF6750A4), Brightness.dark);

      expect(theme.extension<AtlasColors>(), isNotNull);
      expect(
        (theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
    });
  });
}
