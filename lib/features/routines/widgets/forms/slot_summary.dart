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

import 'package:intl/intl.dart';
import 'package:wger/features/routines/models/base_config.dart';
import 'package:wger/features/routines/models/slot_entry.dart';

/// How the load of a slot entry moves from one iteration to the next.
enum ProgressionKind { linear, doubleProgression, manual }

/// Reads the progression of an entry from its configs: more than one iteration
/// with a growing weight is a linear progression, one with a repetition range
/// is a double progression, anything else is progressed by hand.
ProgressionKind progressionOf(SlotEntry entry) {
  if (!entry.hasProgressionRules) {
    return ProgressionKind.manual;
  }
  if (entry.maxRepetitionsConfigs.isNotEmpty) {
    return ProgressionKind.doubleProgression;
  }
  return ProgressionKind.linear;
}

/// The weight added per iteration of a linear progression, if the second
/// weight config is an absolute `+` step.
num? progressionStep(SlotEntry entry) {
  if (entry.weightConfigs.length < 2) {
    return null;
  }
  final next = entry.weightConfigs[1];
  if (next.operation == '+' && next.step == 'abs') {
    return next.value;
  }
  return null;
}

num? _first(List<BaseConfig> configs) => configs.isEmpty ? null : configs.first.value;

/// `120` seconds as `2:00`.
String restLabel(num seconds) {
  final s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Planned sets, repetitions (a range when there is a maximum) and weight of
/// the first iteration of the entry, e.g. `4 x 6-8 · 85 kg`.
String slotEntrySummary(SlotEntry entry, NumberFormat nf) {
  final parts = <String>[];

  final sets = _first(entry.nrOfSetsConfigs);
  final reps = _first(entry.repetitionsConfigs);
  final maxReps = _first(entry.maxRepetitionsConfigs);
  final weight = _first(entry.weightConfigs);
  final rest = _first(entry.restTimeConfigs);

  final repsText = reps == null
      ? null
      : (maxReps != null && maxReps != reps
            ? '${nf.format(reps)}-${nf.format(maxReps)}'
            : nf.format(reps));

  if (sets != null && repsText != null) {
    parts.add('${nf.format(sets)} × $repsText');
  } else if (sets != null) {
    parts.add('${nf.format(sets)} ×');
  } else if (repsText != null) {
    parts.add(repsText);
  }
  if (weight != null) {
    final unit = entry.weightUnitObj?.name ?? '';
    parts.add('${nf.format(weight)} $unit'.trim());
  }
  if (rest != null) {
    parts.add(restLabel(rest));
  }
  return parts.join(' · ');
}
