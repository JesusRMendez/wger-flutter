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
import 'package:wger/features/measurements/screens/weight_screen.dart';
import 'package:wger/features/nutrition/screens/nutritional_plans_screen.dart';
import 'package:wger/features/routines/screens/routine_list_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Score card (ring, level chip) and one card per missing signal, as on the
/// "data for your coach" board. With [limit] only the first signals show.
class DataQualityView extends StatelessWidget {
  const DataQualityView(this.quality, {super.key, this.limit});

  final DataQuality quality;
  final int? limit;

  static void openAction(BuildContext context, String? action) {
    final route = switch (action) {
      'log_weight' => WeightScreen.routeName,
      'log_nutrition' => NutritionalPlansScreen.routeName,
      'log_rir' => RoutineListScreen.routeName,
      _ => null,
    };
    if (route != null) {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;

    final score = quality.score.clamp(0, 100);
    final (level, tone, color) = score < 40
        ? (i18n.coachDataLow, ChipTone.accent, atlas.accent)
        : score < 75
        ? (i18n.coachDataMedium, ChipTone.warn, atlas.warn)
        : (i18n.coachDataHigh, ChipTone.ok, atlas.ok);

    String? actionLabel(String? a) => switch (a) {
      'log_weight' => i18n.coachActionLogWeight,
      'log_nutrition' => i18n.coachActionLogNutrition,
      'log_rir' => i18n.coachActionLogRir,
      _ => null,
    };

    final missing = limit == null ? quality.missing : quality.missing.take(limit!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtlasCard(
          child: Row(
            children: [
              ProgressRing(
                size: 112,
                strokeWidth: 10,
                value: score / 100,
                color: color,
                semanticLabel: i18n.coachDataQuality,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MonoText('$score', size: 32, color: theme.colorScheme.onSurface),
                    Text(
                      i18n.coachDataQuality,
                      style: theme.textTheme.labelSmall?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.coachRecommendationAccuracy,
                      style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PillChip(level, tone: tone, height: 26),
                        const SizedBox(width: 8),
                        MonoText(
                          i18n.coachDataQualityScore(quality.score),
                          size: 13,
                          color: atlas.ink3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i18n.coachDataQualityHelp,
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (quality.missing.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              i18n.coachDataAllGood,
              style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
            ),
          ),
        for (final m in missing)
          AtlasCard(
            margin: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(m.title, style: theme.textTheme.titleMedium)),
                    const SizedBox(width: 8),
                    PillChip(i18n.coachDataToDo, tone: ChipTone.warn, height: 26),
                  ],
                ),
                if (m.detail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.info_outline, size: 16, color: atlas.ink3),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.detail,
                          style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2),
                        ),
                      ),
                    ],
                  ),
                ],
                if (actionLabel(m.action) != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => openAction(context, m.action),
                      child: Text(actionLabel(m.action)!),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
