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
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/form_validators.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/core/number_input.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/repetition_unit.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Input widget for repetition units
///
/// Can be used with a Setting or a Log object
class RepetitionUnitInputWidget extends ConsumerStatefulWidget {
  final RepetitionUnit? initialRepetitionUnit;
  final ValueChanged<RepetitionUnit> onChanged;

  const RepetitionUnitInputWidget(this.initialRepetitionUnit, {super.key, required this.onChanged});

  @override
  _RepetitionUnitInputWidgetState createState() => _RepetitionUnitInputWidgetState();
}

class _RepetitionUnitInputWidgetState extends ConsumerState<RepetitionUnitInputWidget> {
  @override
  Widget build(BuildContext context) {
    final units = ref.watch(routineRepetitionUnitProvider).asData?.value ?? <RepetitionUnit>[];

    RepetitionUnit? selectedWeightUnit = widget.initialRepetitionUnit;

    return DropdownButtonFormField(
      initialValue: selectedWeightUnit,
      decoration: InputDecoration(labelText: AppLocalizations.of(context).repetitionUnit),
      isDense: true,
      onChanged: (RepetitionUnit? newValue) {
        if (newValue == null) {
          return;
        }

        setState(() {
          selectedWeightUnit = newValue;
          widget.onChanged(newValue);
        });
      },
      items: units.map<DropdownMenuItem<RepetitionUnit>>((
        RepetitionUnit value,
      ) {
        return DropdownMenuItem<RepetitionUnit>(
          key: Key(value.id.toString()),
          value: value,
          child: Text(value.name),
        );
      }).toList(),
    );
  }
}

/// Controlled numeric input for repetitions
///
/// If both [unit] and [onUnitChanged] are provided, a compact dropdown listing
/// the values of [routineRepetitionUnitProvider] is rendered as the suffix of
/// the text field. If [onUnitChanged] is null, the dropdown is hidden and the
/// widget behaves as a pure numeric input.
class RepetitionInputWidget extends ConsumerStatefulWidget {
  final num? value;
  final ValueChanged<num?> onChanged;
  final RepetitionUnit? unit;
  final ValueChanged<RepetitionUnit?>? onUnitChanged;
  final num valueChange;
  final TextEditingController? controller;

  /// Large centered number between round buttons, as on the gym mode log page
  final bool stepper;

  const RepetitionInputWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.unit,
    this.onUnitChanged,
    this.controller,
    this.stepper = false,
    num? valueChange,
  }) : valueChange = valueChange ?? 1;

  @override
  ConsumerState<RepetitionInputWidget> createState() => _RepetitionInputWidgetState();
}

