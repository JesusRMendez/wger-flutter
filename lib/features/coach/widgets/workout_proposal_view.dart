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
import 'package:wger/features/coach/models/workout_proposal.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Preview of a proposed workout plan
class WorkoutProposalView extends ConsumerWidget {
  final WorkoutProposal proposal;

  const WorkoutProposalView(this.proposal, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repUnits = {
      for (final u in ref.watch(routineRepetitionUnitProvider).value ?? []) u.id: u.name,
    };
    final weightUnits = {
      for (final u in ref.watch(routineWeightUnitProvider).value ?? []) u.id: u.name,
    };

    String format(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

    String volume(ProposalExercise e) {
      final unit = repUnits[e.repetitionUnitId];
      final reps = e.reps == null ? '' : ' × ${format(e.reps!)}';
      final unitText = unit == null ? '' : ' $unit';
      final weight = e.weight == null
          ? ''
          : ' @ ${format(e.weight!)}${weightUnits[e.weightUnitId] == null ? '' : ' ${weightUnits[e.weightUnitId]}'}';
      return '${e.sets}$reps$unitText$weight';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(proposal.name, style: theme.textTheme.titleLarge),
        if (proposal.weeks != null) Text(i18n.coachPlanWeeks(proposal.weeks!)),
        if (proposal.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(proposal.description),
        ],
        const SizedBox(height: 8),
        for (final day in proposal.days)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.name, style: theme.textTheme.titleMedium),
                  for (final e in day.exercises)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(volume(e)),
                            ],
                          ),
                          Wrap(
                            spacing: 12,
                            children: [
                              if (e.restSeconds != null)
                                Text(
                                  i18n.coachRestSeconds(e.restSeconds!),
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (e.zone != null && e.zone!.isNotEmpty)
                                Text(
                                  i18n.coachZoneValue(e.zone!),
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          if (e.why != null && e.why!.isNotEmpty)
                            Text(
                              e.why!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (proposal.orderRationale.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i18n.coachWhyOrder, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(proposal.orderRationale),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
