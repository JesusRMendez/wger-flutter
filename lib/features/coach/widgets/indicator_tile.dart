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
import 'package:wger/features/coach/models/indicators.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// A number without trailing zeros: 3.5, 12400
String formatNum(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// One indicator of the coach: name, target, the value in mono and its trend.
class IndicatorTile extends StatelessWidget {
  const IndicatorTile(this.indicator, {super.key});

  final Indicator indicator;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;

    final (trendIcon, trendColor, trendBg) = switch (indicator.trend) {
      'up' => (Icons.trending_up, atlas.ok, atlas.okSoft),
      'down' => (Icons.trending_down, atlas.accent, atlas.accentSoft),
      'flat' => (Icons.trending_flat, atlas.ink3, atlas.surface2),
      _ => (null, atlas.ink3, atlas.surface2),
    };
    final unit = indicator.unit.isEmpty ? '' : ' ${indicator.unit}';
    final target = indicator.target;
    final frac = target != null && target > 0 ? indicator.value / target : null;

    return AtlasCard(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.indicatorLabel(indicator.key, fallback: indicator.label),
                      style: theme.textTheme.titleSmall,
                    ),
                    if (target != null)
                      Text(
                        i18n.coachIndicatorTarget('${formatNum(target)}$unit'),
                        style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                      ),
                  ],
                ),
              ),
              MonoText('${formatNum(indicator.value)}$unit', size: 17),
              if (trendIcon != null) ...[
                const SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: trendBg, shape: BoxShape.circle),
                  child: Icon(
                    trendIcon,
                    size: 18,
                    color: trendColor,
                    semanticLabel: indicator.trend,
                  ),
                ),
              ],
            ],
          ),
          if (frac != null) ...[
            const SizedBox(height: 10),
            AtlasBar(value: frac, color: frac >= 0.8 ? atlas.ok : atlas.warn, height: 5),
          ],
        ],
      ),
    );
  }
}
