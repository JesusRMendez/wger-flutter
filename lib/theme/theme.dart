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

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wger/theme/atlas.dart';

// wger "Atlas" visual language.
//
// The fixed palettes come straight from the design tokens: the dark theme from
// the mobile app boards, the light one from the web boards. A theme seeded from
// the platform's dynamic color keeps its own hues but gets the same shapes,
// borders and typography, see [wgerThemeFromSeed].
//
// For the Material color roles see
// * https://pub.dev/packages/flex_color_scheme

const Color wgerPrimaryColor = Color(0xff2a4c7d);
const Color wgerPrimaryButtonColor = Color(0xff266dd3);
const Color wgerPrimaryColorLight = Color(0xff94B2DB);
const Color wgerSecondaryColor = Color(0xffe63946);
const Color wgerSecondaryColorLight = Color(0xffF6B4BA);
const Color wgerTertiaryColor = Color(0xFF6CA450);

/// Family of the UI text.
const String wgerDisplayFont = AtlasText.sans;

/// Family of the figures: weights, reps, kcal, timers.
const String wgerMonoFont = AtlasText.monoFamily;

// Dark scheme from the app tokens.
const ColorScheme schemeDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF8DB2F0),
  onPrimary: Color(0xFF0A0F1C),
  primaryContainer: Color(0xFF2A4C7D),
  onPrimaryContainer: Color(0xFFDCE7FA),
  secondary: Color(0xFFFF7A6E),
  onSecondary: Color(0xFF0A0F1C),
  secondaryContainer: Color(0xFF3A2430),
  onSecondaryContainer: Color(0xFFFFD9D5),
  tertiary: Color(0xFF5BD69A),
  onTertiary: Color(0xFF0A0F1C),
  tertiaryContainer: Color(0xFF173B31),
  onTertiaryContainer: Color(0xFFC4F2DB),
  error: Color(0xFFFF6B6B),
  onError: Color(0xFF0A0F1C),
  errorContainer: Color(0xFF3C1D26),
  onErrorContainer: Color(0xFFFFD6D6),
  surface: Color(0xFF0A0F1C),
  onSurface: Color(0xFFF2F4F8),
  onSurfaceVariant: Color(0xFFB4BCCE),
  outline: Color(0xFF33405F),
  outlineVariant: Color(0xFF232D45),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF03060C),
  inverseSurface: Color(0xFFF2F4F8),
  onInverseSurface: Color(0xFF0A0F1C),
  inversePrimary: Color(0xFF2A4C7D),
  surfaceTint: Color(0xFF8DB2F0),
  surfaceContainerLowest: Color(0xFF080D18),
  surfaceContainerLow: Color(0xFF0E1524),
  surfaceContainer: Color(0xFF121A2B),
  surfaceContainerHigh: Color(0xFF1A2338),
  surfaceContainerHighest: Color(0xFF232D45),
);

// Light scheme from the web tokens.
const ColorScheme schemeLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2A4C7D),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE8EEF8),
  onPrimaryContainer: Color(0xFF1B3358),
  secondary: Color(0xFFD93D42),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFCEBEC),
  onSecondaryContainer: Color(0xFF7A1B1F),
  tertiary: Color(0xFF1C7F46),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFE3F3E9),
  onTertiaryContainer: Color(0xFF0E4426),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFCEBEC),
  onErrorContainer: Color(0xFF601410),
  surface: Color(0xFFF3F4F6),
  onSurface: Color(0xFF0D1321),
  onSurfaceVariant: Color(0xFF3F4859),
  outline: Color(0xFFD6D9E0),
  outlineVariant: Color(0xFFE5E7EB),
  shadow: Color(0xFF0D1321),
  scrim: Color(0xFF0D1321),
  inverseSurface: Color(0xFF0D1321),
  onInverseSurface: Color(0xFFF2F4F8),
  inversePrimary: Color(0xFFB9CBE8),
  surfaceTint: Color(0xFF2A4C7D),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFF7F8FA),
  surfaceContainerHighest: Color(0xFFEEF0F3),
);

// High contrast: pure ink on the page and visible borders.
final ColorScheme schemeLightHc = schemeLight.copyWith(
  primary: const Color(0xFF1B3358),
  onSurface: const Color(0xFF000000),
  onSurfaceVariant: const Color(0xFF0D1321),
  outline: const Color(0xFF3F4859),
  outlineVariant: const Color(0xFF5E6679),
);

