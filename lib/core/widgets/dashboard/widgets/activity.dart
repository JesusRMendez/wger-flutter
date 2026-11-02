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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/measurements/models/measurement_category.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// What the week strip and the streak card need, derived from the workout
/// sessions and the routine schedule.
class WeekActivity {
  const WeekActivity({required this.days, required this.trained, required this.planned});

  /// Monday to Sunday of the week that contains today
  final List<DateTime> days;

  /// Days of [days] with a logged session
  final Set<DateTime> trained;

  /// Days of [days] the current routine schedules a training for
  final Set<DateTime> planned;
}

/// The Monday of the week [day] falls in, at midnight
DateTime startOfWeek(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
}

/// Number of consecutive calendar weeks, ending with the current one, that
/// hold at least one of the [sessionDays]. The current week does not break the
/// streak while it is still empty: the week is not over yet.
int weeklyStreak(Iterable<DateTime> sessionDays, DateTime now) {
  final weeks = {for (final d in sessionDays) startOfWeek(d)};
  var cursor = startOfWeek(now);
  if (!weeks.contains(cursor)) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
  }
  var streak = 0;
  while (weeks.contains(cursor)) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
  }
  return streak;
}

/// Sleep based readiness score, 0 to 100: eight hours is a full score.
int readinessScore(num sleepMinutes) => (sleepMinutes / 480 * 100).clamp(0, 100).round();

/// The dashboard's first card: the week strip with a dot per trained or
/// planned day, and next to each other the readiness (from last night's sleep)
/// and the weekly training streak.
class DashboardActivityWidget extends ConsumerWidget {
  const DashboardActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesRiverpodProvider).value;
    final zone = ref.watch(userProfileProvider).value?.timeZone;
    final now = clock.now();

    final trainedDays = <DateTime>{
      for (final s in routines?.sessions ?? const []) _midnight(s.localDayIn(zone)),
    };
    final monday = startOfWeek(now);
    final days = [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
    final planned = <DateTime>{
      for (final d in routines?.currentRoutine?.dayDataCurrentIteration ?? const [])
        if (d.day != null && !d.day!.isRest) _midnight(d.date),
    };

    final week = WeekActivity(
      days: days,
      trained: trainedDays.where(days.contains).toSet(),
      planned: planned.where(days.contains).toSet(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeekStrip(week: week, today: _midnight(now)),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _ReadinessCard()),
              const SizedBox(width: 12),
              Expanded(child: _StreakCard(streak: weeklyStreak(trainedDays, now))),
            ],
          ),
        ),
      ],
    );
  }
}

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

/// Seven day columns, Monday first: the weekday initial, the date and a dot
/// (green for a trained day, brand for a planned one). Today is the inverse pill.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.week, required this.today});

  final WeekActivity week;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;
    final atlas = context.atlas;
    final theme = Theme.of(context);

    return Row(
      children: [
        for (final day in week.days)
          Expanded(
            child: Builder(
              builder: (context) {
                final isToday = day == today;
                final trained = week.trained.contains(day);
                final planned = week.planned.contains(day);
                final fg = isToday ? scheme.surface : scheme.onSurface;
                final dot = trained ? atlas.ok : (planned ? scheme.primary : null);

                return Semantics(
                  label: DateFormat.MMMEd(locale).format(day),
                  child: Container(
                    key: ValueKey('week-strip-${day.weekday}'),
                    height: 72,
                    decoration: BoxDecoration(
                      color: isToday ? scheme.onSurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(AtlasRadius.card),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.E(locale).format(day).substring(0, 1).toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isToday ? scheme.surface.withValues(alpha: 0.7) : atlas.ink3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        MonoText(
                          '${day.day}',
                          size: 20,
                          color: fg,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 6,
                          width: 6,
                          child: dot == null
                              ? null
                              : DecoratedBox(
                                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Readiness from the latest sleep entry. Collapses when the user has no sleep
/// data (no health sync, no manual entries), since there is nothing to derive
/// it from.
class _ReadinessCard extends ConsumerWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);

    final categories = ref.watch(measurementCategoriesProvider).value ?? const [];
    final latest = ref.watch(latestMeasurementEntriesProvider).value ?? const {};

    // Total sleep when the importer split the night into stages, else the plain sleep metric
    final sleep =
        categories.where((c) => c.metricType == MetricType.sleepTotal).firstOrNull ??
        categories.where((c) => c.metricType == MetricType.sleep).firstOrNull;
    final entry = sleep == null ? null : latest[sleep.id];
    final recent = entry != null && clock.now().difference(entry.date) < const Duration(days: 2);

    final eyebrow = SectionEyebrow(i18n.readiness);
    if (!recent) {
      return AtlasCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrow,
            const SizedBox(height: 8),
            Text(
              i18n.readinessNoData,
              style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
            ),
          ],
        ),
      );
    }

    final minutes = entry.value;
    final score = readinessScore(minutes);
    final (label, color) = score >= 75
        ? (i18n.readinessHigh, atlas.ok)
        : score >= 50
        ? (i18n.readinessMedium, atlas.warn)
        : (i18n.readinessLow, atlas.accent);
    final hours = minutes ~/ 60;
    final rest = (minutes % 60).round();

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eyebrow,
          const SizedBox(height: 10),
          Row(
            children: [
              ProgressRing(
                value: score / 100,
                size: 56,
                strokeWidth: 6,
                color: color,
                semanticLabel: i18n.readiness,
                child: MonoText('$score', size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleSmall),
                    Text(
                      i18n.readinessSleep('$hours h $rest'),
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionEyebrow(i18n.streak),
          const SizedBox(height: 10),
          Row(
            children: [
              IconBadge(
                Icons.local_fire_department_outlined,
                size: 56,
                circle: true,
                color: atlas.accent,
                background: atlas.accentSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoText('$streak', size: 26),
                    Text(
                      i18n.streakWeeks(streak),
                      style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
