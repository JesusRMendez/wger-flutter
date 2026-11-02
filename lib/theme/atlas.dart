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

import 'package:material_ui/material_ui.dart';

/// Design tokens of the "wger Atlas" visual language.
///
/// The dark values come from the mobile app boards, the light ones from the web
/// boards. Everything the Material [ColorScheme] has no role for (the second
/// and third surface step, the two line colors, the semantic status colors and
/// the macro nutrient colors) lives here, reachable as `context.atlas`.
@immutable
class AtlasColors extends ThemeExtension<AtlasColors> {
  const AtlasColors({
    required this.card,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.line2,
    required this.ink2,
    required this.ink3,
    required this.brandSoft,
    required this.accent,
    required this.accentSoft,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.hero,
    required this.onHero,
    required this.scrim,
  });

  /// Surface of cards and sheets (the first step above the page background).
  final Color card;
  final Color surface2;
  final Color surface3;

  /// 1px borders: the regular one and the stronger one for floating things.
  final Color line;
  final Color line2;

  /// Secondary and tertiary ink.
  final Color ink2;
  final Color ink3;

  final Color brandSoft;
  final Color accent;
  final Color accentSoft;
  final Color ok;
  final Color okSoft;
  final Color warn;
  final Color warnSoft;
  final Color protein;
  final Color carbs;
  final Color fat;

  /// The loud call-to-action card of a screen and the ink on it.
  final Color hero;
  final Color onHero;
  final Color scrim;

  static const dark = AtlasColors(
    card: Color(0xFF121A2B),
    surface2: Color(0xFF1A2338),
    surface3: Color(0xFF232D45),
    line: Color(0xFF232D45),
    line2: Color(0xFF33405F),
    ink2: Color(0xFFB4BCCE),
    ink3: Color(0xFF8B95AD),
    brandSoft: Color(0x248DB2F0),
    accent: Color(0xFFFF7A6E),
    accentSoft: Color(0x26FF7A6E),
    ok: Color(0xFF5BD69A),
    okSoft: Color(0x245BD69A),
    warn: Color(0xFFF5C062),
    warnSoft: Color(0x26F5C062),
    protein: Color(0xFF5A86E0),
    carbs: Color(0xFFB8812A),
    fat: Color(0xFF9E72DE),
    hero: Color(0xFF8DB2F0),
    onHero: Color(0xFF0A0F1C),
    scrim: Color(0x9903060C),
  );

  static const light = AtlasColors(
    card: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F8FA),
    surface3: Color(0xFFEEF0F3),
    line: Color(0xFFE5E7EB),
    line2: Color(0xFFD6D9E0),
    ink2: Color(0xFF3F4859),
    ink3: Color(0xFF5E6679),
    brandSoft: Color(0xFFE8EEF8),
    accent: Color(0xFFD93D42),
    accentSoft: Color(0xFFFCEBEC),
    ok: Color(0xFF1C7F46),
    okSoft: Color(0xFFE3F3E9),
    warn: Color(0xFFB7791F),
    warnSoft: Color(0xFFFBF1DE),
    protein: Color(0xFF3D6FD9),
    carbs: Color(0xFFD4932A),
    fat: Color(0xFF8E5BD9),
    hero: Color(0xFF0D1321),
    onHero: Color(0xFFF2F4F8),
    scrim: Color(0x990D1321),
  );

  /// Tokens for a scheme that did not come from the fixed palette (the dynamic
  /// color seeded one): surfaces and lines follow the scheme, the semantic
  /// colors keep their Atlas values so a macro or a status reads the same.
  factory AtlasColors.fromScheme(ColorScheme scheme) {
    final base = scheme.brightness == Brightness.dark ? dark : light;
    return base.copyWith(
      card: scheme.surfaceContainer,
      surface2: scheme.surfaceContainerHigh,
      surface3: scheme.surfaceContainerHighest,
      line: scheme.outlineVariant,
      line2: scheme.outline,
      ink2: scheme.onSurfaceVariant,
      ink3: Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.5), scheme.surface),
      brandSoft: scheme.primary.withValues(alpha: 0.14),
      hero: scheme.primary,
      onHero: scheme.onPrimary,
    );
  }

  @override
  AtlasColors copyWith({
    Color? card,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? line2,
    Color? ink2,
    Color? ink3,
    Color? brandSoft,
    Color? accent,
    Color? accentSoft,
    Color? ok,
    Color? okSoft,
    Color? warn,
    Color? warnSoft,
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? hero,
    Color? onHero,
    Color? scrim,
  }) {
    return AtlasColors(
      card: card ?? this.card,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      brandSoft: brandSoft ?? this.brandSoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      ok: ok ?? this.ok,
      okSoft: okSoft ?? this.okSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AtlasColors lerp(ThemeExtension<AtlasColors>? other, double t) {
    if (other is! AtlasColors) {
      return this;
    }
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AtlasColors(
      card: l(card, other.card),
      surface2: l(surface2, other.surface2),
      surface3: l(surface3, other.surface3),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      ink2: l(ink2, other.ink2),
      ink3: l(ink3, other.ink3),
      brandSoft: l(brandSoft, other.brandSoft),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      ok: l(ok, other.ok),
      okSoft: l(okSoft, other.okSoft),
      warn: l(warn, other.warn),
      warnSoft: l(warnSoft, other.warnSoft),
      protein: l(protein, other.protein),
      carbs: l(carbs, other.carbs),
      fat: l(fat, other.fat),
      hero: l(hero, other.hero),
      onHero: l(onHero, other.onHero),
      scrim: l(scrim, other.scrim),
    );
  }
}

/// Shape tokens.
class AtlasRadius {
  AtlasRadius._();

  static const double card = 16;
  static const double control = 16;
  static const double input = 14;
  static const double sheet = 28;
  static const double dialog = 24;
  static const double pill = 999;
}

/// Motion tokens: everything moves between 140 and 240 ms on the same curve.
class AtlasMotion {
  AtlasMotion._();

  static const Duration press = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 240);
  static const Curve curve = Cubic(0.2, 0, 0, 1);

  /// [d], or zero when the user asked the platform to reduce motion.
  static Duration of(BuildContext context, [Duration d = base]) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
  }
}

extension AtlasContext on BuildContext {
  /// The Atlas tokens of the current theme. Falls back to the dark palette for
  /// a bare [ThemeData] (a test pumping a widget without the app theme).
  AtlasColors get atlas {
    final theme = Theme.of(this);
    return theme.extension<AtlasColors>() ??
        (theme.brightness == Brightness.dark ? AtlasColors.dark : AtlasColors.light);
  }
}

/// Text styles for figures: Geist Mono with tabular numerals, so a column of
/// numbers keeps its width while it counts.
class AtlasText {
  AtlasText._();

  static const String sans = 'Geist';
  static const String monoFamily = 'GeistMono';

  /// [base] switched to the mono family with tabular figures and the tighter
  /// tracking the design uses for numbers.
  static TextStyle mono(TextStyle? base, {double? size, FontWeight? weight, Color? color}) {
    final s = base ?? const TextStyle();
    final fs = size ?? s.fontSize ?? 14;
    return s.copyWith(
      fontFamily: monoFamily,
      fontSize: fs,
      fontWeight: weight ?? s.fontWeight,
      color: color ?? s.color,
      letterSpacing: -0.03 * fs,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
