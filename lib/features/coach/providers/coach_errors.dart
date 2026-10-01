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
import 'package:wger/core/exceptions/http_exception.dart';

/// What went wrong with a coach request, as far as the UI cares.
enum CoachErrorKind {
  /// 403 `ai_not_available`: neither server AI nor an own key is set up
  notAvailable,

  /// 429 `ai_quota_exceeded`: the monthly token limit is used up
  quotaExceeded,

  /// Anything else
  other,
}

CoachErrorKind coachErrorKind(Object error) {
  if (error is WgerHttpException) {
    final code = error.errors['code'];
    if (code == 'ai_not_available') {
      return CoachErrorKind.notAvailable;
    }
    if (code == 'ai_quota_exceeded' || error.statusCode == 429) {
      return CoachErrorKind.quotaExceeded;
    }
  }
  return CoachErrorKind.other;
}