final ColorScheme schemeDarkHc = schemeDark.copyWith(
  primary: const Color(0xFFB9D0F7),
  onSurface: const Color(0xFFFFFFFF),
  onSurfaceVariant: const Color(0xFFE6EAF2),
  outline: const Color(0xFF8B95AD),
  outlineVariant: const Color(0xFF6B7794),
);

const FontWeight _w500 = FontWeight.w500;
const FontWeight _w600 = FontWeight.w600;

TextStyle _s(double size, FontWeight weight, {double em = 0, double? height}) {
  return TextStyle(
    fontFamily: AtlasText.sans,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: em * size,
    height: height,
  );
}

/// Geist type scale of the design: `.h1` 28/650, `.h2` 17/600, `.h3` 15/600,
/// the 11px uppercase eyebrow as labelSmall, numbers in Geist Mono via
/// [AtlasText.mono].
final TextTheme wgerTextTheme = TextTheme(
  displayLarge: _s(44, _w600, em: -0.045, height: 1.05),
  displayMedium: _s(36, _w600, em: -0.045, height: 1.05),
  displaySmall: _s(28, _w600, em: -0.035, height: 1.1),
  headlineLarge: _s(28, _w600, em: -0.035, height: 1.15),
  headlineMedium: _s(24, _w600, em: -0.03, height: 1.15),
  headlineSmall: _s(20, _w600, em: -0.02, height: 1.2),
  titleLarge: _s(20, _w600, em: -0.02, height: 1.2),
  titleMedium: _s(17, _w600, em: -0.015, height: 1.25),
  titleSmall: _s(15, _w600, em: -0.01, height: 1.3),
  bodyLarge: _s(16, FontWeight.w400, height: 1.4),
  bodyMedium: _s(14, FontWeight.w400, height: 1.4),
  bodySmall: _s(12.5, FontWeight.w400, height: 1.35),
  labelLarge: _s(14, _w600, height: 1.2),
  labelMedium: _s(12, _w600, height: 1.2),
  labelSmall: _s(11, _w600, em: 0.04, height: 1.2),
);

RoundedRectangleBorder _shape(double radius, Color line, {double width = 1}) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: BorderSide(color: line, width: width),
  );
}

/// The Atlas [ThemeData] for [scheme]: cards, chips, buttons, bars and sheets
/// share one radius, a 1px line instead of elevation and the Geist type scale.
ThemeData wgerAtlasTheme(ColorScheme scheme, AtlasColors atlas) {
  final textTheme = wgerTextTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  const pill = StadiumBorder();
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AtlasRadius.control),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AtlasRadius.input),
    borderSide: BorderSide(color: atlas.line),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    fontFamily: AtlasText.sans,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    cardColor: atlas.card,
    dividerColor: atlas.line,
    splashFactory: InkRipple.splashFactory,
    splashColor: scheme.primary.withValues(alpha: 0.10),
    highlightColor: scheme.primary.withValues(alpha: 0.05),
    visualDensity: VisualDensity.standard,
    extensions: [atlas],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.onSurface),
      actionsIconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: atlas.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: _shape(AtlasRadius.card, atlas.line),
      clipBehavior: Clip.antiAlias,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: atlas.surface2,
      selectedColor: scheme.onSurface,
      disabledColor: atlas.surface2,
      side: BorderSide(color: atlas.line),
      shape: pill,
      labelStyle: textTheme.labelMedium?.copyWith(color: atlas.ink2),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: scheme.surface),
      checkmarkColor: scheme.surface,
      iconTheme: IconThemeData(color: atlas.ink2, size: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 0,
      pressElevation: 0,
      showCheckmark: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(64, 48),
        shape: controlShape,
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: atlas.surface2,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        minimumSize: const Size(64, 48),
        shape: _shape(AtlasRadius.control, atlas.line),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size(64, 48),
        side: BorderSide(color: atlas.line2),
        shape: controlShape,
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: controlShape,
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: atlas.card,
        selectedBackgroundColor: atlas.surface3,
        selectedForegroundColor: scheme.onSurface,
        foregroundColor: atlas.ink3,
        side: BorderSide(color: atlas.line),
        textStyle: textTheme.labelMedium,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: atlas.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: atlas.surface3,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          fontSize: 10.5,
          letterSpacing: 0,
          color: selected ? scheme.onSurface : atlas.ink3,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(size: 22, color: selected ? scheme.onSurface : atlas.ink3);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: atlas.card,
      indicatorColor: atlas.surface3,
      selectedIconTheme: IconThemeData(color: scheme.onSurface),
      unselectedIconTheme: IconThemeData(color: atlas.ink3),
      selectedLabelTextStyle: textTheme.labelSmall?.copyWith(color: scheme.onSurface),
      unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(color: atlas.ink3),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: atlas.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      modalBackgroundColor: atlas.card,
      modalBarrierColor: atlas.scrim,
      showDragHandle: true,
      dragHandleColor: atlas.line2,
      dragHandleSize: const Size(40, 5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AtlasRadius.sheet)),
        side: BorderSide(color: atlas.line2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: atlas.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: _shape(AtlasRadius.dialog, atlas.line2),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: atlas.ink2),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: atlas.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: _shape(AtlasRadius.input, atlas.line2),
      textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(atlas.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(_shape(AtlasRadius.input, atlas.line2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: atlas.card,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder,
      enabledBorder: inputBorder,
      disabledBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: atlas.line.withValues(alpha: 0.5)),
      ),
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(color: atlas.ink3),
      hintStyle: textTheme.bodyMedium?.copyWith(color: atlas.ink3),
      helperStyle: textTheme.bodySmall?.copyWith(color: atlas.ink3),
      prefixIconColor: atlas.ink3,
      suffixIconColor: atlas.ink3,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: atlas.ink2,
      textColor: scheme.onSurface,
      titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: _w500, color: scheme.onSurface),
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: atlas.ink3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AtlasRadius.input)),
    ),
    dividerTheme: DividerThemeData(color: atlas.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
        fontWeight: _w500,
      ),
      actionTextColor: scheme.inversePrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AtlasRadius.card)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      unselectedLabelColor: atlas.ink3,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
      indicatorColor: scheme.primary,
      dividerColor: atlas.line,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: atlas.surface3,
      circularTrackColor: atlas.surface3,
      linearMinHeight: 6,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: atlas.surface3,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : atlas.ink3,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : atlas.surface3,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.transparent : atlas.line2,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: textTheme.labelMedium?.copyWith(color: scheme.onInverseSurface),
    ),
  );
}

