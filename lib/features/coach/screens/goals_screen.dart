/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
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
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/screens/data_quality_screen.dart';
import 'package:wger/features/coach/screens/follow_up_screen.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/features/coach/widgets/data_quality_view.dart';
import 'package:wger/features/coach/widgets/goal_form.dart';
import 'package:wger/features/coach/widgets/indicator_tile.dart';
import 'package:wger/features/coach/widgets/phase_timeline.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

const indicatorWindows = [7, 28, 90];

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  static const routeName = '/coach-goals';

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int _period = 0;
  int _window = 28;

  Future<void> _edit(CoachGoal? goal) async {
    final saved = await showGoalDialog(
      context,
      goal: goal,
      defaultPeriod: goalPeriods[_period],
    );
    if (saved == null) {
      return;
    }
    final notifier = ref.read(coachGoalsProvider.notifier);
    try {
      if (saved.id == null) {
        await notifier.addGoal(saved);
      } else {
        await notifier.editGoal(saved);
      }
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(content: CoachErrorView(e)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final period = goalPeriods[_period];
    final goals = ref.watch(coachGoalsProvider);
    final indicators = ref.watch(coachIndicatorsProvider(_window));
    final recommendations = ref.watch(planRecommendationsProvider);
    final theme = Theme.of(context);
    final atlas = context.atlas;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('goal-add'),
        tooltip: i18n.coachAddGoal,
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            AtlasHeader(
              title: i18n.coachGoalsAndIndicators,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              actions: [
                RoundIconButton(
                  icon: Icons.insights,
                  tooltip: i18n.coachFollowUp,
                  onPressed: () => Navigator.of(context).pushNamed(FollowUpScreen.routeName),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (var i = 0; i < goalPeriods.length; i++)
                    ButtonSegment(value: i, label: Text(i18n.periodLabel(goalPeriods[i]))),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
            ),
            const SizedBox(height: 16),
            goals.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => CoachErrorView(e, onRetry: () => ref.invalidate(coachGoalsProvider)),
              data: (all) {
                final list = all.where((g) => g.period == period).toList();
                final finalGoal = all
                    .where((g) => g.period == 'plan' && g.status == 'active')
                    .firstOrNull;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (finalGoal != null) _FinalGoalCard(finalGoal),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(i18n.coachGoals, style: theme.textTheme.titleLarge),
                          Text(
                            i18n.periodLabel(period),
                            style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                          ),
                        ],
                      ),
                    ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(i18n.coachNoGoals),
                      ),
                    for (final g in list)
                      _GoalCard(
                        g,
                        onEdit: () => _edit(g),
                        onDelete: () => showConfirmDeleteDialog(
                          context,
                          itemName: g.title,
                          onConfirm: () => ref.read(coachGoalsProvider.notifier).deleteGoal(g.id!),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(i18n.coachIndicators, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const ValueKey('indicator-window'),
              segments: [
                for (final w in indicatorWindows)
                  ButtonSegment(value: w, label: Text(i18n.coachWindowDays(w))),
              ],
              showSelectedIcon: false,
              selected: {_window},
              onSelectionChanged: (s) => setState(() => _window = s.first),
            ),
            const SizedBox(height: 8),
            indicators.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => CoachErrorView(
                e,
                onRetry: () => ref.invalidate(coachIndicatorsProvider(_window)),
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.indicators.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(i18n.coachNoIndicators),
                    ),
                  for (final i in data.indicators) IndicatorTile(i),
                  if (data.dataQuality != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(i18n.coachDataTitle, style: theme.textTheme.titleLarge),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed(DataQualityScreen.routeName),
                          child: Text(i18n.coachDataSeeAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    DataQualityView(data.dataQuality!, limit: 2),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(i18n.coachPlanPhase, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            recommendations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => CoachErrorView(
                e,
                onRetry: () => ref.invalidate(planRecommendationsProvider),
              ),
              data: (r) => PhaseTimeline(r),
            ),
          ],
        ),
      ),
    );
  }
}

/// How a goal is doing: achieved, or active ahead of (on track) or behind
/// (watch) the share of its period that has gone by.
enum GoalHealth { achieved, onTrack, watch, missed, paused }

GoalHealth goalHealth(CoachGoal g) {
  switch (g.status) {
    case 'achieved' || 'done' || 'completed':
      return GoalHealth.achieved;
    case 'missed':
      return GoalHealth.missed;
    case 'paused':
      return GoalHealth.paused;
  }
  final pct = (g.progressPct ?? 0).toDouble();
  final start = DateTime.tryParse(g.startDate ?? '');
  final end = DateTime.tryParse(g.endDate ?? '');
  if (start != null && end != null && end.isAfter(start)) {
    final elapsed = (DateTime.now().difference(start).inHours / end.difference(start).inHours)
        .clamp(0.0, 1.0);
    return pct >= elapsed * 100 * 0.8 ? GoalHealth.onTrack : GoalHealth.watch;
  }
  return pct >= 40 ? GoalHealth.onTrack : GoalHealth.watch;
}

class _FinalGoalCard extends StatelessWidget {
  final CoachGoal goal;

  const _FinalGoalCard(this.goal);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final pct = (goal.progressPct ?? 0).round();

    return AtlasCard(
      hero: true,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionEyebrow(i18n.coachFinalGoal, color: atlas.onHero.withValues(alpha: 0.65)),
              MonoText(i18n.coachGoalPercent(pct), size: 14, color: atlas.onHero),
            ],
          ),
          const SizedBox(height: 10),
          Text(goal.title, style: theme.textTheme.headlineMedium?.copyWith(color: atlas.onHero)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AtlasRadius.pill),
            child: LinearProgressIndicator(
              value: goal.progressFraction,
              minHeight: 8,
              color: atlas.onHero,
              backgroundColor: atlas.onHero.withValues(alpha: 0.2),
            ),
          ),
          if (goal.targetValue != null) ...[
            const SizedBox(height: 12),
            Text(
              i18n.coachGoalValues(
                goal.currentValue == null ? '-' : formatNum(goal.currentValue!),
                formatNum(goal.targetValue!),
                goal.unit,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: atlas.onHero.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final CoachGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard(this.goal, {required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final pct = (goal.progressPct ?? 0).round();
    final health = goalHealth(goal);

    final (label, tone, color) = switch (health) {
      GoalHealth.achieved => (i18n.coachStatusAchieved, ChipTone.ok, atlas.ok),
      GoalHealth.onTrack => (i18n.coachGoalOnTrack, ChipTone.ok, atlas.ok),
      GoalHealth.watch => (i18n.coachGoalWatch, ChipTone.warn, atlas.warn),
      GoalHealth.missed => (i18n.coachStatusMissed, ChipTone.accent, atlas.accent),
      GoalHealth.paused => (i18n.coachStatusPaused, ChipTone.neutral, atlas.ink3),
    };

    return AtlasCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: theme.textTheme.titleMedium),
                    Text(
                      i18n.kindLabel(goal.kind),
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
              PillChip(label, tone: tone, height: 26),
              IconButton(
                tooltip: i18n.edit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: i18n.delete,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: AtlasBar(value: goal.progressFraction, color: color, height: 7),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (goal.targetValue != null)
                  MonoText(
                    i18n.coachGoalValues(
                      goal.currentValue == null ? '-' : formatNum(goal.currentValue!),
                      formatNum(goal.targetValue!),
                      goal.unit,
                    ),
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: atlas.ink3,
                  )
                else
                  const SizedBox.shrink(),
                MonoText(i18n.coachGoalPercent(pct), size: 12.5, color: atlas.ink2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
