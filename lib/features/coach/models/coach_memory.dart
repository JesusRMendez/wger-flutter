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

part 'coach_memory.g.dart';

const memoryCategories = ['preference', 'behavior', 'constraint', 'injury'];

@JsonSerializable()
class CoachMemory {
  final int? id;

  @JsonKey(defaultValue: '')
  final String text;

  @JsonKey(defaultValue: 'preference')
  final String category;

  /// `user`, `ai` or `system`
  @JsonKey(defaultValue: 'user', includeToJson: false)
  final String source;

  @JsonKey(includeToJson: false)
  final String? created;

  const CoachMemory({
    this.id,
    this.text = '',
    this.category = 'preference',
    this.source = 'user',
    this.created,
  });

  factory CoachMemory.fromJson(Map<String, dynamic> json) => _$CoachMemoryFromJson(json);

  Map<String, dynamic> toJson() => _$CoachMemoryToJson(this);
}
