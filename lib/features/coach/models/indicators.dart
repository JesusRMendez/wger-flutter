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

part 'indicators.g.dart';

@JsonSerializable(createToJson: false)
class Indicator {
  @JsonKey(defaultValue: '')
  final String key;

  @JsonKey(defaultValue: '')
  final String label;

  final num value;

  @JsonKey(defaultValue: '')
  final String unit;

  /// `up`, `down`, `flat` or null
  final String? trend;
  final num? target;

  @JsonKey(name: 'exercise_id')
  final int? exerciseId;

  const Indicator({
    required this.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.trend,
    this.target,
    this.exerciseId,
  });

  factory Indicator.fromJson(Map<String, dynamic> json) => _$IndicatorFromJson(json);
}

@JsonSerializable(createToJson: false)
class MissingData {
  @JsonKey(defaultValue: '')
  final String key;

  @JsonKey(defaultValue: '')
  final String title;

  @JsonKey(defaultValue: '')
  final String detail;

  /// `log_weight`, `log_rir`, `log_nutrition`...
  final String? action;

  const MissingData({required this.key, this.title = '', this.detail = '', this.action});

  factory MissingData.fromJson(Map<String, dynamic> json) => _$MissingDataFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataQuality {
  @JsonKey(defaultValue: 0)
  final int score;

  @JsonKey(defaultValue: <MissingData>[])
  final List<MissingData> missing;

  const DataQuality({this.score = 0, this.missing = const []});

  factory DataQuality.fromJson(Map<String, dynamic> json) => _$DataQualityFromJson(json);
}

/// Response of `coach-indicators/`
@JsonSerializable(createToJson: false)
class IndicatorsResponse {
  @JsonKey(defaultValue: 28)
  final int window;

  @JsonKey(defaultValue: <Indicator>[])
  final List<Indicator> indicators;

  @JsonKey(name: 'data_quality')
  final DataQuality? dataQuality;

  const IndicatorsResponse({this.window = 28, this.indicators = const [], this.dataQuality});

  factory IndicatorsResponse.fromJson(Map<String, dynamic> json) =>
      _$IndicatorsResponseFromJson(json);
}
