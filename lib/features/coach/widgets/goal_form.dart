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
import 'package:wger/features/coach/models/coach_goal.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Dialog to create or edit a goal. Returns the goal to save, or null.
Future<CoachGoal?> showGoalDialog(
  BuildContext context, {
  CoachGoal? goal,
  String defaultPeriod = 'monthly',
}) {
  return showDialog<CoachGoal>(
    context: context,
    builder: (_) => _GoalDialog(goal: goal, defaultPeriod: defaultPeriod),
  );
}

class _GoalDialog extends StatefulWidget {
  final CoachGoal? goal;
  final String defaultPeriod;

  const _GoalDialog({this.goal, required this.defaultPeriod});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.goal?.title ?? '');
  late final _target = TextEditingController(text: widget.goal?.targetValue?.toString() ?? '');
  late final _unit = TextEditingController(text: widget.goal?.unit ?? 'kg');
  late String _kind = widget.goal?.kind ?? 'strength';
  late String _period = widget.goal?.period ?? widget.defaultPeriod;
  late String _status = widget.goal?.status ?? 'active';
  late String? _indicator = widget.goal?.indicator;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final old = widget.goal;
    Navigator.of(context).pop(
      CoachGoal(
        id: old?.id,
        title: _title.text.trim(),
        kind: _kind,
        period: _period,
        indicator: _indicator,
        exercise: old?.exercise,
        targetValue: double.tryParse(_target.text.replaceAll(',', '.')),
        unit: _unit.text.trim(),
        baselineValue: old?.baselineValue,
        startDate: old?.startDate,
        endDate: old?.endDate,
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    DropdownButtonFormField<String> dropdown(
      String label,
      String value,
      List<String> options,
      String Function(String) text,
      ValueChanged<String> onChanged, {
      Key? key,
    }) {
      return DropdownButtonFormField<String>(
        key: key,
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [for (final o in options) DropdownMenuItem(value: o, child: Text(text(o)))],
        onChanged: (v) => setState(() => onChanged(v ?? value)),
      );
    }

    return AlertDialog(
      title: Text(widget.goal == null ? i18n.coachAddGoal : i18n.coachEditGoal),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('goal-title'),
                controller: _title,
                decoration: InputDecoration(labelText: i18n.coachGoalTitle),
                validator: (v) => (v ?? '').trim().isEmpty ? i18n.enterValue : null,
              ),
              dropdown(i18n.coachGoalKind, _kind, goalKinds, i18n.kindLabel, (v) => _kind = v),
              dropdown(
                i18n.coachGoalPeriod,
                _period,
                goalPeriods,
                i18n.periodLabel,
                (v) => _period = v,
              ),
              DropdownButtonFormField<String?>(
                initialValue: _indicator,
                isExpanded: true,
                decoration: InputDecoration(labelText: i18n.coachGoalIndicator),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('-')),
                  for (final o in goalIndicators)
                    DropdownMenuItem<String?>(value: o, child: Text(i18n.indicatorLabel(o))),
                ],
                onChanged: (v) => setState(() => _indicator = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('goal-target'),
                      controller: _target,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: i18n.coachGoalTarget),
                      validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null
                          ? i18n.enterValidNumber
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _unit,
                      decoration: InputDecoration(labelText: i18n.unit),
                    ),
                  ),
                ],
              ),
              if (widget.goal != null)
                dropdown(
                  i18n.coachGoalStatus,
                  _status,
                  goalStatuses,
                  i18n.statusLabel,
                  (v) => _status = v,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('goal-save'),
          onPressed: _submit,
          child: Text(i18n.save),
        ),
      ],
    );
  }
}
