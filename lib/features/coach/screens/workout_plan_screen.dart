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
import 'package:wger/features/coach/models/workout_proposal.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/providers/coach_repository.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/workout_proposal_view.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/routine_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(i18n.coachWorkoutPlan)),
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
              DropdownButtonFormField<int?>(
                key: const ValueKey('wp-location'),
                initialValue: _locationId,
                decoration: InputDecoration(labelText: i18n.coachLocation),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(i18n.coachLocationNone)),
                  for (final l in locations)
                    DropdownMenuItem<int?>(value: l.id, child: Text(l.name)),
                ],
                onChanged: (v) => setState(() {
                  _locationId = v;
                  final minutes = locations.where((l) => l.id == v).firstOrNull?.availableMinutes;
                  if (minutes != null) {
                    _minutes = _minuteChoices.reduce(
                      (a, b) => (a - minutes).abs() <= (b - minutes).abs() ? a : b,
                    );
                  }
                }),
              ),
            ],
            if (goals.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                key: const ValueKey('wp-goal'),
                initialValue: _goalId,
                decoration: InputDecoration(labelText: i18n.coachGoal),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(i18n.coachGoalNone)),
                  for (final g in goals) DropdownMenuItem<int?>(value: g.id, child: Text(g.title)),
                ],
                onChanged: (v) => setState(() => _goalId = v),
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
            FilledButton.icon(
              key: const ValueKey('wp-generate'),
              onPressed: generated.isLoading || _applying ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: Text(i18n.coachGenerate),
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
    );
  }
}