class _RepetitionInputWidgetState extends ConsumerState<RepetitionInputWidget> {
  final _logger = Logger('RepetitionInputWidget');
  late TextEditingController _controller;
  late NumberFormat _numberFormat;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _numberFormat = localizedNumberFormat(context);
    // Seeded here and not in initState: the text must use the same locale
    // the validator parses with, and that is only available from the context
    if (!_seeded) {
      _seeded = true;
      if (widget.value != null) {
        _controller.text = _numberFormat.format(widget.value);
      }
    }
  }

  @override
  void didUpdateWidget(covariant RepetitionInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) {
      return;
    }
    // Setting `controller.text` notifies its listeners synchronously,
    // which in turn calls `setState` on the surrounding Form/TextField
    // state, and `didUpdateWidget` runs *during* the build cycle, so
    // that's illegal. Defer the assignment to after the current frame.
    final text = widget.value == null ? '' : _numberFormat.format(widget.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_controller.text != text) {
        _controller.text = text;
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    String labelText = i18n.repetitions;
    Widget? suffixIcon;
    final onUnitChanged = widget.onUnitChanged;
    if (onUnitChanged != null) {
      final units = ref.watch(routineRepetitionUnitProvider).asData?.value ?? <RepetitionUnit>[];
      if (units.isNotEmpty) {
        labelText = widget.unit == null
            ? i18n.repetitions
            : getServerStringTranslation(widget.unit!.name, context);

        suffixIcon = PopupMenuButton<int>(
          icon: const Icon(Icons.arrow_drop_down),
          tooltip: i18n.repetitionUnit,
          onSelected: (id) {
            onUnitChanged(units.firstWhere((u) => u.id == id));
          },
          itemBuilder: (context) => units
              .map(
                (u) => PopupMenuItem<int>(
                  value: u.id,
                  child: Text(getServerStringTranslation(u.name, context)),
                ),
              )
              .toList(),
        );
      }
    }

    return Row(
      children: [
        // "Quick-remove" button
        if (widget.stepper)
          StepButton(
            icon: Icons.remove,
            size: 40,
            tooltip: i18n.decrease,
            onPressed: () {
              final base = widget.value ?? 0;
              final newValue = base - widget.valueChange;
              if (newValue >= 0) {
                widget.onChanged(newValue);
              }
            },
          )
        else
          IconButton(
            icon: const Icon(Icons.remove),
            iconSize: 25,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            tooltip: i18n.decrease,
            onPressed: () {
              final base = widget.value ?? 0;
              final newValue = base - widget.valueChange;
              if (newValue >= 0) {
                widget.onChanged(newValue);
              }
            },
          ),

        // Text field
        Expanded(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: labelText,
                  suffixIcon: widget.stepper ? null : suffixIcon,
                  suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  isDense: true,
                  // The stepper has no box: the number is the control
                  border: widget.stepper ? InputBorder.none : null,
                  enabledBorder: widget.stepper ? InputBorder.none : null,
                  focusedBorder: widget.stepper ? InputBorder.none : null,
                  errorBorder: widget.stepper ? InputBorder.none : null,
                  filled: widget.stepper ? false : null,
                  floatingLabelBehavior: widget.stepper ? FloatingLabelBehavior.always : null,
                  floatingLabelAlignment: widget.stepper ? FloatingLabelAlignment.center : null,
                  contentPadding: widget.stepper ? const EdgeInsets.only(top: 14, bottom: 4) : null,
                ),
                textAlign: widget.stepper ? TextAlign.center : TextAlign.start,
                style: widget.stepper
                    ? AtlasText.mono(Theme.of(context).textTheme.titleLarge, size: 26)
                    : null,
                enabled: true,
                controller: _controller,
                keyboardType: textInputTypeDecimal,
                inputFormatters: [
                  LocalizedDecimalInputFormatter(_numberFormat.symbols.DECIMAL_SEP),
                ],
                onChanged: (text) {
                  if (text.isEmpty) {
                    widget.onChanged(null);
                    return;
                  }
                  try {
                    widget.onChanged(_numberFormat.parse(text));
                  } on FormatException catch (error) {
                    _logger.finer('Error parsing repetitions: $error');
                  }
                },
                onSaved: (text) {
                  if (text == null || text.isEmpty) {
                    return;
                  }
                  widget.onChanged(_numberFormat.parse(text));
                },
                validator: (text) =>
                    validateOptionalDecimal(text, _numberFormat, context, max: Log.MAX_VALUE),
              ),
              if (widget.stepper && suffixIcon != null)
                SizedBox(width: 28, height: 28, child: suffixIcon),
            ],
          ),
        ),

        // "Quick-add" button
        if (widget.stepper)
          StepButton(
            icon: Icons.add,
            size: 40,
            tooltip: i18n.increase,
            onPressed: () {
              final base = widget.value ?? 0;
              final newValue = base + widget.valueChange;
              if (newValue >= 0) {
                widget.onChanged(newValue);
              }
            },
          )
        else
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 25,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            tooltip: i18n.increase,
            onPressed: () {
              final base = widget.value ?? 0;
              final newValue = base + widget.valueChange;
              if (newValue >= 0) {
                widget.onChanged(newValue);
              }
            },
          ),
      ],
    );
  }
}
