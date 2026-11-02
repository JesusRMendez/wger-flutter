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

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/legacy_material_scope.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/routines/logic/session_stats.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/models/session.dart';
import 'package:wger/features/routines/widgets/logs/day_logs_container.dart';
import 'package:wger/features/trophies/providers/trophy_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class WorkoutLogs extends ConsumerWidget {
  final Routine _routine;

  const WorkoutLogs(this._routine);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final trophyNotifier = ref.read(trophyStateProvider.notifier);
    trophyNotifier.fetchUserTrophies(language: languageCode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SizedBox(
          width: double.infinity,
          child: WorkoutLogCalendar(_routine, ref.watch(ownerTimeZoneProvider)),
        ),
      ],
    );
  }
}

/// An event in the workout log calendar
class WorkoutLogEvent {
  final DateTime dateTime;

  const WorkoutLogEvent(this.dateTime);
}

class WorkoutLogCalendar extends StatefulWidget {
  final Routine _routine;

  /// The owner's IANA zone the day markers are cut in, null falls back to
  /// the device zone
  final String? _ownerZone;

  const WorkoutLogCalendar(this._routine, this._ownerZone);

  @override
  _WorkoutLogCalendarState createState() => _WorkoutLogCalendarState();
}

class _WorkoutLogCalendarState extends State<WorkoutLogCalendar> {
  DateTime _focusedDay = clock.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<DateTime>> _selectedEvents;
  late Map<String, List<DateTime>> _events;

