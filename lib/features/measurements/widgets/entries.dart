/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2020 - 2026 wger Team
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

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/snackbar.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/features/measurements/charts/data.dart';
import 'package:wger/features/measurements/charts/range.dart';
import 'package:wger/features/measurements/charts/series.dart';
import 'package:wger/features/measurements/models/measurement_category.dart';
import 'package:wger/features/measurements/models/measurement_entry.dart';
import 'package:wger/features/measurements/models/unit_conversion.dart';
import 'package:wger/features/measurements/providers/measurement_notifier.dart';
import 'package:wger/features/measurements/widgets/calculation_mark.dart';
import 'package:wger/features/measurements/widgets/chart_range_selector.dart';
import 'package:wger/features/measurements/widgets/helpers.dart';
import 'package:wger/features/measurements/widgets/measurement_hero.dart';
import 'package:wger/features/nutrition/models/nutritional_plan.dart';
import 'package:wger/features/nutrition/providers/nutrition_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

import 'forms/entry.dart';

class EntriesList extends ConsumerWidget {
  final MeasurementCategory category;

  /// Range the entries were read for. Owned by the screen, because it decides
  /// how far back the query reaches, not just what the chart draws.
  final ChartRange range;
  final ValueChanged<ChartRange> onRangeChanged;

  /// Name the category is presented under, `category.name` by default. Body
  /// weight is created by the server and is titled in the user's language
  /// instead of with the name it was stored with.
  final String? title;

  /// Unit the values are converted to, `category.unit` by default. Body weight
  /// is shown in the profile unit, since its entries can be stored in either.
  final String? displayUnit;

  /// Label for [displayUnit], the unit itself by default. The two differ where
  /// the unit is translated (kg reads كغم in Arabic).
  final String? displayUnitLabel;

  /// Form the edit action opens, [MeasurementEntryForm] by default. Body
  /// weight has one of its own, with quick steppers and a unit dropdown.
  final Widget Function(MeasurementEntry entry)? editFormBuilder;

  /// Opens the chart with the newest value large and how much it moved over the
  /// range. The weight screen asks for it, where that number is the point.
  final bool showHero;

  /// Weight (in [displayUnit]) the user is heading for; the weight screen
  /// derives from it when it will be reached at the current pace
  final num? projectionTarget;

