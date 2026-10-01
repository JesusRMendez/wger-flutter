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

import 'package:wger/features/routines/models/set_config_data.dart';

/// Time budgets (in minutes) offered as chips
const TIME_BUDGET_MINUTES = [30, 45, 60, 75];

/// Rest between sets if the exercise has none configured, in seconds
const DEFAULT_REST_SECONDS = 60;

/// Seconds that one repetition takes, for sets that are counted in repetitions
const SECONDS_PER_REPETITION = 4;

/// Assumed work time of a set without a usable number of repetitions
const DEFAULT_WORK_SECONDS = 40;

/// Seconds of work of one set. Time-based units (seconds, minutes) are taken
/// as they are, repetitions are estimated at [SECONDS_PER_REPETITION] each.
int estimateWorkSeconds(SetConfigData config) {
  final value = config.repetitions ?? config.maxRepetitions;
  final unit = config.repetitionsUnit?.name.toLowerCase();

  if (value != null && value > 0) {
    if (unit == 'seconds') {
      return value.round();
    }
    if (unit == 'minutes') {
      return (value * 60).round();
    }
    if (unit == null || unit == 'repetitions') {
      return (value * SECONDS_PER_REPETITION).round();
    }
  }
  return DEFAULT_WORK_SECONDS;
}

/// Seconds of rest after one set
int estimateRestSeconds(SetConfigData config, {int defaultRest = DEFAULT_REST_SECONDS}) {
  return (config.restTime ?? defaultRest).round();
}

/// The sets of one exercise (page) that are still to be done
class BudgetItem {
  /// Identifies the item, e.g. the UUID of the gym mode page
  final String id;

  /// Seconds (work + rest) of each remaining set, in the order they are done
  final List<int> setSeconds;

  /// Sets are dropped in groups of this size, e.g. 2 for a superset of two
  /// exercises so that the exercises stay balanced
  final int granularity;

  /// Number of sets that always stay. Exercises that were already started
  /// can be shortened completely, others keep at least one group.
  final int minKeep;

  const BudgetItem({
    required this.id,
    required this.setSeconds,
    this.granularity = 1,
    this.minKeep = 1,
  });

  int get totalSeconds => setSeconds.fold(0, (a, b) => a + b);

  /// Whether another group of sets can be dropped
  bool get canDrop => setSeconds.length - granularity >= minKeep;
}

/// The result of [suggestSetsToDrop]
class BudgetSuggestion {
  final int budgetSeconds;
  final int estimatedSeconds;
  final int estimatedAfterSeconds;

  /// Number of sets to drop per item id, only items that lose sets are listed
  final Map<String, int> drops;

  const BudgetSuggestion({
    required this.budgetSeconds,
    required this.estimatedSeconds,
    required this.estimatedAfterSeconds,
    required this.drops,
  });

  int get totalDropped => drops.values.fold(0, (a, b) => a + b);

  bool get fitsAlready => estimatedSeconds <= budgetSeconds;

  /// Whether the workout fits after the sets were dropped
  bool get fitsAfter => estimatedAfterSeconds <= budgetSeconds;
}

/// Estimated duration of the sets that are still to be done, in seconds
int estimateDurationSeconds(Iterable<BudgetItem> items) =>
    items.fold(0, (sum, item) => sum + item.totalSeconds);

/// Suggests which sets to drop so that the workout fits into [budgetMinutes].
///
/// Sets are taken from the exercise that has the most sets left (the last one
/// if several tie) one at a time, so that no exercise is cut down while
/// others keep a lot of volume. Every exercise keeps at least
/// [BudgetItem.minKeep] sets. If the budget cannot be reached, as many sets
/// as possible are dropped and [BudgetSuggestion.fitsAfter] is false.
BudgetSuggestion suggestSetsToDrop(Iterable<BudgetItem> items, int budgetMinutes) {
  final budgetSeconds = budgetMinutes * 60;
  final list = items.toList();
  final remaining = [
    for (final item in list) [...item.setSeconds],
  ];
  final drops = <String, int>{};

  final estimated = estimateDurationSeconds(list);
  var total = estimated;

  while (total > budgetSeconds) {
    int? best;
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      final canDrop =
          remaining[i].length >= item.granularity &&
          remaining[i].length - item.granularity >= item.minKeep;
      if (!canDrop) {
        continue;
      }
      if (best == null || remaining[i].length >= remaining[best].length) {
        best = i;
      }
    }
    if (best == null) {
      break;
    }

    final item = list[best];
    for (var n = 0; n < item.granularity; n++) {
      total -= remaining[best].removeLast();
    }
    drops[item.id] = (drops[item.id] ?? 0) + item.granularity;
  }

  return BudgetSuggestion(
    budgetSeconds: budgetSeconds,
    estimatedSeconds: estimated,
    estimatedAfterSeconds: total,
    drops: drops,
  );
}

/// The budget chips to offer: the fixed choices plus the minutes the location
/// has available, sorted and without duplicates
List<int> timeBudgetChoices({int? locationMinutes}) {
  final out = {...TIME_BUDGET_MINUTES};
  if (locationMinutes != null && locationMinutes > 0) {
    out.add(locationMinutes);
  }
  return out.toList()..sort();
}
