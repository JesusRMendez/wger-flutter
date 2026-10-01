import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/error_dialogs.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/core/widgets/form_submit_button.dart';
import 'package:wger/features/routines/models/day.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/widgets/forms/slot.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class ReorderableDaysList extends ConsumerStatefulWidget {
  final int routineId;
  final List<Day> days;
  final int? selectedDayId;
  final ValueChanged<int> onDaySelected;

  const ReorderableDaysList({
    super.key,
    required this.routineId,
    required this.days,
    required this.selectedDayId,
    required this.onDaySelected,
  });

  @override
  ConsumerState<ReorderableDaysList> createState() => _ReorderableDaysListState();
}

class _ReorderableDaysListState extends ConsumerState<ReorderableDaysList> {
  Widget errorMessage = const SizedBox.shrink();

  void _showDeleteConfirmationDialog(BuildContext context, Day day) {
    final i18n = AppLocalizations.of(context);

    showConfirmDeleteDialog(
      context,
      title: i18n.delete,
      itemName: day.isRest ? i18n.restDay : day.name,
      onConfirm: () async {
        widget.days.remove(day);
        await ref.read(routinesRiverpodProvider.notifier).deleteDay(day.id!, day.routineId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final provider = ref.read(routinesRiverpodProvider.notifier);
    final isOnline = ref.watch(networkStatusProvider);

    return Column(
      children: [
        errorMessage,
        ReorderableListView.builder(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.days.length,
          itemBuilder: (context, index) {
            final day = widget.days[index];
            final isDaySelected = day.id == widget.selectedDayId;

            return Padding(
              key: ValueKey(day),
              padding: const EdgeInsets.only(bottom: 8),
              child: AtlasCard(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                borderColor: isDaySelected ? Theme.of(context).colorScheme.primary : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 4, right: 4),
                  title: Text(
                    day.isRest ? i18n.restDay : day.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  leading: isOnline
                      ? ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_indicator, color: context.atlas.ink3),
                        )
                      : Icon(Icons.drag_indicator, color: context.atlas.ink3.withAlpha(90)),
                  subtitle: day.description.isEmpty
                      ? null
                      : Text(
                          day.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.atlas.ink3),
                        ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: ValueKey('edit-day-${day.id}'),
                        onPressed: () => widget.onDaySelected(day.id!),
                        icon: isDaySelected ? const Icon(Icons.edit_off) : const Icon(Icons.edit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: isOnline
                            ? () => _showDeleteConfirmationDialog(context, day)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          onReorderItem: (int oldIndex, int newIndex) {
            setState(() {
              final Day item = widget.days.removeAt(oldIndex);
              widget.days.insert(newIndex, item);

              for (int i = 0; i < widget.days.length; i++) {
                widget.days[i].order = i + 1;
              }
            });

            try {
              provider.editDays(widget.days);
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
          },
        ),
        AtlasCard(
          key: const ValueKey('add-day'),
          dashed: true,
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          onTap: isOnline
              ? () async {
                  final day = Day(
                    routineId: widget.routineId,
                    name: '${i18n.newDay} ${widget.days.length + 1}',
                    order: widget.days.length + 1,
                  );
                  final newDay = await provider.addDay(day);

                  widget.onDaySelected(newDay.id!);
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              const Icon(Icons.add, size: 20),
              Text(i18n.newDay, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class DayFormWidget extends ConsumerStatefulWidget {
  late final Day day;

  DayFormWidget({required Day day, super.key}) {
    this.day = day.copyWith();
  }

  @override
  _DayFormWidgetState createState() => _DayFormWidgetState();
}

class _DayFormWidgetState extends ConsumerState<DayFormWidget> {
  final descriptionController = TextEditingController();
  final nameController = TextEditingController();

  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    descriptionController.text = widget.day.description;
    nameController.text = widget.day.name;
  }

  @override
  void dispose() {
    descriptionController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final isOnline = ref.watch(networkStatusProvider);

    final atlas = context.atlas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Text(
            widget.day.isRest ? i18n.restDay : widget.day.name,
            style: Theme.of(context).textTheme.titleLarge,
            key: ValueKey('day-title-${widget.day.id!}'),
          ),
        ),
        AtlasCard(
          child: Form(
            key: _form,
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('field-is-rest-day'),
                  title: Text(i18n.isRestDay),
                  subtitle: Text(i18n.isRestDayHelp),
                  value: widget.day.isRest,
                  contentPadding: const EdgeInsets.all(4),
                  onChanged: (value) {
                    setState(() {
                      widget.day.isRest = value;
                      widget.day.type = DayType.custom;
                      widget.day.needLogsToAdvance = false;
                      nameController.clear();
                      descriptionController.clear();
                    });
                    widget.day.isRest = value;
                  },
                ),
                TextFormField(
                  enabled: !widget.day.isRest,
                  key: const Key('field-name'),
                  decoration: InputDecoration(
                    labelText: i18n.name,
                    prefixIcon: Icon(Icons.edit_outlined, size: 18, color: atlas.ink3),
                  ),
                  controller: nameController,
                  onSaved: (value) {
                    widget.day.name = value!;
                  },
                  validator: (value) {
                    if (widget.day.isRest) {
                      return null;
                    }

                    if (value!.isEmpty ||
                        value.length < Day.MIN_LENGTH_NAME ||
                        value.length > Day.MAX_LENGTH_NAME) {
                      return i18n.enterCharacters(
                        Day.MIN_LENGTH_NAME.toString(),
                        Day.MAX_LENGTH_NAME.toString(),
                      );
                    }

                    return null;
                  },
                ),

                TextFormField(
                  key: const Key('field-description'),
                  enabled: !widget.day.isRest,
                  decoration: InputDecoration(labelText: i18n.description),
                  controller: descriptionController,
                  onSaved: (value) {
                    widget.day.description = value!;
                  },
                  minLines: 2,
                  maxLines: 10,
                  validator: (value) {
                    if (widget.day.isRest) {
                      return null;
                    }

                    if (value != null && value.length > Day.MAX_LENGTH_DESCRIPTION) {
                      return i18n.enterCharacters('0', Day.MAX_LENGTH_DESCRIPTION.toString());
                    }

                    return null;
                  },
                ),
                DropdownButtonFormField<DayType>(
                  key: const Key('field-day-type'),
                  isExpanded: true,
                  initialValue: widget.day.type,
                  decoration: const InputDecoration(labelText: 'Typ'),
                  items: DayType.values.map((type) {
                    return DropdownMenuItem(
                      key: Key('day-type-option-${type.name}'),
                      value: type,
                      child: Text(
                        '${type.name.toUpperCase()} - ${type.i18Label(i18n)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: widget.day.isRest
                      ? null
                      : (value) {
                          setState(() {
                            widget.day.type = value!;
                          });
                        },
                ),
                SwitchListTile(
                  key: const Key('field-need-logs-to-advance'),
                  title: Text(i18n.needsLogsToAdvance),
                  subtitle: Text(i18n.needsLogsToAdvanceHelp),
                  value: widget.day.needLogsToAdvance,
                  contentPadding: const EdgeInsets.all(4),
                  onChanged: widget.day.isRest
                      ? null
                      : (value) {
                          setState(() {
                            widget.day.needLogsToAdvance = value;
                          });
                        },
                ),
                const SizedBox(height: 5),
                FormSubmitButton(
                  key: const Key(SUBMIT_BUTTON_KEY_NAME),
                  enabled: isOnline,
                  label: AppLocalizations.of(context).save,
                  onPressed: () async {
                    if (!_form.currentState!.validate()) {
                      return;
                    }
                    _form.currentState!.save();

                    await ref.read(routinesRiverpodProvider.notifier).editDay(widget.day);
                  },
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ReorderableSlotList(widget.day.slots, widget.day),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('delete-day'),
          style: TextButton.styleFrom(foregroundColor: atlas.accent),
          onPressed: isOnline
              ? () => showConfirmDeleteDialog(
                  context,
                  title: i18n.delete,
                  itemName: widget.day.isRest ? i18n.restDay : widget.day.name,
                  onConfirm: () async {
                    await ref
                        .read(routinesRiverpodProvider.notifier)
                        .deleteDay(widget.day.id!, widget.day.routineId);
                  },
                )
              : null,
          child: Text(i18n.deleteDay),
        ),
      ],
    );
  }
}
