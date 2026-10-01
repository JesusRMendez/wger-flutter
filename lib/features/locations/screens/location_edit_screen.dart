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
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/features/exercises/models/equipment.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';
import 'package:wger/features/locations/widgets/equipment_picker.dart';
import 'package:wger/features/locations/zone_rules.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Edit (or create) a training location and its zones. The location is passed
/// as route argument, null creates a new one.
class LocationEditScreen extends ConsumerStatefulWidget {
  const LocationEditScreen({super.key});

  static const routeName = '/training-location-edit';

  @override
  ConsumerState<LocationEditScreen> createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends ConsumerState<LocationEditScreen> {
  final _logger = Logger('LocationEditScreen');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minutesController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  TrainingLocation _location = const TrainingLocation(name: '');
  List<LocationZone> _zones = [];

  @override
  void dispose() {
    _nameController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is TrainingLocation) {
      _location = arg;
      _nameController.text = arg.name;
      _minutesController.text = arg.availableMinutes?.toString() ?? '';
      if (arg.id != null) {
        _loadZones();
      }
    }
  }

  Future<void> _loadZones() async {
    try {
      final zones = await ref.read(locationsRepositoryProvider).fetchZones(_location.id!);
      if (mounted) {
        setState(() => _zones = zones);
      }
    } catch (e, stk) {
      _logger.warning('Could not load the zones', e, stk);
    }
  }

  void _showError(Object e) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final i18n = AppLocalizations.of(context);
    final repo = ref.read(locationsRepositoryProvider);
    final minutes = int.tryParse(_minutesController.text.trim());

