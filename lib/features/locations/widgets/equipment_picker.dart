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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/features/exercises/models/equipment.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Dialog to select several pieces of equipment from [options]. Returns the
/// selected ids, or null if the dialog was cancelled.
Future<List<int>?> showEquipmentPicker(
  BuildContext context, {
  required List<Equipment> options,
  required List<int> selected,
  String? title,
}) {
  return showDialog<List<int>>(
    context: context,
    builder: (ctx) => _EquipmentPickerDialog(options: options, selected: selected, title: title),
  );
}

class _EquipmentPickerDialog extends StatefulWidget {
  final List<Equipment> options;
  final List<int> selected;
  final String? title;

  const _EquipmentPickerDialog({required this.options, required this.selected, this.title});

  @override
  State<_EquipmentPickerDialog> createState() => _EquipmentPickerDialogState();
}

class _EquipmentPickerDialogState extends State<_EquipmentPickerDialog> {
  late final Set<int> _selected = widget.selected.toSet();

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title ?? i18n.equipment),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.options.isEmpty
            ? Text(i18n.locationsNoEquipmentAvailable)
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final equipment in widget.options)
                    CheckboxListTile(
                      key: ValueKey('equipment-option-${equipment.id}'),
                      dense: true,
                      title: Text(getServerStringTranslation(equipment.name, context)),
                      value: _selected.contains(equipment.id),
                      onChanged: (value) => setState(() {
                        if (value ?? false) {
                          _selected.add(equipment.id);
                        } else {
                          _selected.remove(equipment.id);
                        }
                      }),
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
          key: const ValueKey('equipment-picker-ok'),
          onPressed: () => Navigator.of(context).pop(_selected.toList()..sort()),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

/// The names of the equipment with the given ids as chips
class EquipmentChips extends StatelessWidget {
  final List<Equipment> all;
  final List<int> ids;

  const EquipmentChips({super.key, required this.all, required this.ids});

  @override
  Widget build(BuildContext context) {
    final byId = {for (final e in all) e.id: e};

    return Wrap(
      spacing: 6,
      runSpacing: 0,
      children: [
        for (final id in ids)
          if (byId[id] != null)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(getServerStringTranslation(byId[id]!.name, context)),
            ),
      ],
    );
  }
}
