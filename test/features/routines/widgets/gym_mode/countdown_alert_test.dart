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

import 'package:flutter_test/flutter_test.dart';
import 'package:wger/features/routines/widgets/gym_mode/countdown_alert.dart';

CountdownAlert alert(
  int remaining, {
  int total = 90,
  bool at20 = true,
  bool last5 = true,
  bool end = true,
}) => countdownAlertFor(
  remainingSeconds: remaining,
  totalSeconds: total,
  alertAt20s: at20,
  alertLast5s: last5,
  alertAtEnd: end,
);

void main() {
  group('countdownAlertFor', () {
    test('warns exactly when 20 seconds remain', () {
      expect(alert(20), CountdownAlert.warning);
      expect(alert(21), CountdownAlert.none);
      expect(alert(19), CountdownAlert.none);
    });

    test('ticks on each of the last 5 seconds', () {
      for (final s in [5, 4, 3, 2, 1]) {
        expect(alert(s), CountdownAlert.tick, reason: '$s seconds');
      }
      expect(alert(6), CountdownAlert.none);
    });

    test('ends at zero', () {
      expect(alert(0), CountdownAlert.end);
    });

    test('nothing in the middle of the countdown', () {
      for (final s in [89, 60, 45, 30, 15, 10, 7, 6]) {
        expect(alert(s), CountdownAlert.none, reason: '$s seconds');
      }
    });

    test('every alert can be switched off on its own', () {
      expect(alert(20, at20: false), CountdownAlert.none);
      expect(alert(3, last5: false), CountdownAlert.none);
      expect(alert(0, end: false), CountdownAlert.none);

      // The others are not affected
      expect(alert(20, last5: false, end: false), CountdownAlert.warning);
      expect(alert(3, at20: false, end: false), CountdownAlert.tick);
      expect(alert(0, at20: false, last5: false), CountdownAlert.end);
    });

    test('no warning for a countdown that is not longer than 20 seconds', () {
      expect(alert(20, total: 20), CountdownAlert.none);
      expect(alert(20, total: 15), CountdownAlert.none);
      expect(alert(20, total: 21), CountdownAlert.warning);
    });

    test('no tick at the very start of a short countdown', () {
      expect(alert(5, total: 5), CountdownAlert.none);
      expect(alert(4, total: 5), CountdownAlert.tick);
      expect(alert(3, total: 3), CountdownAlert.none);
    });

    test('the end alert applies to every countdown, also very short ones', () {
      expect(alert(0, total: 1), CountdownAlert.end);
      expect(alert(0, total: 0), CountdownAlert.end);
    });

    test('negative values never alert', () {
      expect(alert(-1), CountdownAlert.none);
    });
  });
}