    setState(() => _saving = true);
    try {
      final wasNew = _location.id == null;
      final saved = await repo.saveLocation(
        _location.copyWith(
          name: _nameController.text.trim(),
          availableMinutes: minutes,
          clearAvailableMinutes: minutes == null,
        ),
      );

      // Zones can only offer equipment of the location, drop what is gone
      final updatedZones = <LocationZone>[];
      for (final zone in _zones) {
        final pruned = pruneZoneEquipment(zone, saved);
        if (pruned != zone) {
          updatedZones.add(await repo.saveZone(pruned));
        } else {
          updatedZones.add(zone);
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _location = saved;
        _zones = updatedZones;
      });
      ref.invalidate(trainingLocationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(i18n.locationsSaved)));
      if (!wasNew) {
        Navigator.of(context).pop();
      }
    } catch (e, stk) {
      _logger.warning('Could not save the location', e, stk);
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickLocationEquipment(List<Equipment> all) async {
    final selected = await showEquipmentPicker(
      context,
      options: all,
      selected: _location.equipmentIds,
    );
    if (selected != null) {
      setState(() => _location = _location.copyWith(equipmentIds: selected));
    }
  }

  Future<void> _editZone(List<Equipment> all, [LocationZone? zone]) async {
    final result = await showDialog<LocationZone>(
      context: context,
      builder: (ctx) => _ZoneDialog(
        zone: zone ?? LocationZone(locationId: _location.id!, name: '', order: _zones.length),
        location: _location,
        allEquipment: all,
      ),
    );
    if (result == null) {
      return;
    }

    try {
      final saved = await ref.read(locationsRepositoryProvider).saveZone(result);
      if (!mounted) {
        return;
      }
      setState(() {
        final index = _zones.indexWhere((z) => z.id == saved.id);
        if (index == -1) {
          _zones = [..._zones, saved];
        } else {
          _zones = [..._zones]..[index] = saved;
        }
      });
    } catch (e, stk) {
      _logger.warning('Could not save the zone', e, stk);
      _showError(e);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final before = _zones;
    final after = reorderZones(before, oldIndex, newIndex);
    setState(() => _zones = after);

    try {
      final repo = ref.read(locationsRepositoryProvider);
      for (var i = 0; i < after.length; i++) {
        if (i >= before.length || after[i] != before[i]) {
          await repo.saveZone(after[i]);
        }
      }
    } catch (e, stk) {
      _logger.warning('Could not save the zone order', e, stk);
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final equipment = ref.watch(exerciseEquipmentProvider).value ?? const <Equipment>[];
    final locationEquipment = [
      for (final e in equipment)
        if (_location.equipmentIds.contains(e.id)) e,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_location.id == null ? i18n.locationsAdd : i18n.locationsEdit),
      ),
      body: WidescreenWrapper(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const ValueKey('location-name-field'),
                controller: _nameController,
                decoration: InputDecoration(labelText: i18n.name),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? i18n.enterValue : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('location-minutes-field'),
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: i18n.locationsAvailableMinutes,
                  helperText: i18n.locationsAvailableMinutesHelp,
                ),
                validator: (value) =>
                    isValidAvailableMinutes(value) ? null : i18n.locationsInvalidMinutes,
              ),
              SwitchListTile(
                key: const ValueKey('location-default-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(i18n.locationsDefault),
                subtitle: Text(i18n.locationsDefaultHelp),
                value: _location.isDefault,
                onChanged: (value) =>
                    setState(() => _location = _location.copyWith(isDefault: value)),
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('location-equipment-tile'),
                contentPadding: EdgeInsets.zero,
                title: Text(i18n.equipment),
                subtitle: Text(i18n.locationsEquipmentCount(_location.equipmentIds.length)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _pickLocationEquipment(equipment),
              ),
              EquipmentChips(all: locationEquipment, ids: _location.equipmentIds),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('location-save-button'),
                onPressed: _saving ? null : _save,
                child: Text(i18n.save),
              ),
              const Divider(height: 32),
              Text(i18n.locationsZones, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(i18n.locationsZonesHelp, style: Theme.of(context).textTheme.bodySmall),
              if (_location.id == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(i18n.locationsSaveFirst, key: const ValueKey('zones-save-first')),
                )
              else ...[
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: true,
                  onReorderItem: _reorder,
                  children: [
                    for (final zone in _zones)
                      ListTile(
                        key: ValueKey('zone-${zone.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(zone.name),
                        subtitle: Text(i18n.locationsEquipmentCount(zone.equipmentIds.length)),
                        onTap: () => _editZone(equipment, zone),
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 32),
                          child: IconButton(
                            tooltip: i18n.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => showConfirmDeleteDialog(
                              context,
                              itemName: zone.name,
                              onConfirm: () async {
                                await ref.read(locationsRepositoryProvider).deleteZone(zone.id!);
                                if (mounted) {
                                  setState(
                                    () => _zones = renumberZones([
                                      for (final z in _zones)
                                        if (z.id != zone.id) z,
                                    ]),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  key: const ValueKey('add-zone-button'),
                  onPressed: () => _editZone(equipment),
                  icon: const Icon(Icons.add),
                  label: Text(i18n.locationsAddZone),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Name and equipment of a zone. The equipment can only be chosen from what
/// the location offers.
class _ZoneDialog extends StatefulWidget {
  final LocationZone zone;
  final TrainingLocation location;
  final List<Equipment> allEquipment;

  const _ZoneDialog({required this.zone, required this.location, required this.allEquipment});

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.zone.name);
  late List<int> _equipmentIds = pruneZoneEquipment(widget.zone, widget.location).equipmentIds;
  bool _nameError = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final options = [
      for (final e in widget.allEquipment)
        if (widget.location.equipmentIds.contains(e.id)) e,
    ];

    return AlertDialog(
      title: Text(widget.zone.id == null ? i18n.locationsAddZone : i18n.locationsEditZone),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('zone-name-field'),
              controller: _name,
              decoration: InputDecoration(
                labelText: i18n.name,
                errorText: _nameError ? i18n.enterValue : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(i18n.equipment, style: Theme.of(context).textTheme.titleSmall),
            EquipmentChips(all: options, ids: _equipmentIds),
            TextButton.icon(
              key: const ValueKey('zone-equipment-button'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(i18n.locationsZoneEquipment),
              onPressed: () async {
                final selected = await showEquipmentPicker(
                  context,
                  options: options,
                  selected: _equipmentIds,
                );
                if (selected != null) {
                  setState(() => _equipmentIds = selected);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          key: const ValueKey('zone-save-button'),
          onPressed: () {
            if (_name.text.trim().isEmpty) {
              setState(() => _nameError = true);
              return;
            }
            Navigator.of(context).pop(
              widget.zone.copyWith(name: _name.text.trim(), equipmentIds: _equipmentIds),
            );
          },
          child: Text(i18n.save),
        ),
      ],
    );
  }
}
