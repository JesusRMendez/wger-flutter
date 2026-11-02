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
import 'package:wger/core/consts.dart';
import 'package:wger/core/error_dialogs.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/core/form_validators.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/decimal_input.dart';
import 'package:wger/core/widgets/form_submit_button.dart';
import 'package:wger/features/exercises/widgets/autocompleter.dart';
import 'package:wger/features/routines/models/base_config.dart';
import 'package:wger/features/routines/models/slot_entry.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/widgets/forms/repetitions.dart';
import 'package:wger/features/routines/widgets/forms/rir.dart';
import 'package:wger/features/routines/widgets/forms/slot_summary.dart';
import 'package:wger/features/routines/widgets/forms/weight.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class SlotEntryForm extends ConsumerStatefulWidget {
  final SlotEntry entry;
  final bool simpleMode;
  final int routineId;

  /// Shows the exercise name and a delete button above the fields, for the
  /// entries of a superset where the card header names no single exercise.
  final bool showHeader;

  /// Adds the "Superset" button when set
  final VoidCallback? onAddSuperset;

  const SlotEntryForm(
    this.entry,
    this.routineId, {
    this.simpleMode = true,
    this.showHeader = false,
    this.onAddSuperset,
    super.key,
  });

  @override
  _SlotEntryFormState createState() => _SlotEntryFormState();
}

class _SlotEntryFormState extends ConsumerState<SlotEntryForm> {
  bool isDeleting = false;

  final iconSize = 18.0;

  int setsValue = 1;

  num? _weight;
  num? _maxWeight;
  num? _reps;
  num? _maxReps;
  final restController = TextEditingController();
  final maxRestController = TextEditingController();
  final rirController = TextEditingController();

  Widget errorMessage = const SizedBox.shrink();

  final _form = GlobalKey<FormState>();

