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
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/measurements/charts/series.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// The newest value of a measurement, large, and how far it moved since the
/// first point of the range the chart shows.
class MeasurementHero extends StatelessWidget {
  const MeasurementHero({super.key, required this.first, required this.last, required this.unit});

  final MeasurementChartEntry first;
  final MeasurementChartEntry last;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1);

    final delta = last.value - first.value;
    final days = last.date.difference(first.date).inDays;
    // A minus sign, not a hyphen, and no sign at all for no change
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              MonoText(format.format(last.value), size: 44, weight: FontWeight.w600),
              const SizedBox(width: 6),
              Text(unit, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          if (days > 0) ...[
            const SizedBox(height: 6),
            PillChip(
              i18n.measurementHeroChange('$sign${format.format(delta.abs())}', unit, days),
              key: const ValueKey('measurement-hero-change'),
              tone: delta < 0 ? ChipTone.ok : ChipTone.neutral,
              mono: true,
            ),
          ],
        ],
      ),
    );
  }
}
