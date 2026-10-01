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

import 'package:json_annotation/json_annotation.dart';

part 'coach_location.g.dart';

/// The subset of a training location the coach needs to pick a location.
@JsonSerializable(createToJson: false)
class CoachLocation {
  final int id;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(name: 'is_default', defaultValue: false)
  final bool isDefault;

  @JsonKey(name: 'available_minutes')
  final int? availableMinutes;

  const CoachLocation({
    required this.id,
    this.name = '',
    this.isDefault = false,
    this.availableMinutes,
  });

  factory CoachLocation.fromJson(Map<String, dynamic> json) => _$CoachLocationFromJson(json);
}
