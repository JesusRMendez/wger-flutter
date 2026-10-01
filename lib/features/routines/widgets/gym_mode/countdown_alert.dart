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

/// The alert that is played at a given moment of the rest countdown
enum CountdownAlert {
  /// Nothing to do
  none,

  /// 20 seconds are left: double haptic feedback and a sound
  warning,

  /// One of the last seconds: light haptic feedback and a click
  tick,

  /// The countdown reached zero
  end,
}

/// Remaining seconds at which the warning is given
const COUNTDOWN_WARNING_SECONDS = 20;

/// Number of seconds at the end of the countdown that are ticked
const COUNTDOWN_TICK_SECONDS = 5;

/// Decides which alert (if any) is due when [remainingSeconds] of a countdown
/// of [totalSeconds] are left.
///
/// - 0 seconds: [CountdownAlert.end], if [alertAtEnd] is set
/// - 1 to 5 seconds: [CountdownAlert.tick], if [alertLast5s] is set
/// - exactly 20 seconds: [CountdownAlert.warning], if [alertAt20s] is set
///
/// Alerts only make sense for time that actually elapsed, so a countdown that
/// starts at (or below) a threshold does not alert for it: no warning for a
/// rest of 20 seconds or less and no tick at the very start of a short rest.
/// The end alert always applies.
CountdownAlert countdownAlertFor({
  required int remainingSeconds,
  required int totalSeconds,
  bool alertAt20s = true,
  bool alertLast5s = true,
  bool alertAtEnd = true,
}) {
  if (remainingSeconds == 0) {
    return alertAtEnd ? CountdownAlert.end : CountdownAlert.none;
  }

  if (remainingSeconds < 0 || remainingSeconds >= totalSeconds) {
    return CountdownAlert.none;
  }

  if (remainingSeconds <= COUNTDOWN_TICK_SECONDS) {
    return alertLast5s ? CountdownAlert.tick : CountdownAlert.none;
  }

  if (remainingSeconds == COUNTDOWN_WARNING_SECONDS) {
    return alertAt20s ? CountdownAlert.warning : CountdownAlert.none;
  }

  return CountdownAlert.none;
}
