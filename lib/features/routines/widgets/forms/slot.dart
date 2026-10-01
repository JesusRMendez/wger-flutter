/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2020 - 2026 wger Team
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
import 'package:wger/core/error_dialogs.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/exercises/widgets/autocompleter.dart';
import 'package:wger/features/routines/models/day.dart';
import 'package:wger/features/routines/models/slot.dart';
import 'package:wger/features/routines/models/slot_entry.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/widgets/forms/slot_entry.dart';
import 'package:wger/features/routines/widgets/forms/slot_summary.dart';
import 'package:wger/features/routines/widgets/slot.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

typedef SlotGroupInfo = ({int groupSize, int indexInGroup, String? exerciseName});

/// Groups consecutive single-entry slots with the same exerciseId.
/// Returns a map from slot index to group metadata.
Map<int, SlotGroupInfo> computeSlotGroups(List<Slot> slots, String languageCode) {
  final result = <int, SlotGroupInfo>{};
  int i = 0;
  while (i < slots.length) {
    final slot = slots[i];
    if (slot.entries.length != 1) {
      result[i] = (groupSize: 1, indexInGroup: 0, exerciseName: null);
      i++;
      continue;
    }
    final exerciseId = slot.entries[0].exerciseId;
    int j = i + 1;
    while (j < slots.length &&
        slots[j].entries.length == 1 &&
        slots[j].entries[0].exerciseId == exerciseId) {
      j++;
    }
    final groupSize = j - i;
    final exerciseName = groupSize > 1
        ? slot.entries[0].exerciseObj.getTranslation(languageCode).name
        : null;
    for (int k = i; k < j; k++) {
      result[k] = (groupSize: groupSize, indexInGroup: k - i, exerciseName: exerciseName);
    }
    i = j;
  }
  return result;
}

class SlotDetailWidget extends ConsumerStatefulWidget {
  final Slot slot;
  final bool simpleMode;
  final int routineId;

  const SlotDetailWidget(this.slot, this.routineId, {this.simpleMode = true, super.key});

  @override
  _SlotDetailWidgetState createState() => _SlotDetailWidgetState();
}

class _SlotDetailWidgetState extends ConsumerState<SlotDetailWidget> {
  bool _showExerciseSearchBox = false;
  Widget errorMessage = const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final provider = ref.read(routinesRiverpodProvider.notifier);
    final isOnline = ref.watch(networkStatusProvider);
    final multiple = widget.slot.entries.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        errorMessage,
        ...widget.slot.entries.indexed.map(
          (e) => Padding(
            padding: EdgeInsets.only(bottom: e.$1 == widget.slot.entries.length - 1 ? 0 : 16),
            child: e.$2.hasProgressionRules
                ? ProgressionRulesInfoBox(e.$2.exerciseObj)
                : SlotEntryForm(
                    e.$2,
                    widget.routineId,
                    simpleMode: widget.simpleMode,
                    showHeader: multiple,
                    onAddSuperset: e.$1 == widget.slot.entries.length - 1
                        ? () => setState(() => _showExerciseSearchBox = !_showExerciseSearchBox)
                        : null,
                  ),
          ),
        ),
        if (isOnline && (_showExerciseSearchBox || widget.slot.entries.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ExerciseAutocompleter(
              onExerciseSelected: (exercise) async {
                setState(() => _showExerciseSearchBox = false);

                final SlotEntry entry = SlotEntry.withData(
                  slotId: widget.slot.id!,
                  order: widget.slot.entries.length + 1,
                  exercise: exercise,
                );

                try {
                  await provider.addSlotEntry(entry, widget.routineId);
                  if (context.mounted) {
                    setState(() => errorMessage = const SizedBox.shrink());
                  }
                } on WgerHttpException catch (error) {
                  if (context.mounted) {
                    setState(() {
                      errorMessage = FormHttpErrorsWidget(error);
                    });
                  }
                }
              },
            ),
          ),
      ],
    );
  }
}

class ReorderableSlotList extends ConsumerStatefulWidget {
  final List<Slot> slots;
  final Day day;

