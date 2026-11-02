/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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

import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/routines/models/session.dart';

/// A personal record set in a session: the best set of an exercise, which
/// beats every set of that exercise logged in earlier sessions.
class SessionRecord {
  final Exercise exercise;
  final num weight;
  final num repetitions;

  /// Estimated one rep max of the set (Epley)
  final num oneRepMax;

  const SessionRecord({
    required this.exercise,
    required this.weight,
    required this.repetitions,
    required this.oneRepMax,
  });
}

/// Epley estimate of the one rep max: weight x (1 + reps / 30)
num estimatedOneRepMax(num weight, num repetitions) => weight * (1 + repetitions / 30);

/// The records of [session] derived from the logs: for every exercise whose
/// best set (by estimated one rep max) is better than the best set of the
/// same exercise in [previous]. An exercise without history has no record, the
/// first time is a baseline.
List<SessionRecord> deriveRecords(WorkoutSession session, Iterable<WorkoutSession> previous) {
  final before = previous.where((s) => s.datetimeStart.isBefore(session.datetimeStart));

  final best = <int, num>{};
  for (final s in before) {
    for (final log in s.logs) {
      final w = log.weight;
      final r = log.repetitions;
      if (w == null || r == null || w <= 0 || r <= 0) {
        continue;
      }
      final e = estimatedOneRepMax(w, r);
      if (e > (best[log.exerciseId] ?? 0)) {
        best[log.exerciseId] = e;
      }
    }
  }

  final records = <int, SessionRecord>{};
  for (final log in session.logs) {
    final w = log.weight;
    final r = log.repetitions;
    if (w == null || r == null || w <= 0 || r <= 0) {
      continue;
    }
    final e = estimatedOneRepMax(w, r);
    final prior = best[log.exerciseId];
    if (prior == null || e <= prior) {
      continue;
    }
    final known = records[log.exerciseId];
    if (known == null || e > known.oneRepMax) {
      records[log.exerciseId] = SessionRecord(
        exercise: log.exerciseObj,
        weight: w,
        repetitions: r,
        oneRepMax: e,
      );
    }
  }
  return records.values.toList();
}

/// Volume of the session in the unit it was mostly logged in
num sessionVolume(WorkoutSession session) {
  final v = session.volume;
  return v['metric']! > v['imperial']! ? v['metric']! : v['imperial']!;
}

/// Change of the volume of [session] against the latest earlier session of the
/// same day in [previous], in percent. Null without such a session.
int? volumeChangePercent(WorkoutSession session, Iterable<WorkoutSession> previous) {
  final candidates =
      previous
          .where(
            (s) =>
                s.id != session.id &&
                s.dayId == session.dayId &&
                s.datetimeStart.isBefore(session.datetimeStart) &&
                sessionVolume(s) > 0,
          )
          .toList()
        ..sort((a, b) => b.datetimeStart.compareTo(a.datetimeStart));
  if (candidates.isEmpty) {
    return null;
  }
  final prev = sessionVolume(candidates.first);
  return ((sessionVolume(session) - prev) / prev * 100).round();
}
