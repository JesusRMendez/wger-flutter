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
import 'package:wger/core/i18n.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';
import 'package:wger/features/locations/screens/locations_screen.dart';
import 'package:wger/features/routines/logic/time_budget.dart';
import 'package:wger/features/routines/logic/zone_order_logic.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Name of the exercise with the given id in the current workout, if any
String? _exerciseName(GymModeState state, int exerciseId, String languageCode) {
  for (final page in state.pages) {
    for (final Exercise e in page.exercises) {
      if (e.id == exerciseId) {
        return e.getTranslation(languageCode).name;
      }
    }
  }
  return null;
}

String _pageName(PageEntry page, String languageCode) =>
    page.exercises.map((e) => e.getTranslation(languageCode).name).join(' / ');

/// Planning options on the start page: training location, order by zone and
/// the time budget.
class GymPlanningCard extends ConsumerStatefulWidget {
  const GymPlanningCard({super.key});

  @override
  ConsumerState<GymPlanningCard> createState() => _GymPlanningCardState();
}

class _GymPlanningCardState extends ConsumerState<GymPlanningCard> {
  bool _defaultApplied = false;

  /// Preselects the default location the first time the locations are known
  void _applyDefault(List<TrainingLocation> locations) {
    if (_defaultApplied) {
      return;
    }
    _defaultApplied = true;

    final notifier = ref.read(gymStateProvider.notifier);
    final state = ref.read(gymStateProvider);
    if (state.zoneOrder != null) {
      return;
    }

    final selected = locations.where((l) => l.id == state.locationId).firstOrNull;
    final location = selected ?? locations.where((l) => l.isDefault).firstOrNull;
    if (location != null) {
      notifier.setLocationId(location.id);
    }
    // Without a selection the server uses the default location
    Future(() => notifier.loadZoneOrder());
  }

  Future<void> _select(int? id) async {
    final notifier = ref.read(gymStateProvider.notifier);
    notifier.setLocationId(id);
    await notifier.loadZoneOrder();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final state = ref.watch(gymStateProvider);
    final notifier = ref.read(gymStateProvider.notifier);
    final locationsAsync = ref.watch(trainingLocationsProvider);
    final locations = locationsAsync.value ?? const <TrainingLocation>[];

    if (locationsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyDefault(locations);
        }
      });
    }

    final location = locations.where((l) => l.id == state.locationId).firstOrNull;
    final order = state.zoneOrder;
    final currentChanges = order == null ? null : currentZoneChanges(state.pages, order);

    final items = notifier.budgetItems();
    final budgetChoices = timeBudgetChoices(locationMinutes: location?.availableMinutes);
    final budget = state.timeBudgetMinutes;
    final suggestion = budget == null ? null : suggestSetsToDrop(items, budget);
    final estimatedMinutes = (estimateDurationSeconds(items) / 60).ceil();

    return Card(
      key: const ValueKey('gym-planning-card'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (locations.isNotEmpty)
              DropdownButtonFormField<int?>(
                key: const ValueKey('gym-location-dropdown'),
                initialValue: location?.id,
                decoration: InputDecoration(labelText: i18n.locationsTitle),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(i18n.gymModeNoLocation)),
                  for (final l in locations)
                    DropdownMenuItem<int?>(value: l.id, child: Text(l.name)),
                ],
                onChanged: _select,
              )
            else if (locationsAsync.hasValue)
              ListTile(
                key: const ValueKey('gym-set-up-locations'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(i18n.gymModeSetUpLocations),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LocationsScreen()),
                ),
              ),

            if (order != null && order.hasZones) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      i18n.gymModeZoneChanges(
                        currentChanges ?? order.zoneChangesPlanned,
                        order.zoneChangesSuggested,
                      ),
                      key: const ValueKey('zone-changes-text'),
                    ),
                  ),
                  FilledButton.tonal(
                    key: const ValueKey('order-by-zone-button'),
                    onPressed: (currentChanges ?? 0) > order.zoneChangesSuggested
                        ? () {
                            final changed = notifier.orderByZone();
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    changed
                                        ? i18n.gymModeOrderedByZone
                                        : i18n.gymModeAlreadyOrdered,
                                  ),
                                ),
                              );
                          }
                        : null,
                    child: Text(i18n.gymModeOrderByZone),
                  ),
                ],
              ),
            ],

            if (order != null && order.missingEquipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                key: const ValueKey('missing-equipment-warning'),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            i18n.gymModeMissingEquipment(order.locationName ?? ''),
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                    for (final missing in order.missingEquipment)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 2),
                        child: Text(
                          '${_exerciseName(state, missing.exerciseId, languageCode) ?? '#${missing.exerciseId}'}: '
                          '${missing.equipment.values.map((n) => getServerStringTranslation(n, context)).join(', ')}',
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Text(i18n.gymModeTimeBudget, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final minutes in budgetChoices)
                  ChoiceChip(
                    key: ValueKey('time-budget-$minutes'),
                    label: Text(i18n.locationsMinutesValue(minutes)),
                    selected: budget == minutes,
                    onSelected: (selected) => notifier.setTimeBudget(selected ? minutes : null),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              i18n.gymModeEstimatedDuration(estimatedMinutes),
              key: const ValueKey('estimated-duration'),
              style: theme.textTheme.bodySmall,
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 4),
              if (suggestion.fitsAlready)
                Text(i18n.gymModeFitsBudget, key: const ValueKey('budget-fits'))
              else ...[
                Text(
                  suggestion.fitsAfter
                      ? i18n.gymModeDropSetsSuggestion(
                          suggestion.totalDropped,
                          (suggestion.estimatedAfterSeconds / 60).ceil(),
                        )
                      : i18n.gymModeDropSetsNotEnough(
                          suggestion.totalDropped,
                          (suggestion.estimatedAfterSeconds / 60).ceil(),
                        ),
                  key: const ValueKey('budget-suggestion'),
                ),
                for (final entry in suggestion.drops.entries)
                  Builder(
                    builder: (context) {
                      final page = state.pages.where((p) => p.uuid == entry.key).firstOrNull;
                      return Text(
                        '- ${page == null ? '' : _pageName(page, languageCode)}: -${entry.value}',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                if (suggestion.totalDropped > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      key: const ValueKey('apply-time-budget'),
                      onPressed: () {
                        notifier.applyBudgetDrops(suggestion.drops);
                      },
                      child: Text(i18n.gymModeApplySuggestion),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