  var _edit = false;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry.nrOfSetsConfigs.isNotEmpty) {
      setsValue = widget.entry.nrOfSetsConfigs.first.value.round();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) {
      return;
    }
    _controllersInitialized = true;

    if (widget.entry.weightConfigs.isNotEmpty) {
      _weight = widget.entry.weightConfigs.first.value;
    }
    if (widget.entry.maxWeightConfigs.isNotEmpty) {
      _maxWeight = widget.entry.maxWeightConfigs.first.value;
    }
    if (widget.entry.repetitionsConfigs.isNotEmpty) {
      _reps = widget.entry.repetitionsConfigs.first.value;
    }
    if (widget.entry.maxRepetitionsConfigs.isNotEmpty) {
      _maxReps = widget.entry.maxRepetitionsConfigs.first.value;
    }

    if (widget.entry.restTimeConfigs.isNotEmpty) {
      restController.text = widget.entry.restTimeConfigs.first.value.round().toString();
    }
    if (widget.entry.maxRestTimeConfigs.isNotEmpty) {
      maxRestController.text = widget.entry.maxRestTimeConfigs.first.value.round().toString();
    }

    if (widget.entry.rirConfigs.isNotEmpty) {
      // RiR uses 0.5 steps, so the fractional part must be kept
      rirController.text = widget.entry.rirConfigs.first.value.toString();
    }
  }

  @override
  void dispose() {
    restController.dispose();
    maxRestController.dispose();

    rirController.dispose();

    super.dispose();
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.atlas.ink3),
    ),
  );

  Widget _progressionChips(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final kind = progressionOf(widget.entry);
    final step = progressionStep(widget.entry);
    final nf = localizedNumberFormat(context);

    final labels = {
      ProgressionKind.linear: step != null
          ? '${i18n.progressionLinear} +${nf.format(step)}'
          : i18n.progressionLinear,
      ProgressionKind.doubleProgression: i18n.progressionDouble,
      ProgressionKind.manual: i18n.progressionManual,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, i18n.progression),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in ProgressionKind.values)
              PillChip(labels[k]!, selected: k == kind, fontSize: 12),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final numberFormat = localizedNumberFormat(context);
    final atlas = context.atlas;

    final provider = ref.read(routinesRiverpodProvider.notifier);
    final isOnline = ref.watch(networkStatusProvider);

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          errorMessage,
          if (widget.showHeader)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.exerciseObj.getTranslation(languageCode).name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: i18n.delete,
                    icon: Icon(Icons.delete_outline, size: iconSize),
                    onPressed: isDeleting || !isOnline
                        ? null
                        : () async {
                            setState(() => isDeleting = true);
                            try {
                              await provider.deleteSlotEntry(widget.entry.id!, widget.routineId);
                            } on WgerHttpException catch (error) {
                              if (context.mounted) {
                                setState(() {
                                  errorMessage = FormHttpErrorsWidget(error);
                                });
                              }
                            } finally {
                              if (mounted) {
                                setState(() => isDeleting = false);
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          if (_edit)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExerciseAutocompleter(
                onExerciseSelected: (exercise) => setState(() {
                  widget.entry.exercise = exercise;
                  _edit = false;
                }),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    i18n.sets,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: atlas.ink2),
                  ),
                ),
                StepButton(
                  key: const ValueKey('sets-minus'),
                  icon: Icons.remove,
                  size: 36,
                  tooltip: i18n.removeSet,
                  onPressed: setsValue > 1 ? () => setState(() => setsValue--) : null,
                ),
                SizedBox(
                  width: 40,
                  child: MonoText(
                    '$setsValue',
                    key: const ValueKey('sets-value'),
                    size: 18,
                    textAlign: TextAlign.center,
                  ),
                ),
                StepButton(
                  key: const ValueKey('sets-plus'),
                  icon: Icons.add,
                  size: 36,
                  tooltip: i18n.addSet,
                  onPressed: setsValue < 20 ? () => setState(() => setsValue++) : null,
                ),
              ],
            ),
          ),
          if (!widget.simpleMode)
            DropdownButtonFormField<SlotEntryType>(
              key: const Key('field-slot-entry-type'),
              initialValue: widget.entry.type,
              decoration: const InputDecoration(labelText: 'Typ'),
              items: SlotEntryType.values.map((type) {
                return DropdownMenuItem(
                  key: Key('slot-entry-type-option-${type.name}'),
                  value: type,
                  child: Text('${type.name.toUpperCase()} - ${type.i18Label(i18n)}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  widget.entry.type = value!;
                });
              },
            ),
          if (!widget.simpleMode)
            WeightUnitInputWidget(
              widget.entry.weightUnitObj,
              onChanged: (value) => widget.entry.weightUnit = value,
            ),
          if (widget.simpleMode)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Flexible(
                  child: DecimalInputWidget(
                    key: const ValueKey('field-repetitions'),
                    value: _reps,
                    labelText: i18n.reps,
                    min: 0,
                    max: BaseConfig.MAX_VALUE,
                    onChanged: (v) => _reps = v,
                  ),
                ),
                Flexible(
                  child: DecimalInputWidget(
                    key: const ValueKey('field-weight'),
                    value: _weight,
                    labelText: i18n.weight,
                    min: 0,
                    max: BaseConfig.MAX_VALUE,
                    onChanged: (v) => _weight = v,
                  ),
                ),
                Flexible(
                  child: TextFormField(
                    key: const ValueKey('field-rest'),
                    controller: restController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: i18n.restShort, suffixText: 's'),
                    validator: (value) =>
                        validateOptionalIntegerInRange(value, 0, BaseConfig.MAX_REST, i18n),
                  ),
                ),
              ],
            ),
          if (!widget.simpleMode) ...[
            Row(
              spacing: 10,
              children: [
                Flexible(
                  child: DecimalInputWidget(
                    key: const ValueKey('field-weight'),
                    value: _weight,
                    labelText: i18n.weight,
                    min: 0,
                    max: BaseConfig.MAX_VALUE,
                    onChanged: (v) => _weight = v,
                  ),
                ),
                Flexible(
                  child: DecimalInputWidget(
                    key: const ValueKey('field-max-weight'),
                    value: _maxWeight,
                    labelText: i18n.max,
                    min: 0,
                    max: BaseConfig.MAX_VALUE,
                    onChanged: (v) => _maxWeight = v,
                  ),
                ),
              ],
            ),
            RepetitionUnitInputWidget(
              widget.entry.repetitionUnitObj,
              onChanged: (value) => widget.entry.repetitionUnit = value,
            ),
            Row(
              spacing: 10,
              children: [
                Flexible(
                  child: DecimalInputWidget(
                    key: const ValueKey('field-repetitions'),
                    value: _reps,
                    labelText: i18n.repetitions,
                    min: 0,
                    max: BaseConfig.MAX_VALUE,
                    onChanged: (v) => _reps = v,
                  ),
                ),
                Flexible(
                  child: DecimalInputWidget(
                    key: const ValueKey('field-max-repetitions'),
                    value: _maxReps,
                    labelText: i18n.max,
                    min: 0,
                    max: BaseConfig.MAX_VALUE,
                    onChanged: (v) => _maxReps = v,
                  ),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Flexible(
                  child: TextFormField(
                    key: const ValueKey('field-rest'),
                    controller: restController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: i18n.restTime),
                    validator: (value) =>
                        validateOptionalIntegerInRange(value, 0, BaseConfig.MAX_REST, i18n),
                  ),
                ),
                Flexible(
                  child: TextFormField(
                    key: const ValueKey('field-max-rest'),
                    controller: maxRestController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: i18n.max),
                    validator: (value) =>
                        validateOptionalIntegerInRange(value, 0, BaseConfig.MAX_REST_TARGET, i18n),
                  ),
                ),
              ],
            ),
            RiRInputWidget(
              rirController.text == '' ? null : num.parse(rirController.text),
              onChanged: (value) => rirController.text = value,
            ),
          ],
          const SizedBox(height: 14),
          _progressionChips(context),
          const SizedBox(height: 14),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('change-exercise'),
                  onPressed: isOnline ? () => setState(() => _edit = !_edit) : null,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(i18n.changeExercise),
                ),
              ),
              if (widget.onAddSuperset != null)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('add-superset'),
                    onPressed: isOnline ? widget.onAddSuperset : null,
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(i18n.superset),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FormSubmitButton(
            key: const Key(SUBMIT_BUTTON_KEY_NAME),
            enabled: isOnline,
            label: AppLocalizations.of(context).save,
            onPressed: () async {
              if (!_form.currentState!.validate()) {
                return;
              }
              _form.currentState!.save();

              // Process new, edited or entries to be deleted
              await Future.wait([
                provider.handleConfig(
                  widget.entry,
                  setsValue == 0 ? null : setsValue,
                  ConfigType.sets,
                ),
                provider.handleConfig(widget.entry, _weight, ConfigType.weight),
                provider.handleConfig(widget.entry, _maxWeight, ConfigType.maxWeight),
                provider.handleConfig(widget.entry, _reps, ConfigType.repetitions),
                provider.handleConfig(widget.entry, _maxReps, ConfigType.maxRepetitions),
                provider.handleConfig(
                  widget.entry,
                  numberFormat.tryParse(restController.text),
                  ConfigType.rest,
                ),
                provider.handleConfig(
                  widget.entry,
                  numberFormat.tryParse(maxRestController.text),
                  ConfigType.maxRest,
                ),
                provider.handleConfig(
                  widget.entry,
                  // RiR is slider-driven and held as an invariant string
                  num.tryParse(rirController.text),
                  ConfigType.rir,
                ),
              ]);
              await provider.editSlotEntry(widget.entry, widget.routineId);
            },
          ),
        ],
      ),
    );
  }
}
