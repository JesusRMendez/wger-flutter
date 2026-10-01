/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/date.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/screens/routine_edit_screen.dart';
import 'package:wger/features/routines/widgets/day.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class RoutineDetail extends StatefulWidget {
  final Routine _routine;
  final bool viewMode;

  /// Told which day is shown, so the screen can offer to start it
  final ValueNotifier<DayData?>? selectedDay;

  const RoutineDetail(this._routine, {this.viewMode = false, this.selectedDay, super.key});

  @override
  State<RoutineDetail> createState() => _RoutineDetailState();
}

class _RoutineDetailState extends State<RoutineDetail> {
  late int _iteration;
  int? _dayIndex;

  Routine get _routine => widget._routine;

  int get _currentIteration => _routine.getIteration() ?? 1;

  @override
  void initState() {
    super.initState();
    _iteration = _currentIteration;
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  List<DayData> get _days => _routine.dayDataFilteredFor(_iteration);

  /// The shown day: the chosen one, else today's, else the first
  int get _shownIndex {
    final days = _days;
    if (days.isEmpty) {
      return 0;
    }
    if (_dayIndex != null) {
      return _dayIndex!.clamp(0, days.length - 1);
    }
    final today = days.indexWhere((d) => d.date.isSameDayAs(DateTime.now()));
    return today == -1 ? 0 : today;
  }

  void _publish() {
    final days = _days;
    widget.selectedDay?.value = days.isEmpty ? null : days[_shownIndex];
  }

  @override
  void didUpdateWidget(RoutineDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  Widget _weekChips(BuildContext context, List<int> iterations) {
    final i18n = AppLocalizations.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: iterations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final it = iterations[i];
          final done = it < _currentIteration;
          return Center(
            child: PillChip(
              done ? '${i18n.routineWeekChip(it)} ✓' : i18n.routineWeekChip(it),
              key: ValueKey('week-chip-$it'),
              selected: it == _iteration,
              height: 36,
              fontSize: 13,
              onTap: () => setState(() {
                _iteration = it;
                _dayIndex = null;
                _publish();
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _dayTabs(BuildContext context, List<DayData> days) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final selected = _shownIndex;
    final animate = !MediaQuery.of(context).disableAnimations;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
            for (final (i, d) in days.indexed)
              Pressable(
                key: ValueKey('day-tab-$i'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  _dayIndex = i;
                  _publish();
                }),
                child: AnimatedContainer(
                  duration: animate ? AtlasMotion.base : Duration.zero,
                  curve: AtlasMotion.curve,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? atlas.surface3 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    d.day!.isRest ? AppLocalizations.of(context).restDay : d.day!.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: i == selected ? theme.colorScheme.onSurface : atlas.ink3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    final description = _routine.description.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              _routine.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.atlas.ink2),
            ),
          );

    final emptyEdit = !widget.viewMode && _routine.days.isEmpty
        ? Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, RoutineEditScreen.routeName, arguments: _routine.id);
              },
              child: Text(i18n.edit),
            ),
          )
        : null;

    if (widget.viewMode) {
      return Column(
        children: [
          const SizedBox(height: 10),
          ?description,
          ?emptyEdit,
          ..._routine.dayDataCurrentIterationFiltered.map(
            (dayData) => RoutineDayWidget(dayData, _routine.id!, true),
          ),
        ],
      );
    }

    final iterations = _routine.iterations;
    final days = _days;
    final shown = days.isEmpty ? null : days[_shownIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        if (iterations.length > 1) ...[_weekChips(context, iterations), const SizedBox(height: 8)],
        if (days.length > 1) _dayTabs(context, days),
        if (description != null) description else const SizedBox(height: 8),
        ?emptyEdit,
        if (shown != null)
          RoutineDayWidget(
            shown,
            _routine.id!,
            false,
            framed: false,
            key: ValueKey('day-${shown.iteration}-${shown.day!.id}'),
          ),
      ],
    );
  }
}