  const EntriesList(
    this.category, {
    required this.range,
    required this.onRangeChanged,
    this.title,
    this.displayUnit,
    this.displayUnitLabel,
    this.editFormBuilder,
    this.showHero = false,
    this.projectionTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The overrides describe a single category and only apply to the leaf
    // branch below; a group is presented through its components
    final name = title ?? category.displayName(context);
    final unit = displayUnit ?? category.unit;
    final unitLabel = displayUnitLabel ?? unit;

    // A group carries no entries of its own, its readings live in the
    // components, so everything below would chart an empty list
    if (category.hasChildren) {
      return _buildGroup(context, ref, category);
    }

    // Plan periods only matter where a nutrition plan can plausibly move the
    // metric; other categories skip the watch, so nutrition edits don't
    // rebuild them
    final planPeriods = category.metricType.correlatesWithNutrition
        ? [
            for (final plan
                in ref.watch(nutritionProvider).value?.plans ?? const <NutritionalPlan>[])
              (
                range: DateTimeRange(start: plan.startDate, end: plan.endDate ?? DateTime.now()),
                name: plan.getLabel(context),
              ),
          ]
        : const <PlanPeriod>[];

    return Column(
      children: [
        if (category.isCalculated)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: CalculationMark(category),
            ),
          ),
        if (!showHero)
          ChartRangeSelector(
            value: range,
            onChanged: onRangeChanged,
          ),
        MeasurementChartArea<List<MeasurementChartEntry>>(
          identity: category.id!,
          // Values are read through the unit helper; for plain categories
          // without per-entry units this is a pass-through
          watch: (ref) => chartPointsFor(ref, category, range, targetUnit: unit),
          builder: (context, points) => _chart(context, points, name, unit, unitLabel, planPeriods),
          onError: (_, error) => [StreamErrorIndicator(error.toString())],
        ),
        _EntryList(
          category: category,
          unit: unit,
          unitLabel: unitLabel,
          editFormBuilder: editFormBuilder,
        ),
      ],
    );
  }

  /// The chart, its overall change and the legend, over the range the points
  /// were read for.
  List<Widget> _chart(
    BuildContext context,
    List<MeasurementChartEntry> allPoints,
    String name,
    String unit,
    String unitLabel,
    List<PlanPeriod> planPeriods,
  ) {
    final settings = category.chartSettings;
    final (:entries, :average) = chartSeriesFor(allPoints, range, settings);

    final section = buildSeriesChartSection(
      context,
      name: name,
      entriesAll: entries,
      average: average,
      unit: unitLabel,
      planPeriods: planPeriods,
      metricType: category.metricType,
      chartType: category.chartType,
      settings: settings,
      distribution: MeasurementDistributionChart(
        category: category,
        range: range,
        unitLabel: unitLabel,
        targetUnit: unit,
      ),
    );

    if (!showHero) {
      return section;
    }
    // The weight screen: the value, the range, the chart in a card and what the
    // pace means for the goal
    return [
      if (entries.isNotEmpty)
        MeasurementHero(first: entries.first, last: entries.last, unit: unitLabel),
      ChartRangeSelector(value: range, onChanged: onRangeChanged),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: AtlasCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: section),
        ),
      ),
      if (projectionTarget != null && allPoints.length > 1)
        _ProjectionCard(points: allPoints, target: projectionTarget!, unit: unitLabel),
    ];
  }

  /// Detail view of a multi-value group: one chart over all components, a
  /// legend that doubles as the way into each component, and the readings
  /// themselves.
  ///
  /// Readings are shown but not edited here: one of them is several entries,
  /// and the group form only creates. Editing stays on the component screens,
  /// which the legend rows lead to.
  Widget _buildGroup(BuildContext context, WidgetRef ref, MeasurementCategory category) {
    final i18n = AppLocalizations.of(context);

    return Column(
      children: [
        ChartRangeSelector(
          value: range,
          onChanged: onRangeChanged,
        ),
        MeasurementChartArea<Map<String, List<MeasurementChartEntry>>>(
          identity: category.id!,
          watch: (ref) => groupPointsFor(ref, category, range),
          builder: (context, points) => [
            Container(
              padding: const EdgeInsets.all(15),
              height: 220,
              child: groupHasData(points)
                  ? buildGroupChart(context, category, points)
                  : Center(
                      child: Text(
                        i18n.noDataAvailable,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
            ),
          ],
          onError: (_, error) => [StreamErrorIndicator(error.toString())],
        ),
        GroupComponentRows(
          category,
          trailing: (_, _) => const Icon(Icons.chevron_right),
        ),
        const Divider(),
        _GroupReadingsList(category),
      ],
    );
  }
}

/// A category's entries, newest first, read one page at a time.
///
/// A history that runs into five figures is not a list anyone scrolls to the
/// end of, and reading it whole is what the aggregated queries were introduced
/// to stop. The page grows as it is scrolled.
class _EntryList extends ConsumerStatefulWidget {
  const _EntryList({
    required this.category,
    required this.unit,
    required this.unitLabel,
    this.editFormBuilder,
  });

  final MeasurementCategory category;
  final String unit;
  final String unitLabel;
  final Widget Function(MeasurementEntry entry)? editFormBuilder;

  @override
  ConsumerState<_EntryList> createState() => _EntryListState();
}

class _EntryListState extends ConsumerState<_EntryList> with _GrowsWhileScrolled {
  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final page = ref.watch(measurementEntriesPageProvider(category.id!, limit));
    if (page case AsyncError(:final error)) {
      return StreamErrorIndicator(error.toString());
    }
    final entries = page.value ?? const <MeasurementEntry>[];
    final datetimeFormat = localizedDate(context);

    return _pagedBox(
      itemCount: entries.length,
      hasMore: entries.length >= limit,
      itemBuilder: (context, index) {
        final currentEntry = entries[index];
        final isCalculated = currentEntry.source == measurementSourceCalculated;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: IconBadge(
            currentEntry.source == measurementSourceUser ? Icons.edit_outlined : Icons.sync,
            color: context.atlas.ink2,
          ),
          title: MonoText(
            unitSuffixed(
              measurementValue(
                context,
                currentEntry.valueIn(widget.unit, categoryUnit: category.unit),
                widget.unit,
              ),
              widget.unitLabel,
            ),
            size: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          subtitle: Row(
            children: [
              Text(datetimeFormat.format(currentEntry.date)),
              Text(
                ' · ${isCalculated
                    ? AppLocalizations.of(context).measurementSourceCalculated
                    : currentEntry.source == measurementSourceUser
                    ? AppLocalizations.of(context).measurementSourceManual
                    : AppLocalizations.of(context).measurementSourceImported}',
              ),
            ],
          ),
          // Entries the user did not write are read-only, for two
          // different reasons: an import belongs to the app it came from,
          // a calculated value to the data it is computed from
          trailing: currentEntry.source != measurementSourceUser
              ? Tooltip(
                  message: isCalculated
                      ? AppLocalizations.of(context).calculationEntryInfo
                      : AppLocalizations.of(context).importedEntry,
                  child: Icon(
                    isCalculated ? Icons.calculate_outlined : Icons.monitor_heart_outlined,
                    size: 18,
                    color: context.atlas.ink3,
                  ),
                )
              : PopupMenuButton(
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        child: Text(AppLocalizations.of(context).edit),
                        onTap: () => Navigator.pushNamed(
                          context,
                          FormScreen.routeName,
                          arguments: FormScreenArguments(
                            AppLocalizations.of(context).edit,
                            widget.editFormBuilder?.call(currentEntry) ??
                                MeasurementEntryForm(category.id!, currentEntry),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        child: Text(AppLocalizations.of(context).delete),
                        onTap: () async {
                          await ref
                              .read(measurementProvider.notifier)
                              .deleteEntry(currentEntry.id!);

                          if (context.mounted) {
                            showSnackbar(
                              context,
                              AppLocalizations.of(context).successfullyDeleted,
                              center: true,
                            );
                          }
                        },
                      ),
                    ];
                  },
                ),
        );
      },
    );
  }
}