  @override
  void initState() {
    super.initState();

    _events = {};
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void loadEvents() {
    for (final session in widget._routine.sessions) {
      // One entry per session, the calendar draws a marker for each of them
      final day = session.localDayIn(widget._ownerZone);
      _events.putIfAbsent(DateFormatLists.format(day), () => []).add(day);
    }

    _selectedEvents.value = _getEventsForDay(_selectedDay!);
  }

  List<DateTime> _getEventsForDay(DateTime day) {
    return _events[DateFormatLists.format(day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  /// The color of a training day in the calendar and its legend
  Color _dayColor(BuildContext context, int? dayId) {
    final atlas = context.atlas;
    final palette = [
      Theme.of(context).colorScheme.primary,
      atlas.ok,
      atlas.fat,
      atlas.warn,
      atlas.accent,
      atlas.protein,
    ];
    final index = widget._routine.days.indexWhere((d) => d.id == dayId);
    return palette[(index < 0 ? 0 : index) % palette.length];
  }

  /// The sessions of the month on screen
  List<WorkoutSession> _monthSessions() => [
    for (final s in widget._routine.sessions)
      if (s.localDayIn(widget._ownerZone).year == _focusedDay.year &&
          s.localDayIn(widget._ownerZone).month == _focusedDay.month)
        s,
  ];

  Widget _stats(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final sessions = _monthSessions();

    final minutes = sessions.fold<int>(0, (sum, s) => sum + (s.duration?.inMinutes ?? 0));
    final volume = sessions.fold<num>(0, (sum, s) => sum + sessionVolume(s));
    final nf = NumberFormat.decimalPattern(locale);

    final hours = nf.format(double.parse((minutes / 60).toStringAsFixed(1)));
    final tonnes = volume >= 1000;
    final volumeText = tonnes
        ? nf.format(double.parse((volume / 1000).toStringAsFixed(1)))
        : nf.format(volume.round());

    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: _MiniStat(
            key: const ValueKey('history-sessions'),
            value: '${sessions.length}',
            label: i18n.historySessionsIn(DateFormat.MMM(locale).format(_focusedDay)),
          ),
        ),
        Expanded(
          child: _MiniStat(
            key: const ValueKey('history-hours'),
            value: '$hours h',
            label: i18n.historyTraining,
          ),
        ),
        Expanded(
          child: _MiniStat(
            key: const ValueKey('history-volume'),
            value: '$volumeText ${tonnes ? 't' : i18n.kg}',
            label: i18n.volume.toLowerCase(),
          ),
        ),
      ],
    );
  }

  Widget _calendar(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    Widget cell(
      DateTime day, {
      Color? fill,
      Color? border,
      Color? text,
      FontWeight? weight,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Text(
          '${day.day}',
          style: theme.textTheme.bodyLarge?.copyWith(color: text, fontWeight: weight),
        ),
      );
    }

    // The days of the month that have a session, to list in the legend
    final legendDays = <int?>{
      for (final s in _monthSessions()) s.dayId,
    };

    return AtlasCard(
      key: const ValueKey('history-calendar'),
      child: Column(
        children: [
          LegacyMaterialScope(
            child: TableCalendar(
              locale: locale,
              firstDay: clock.now().subtract(const Duration(days: 1000)),
              lastDay: clock.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              rowHeight: 48,
              daysOfWeekHeight: 28,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: theme.textTheme.bodyLarge!,
                weekendTextStyle: theme.textTheme.bodyLarge!,
                markersMaxCount: 3,
                markersAlignment: Alignment.bottomCenter,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!,
                headerPadding: const EdgeInsets.only(bottom: 8),
                leftChevronIcon: _chevron(context, Icons.chevron_left),
                rightChevronIcon: _chevron(context, Icons.chevron_right),
                leftChevronMargin: EdgeInsets.zero,
                rightChevronMargin: EdgeInsets.zero,
                leftChevronPadding: EdgeInsets.zero,
                rightChevronPadding: EdgeInsets.zero,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.bodySmall!.copyWith(color: atlas.ink3),
                weekendStyle: theme.textTheme.bodySmall!.copyWith(color: atlas.ink3),
              ),
              eventLoader: _getEventsForDay,
              availableGestures: AvailableGestures.horizontalSwipe,
              availableCalendarFormats: const {CalendarFormat.month: ''},
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focused) => cell(
                  day,
                  fill: _getEventsForDay(day).isEmpty ? null : atlas.surface2,
                ),
                todayBuilder: (context, day, focused) => cell(
                  day,
                  fill: _getEventsForDay(day).isEmpty ? null : atlas.surface2,
                  border: theme.colorScheme.primary,
                ),
                selectedBuilder: (context, day, focused) => cell(
                  day,
                  fill: theme.colorScheme.onSurface,
                  text: theme.colorScheme.surface,
                  weight: FontWeight.w600,
                ),
                markerBuilder: (context, day, events) {
                  final sessions = [
                    for (final s in widget._routine.sessions)
                      if (isSameDay(s.localDayIn(widget._ownerZone), day)) s,
                  ];
                  if (sessions.isEmpty) {
                    return null;
                  }
                  return Positioned(
                    bottom: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 3,
                      children: [
                        for (final s in sessions.take(3))
                          Container(
                            key: ValueKey('history-dot-${s.id}'),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _dayColor(context, s.dayId),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (legendDays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              key: const ValueKey('history-legend'),
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final id in legendDays)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _dayColor(context, id),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        widget._routine.days.firstWhereOrNull((d) => d.id == id)?.name ??
                            AppLocalizations.of(context).workoutSession,
                        style: theme.textTheme.bodyMedium?.copyWith(color: _dayColor(context, id)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chevron(BuildContext context, IconData icon) {
    final atlas = context.atlas;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: atlas.line),
      ),
      child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _stats(context),
        const SizedBox(height: 12),
        _calendar(context),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<DateTime>>(
          valueListenable: _selectedEvents,
          builder: (context, logEvents, _) {
            // Every event of a day carries that same day, the widget below
            // renders all sessions logged on it
            return logEvents.isNotEmpty
                ? DayLogWidget(logEvents.first, widget._routine)
                : Container();
          },
        ),
        ExpansionTile(
          showTrailingIcon: false,
          dense: true,
          title: const Align(alignment: Alignment.centerLeft, child: Icon(Icons.info_outline)),
          children: [
            Text(
              AppLocalizations.of(context).logHelpEntries,
              textAlign: TextAlign.justify,
            ),
            Text(
              AppLocalizations.of(context).logHelpEntriesUnits,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return AtlasCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MonoText(value, size: 24, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
          ),
        ],
      ),
    );
  }
}
