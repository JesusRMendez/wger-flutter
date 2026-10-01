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
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/theme/atlas.dart';

/// Building blocks shared by the nutrition, progress and coach screens of the
/// "wger Atlas" design that the base atlas widgets do not cover.

/// 44px round button with a 1px border, as in the header of the board screens.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final button = Pressable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AtlasRadius.pill),
      scale: 0.94,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: atlas.card,
          shape: BoxShape.circle,
          border: Border.all(color: atlas.line),
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
    return Semantics(
      label: tooltip,
      button: true,
      child: tooltip == null ? button : Tooltip(message: tooltip, child: button),
    );
  }
}

/// Header of a full screen: an optional round back button, a title with a muted
/// line above it (the eyebrow) and round action buttons on the right.
class AtlasHeader extends StatelessWidget {
  const AtlasHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.centered = false,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  /// Title in the middle between the buttons (the small page header variant)
  final bool centered;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final canPop = showBack && (ModalRoute.of(context)?.canPop ?? false);

    final titleColumn = Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null)
          Text(
            eyebrow!,
            style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          title,
          style: centered ? theme.textTheme.titleMedium : theme.textTheme.headlineLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (canPop) ...[
              RoundIconButton(
                icon: Icons.chevron_left,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: titleColumn),
            for (final a in actions) ...[const SizedBox(width: 8), a],
          ],
        ),
      ),
    );
  }
}

/// A rounded tile with a mono value and a label with a colored dot, e.g.
/// "11.5 / protein", used for macro nutrients.
class MacroTile extends StatelessWidget {
  const MacroTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.unit = '',
  });

  final String value;
  final String label;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: atlas.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MonoText('$value$unit', size: 18, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal bar split in coloured segments proportional to [values]
/// (protein, carbs, fat share of the calories).
class SplitBar extends StatelessWidget {
  const SplitBar({super.key, required this.values, required this.colors, this.height = 8});

  final List<double> values;
  final List<Color> colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final atlas = context.atlas;
    if (total <= 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: atlas.surface3,
          borderRadius: BorderRadius.circular(AtlasRadius.pill),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AtlasRadius.pill),
      child: SizedBox(
        height: height,
        child: Row(
          spacing: 3,
          children: [
            for (var i = 0; i < values.length; i++)
              if (values[i] > 0)
                Expanded(
                  flex: (values[i] / total * 1000).round().clamp(1, 1000),
                  child: ColoredBox(color: colors[i]),
                ),
          ],
        ),
      ),
    );
  }
}

/// Round check button of a list row: filled green when [checked].
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.checked, this.onTap, this.semanticLabel});

  final bool checked;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      borderRadius: BorderRadius.circular(14),
      semanticLabel: semanticLabel,
      child: AnimatedContainer(
        duration: AtlasMotion.of(context),
        curve: AtlasMotion.curve,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: checked ? atlas.ok : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: checked ? atlas.ok : atlas.line2),
        ),
        child: Icon(
          Icons.check,
          size: 18,
          color: checked ? atlas.onHero : atlas.ink3,
        ),
      ),
    );
  }
}