/// The readings of a group, newest first, read one page at a time.
///
/// A page is entries, not readings, so it lists fewer rows than it read: a
/// blood pressure page of fifty entries is twenty-five readings. Whether there
/// is more to fetch therefore follows from the entries, not from the list.
class _GroupReadingsList extends ConsumerStatefulWidget {
  const _GroupReadingsList(this.category);

  final MeasurementCategory category;

  @override
  ConsumerState<_GroupReadingsList> createState() => _GroupReadingsListState();
}

class _GroupReadingsListState extends ConsumerState<_GroupReadingsList> with _GrowsWhileScrolled {
  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final page = ref.watch(measurementGroupEntriesPageProvider(category.id!, limit));
    if (page case AsyncError(:final error)) {
      return StreamErrorIndicator(error.toString());
    }
    final entries = page.value ?? const <MeasurementEntry>[];
    final readings = groupReadings(category, entries);
    final datetimeFormat = localizedDate(context);
    final total = category.children.firstWhereOrNull((c) => c.metricType.isGroupTotal)?.id;
    final componentsById = {for (final c in category.children) c.id!: c};

    return _pagedBox(
      itemCount: readings.length,
      hasMore: entries.length >= limit,
      itemBuilder: (context, index) {
        final (date, values) = readings[index];
        // A roll-up leads and the parts explain it; without one the values are
        // the reading itself, written the way it is read (a blood pressure as
        // 120/80)
        String formatted(num value) => measurementValue(context, value, category.unit);
        final headline = unitSuffixed(
          quoteGroupReading(category, values, formatted),
          category.unit,
        );
        final parts = [
          for (final MapEntry(key: id, value: value) in values.entries)
            if (id != total) '${componentsById[id]!.displayName(context)} ${formatted(value)}',
        ];

        return ListTile(
          title: Text(headline),
          subtitle: Text(
            [
              datetimeFormat.format(date),
              if (parts.isNotEmpty) parts.join(', '),
            ].join(' · '),
          ),
        );
      },
    );
  }
}

