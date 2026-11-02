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
import 'package:wger/features/coach/models/recommendations.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The phases of the plan as a progress strip and a vertical timeline: done
/// phases, the current one with its recommendations and the ones to come.
class PhaseTimeline extends StatelessWidget {
  const PhaseTimeline(this.data, {super.key});

  final PlanRecommendations data;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final current = data.phase?.key;
    final currentIndex = planPhaseOrder.indexOf(current ?? '');

    String hint(String key) => switch (key) {
      'adaptation' => i18n.coachPhaseAdaptationHint,
      'progression' => i18n.coachPhaseProgressionHint,
      'deload' => i18n.coachPhaseDeloadHint,
      _ => i18n.coachPhaseConsolidationHint,
    };

    IconData severityIcon(String s) => switch (s) {
      'warning' => Icons.warning_amber,
      'success' => Icons.check_circle_outline,
      _ => Icons.info_outline,
    };
    Color severityColor(String s) => switch (s) {
      'warning' => atlas.warn,
      'success' => atlas.ok,
      _ => theme.colorScheme.primary,
    };

    Color stateColor(int i) => i < currentIndex
        ? atlas.ok
        : i == currentIndex
        ? theme.colorScheme.primary
        : atlas.surface3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionEyebrow(i18n.coachYouAreHere),
                  if (data.week != null)
                    PillChip(i18n.coachPlanWeek(data.week!), tone: ChipTone.brand, height: 28),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                key: const ValueKey('phase-timeline'),
                spacing: 6,
                children: [
                  for (var i = 0; i < planPhaseOrder.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: AtlasMotion.of(context),
                        height: 6,
                        decoration: BoxDecoration(
                          color: stateColor(i),
                          borderRadius: BorderRadius.circular(AtlasRadius.pill),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < planPhaseOrder.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: i <= currentIndex ? stateColor(i) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: i <= currentIndex
                              ? null
                              : Border.all(color: atlas.line2, width: 2),
                        ),
                      ),
                      if (i < planPhaseOrder.length - 1)
                        Expanded(child: Container(width: 2, color: atlas.line2)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (i == currentIndex &&
                                        data.phase?.weekFrom != null &&
                                        data.phase?.weekTo != null)
                                      MonoText(
                                        i18n.coachPhaseWeeks(
                                          data.phase!.weekFrom!,
                                          data.phase!.weekTo!,
                                        ),
                                        size: 12.5,
                                        weight: FontWeight.w500,
                                        color: atlas.ink3,
                                      ),
                                    Text(
                                      i18n.phaseLabel(planPhaseOrder[i]),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              if (currentIndex >= 0)
                                PillChip(
                                  i < currentIndex
                                      ? i18n.coachPhaseDone
                                      : i == currentIndex
                                      ? i18n.coachPhaseNow
                                      : i18n.coachPhaseUpcoming,
                                  tone: i < currentIndex
                                      ? ChipTone.ok
                                      : i == currentIndex
                                      ? ChipTone.brand
                                      : ChipTone.neutral,
                                  height: 26,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hint(planPhaseOrder[i]),
                            style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2),
                          ),
                          if (i == currentIndex) ...[
                            if (data.recommendations.isEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                i18n.coachNoRecommendations,
                                style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                              ),
                            ],
                            for (final r in data.recommendations) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Divider(height: 1, color: atlas.line),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    severityIcon(r.severity),
                                    size: 18,
                                    color: severityColor(r.severity),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.title,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (r.detail.isNotEmpty)
                                          Text(
                                            r.detail,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: atlas.ink2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
