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
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/snackbar.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/coach/models/workout_proposal.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/providers/coach_repository.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/features/coach/widgets/workout_proposal_view.dart';
import 'package:wger/features/locations/screens/locations_screen.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/routine_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// How long to wait for a freshly created routine to arrive through the sync
/// before opening it anyway. Tests set this to zero.
@visibleForTesting
Duration routineSyncTimeout = const Duration(seconds: 8);

class WorkoutPlanScreen extends ConsumerStatefulWidget {
  const WorkoutPlanScreen({super.key});

  static const routeName = '/coach-workout-plan';

  @override
  ConsumerState<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends ConsumerState<WorkoutPlanScreen> {
  static const _minuteChoices = [20, 30, 45, 60, 75, 90, 120];

  int _days = 3;
  int _minutes = 60;
  int? _locationId;
  int? _goalId;
  final _notes = TextEditingController();
  bool _applying = false;
  Object? _applyError;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() => _applyError = null);
    ref
        .read(workoutPlanGeneratorProvider.notifier)
        .generate(
          WorkoutPlanRequest(
            goalId: _goalId,
            daysPerWeek: _days,
            minutesPerSession: _minutes,
            locationId: _locationId,
            notes: _notes.text,
          ),
        );
  }

  /// Waits until the routine shows up in the local (synced) list. Polls the
  /// current state rather than awaiting the provider's future, which stays
  /// pending while the stream is being rebuilt.
  Future<void> _waitForRoutine(int id) async {
    final deadline = DateTime.now().add(routineSyncTimeout);
    while (true) {
      final state = ref.read(routinesRiverpodProvider).value;
      if (state?.findByIdOrNull(id) != null || !DateTime.now().isBefore(deadline)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _apply(WorkoutProposal proposal) async {
    setState(() {
      _applying = true;
      _applyError = null;
    });
    try {
      final id = await ref.read(coachRepositoryProvider).applyWorkoutPlan(proposal);

      ref.invalidate(routinesRiverpodProvider);
      await _waitForRoutine(id);

      try {
        await ref.read(routinesRiverpodProvider.notifier).fetchAndSetRoutineFull(id);
      } catch (_) {
        // The detail screen still opens, it just shows what is available
      }

      if (!mounted) {
        return;
      }
      showSnackbar(context, AppLocalizations.of(context).coachPlanApplied);
      ref.read(workoutPlanGeneratorProvider.notifier).reset();
      unawaited(Navigator.of(context).pushNamed(RoutineScreen.routeName, arguments: id));
    } catch (e) {
      if (mounted) {
        setState(() => _applyError = e);
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final generated = ref.watch(workoutPlanGeneratorProvider);
    final locations = ref.watch(coachLocationsProvider).value ?? const [];
    final goals = ref.watch(coachGoalsProvider).value ?? const [];

    final theme = Theme.of(context);
    final atlas = context.atlas;
    final activeGoals = goals.where((g) => g.status == 'active').toList();
    // The goals of the plan by horizon: the final one, then the monthly and weekly ones
    final summary = [
      for (final period in ['plan', 'monthly', 'weekly'])
        for (final g in activeGoals.where((g) => g.period == period).take(1)) (period, g),
    ];

    return Scaffold(
      body: WidescreenWrapper(
        child: Column(
          children: [
            AtlasHeader(
              title: i18n.coachWorkoutPlan,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (goals.isNotEmpty) ...[
                    AtlasCard(
                      key: const ValueKey('wp-goal'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionEyebrow(i18n.coachGoal),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              PillChip(
                                i18n.coachGoalNone,
                                height: 40,
                                fontSize: 14,
                                selected: _goalId == null,
                                onTap: () => setState(() => _goalId = null),
                              ),
                              for (final g in goals)
                                PillChip(
                                  g.title,
                                  height: 40,
                                  fontSize: 14,
                                  selected: _goalId == g.id,
                                  onTap: () => setState(() => _goalId = g.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AtlasCard(
                    key: const ValueKey('wp-schedule'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionEyebrow(
                          i18n.coachMinutesPerSession,
                          trailing: MonoText(
                            '$_minutes min',
                            key: const ValueKey('wp-minutes-value'),
                            size: 18,
                          ),
                        ),
                        Slider(
                          key: const ValueKey('wp-minutes'),
                          value: _minuteChoices.indexOf(_minutes).toDouble(),
                          min: 0,
                          max: _minuteChoices.length - 1.0,
                          divisions: _minuteChoices.length - 1,
                          label: '$_minutes',
                          onChanged: (v) => setState(() => _minutes = _minuteChoices[v.round()]),
                        ),
                        const SizedBox(height: 4),
                        SectionEyebrow(i18n.coachDaysPerWeek),
                        const SizedBox(height: 8),
                        Wrap(
                          key: const ValueKey('wp-days'),
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var d = 1; d <= 7; d++)
                              PillChip(
                                '$d',
                                key: ValueKey('wp-days-$d'),
                                mono: true,
                                height: 44,
                                fontSize: 15,
                                selected: _days == d,
                                onTap: () => setState(() => _days = d),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (locations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionEyebrow(
                            i18n.coachLocation,
                            trailing: GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushNamed(LocationsScreen.routeName),
                              child: Text(
                                i18n.coachEditEquipment,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<int?>(
                              key: const ValueKey('wp-location'),
                              showSelectedIcon: false,
                              emptySelectionAllowed: false,
                              segments: [
                                ButtonSegment<int?>(
                                  value: null,
                                  label: Text(i18n.coachLocationNone, maxLines: 1),
                                ),
                                for (final l in locations)
                                  ButtonSegment<int?>(
                                    value: l.id,
                                    label: Text(
                                      l.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              selected: {_locationId},
                              onSelectionChanged: (sel) => setState(() {
                                final v = sel.first;
                                _locationId = v;
                                final minutes = locations
                                    .where((l) => l.id == v)
                                    .firstOrNull
                                    ?.availableMinutes;
                                if (minutes != null) {
                                  _minutes = _minuteChoices.reduce(
                                    (a, b) => (a - minutes).abs() <= (b - minutes).abs() ? a : b,
                                  );
                                }
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AtlasCard(
                      onTap: () => Navigator.of(context).pushNamed(GoalsScreen.routeName),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionEyebrow(
                            i18n.coachPlanGoals,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  i18n.coachGoalsAndIndicators,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final (period, g) in summary)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 88,
                                    child: PillChip(
                                      i18n.periodLabel(period),
                                      height: 26,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      g.title,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: atlas.ink2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('wp-notes'),
                    controller: _notes,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: i18n.notes),
                  ),
                  const SizedBox(height: 16),
                  if (generated.isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(i18n.coachGenerating),
                      ],
                    ),
                  if (generated.hasError) CoachErrorView(generated.error!, onRetry: _generate),
                  if (_applyError != null) CoachErrorView(_applyError!),
                  if (generated.value != null) ...[
                    WorkoutProposalView(generated.value!),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const ValueKey('wp-apply'),
                      onPressed: _applying ? null : () => _apply(generated.value!),
                      child: _applying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(i18n.coachApply),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    key: const ValueKey('wp-generate'),
                    onPressed: generated.isLoading || _applying ? null : _generate,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(i18n.coachGenerate),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