final wgerLightTheme = wgerAtlasTheme(schemeLight, AtlasColors.light);
final wgerDarkTheme = wgerAtlasTheme(schemeDark, AtlasColors.dark);
final wgerLightThemeHc = wgerAtlasTheme(schemeLightHc, AtlasColors.light);
final wgerDarkThemeHc = wgerAtlasTheme(schemeDarkHc, AtlasColors.dark);

/// Builds a wger theme for [brightness] with the palette generated from [seed],
/// e.g. the platform's dynamic color. Shapes, borders and typography match the
/// fixed themes, so only the hues change.
///
/// With [highContrast] the palette is spread over a wider tonal range, matching
/// the fixed high contrast themes the OS accessibility setting switches to.
ThemeData wgerThemeFromSeed(
  Color seed,
  Brightness brightness, {
  bool highContrast = false,
}) {
  final scheme = SeedColorScheme.fromSeeds(
    primaryKey: seed,
    brightness: brightness,
    tones: highContrast ? FlexTones.ultraContrast(brightness) : FlexTones.vivid(brightness),
  );

  return wgerAtlasTheme(scheme, AtlasColors.fromScheme(scheme));
}

CalendarStyle getWgerCalendarStyle(ThemeData theme) {
  final scheme = theme.colorScheme;
  final selectedDecoration = BoxDecoration(
    color: scheme.secondary,
    shape: BoxShape.circle,
  );
  // table_calendar defaults these to a near-white that only works on a dark
  // circle, and secondary is light in dark mode.
  final selectedTextStyle = TextStyle(color: scheme.onSecondary, fontSize: 16);

  return CalendarStyle(
    outsideDaysVisible: false,
    todayDecoration: const BoxDecoration(
      color: Colors.amber,
      shape: BoxShape.circle,
    ),
    markerDecoration: BoxDecoration(
      color: theme.textTheme.headlineLarge?.color,
      shape: BoxShape.circle,
    ),
    selectedDecoration: selectedDecoration,
    selectedTextStyle: selectedTextStyle,
    rangeStartDecoration: selectedDecoration,
    rangeStartTextStyle: selectedTextStyle,
    rangeEndDecoration: selectedDecoration,
    rangeEndTextStyle: selectedTextStyle,
    rangeHighlightColor: scheme.secondaryContainer,
    weekendTextStyle: TextStyle(color: scheme.secondary),
  );
}