  const ReorderableSlotList(this.slots, this.day);

  @override
  _SlotFormWidgetStateNg createState() => _SlotFormWidgetStateNg();
}

class _SlotFormWidgetStateNg extends ConsumerState<ReorderableSlotList> {
  int? selectedSlotId;
  bool simpleMode = true;
  bool isAddingSlot = false;
  int? isDeletingSlot;
  Widget errorMessage = const SizedBox.shrink();

  Future<void> _handleAddSet(Slot slot, int slotIndex) async {
    final provider = ref.read(routinesRiverpodProvider.notifier);
    if (slot.entries.isEmpty) {
      return;
    }

    setState(() => isAddingSlot = true);
    try {
      final insertOrder = slotIndex + 2;

      // Shift orders of subsequent slots
      final slotsToUpdate = <Slot>[];
      for (int k = slotIndex + 1; k < widget.slots.length; k++) {
        widget.slots[k].order = insertOrder + (k - slotIndex);
        slotsToUpdate.add(widget.slots[k]);
      }
      if (slotsToUpdate.isNotEmpty) {
        await provider.editSlots(slotsToUpdate, widget.day.routineId);
      }

      // Create new slot after source
      final newSlot = await provider.addSlot(
        Slot.withData(day: widget.day.id, order: insertOrder),
        widget.day.routineId,
      );

      // Create entry with same exercise
      final sourceEntry = slot.entries[0];
      await provider.addSlotEntry(
        SlotEntry.withData(
          slotId: newSlot.id!,
          exercise: sourceEntry.exerciseObj,
          order: 1,
          weightUnitId: sourceEntry.weightUnitId,
        ),
        widget.day.routineId,
      );

      if (mounted) {
        setState(() {
          isAddingSlot = false;
          errorMessage = const SizedBox.shrink();
        });
      }
    } on WgerHttpException catch (error) {
      if (mounted) {
        setState(() {
          isAddingSlot = false;
          errorMessage = FormHttpErrorsWidget(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final provider = ref.read(routinesRiverpodProvider.notifier);
    final isOnline = ref.watch(networkStatusProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final groupInfo = computeSlotGroups(widget.slots, languageCode);
    final atlas = context.atlas;
    final nf = localizedNumberFormat(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        errorMessage,
        if (!widget.day.isRest) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Row(
              spacing: 8,
              children: [
                Icon(Icons.drag_indicator, size: 16, color: atlas.ink3),
                Expanded(
                  child: Text(
                    i18n.dragToReorderHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            value: simpleMode,
            title: Text(i18n.simpleMode),
            subtitle: Text(i18n.simpleModeHelp),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onChanged: (value) {
              setState(() => simpleMode = value);
            },
          ),
        ],
        ReorderableListView.builder(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.slots.length,
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: child,
          ),
          itemBuilder: (context, index) {
            final slot = widget.slots[index];
            final isOpen = slot.id == selectedSlotId;
            final info = groupInfo[index]!;
            final isGrouped = info.groupSize > 1;
            final isLast = info.indexInGroup == info.groupSize - 1;
            final isSuperset = slot.entries.length > 1;

            // Title: the exercise (or all exercises of a superset)
            final names = slot.entries.map((e) => e.exerciseObj.getTranslation(languageCode).name);
            final title = slot.entries.isEmpty ? i18n.setHasNoExercises : names.join(' + ');
            final subtitle = slot.entries.isEmpty
                ? null
                : isSuperset
                ? i18n.supersetNr('${index + 1}')
                : slotEntrySummary(slot.entries.first, nf);

            final animate = !MediaQuery.of(context).disableAnimations;

            return Padding(
              key: ValueKey(slot.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: AtlasCard(
                padding: EdgeInsets.zero,
                color: slot.entries.isEmpty ? atlas.brandSoft : null,
                borderColor: isSuperset
                    ? Theme.of(context).colorScheme.primary.withAlpha(90)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: selectedSlotId == null && isOnline
                              ? ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(Icons.drag_indicator, size: 20, color: atlas.ink3),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    size: 20,
                                    color: atlas.ink3.withAlpha(90),
                                  ),
                                ),
                        ),
                        Expanded(
                          child: InkWell(
                            key: ValueKey('slot-toggle-${slot.id}'),
                            onTap: () {
                              setState(() => selectedSlotId = isOpen ? null : slot.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                      ),
                                      if (isGrouped) ...[
                                        const SizedBox(width: 8),
                                        PillChip(
                                          i18n.setNr('${info.indexInGroup + 1}'),
                                          height: 20,
                                          fontSize: 10.5,
                                        ),
                                      ],
                                      if (isSuperset) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.link,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (subtitle != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: MonoText(
                                        subtitle,
                                        size: 12.5,
                                        weight: FontWeight.w500,
                                        color: atlas.ink3,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('slot-chevron-${slot.id}'),
                          onPressed: () {
                            setState(() => selectedSlotId = isOpen ? null : slot.id);
                          },
                          icon: AnimatedRotation(
                            turns: isOpen ? 0.5 : 0,
                            duration: animate ? AtlasMotion.slow : Duration.zero,
                            curve: AtlasMotion.curve,
                            child: Icon(Icons.expand_more, color: atlas.ink2),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: animate ? AtlasMotion.slow : Duration.zero,
                      curve: AtlasMotion.curve,
                      alignment: Alignment.topCenter,
                      child: !isOpen
                          ? const SizedBox(width: double.infinity)
                          : Container(
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: atlas.line)),
                              ),
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SlotDetailWidget(
                                    slot,
                                    widget.day.routineId,
                                    simpleMode: simpleMode,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    spacing: 8,
                                    children: [
                                      if (slot.entries.length == 1 && isLast)
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            key: ValueKey('add-set-${slot.id}'),
                                            onPressed: isAddingSlot || !isOnline
                                                ? null
                                                : () => _handleAddSet(slot, index),
                                            icon: isAddingSlot
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.content_copy, size: 16),
                                            label: Text(i18n.addSet),
                                          ),
                                        ),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          key: ValueKey('delete-slot-${slot.id}'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: atlas.accent,
                                          ),
                                          onPressed: isDeletingSlot == index || !isOnline
                                              ? null
                                              : () async {
                                                  selectedSlotId = null;
                                                  setState(() => isDeletingSlot = index);
                                                  await provider.deleteSlot(
                                                    slot.id!,
                                                    widget.day.routineId,
                                                  );
                                                  if (mounted) {
                                                    setState(() => isDeletingSlot = null);
                                                  }
                                                },
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          label: Text(i18n.delete),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
          onReorderItem: (int oldIndex, int newIndex) {
            setState(() {
              // Update the order of slots in your data source
              final item = widget.slots.removeAt(oldIndex);
              widget.slots.insert(newIndex, item);

              for (int i = 0; i < widget.slots.length; i++) {
                widget.slots[i].order = i + 1;
              }

              try {
                provider.editSlots(widget.slots, widget.day.routineId);
                setState(() {
                  errorMessage = const SizedBox.shrink();
                });
              } on WgerHttpException catch (error) {
                if (context.mounted) {
                  setState(() {
                    errorMessage = FormHttpErrorsWidget(error);
                  });
                }
              }
            });
          },
        ),
        if (!widget.day.isRest)
          AtlasCard(
            key: const ValueKey('add-exercise'),
            dashed: true,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            onTap: isAddingSlot || !isOnline
                ? null
                : () async {
                    setState(() => isAddingSlot = true);

                    final newSlot = await provider.addSlot(
                      Slot.withData(
                        day: widget.day.id,
                        order: widget.slots.length + 1,
                      ),
                      widget.day.routineId,
                    );
                    if (mounted) {
                      setState(() => isAddingSlot = false);
                      setState(() => selectedSlotId = newSlot.id);
                    }
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                if (isAddingSlot)
                  const FormProgressIndicator()
                else
                  const Icon(Icons.add, size: 20),
                Text(i18n.addExercise, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
      ],
    );
  }
}
