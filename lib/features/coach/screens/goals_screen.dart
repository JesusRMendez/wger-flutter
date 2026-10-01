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
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/models/indicators.dart';
import 'package:wger/features/coach/models/recommendations.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/features/coach/widgets/goal_form.dart';
import 'package:wger/features/measurements/screens/weight_screen.dart';
import 'package:wger/features/nutrition/screens/nutritional_plans_screen.dart';
import 'package:wger/features/routines/screens/routine_list_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

const indicatorWindows = [7, 28, 90];

String _num(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  static const routeName = '/coach-goals';

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: goalPeriods.length, vsync: this);
  int _window = 28;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _edit(CoachGoal? goal) async {
    final saved = await showGoalDialog(
      context,
      goal: goal,
      defaultPeriod: goalPeriods[_tabs.index],
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
    final period = goalPeriods[_tabs.index];
    final goals = ref.watch(coachGoalsProvider);
    final indicators = ref.watch(coachIndicatorsProvider(_window));
    final recommendations = ref.watch(planRecommendationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.coachGoalsAndIndicators),
        bottom: TabBar(
          controller: _tabs,
          tabs: [for (final p in goalPeriods) Tab(text: i18n.periodLabel(p))],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('goal-add'),
        tooltip: i18n.coachAddGoal,
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            Text(i18n.coachGoals, style: theme.textTheme.titleLarge),
            goals.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => CoachErrorView(e, onRetry: () => ref.invalidate(coachGoalsProvider)),
              data: (all) {
                final list = all.where((g) => g.period == period).toList();
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(i18n.coachNoGoals),
                  );
                }
                return Column(
                  children: [
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
            Text(i18n.coachIndicators, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const ValueKey('indicator-window'),
              segments: [
                for (final w in indicatorWindows)
                  ButtonSegment(value: w, label: Text(i18n.coachWindowDays(w))),
              ],
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
                  for (final i in data.indicators) _IndicatorTile(i),
                  if (data.dataQuality != null) _DataQualityCard(data.dataQuality!),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(i18n.coachPlanPhase, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            recommendations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => CoachErrorView(
                e,
                onRetry: () => ref.invalidate(planRecommendationsProvider),
              ),
              data: (r) => _PlanPhaseSection(r),
            ),
          ],
        ),
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
    final pct = (goal.progressPct ?? 0).round();

    final atlas = context.atlas;
    final tone = switch (goal.status) {
      'achieved' || 'done' || 'completed' => ChipTone.ok,
      'active' => ChipTone.brand,
      _ => ChipTone.neutral,
    };

    return AtlasCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(
        children: [
          ProgressRing(
            size: 64,
            strokeWidth: 7,
            value: goal.progressFraction,
            color: tone == ChipTone.ok ? atlas.ok : theme.colorScheme.primary,
            child: MonoText(i18n.coachGoalPercent(pct), size: 13),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PillChip(i18n.statusLabel(goal.status), tone: tone, height: 22, fontSize: 11),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        i18n.kindLabel(goal.kind),
                        style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (goal.targetValue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      i18n.coachGoalValues(
                        goal.currentValue == null ? '-' : _num(goal.currentValue!),
                        _num(goal.targetValue!),
                        goal.unit,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink2),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
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
        ],
      ),
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  final Indicator indicator;

  const _IndicatorTile(this.indicator);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final trend = switch (indicator.trend) {
      'up' => Icon(Icons.trending_up, color: scheme.primary, semanticLabel: 'up'),
      'down' => Icon(Icons.trending_down, color: scheme.error, semanticLabel: 'down'),
      'flat' => Icon(Icons.trending_flat, color: scheme.outline, semanticLabel: 'flat'),
      _ => null,
    };
    final unit = indicator.unit.isEmpty ? '' : ' ${indicator.unit}';

    final atlas = context.atlas;

    return AtlasCard(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.indicatorLabel(indicator.key, fallback: indicator.label),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (indicator.target != null)
                  Text(
                    i18n.coachIndicatorTarget('${_num(indicator.target!)}$unit'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  ),
              ],
            ),
          ),
          MonoText('${_num(indicator.value)}$unit', size: 17),
          if (trend != null) ...[const SizedBox(width: 8), trend],
        ],
      ),
    );
  }
}

class _DataQualityCard extends StatelessWidget {
  final DataQuality quality;

  const _DataQualityCard(this.quality);

  void _open(BuildContext context, String? action) {
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

    String? actionLabel(String? a) => switch (a) {
      'log_weight' => i18n.coachActionLogWeight,
      'log_nutrition' => i18n.coachActionLogNutrition,
      'log_rir' => i18n.coachActionLogRir,
      _ => null,
    };

    return AtlasCard(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(i18n.coachDataQuality, style: theme.textTheme.titleMedium)),
              MonoText(i18n.coachDataQualityScore(quality.score), size: 13),
            ],
          ),
          const SizedBox(height: 10),
          AtlasBar(value: (quality.score / 100).clamp(0.0, 1.0), color: context.atlas.ok),
          const SizedBox(height: 6),
          Text(
            i18n.coachDataQualityHelp,
            style: theme.textTheme.bodySmall?.copyWith(color: context.atlas.ink3),
          ),
          for (final m in quality.missing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.title),
              subtitle: Text(m.detail),
              trailing: actionLabel(m.action) == null
                  ? null
                  : TextButton(
                      onPressed: () => _open(context, m.action),
                      child: Text(actionLabel(m.action)!),
                    ),
            ),
        ],
      ),
    );
  }
}

class _PlanPhaseSection extends StatelessWidget {
  final PlanRecommendations data;

  const _PlanPhaseSection(this.data);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = data.phase?.key;

    final atlas = context.atlas;
    Color color(String severity) => switch (severity) {
      'warning' => atlas.warnSoft,
      'success' => atlas.okSoft,
      _ => atlas.brandSoft,
    };

    IconData icon(String severity) => switch (severity) {
      'warning' => Icons.warning_amber,
      'success' => Icons.check_circle_outline,
      _ => Icons.info_outline,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.week != null) Text(i18n.coachPlanWeek(data.week!)),
        const SizedBox(height: 8),
        Row(
          key: const ValueKey('phase-timeline'),
          children: [
            for (final p in planPhaseOrder)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: p == current ? theme.colorScheme.primary : atlas.surface3,
                    borderRadius: BorderRadius.circular(AtlasRadius.pill),
                  ),
                  child: Text(
                    i18n.phaseLabel(p),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: p == current
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.recommendations.isEmpty) Text(i18n.coachNoRecommendations),
        for (final r in data.recommendations)
          AtlasCard(
            margin: const EdgeInsets.only(top: 8),
            color: color(r.severity),
            borderColor: Colors.transparent,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(icon(r.severity)),
              title: Text(r.title),
              subtitle: Text(r.detail),
            ),
          ),
      ],
    );
  }
}
