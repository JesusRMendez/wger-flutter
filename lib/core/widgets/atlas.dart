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

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:wger/theme/atlas.dart';

/// Shared building blocks of the "wger Atlas" design: pressable surfaces, cards,
/// progress rings, stat tiles, section eyebrows, pill chips and mono numbers.

/// Wraps [child] in a tap target that scales down to [scale] while pressed
/// (140 ms), with an ink response clipped to [borderRadius].
///
/// The scale is skipped when the platform asks to reduce motion.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.borderRadius = const BorderRadius.all(Radius.circular(AtlasRadius.card)),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    if (!enabled) {
      return widget.child;
    }
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scaled = _down && !reduce;

    Widget result = AnimatedScale(
      scale: scaled ? widget.scale : 1,
      duration: AtlasMotion.of(context, AtlasMotion.press),
      curve: AtlasMotion.curve,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged: (v) => setState(() => _down = v),
          // The press scale is the feedback, a ripple on top of it is noise
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          child: widget.child,
        ),
      ),
    );
    if (widget.semanticLabel != null) {
      result = Semantics(label: widget.semanticLabel, button: true, child: result);
    }
    return result;
  }
}

/// The Atlas surface: 16 radius, 1px line border, no elevation. With [onTap]
/// it presses like a button. [hero] paints the loud call-to-action variant.
class AtlasCard extends StatelessWidget {
  const AtlasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.radius = AtlasRadius.card,
    this.hero = false,
    this.dashed = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool hero;
  final bool dashed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final r = BorderRadius.circular(radius);
    final bg = color ?? (hero ? atlas.hero : atlas.card);
    final border = hero ? Colors.transparent : (borderColor ?? atlas.line);

    // A Material rather than a DecoratedBox, so list tiles inside paint their
    // ink on the card's own surface
    Widget content = Material(
      color: dashed ? Colors.transparent : bg,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );

    if (hero) {
      content = DefaultTextStyle.merge(
        style: TextStyle(color: atlas.onHero),
        child: IconTheme.merge(
          data: IconThemeData(color: atlas.onHero),
          child: content,
        ),
      );
    }

    if (onTap != null || onLongPress != null) {
      content = Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: r,
        semanticLabel: semanticLabel,
        child: content,
      );
    }

    return Padding(padding: margin, child: content);
  }
}

/// Text in Geist Mono with tabular figures, for every number that can change.
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.size,
    this.weight = FontWeight.w600,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final double? size;
  final FontWeight weight;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: AtlasText.mono(base, size: size, weight: weight, color: color),
    );
  }
}

/// The 11px uppercase label above a group of content, with an optional action.
class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow(this.text, {super.key, this.trailing, this.color, this.padding});

  final String text;
  final Widget? trailing;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final label = Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color ?? atlas.ink3,
        letterSpacing: 0.88,
      ),
    );
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: trailing == null
          ? label
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: label),
                trailing!,
              ],
            ),
    );
  }
}

enum ChipTone { neutral, brand, ok, accent, warn, inverse }

/// Pill shaped chip. [selected] flips it to the inverse (ink) fill, [tone]
/// colors a status chip. Tappable chips press like buttons.
class PillChip extends StatelessWidget {
  const PillChip(
    this.label, {
    super.key,
    this.icon,
    this.tone = ChipTone.neutral,
    this.selected = false,
    this.onTap,
    this.mono = false,
    this.height = 28,
    this.fontSize = 12,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final ChipTone tone;
  final bool selected;
  final VoidCallback? onTap;
  final bool mono;
  final double height;
  final double fontSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final scheme = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    Color? border = atlas.line;
    if (selected || tone == ChipTone.inverse) {
      bg = scheme.onSurface;
      fg = scheme.surface;
      border = scheme.onSurface;
    } else {
      switch (tone) {
        case ChipTone.brand:
          bg = atlas.brandSoft;
          fg = scheme.primary;
          border = Colors.transparent;
        case ChipTone.ok:
          bg = atlas.okSoft;
          fg = atlas.ok;
          border = Colors.transparent;
        case ChipTone.accent:
          bg = atlas.accentSoft;
          fg = atlas.accent;
          border = Colors.transparent;
        case ChipTone.warn:
          bg = atlas.warnSoft;
          fg = atlas.warn;
          border = Colors.transparent;
        case ChipTone.neutral:
        case ChipTone.inverse:
          bg = atlas.surface2;
          fg = atlas.ink2;
      }
    }

    final base = Theme.of(context).textTheme.labelMedium!.copyWith(fontSize: fontSize, color: fg);
    final textStyle = mono ? AtlasText.mono(base, weight: FontWeight.w600) : base;

    final chip = AnimatedContainer(
      duration: AtlasMotion.of(context),
      curve: AtlasMotion.curve,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 10 : 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(label, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return chip;
    }
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      borderRadius: BorderRadius.circular(AtlasRadius.pill),
      semanticLabel: semanticLabel ?? label,
      child: chip,
    );
  }
}

/// Circular progress arc, as used for the calories, the readiness score, the
/// goals and the rest timer. [value] is 0..1. The arc eases to a new value in
/// [duration]; [child] sits in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 88,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.child,
    this.duration = const Duration(milliseconds: 600),
    this.semanticLabel,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;
  final Duration duration;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    Widget ring = TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: AtlasMotion.of(context, duration),
      curve: AtlasMotion.curve,
      builder: (context, v, _) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          value: v,
          strokeWidth: strokeWidth,
          color: color ?? Theme.of(context).colorScheme.primary,
          track: trackColor ?? atlas.surface3,
        ),
      ),
    );

    ring = SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [ring, ?child]),
    );

    return semanticLabel == null
        ? ring
        : Semantics(label: semanticLabel, value: '${(target * 100).round()} %', child: ring);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.track,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arc, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * value, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}

