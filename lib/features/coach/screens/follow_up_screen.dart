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
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/coach/models/indicators.dart';
import 'package:wger/features/coach/models/recommendations.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/screens/data_quality_screen.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/features/coach/widgets/data_quality_view.dart';
import 'package:wger/features/coach/widgets/indicator_tile.dart';
import 'package:wger/features/routines/screens/routine_list_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Weekly review built from the coach endpoints: where you stand in the plan,
/// the indicators with their trends, the recommended adjustments and how
/// reliable they are (data quality).
class FollowUpScreen extends ConsumerStatefulWidget {
  const FollowUpScreen({super.key});

  static const routeName = '/coach-follow-up';

  @override
  ConsumerState<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends ConsumerState<FollowUpScreen> {
  int _window = 7;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final indicators = ref.watch(coachIndicatorsProvider(_window));
    final recommendations = ref.watch(planRecommendationsProvider);

    final recs = recommendations.value;
    final inds = indicators.value;

    final needsAttention =
        (recs?.recommendations.any((r) => r.severity == 'warning') ?? false) ||
        (inds?.indicators.any(
              (i) => i.target != null && i.target! > 0 && i.value < i.target! * 0.8,
            ) ??
            false);

    Widget hero() {
      final phase = recs?.phase;
      final eyebrow = recs?.week == null
          ? i18n.coachFollowUp
          : i18n.coachFollowUpWeekPhase(
              recs!.week!,
              phase == null ? '' : i18n.phaseLabel(phase.key, fallback: phase.name),
            );
      // Up to three indicators with a target, else the first ones
      final all = inds?.indicators ?? const <Indicator>[];
      final withTarget = all.where((i) => i.target != null).toList();
      final tiles = (withTarget.length >= 3 ? withTarget : all).take(3).toList();

      return AtlasCard(
        hero: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionEyebrow(eyebrow, color: atlas.onHero.withValues(alpha: 0.65)),
            const SizedBox(height: 10),
            Text(
              needsAttention ? i18n.coachFollowUpAttention : i18n.coachFollowUpOnPlan,
              style: theme.textTheme.headlineMedium?.copyWith(color: atlas.onHero),
            ),
            if (tiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                spacing: 10,
                children: [
                  for (final t in tiles)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: atlas.onHero.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: MonoText(
                                t.target == null
                                    ? formatNum(t.value)
                                    : '${formatNum(t.value)}/${formatNum(t.target!)}',
                                size: 22,
                                color: atlas.onHero,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              i18n.indicatorLabel(t.key, fallback: t.label),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: atlas.onHero.withValues(alpha: 0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    Widget recommendationCard(Recommendation r) {
      final (icon, color, bg) = switch (r.severity) {
        'warning' => (Icons.warning_amber, atlas.warn, atlas.warnSoft),
        'success' => (Icons.check_circle_outline, atlas.ok, atlas.okSoft),
        _ => (Icons.info_outline, theme.colorScheme.primary, atlas.brandSoft),
      };
      return AtlasCard(
        margin: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: theme.textTheme.titleSmall),
                      if (r.detail.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            r.detail,
                            style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (r.action == 'open_routine') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pushNamed(RoutineListScreen.routeName),
                  child: Text(i18n.coachFollowUpOpenRoutine),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            AtlasHeader(
              title: i18n.coachFollowUp,
              subtitle: i18n.coachFollowUpSubtitle(_window),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              actions: [
                RoundIconButton(
                  icon: Icons.flag_outlined,
                  tooltip: i18n.coachGoalsAndIndicators,
                  onPressed: () => Navigator.of(context).pushNamed(GoalsScreen.routeName),
                ),
              ],
            ),
            SegmentedButton<int>(
              key: const ValueKey('followup-window'),
              showSelectedIcon: false,
              segments: [
                for (final w in indicatorWindows)
                  ButtonSegment(value: w, label: Text(i18n.coachWindowDays(w))),
              ],
              selected: {_window},
              onSelectionChanged: (s) => setState(() => _window = s.first),
            ),
            const SizedBox(height: 12),
            if (indicators.isLoading && recommendations.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (indicators.hasError && inds == null)
              CoachErrorView(
                indicators.error!,
                onRetry: () => ref.invalidate(coachIndicatorsProvider(_window)),
              ),
            if (inds != null || recs != null) hero(),
            if (recommendations.hasError && recs == null)
              CoachErrorView(
                recommendations.error!,
                onRetry: () => ref.invalidate(planRecommendationsProvider),
              ),
            if (recs != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(i18n.coachFollowUpAdjustments, style: theme.textTheme.titleLarge),
                    Text(
                      i18n.coachFollowUpPending(recs.recommendations.length),
                      style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
              if (recs.recommendations.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Text(
                    recs.routine == null ? i18n.coachFollowUpNone : i18n.coachNoRecommendations,
                    style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                  ),
                ),
              for (final r in recs.recommendations) recommendationCard(r),
            ],
            if (inds != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
                child: Text(i18n.coachFollowUpIndicators, style: theme.textTheme.titleLarge),
              ),
              if (inds.indicators.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Text(
                    i18n.coachNoIndicators,
                    style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                  ),
                ),
              for (final i in inds.indicators) IndicatorTile(i),
              if (inds.dataQuality != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 24, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(i18n.coachDataTitle, style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(DataQualityScreen.routeName),
                        child: Text(i18n.coachDataSeeAll),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                DataQualityView(inds.dataQuality!, limit: 2),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
