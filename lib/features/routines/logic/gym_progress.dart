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

import 'package:wger/core/consts.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/providers/gym_state.dart';

/// Where a set page sits in the workout: "exercise 2 of 8, set 3 of 4"
class SetPosition {
  const SetPosition({
    required this.exercise,
    required this.exercises,
    required this.set,
    required this.sets,
  });

  /// 1-based position of the exercise (set page) among the exercises
  final int exercise;
  final int exercises;

  /// 1-based position of the set within the exercise
  final int set;
  final int sets;
}

/// The position of the log page [slotUuid], null if it is not one
SetPosition? setPositionOf(GymModeState state, String slotUuid) {
  final setPages = state.pages.where((p) => p.type == PageType.set && p.slotPages.isNotEmpty);
  var exercise = 0;
  for (final page in setPages) {
    exercise++;
    final logs = page.slotPages.where((s) => s.type == SlotPageType.log).toList();
    final index = logs.indexWhere((s) => s.uuid == slotUuid);
    if (index != -1) {
      return SetPosition(
        exercise: exercise,
        exercises: setPages.length,
        set: index + 1,
        sets: logs.length,
      );
    }
  }
  return null;
}

/// Seconds a set is assumed to take, on top of its rest
const assumedSetSeconds = 45;

/// Rest assumed for a set that plans none
const assumedRestSeconds = 90;

/// A rough estimate of the minutes the sets that are not done yet still take:
/// the time of the set itself plus its planned rest, [assumedRestSeconds] where
/// the plan gives none. Zero once everything is done.
int estimatedMinutesLeft(GymModeState state) {
  var seconds = 0;
  for (final page in state.pages) {
    for (final slot in page.slotPages) {
      if (slot.type != SlotPageType.log || slot.logDone) {
        continue;
      }
      seconds += assumedSetSeconds + (slot.setConfigData?.restTime?.toInt() ?? assumedRestSeconds);
    }
  }
  return (seconds / 60).ceil();
}

/// m:ss for a number of seconds
String formatRest(num seconds) {
  final s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// What a training day adds up to, from its plan
class DayStats {
  const DayStats({required this.sets, this.averageRestSeconds, this.volumeKg});

  final int sets;

  /// Mean planned rest, null when no set plans one
  final double? averageRestSeconds;

  /// Planned sets x repetitions x weight, in kg. Null when nothing is planned
  /// with both a weight and repetitions. Weights in other units than kg are
  /// left out rather than guessed.
  final double? volumeKg;
}

/// The totals of the planned sets [configs] of a training day
DayStats dayStats(Iterable<SetConfigData> configs) {
  var sets = 0;
  var restSum = 0.0;
  var restCount = 0;
  var volume = 0.0;
  var hasVolume = false;

  for (final c in configs) {
    final n = (c.nrOfSets ?? 1).toInt();
    sets += n;

    final rest = c.restTime;
    if (rest != null) {
      restSum += rest * n;
      restCount += n;
    }

    final weight = c.weight;
    final reps = c.repetitions;
    final isKg = c.weightUnitId == null || c.weightUnitId == WEIGHT_UNIT_KG;
    if (weight != null && weight > 0 && reps != null && isKg) {
      volume += n * reps * weight;
      hasVolume = true;
    }
  }

  return DayStats(
    sets: sets,
    averageRestSeconds: restCount == 0 ? null : restSum / restCount,
    volumeKg: hasVolume ? volume : null,
  );
}

/// A volume for a tile: tonnes from one tonne up, else kilograms
String formatVolume(double kg) =>
    kg >= 1000 ? '${(kg / 1000).toStringAsFixed(1)} t' : '${kg.round()} kg';

/// A rough duration of the planned sets [configs], in minutes: the set itself
/// and its rest ([assumedRestSeconds] where the plan gives none)
int estimatedMinutesFor(Iterable<SetConfigData> configs) {
  var seconds = 0;
  for (final c in configs) {
    seconds +=
        (c.nrOfSets ?? 1).toInt() *
        (assumedSetSeconds + (c.restTime?.toInt() ?? assumedRestSeconds));
  }
  return (seconds / 60).ceil();
}