/// A big mono number under an eyebrow, optionally with a unit, a status chip
/// and a leading icon: the "stat tile" of the dashboard and the summary.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.iconColor,
    this.chip,
    this.footer,
    this.onTap,
    this.valueSize = 28,
    this.padding = const EdgeInsets.all(14),
  });

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? iconColor;
  final Widget? chip;
  final Widget? footer;
  final VoidCallback? onTap;
  final double valueSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor ?? atlas.ink3),
                const SizedBox(width: 6),
              ],
              Expanded(child: SectionEyebrow(label)),
              ?chip,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MonoText(value, size: valueSize, color: theme.colorScheme.onSurface),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!, style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3)),
              ],
            ],
          ),
          ?footer,
        ],
      ),
    );
  }
}

/// Thin horizontal bar that eases to its fill, for macro nutrients and
/// progress. [value] is 0..1.
class AtlasBar extends StatelessWidget {
  const AtlasBar({super.key, required this.value, this.color, this.height = 6});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AtlasRadius.pill),
      child: Container(
        height: height,
        color: atlas.surface3,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: AtlasMotion.of(context, const Duration(milliseconds: 600)),
          curve: AtlasMotion.curve,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AtlasRadius.pill),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled [AtlasBar]: name on the left, "value/target" in mono on the right.
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.unit = '',
  });

  final String label;
  final num value;

  /// The goal; without one only the value is shown and the bar stays empty
  final num? target;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final goal = target;
    final frac = goal != null && goal > 0 ? value / goal : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: theme.textTheme.bodySmall, maxLines: 1)),
            const SizedBox(width: 8),
            MonoText(
              goal == null ? '${value.round()}$unit' : '${value.round()}/${goal.round()}$unit',
              size: 12,
              weight: FontWeight.w500,
              color: atlas.ink3,
            ),
          ],
        ),
        const SizedBox(height: 4),
        AtlasBar(value: frac, color: color),
      ],
    );
  }
}

/// Round leading icon holder used in list rows and cards.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.size = 44,
    this.color,
    this.background,
    this.circle = false,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? atlas.surface2,
        borderRadius: BorderRadius.circular(circle ? AtlasRadius.pill : 14),
      ),
      child: Icon(icon, size: size * 0.45, color: color ?? Theme.of(context).colorScheme.primary),
    );
  }
}

/// Fades and rises its [child] into place on first build (the design's "rise"),
/// staggered by [index]. Instant when the platform reduces motion.
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + 30 * math.min(index, 6)),
      curve: AtlasMotion.curve,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
      ),
      child: child,
    );
  }
}

/// Header row of a card: an icon badge, a title with an optional muted line
/// below and a trailing widget (a chip, a button, a chevron).
class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.iconColor,
    this.iconBackground,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Replaces the icon badge, e.g. with a font awesome icon
  final Widget? leading;
  final Widget? trailing;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atlas = context.atlas;

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          IconBadge(icon!, size: 40, color: iconColor, background: iconBackground),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleSmall, maxLines: 2),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// Round plus / minus button of a numeric stepper.
class StepButton extends StatelessWidget {
  const StepButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return IconButton(
      icon: Icon(icon),
      iconSize: size * 0.45,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: atlas.surface2,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(color: atlas.line),
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
