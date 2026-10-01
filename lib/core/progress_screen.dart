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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/coach/screens/follow_up_screen.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';
import 'package:wger/features/gallery/screens/gallery_screen.dart';
import 'package:wger/features/measurements/charts/data.dart';
import 'package:wger/features/measurements/charts/range.dart';
import 'package:wger/features/measurements/charts/series.dart';
import 'package:wger/features/measurements/models/measurement_bucket.dart';
import 'package:wger/features/measurements/models/measurement_category.dart';
import 'package:wger/features/measurements/models/unit_conversion.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/measurements/screens/measurement_categories_screen.dart';
import 'package:wger/features/measurements/screens/measurement_entries_screen.dart';
import 'package:wger/features/measurements/screens/weight_screen.dart';
import 'package:wger/features/measurements/widgets/charts/spark_charts.dart';
import 'package:wger/features/measurements/widgets/helpers.dart';
import 'package:wger/features/measurements/widgets/weight_form.dart';
import 'package:wger/features/trophies/screens/trophy_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The fourth tab: the weight at a glance, the measurements with their
/// trends and the screens that hold the rest (photos, trophies, goals and the
/// weekly follow-up), each opening its own screen.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _days = 90;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final weightCategory = ref.watch(bodyWeightCategoryOnlyProvider).value;

    Widget row(
      Key key,
      IconData icon,
      Color color,
      String title,
      String subtitle,
      String route,
    ) {
      return AtlasCard(
        key: key,
        margin: const EdgeInsets.only(top: 12),
        onTap: () => Navigator.of(context).pushNamed(route),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconBadge(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: atlas.ink3),
          ],
        ),
      );
    }

    return Scaffold(
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            AtlasHeader(
              title: i18n.labelBottomNavProgress,
              showBack: false,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              actions: [
                if (weightCategory != null)
                  RoundIconButton(
                    icon: Icons.add,
                    tooltip: i18n.newEntry,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      FormScreen.routeName,
                      arguments: FormScreenArguments(
                        i18n.newEntry,
                        WeightForm(weightCategory),
                      ),
                    ),
                  ),
              ],
            ),
            const _WeightCard(key: ValueKey('progress-weight'), days: _days),
            const _MeasurementsCard(key: ValueKey('progress-measurements'), days: _days),
            row(
              const ValueKey('progress-gallery'),
              Icons.photo_library_outlined,
              atlas.accent,
              i18n.gallery,
              i18n.progressSubtitleGallery,
              GalleryScreen.routeName,
            ),
            row(
              const ValueKey('progress-trophies'),
              Icons.emoji_events_outlined,
              atlas.warn,
              i18n.trophies,
              i18n.progressSubtitleTrophies,
              TrophyScreen.routeName,
            ),
            row(
              const ValueKey('progress-goals'),
              Icons.flag_outlined,
              theme.colorScheme.primary,
              i18n.coachGoalsAndIndicators,
              i18n.progressSubtitleGoals,
              GoalsScreen.routeName,
            ),
            row(
              const ValueKey('progress-follow-up'),
              Icons.insights,
              atlas.fat,
              i18n.coachFollowUp,
              i18n.progressSubtitleFollowUp,
              FollowUpScreen.routeName,
            ),
          ],
        ),
      ),
    );
  }
}

/// "-1.7 kg · 90 d" style change chip
Widget _changeChip(BuildContext context, num change, String unit, int days, {int decimals = 1}) {
  final sign = change > 0 ? '+' : '';
  return PillChip(
    '$sign${change.toStringAsFixed(decimals)} $unit · $days d',
    mono: true,
    tone: ChipTone.brand,
    height: 30,
  );
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final category = ref.watch(bodyWeightCategoryOnlyProvider).value;
    final profile = ref.watch(userProfileProvider).value;

    List<MeasurementChartEntry>? points;
    if (category != null && profile != null) {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      points = chartPointsFor(
        ref,
        category,
        ChartRange.last3Months,
        targetUnit: weightDisplayUnit(profile.isMetric),
      ).value?.where((e) => !e.date.isBefore(cutoff)).toList();
    }
    final unit = profile == null ? 'kg' : weightUnit(profile.isMetric, context);

    final hasData = points != null && points.isNotEmpty;
    final last = hasData ? points.last.value : null;
    final change = hasData ? points.last.value - points.first.value : null;

    return AtlasCard(
      onTap: () => Navigator.of(context).pushNamed(WeightScreen.routeName),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(i18n.weight, style: theme.textTheme.titleMedium)),
              if (change != null && points!.length > 1) _changeChip(context, change, unit, days),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                category == null || profile == null ? '' : i18n.noWeightEntries,
                style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MonoText(
                  last!.toStringAsFixed(1),
                  size: 52,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(unit, style: theme.textTheme.bodyLarge?.copyWith(color: atlas.ink3)),
              ],
            ),
            const SizedBox(height: 12),
            AreaSparkline(values: [for (final p in points) p.value.toDouble()]),
          ],
        ],
      ),
    );
  }
}

class _MeasurementsCard extends ConsumerWidget {
  const _MeasurementsCard({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final categories = ref.watch(measurementCategoriesProvider).value ?? const [];
    final shown = categories
        .where((c) => c.parentId == null && !c.isOfficialBodyWeight && !c.hasChildren)
        .take(4)
        .toList();

    return AtlasCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(i18n.measurements, style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(MeasurementCategoriesScreen.routeName),
                child: Text(i18n.edit),
              ),
            ],
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                i18n.progressSubtitleMeasurements,
                style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
              ),
            ),
          for (final (i, c) in shown.indexed) ...[
            if (i > 0) Divider(height: 1, color: atlas.line),
            _MeasurementRow(c, days: days),
          ],
        ],
      ),
    );
  }
}

class _MeasurementRow extends ConsumerWidget {
  const _MeasurementRow(this.category, {required this.days});

  final MeasurementCategory category;
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final latest = ref.watch(latestMeasurementEntriesProvider).value?[category.id];
    final start = DateTime.now().subtract(Duration(days: days));
    final startDay = DateTime(start.year, start.month, start.day);
    final points = ref
        .watch(
          measurementChartBucketsProvider(
            category.id!,
            startDay,
            null,
            MeasurementBucketLevel.day,
          ),
        )
        .whenData(
          (b) => chartEntriesForBuckets(
            b,
            targetUnit: category.unit,
            categoryUnit: category.unit,
            summed: category.metricType.isSummedPerDay,
          ),
        )
        .value;

    final decimals = category.metricType.displayDecimals;
    final value = latest == null
        ? '—'
        : measurementValue(
            context,
            latest.valueIn(category.unit, categoryUnit: category.unit),
            category.unit,
            decimals: decimals,
          );
    final change = points != null && points.length > 1
        ? points.last.value - points.first.value
        : null;

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        MeasurementEntriesScreen.routeName,
        arguments: category.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.displayName(context),
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  MonoText(
                    '$value ${measurementUnit(category.unit)}'.trim(),
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: atlas.ink3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              height: 36,
              child: points != null && points.length > 1
                  ? SparkLineChart(points, start: startDay, days: days)
                  : null,
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 68,
              child: change == null
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: PillChip(
                        '${change > 0 ? '+' : ''}${change.toStringAsFixed(decimals.clamp(0, 1))}',
                        mono: true,
                        tone: ChipTone.brand,
                        height: 30,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
