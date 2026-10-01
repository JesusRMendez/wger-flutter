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

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/features/exercises/models/equipment.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';
import 'package:wger/features/locations/screens/location_edit_screen.dart';
import 'package:wger/features/locations/zone_rules.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The training locations of the user as tabs, with the equipment of the
/// selected one as toggles. The toggles save right away.
class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  static const routeName = '/training-locations';

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  int? _selectedId;

  /// Equipment toggled here, shown until the list is read again
  final Map<int, List<int>> _equipment = {};

  Future<void> _open([TrainingLocation? location]) async {
    await Navigator.of(context).pushNamed(LocationEditScreen.routeName, arguments: location);
    _equipment.clear();
    ref.invalidate(trainingLocationsProvider);
  }

  Future<void> _toggle(TrainingLocation location, int equipmentId, bool on) async {
    final ids = {...location.equipmentIds};
    if (on) {
      ids.add(equipmentId);
    } else {
      ids.remove(equipmentId);
    }
    final updated = location.copyWith(equipmentIds: ids.toList()..sort());
    setState(() => _equipment[location.id!] = updated.equipmentIds);

    final repo = ref.read(locationsRepositoryProvider);
    try {
      await repo.saveLocation(updated);

      // Zones can only offer equipment of the location, drop what is gone
      if (!on) {
        for (final zone in await repo.fetchZones(location.id!)) {
          final pruned = pruneZoneEquipment(zone, updated);
          if (pruned != zone) {
            await repo.saveZone(pruned);
          }
        }
      }
    } catch (e) {
      // Back to what is saved
      if (mounted) {
        setState(() => _equipment.remove(location.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _tabs(BuildContext context, List<TrainingLocation> items, TrainingLocation selected) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final animate = !MediaQuery.of(context).disableAnimations;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: atlas.card,
        borderRadius: BorderRadius.circular(AtlasRadius.input),
        border: Border.all(color: atlas.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final l in items)
              Pressable(
                key: ValueKey('location-tab-${l.id}'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedId = l.id),
                child: AnimatedContainer(
                  duration: animate ? AtlasMotion.base : Duration.zero,
                  curve: AtlasMotion.curve,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: l.id == selected.id ? atlas.surface3 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: l.id == selected.id ? theme.colorScheme.onSurface : atlas.ink3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _details(BuildContext context, TrainingLocation location, List<Equipment> catalogue) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final ids = location.equipmentIds.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        AtlasCard(
          key: ValueKey('location-${location.id}'),
          child: Row(
            children: [
              IconBadge(
                location.isDefault ? Icons.star : Icons.place_outlined,
                color: location.isDefault ? atlas.warn : null,
                background: location.isDefault ? atlas.warnSoft : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name, style: theme.textTheme.titleMedium),
                    Text(
                      [
                        i18n.locationsEquipmentCount(location.equipmentIds.length),
                        if (location.availableMinutes != null)
                          i18n.locationsMinutesValue(location.availableMinutes!),
                        if (location.isDefault) i18n.locationsDefault,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('location-edit-button'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: i18n.locationsEdit,
                onPressed: () => _open(location),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: i18n.delete,
                onPressed: () => showConfirmDeleteDialog(
                  context,
                  itemName: location.name,
                  onConfirm: () async {
                    await ref.read(locationsRepositoryProvider).deleteLocation(location.id!);
                    _selectedId = null;
                    ref.invalidate(trainingLocationsProvider);
                  },
                ),
              ),
            ],
          ),
        ),
        AtlasCard(
          key: const ValueKey('location-equipment'),
          child: catalogue.isEmpty
              ? Text(
                  i18n.locationsNoCatalog,
                  style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionEyebrow(
                      i18n.equipment,
                      trailing: MonoText(
                        i18n.locationsCountOf(
                          catalogue.where((e) => ids.contains(e.id)).length,
                          catalogue.length,
                        ),
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: atlas.ink3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final e in catalogue)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: atlas.line)),
                        ),
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.only(top: 4),
                        child: SwitchListTile(
                          key: ValueKey('equipment-switch-${e.id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(getServerStringTranslation(e.name, context)),
                          value: ids.contains(e.id),
                          onChanged: (on) => _toggle(location, e.id, on),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final locations = ref.watch(trainingLocationsProvider);
    final catalogue = ref.watch(exerciseEquipmentProvider).value ?? const <Equipment>[];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(i18n.locationsTitle, style: Theme.of(context).textTheme.titleMedium),
            Text(
              i18n.locationsSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('add-location-button'),
            tooltip: i18n.locationsAdd,
            style: IconButton.styleFrom(
              backgroundColor: atlas.card,
              side: BorderSide(color: atlas.line),
              fixedSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.add),
            onPressed: () => _open(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: WidescreenWrapper(
        child: AsyncValueWidget<List<TrainingLocation>>(
          value: locations,
          loggerName: 'LocationsScreen',
          data: (loaded) {
            if (loaded.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(i18n.locationsEmpty, textAlign: TextAlign.center),
                ),
              );
            }

            final items = [
              for (final l in loaded)
                if (_equipment[l.id] != null) l.copyWith(equipmentIds: _equipment[l.id]) else l,
            ];
            final selected =
                items.firstWhereOrNull((l) => l.id == _selectedId) ??
                items.firstWhereOrNull((l) => l.isDefault) ??
                items.first;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _tabs(context, items, selected),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _details(context, selected, catalogue),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