/// A fixed-height list that asks for the next page as it nears its end.
mixin _GrowsWhileScrolled<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  static const _pageSize = 50;

  int limit = _pageSize;

  /// [hasMore] says whether the page came back full, i.e. whether asking for
  /// a larger one can yield anything. It cannot be read off [itemCount], which
  /// counts what is listed rather than what was read: a group lists one
  /// reading per several entries.
  Widget _pagedBox({
    required int itemCount,
    required bool hasMore,
    required Widget? Function(BuildContext context, int index) itemBuilder,
  }) {
    // The limit [hasMore] was decided against. A drag sends many notifications
    // before the rebuild, and without this one gesture would grow the page by
    // several at once, since the answer to "is there more" cannot change
    // until the next build.
    final asked = limit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: AtlasCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 300,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Grown before the end is reached, so the next page is there by the
              // time the user gets to it
              if (notification.metrics.extentAfter < 200 && hasMore && limit == asked) {
                setState(() => limit += _pageSize);
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: itemCount,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, indent: 16, endIndent: 16, color: context.atlas.line),
              itemBuilder: itemBuilder,
            ),
          ),
        ),
      ),
    );
  }
}

/// "At your current pace you reach 77 kg around 10 Dec": a straight line
/// through the last four weeks of readings, followed to the weight the user is
/// heading for.
class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.points, required this.target, required this.unit});

  final List<MeasurementChartEntry> points;
  final num target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);

    final last = points.last;
    final from = last.date.subtract(const Duration(days: 28));
    final window = points.where((p) => !p.date.isBefore(from)).toList();
    if (window.length < 2) {
      return const SizedBox.shrink();
    }

    // Least squares slope in unit per day
    final t0 = window.first.date;
    final xs = [for (final p in window) p.date.difference(t0).inHours / 24];
    final ys = [for (final p in window) p.value.toDouble()];
    final n = xs.length;
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    var num_ = 0.0;
    var den = 0.0;
    for (var i = 0; i < n; i++) {
      num_ += (xs[i] - mx) * (ys[i] - my);
      den += (xs[i] - mx) * (xs[i] - mx);
    }
    if (den == 0) {
      return const SizedBox.shrink();
    }
    final slope = num_ / den;
    final remaining = target - last.value;

    final String text;
    if (remaining.abs() < 0.05) {
      return const SizedBox.shrink();
    } else if (slope.abs() < 0.005 || slope.sign != remaining.sign) {
      text = i18n.weightProjectionAway(target.toStringAsFixed(1), unit);
    } else {
      final days = (remaining / slope).ceil();
      final date = last.date.add(Duration(days: days));
      text = i18n.weightProjectionReach(
        (slope * 7).toStringAsFixed(2),
        unit,
        target.toStringAsFixed(1),
        DateFormat.MMMMd(Localizations.localeOf(context).toString()).format(date),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AtlasCard(
        borderColor: atlas.ok.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, size: 20, color: atlas.ok),
                const SizedBox(width: 10),
                Text(i18n.weightProjection, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2)),
          ],
        ),
      ),
    );
  }
}
