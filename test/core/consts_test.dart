/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
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

import 'package:flutter_test/flutter_test.dart';
import 'package:wger/core/consts.dart';

void main() {
  // The override is a compile time define, so a single run can only observe one
  // side of it. CI runs the plain suite, which covers the fallback; the other
  // side is covered by
  // `flutter test --dart-define=WGER_DEFAULT_SERVER=https://qa.example.com test/core/consts_test.dart`
  const override = String.fromEnvironment('WGER_DEFAULT_SERVER');

  group('DEFAULT_SERVER_PROD', () {
    test('keeps the upstream server when WGER_DEFAULT_SERVER is unset or empty', () {
      expect(UPSTREAM_SERVER_PROD, 'https://wger.de');
      expect(DEFAULT_SERVER_PROD, 'https://wger.de');
    }, skip: override.isNotEmpty ? 'WGER_DEFAULT_SERVER is defined for this run' : false);

    test('uses WGER_DEFAULT_SERVER when it is defined', () {
      expect(DEFAULT_SERVER_PROD, override);
    }, skip: override.isEmpty ? 'WGER_DEFAULT_SERVER is not defined for this run' : false);
  });
}
