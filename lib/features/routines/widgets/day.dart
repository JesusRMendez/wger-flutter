/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/date.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/widgets/exercises.dart';
import 'package:wger/features/routines/logic/gym_progress.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/models/slot_data.dart';
import 'package:wger/features/routines/models/slot_entry.dart';
import 'package:wger/features/routines/screens/guided_mode.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';
import 'package:wger/features/routines/widgets/forms/slot_summary.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The planned headline of the sets of one exercise, e.g. `4 × 6-8 @ 85 kg`
String setConfigHeadline(SetConfigData c, NumberFormat nf) {
  final parts = <String>[];
  final reps = c.repetitions;
  final maxReps = c.maxRepetitions;
  final repsText = reps == null
      ? null
      : (maxReps != null && maxReps != reps
            ? '${nf.format(reps)}-${nf.format(maxReps)}'
            : nf.format(reps));
  final sets = c.nrOfSets;
  if (sets != null && repsText != null) {
    parts.add('${nf.format(sets)} × $repsText');
  } else if (sets != null) {
    parts.add('${nf.format(sets)} ×');
  } else if (repsText != null) {
    parts.add(repsText);
  }
  var text = parts.join();
  final weight = c.weight;
  if (weight != null && weight > 0) {
    final unit = c.weightUnit?.name ?? 'kg';
    text += '${text.isEmpty ? '' : ' @ '}${nf.format(weight)} $unit';
  }
  return text;
}

/// One exercise of a slot with what is planned for it: the headline in mono
/// and chips for the rest, the RiR and the set type.
class SetConfigDataWidget extends StatelessWidget {
  final Exercise exercise;
  final List<SetConfigData> configs;

  const SetConfigDataWidget({required this.exercise, required this.configs, super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final atlas = context.atlas;
    final nf = localizedNumberFormat(context);
    final first = configs.first;

    final chips = <Widget>[
      if (first.restTime != null)
        PillChip(
          i18n.slotChipRest(restLabel(first.restTime!)),
          mono: true,
          height: 28,
          fontSize: 12,
        ),
      if (first.rir != null)
        PillChip(i18n.slotChipRir(nf.format(first.rir)), mono: true, fontSize: 12),
      if (first.type != SlotEntryType.normal)
        PillChip(first.type.name.toUpperCase(), tone: ChipTone.warn, fontSize: 11),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(exercise.getTranslation(languageCode).name),
                  content: ExerciseDetail(exercise),
                  actions: [
                    TextButton(
                      child: Text(MaterialLocalizations.of(context).closeButtonLabel),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            exercise.getTranslation(languageCode).name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        if (configs.length == 1)
          MonoText(
            setConfigHeadline(first, nf),
            key: ValueKey('slot-headline-${first.slotEntryId}'),
            size: 17,
            color: Theme.of(context).colorScheme.onSurface,
          )
        else
          for (final c in configs) Text(c.textReprWithType, style: TextStyle(color: atlas.ink2)),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ],
    );
  }
}

class RoutineDayWidget extends StatelessWidget {
  final DayData _dayData;
  final int _routineId;
  final bool _viewMode;

  /// Draw the day as a card with its header; the tabbed view shows the day
  /// bare, the tab already names it
  final bool framed;

  const RoutineDayWidget(
    this._dayData,
    this._routineId,
    this._viewMode, {
    this.framed = true,
    super.key,
  });

  Widget getSlotDataRow(SlotData slotData, int number, BuildContext context) {
    final atlas = context.atlas;
    final brand = Theme.of(context).colorScheme.primary;

    // If there's a single exercise with different sets, group them all into
    // the one exercise and don't show separate rows for each one.
    final groups = slotData.setConfigs.fold<Map<Exercise, List<SetConfigData>>>({}, (acc, entry) {
      acc.putIfAbsent(entry.exercise, () => []).add(entry);
      return acc;
    });

    return Container(
      key: ValueKey('slot-card-$number'),
      margin: EdgeInsets.fromLTRB(framed ? 12 : 0, 0, framed ? 12 : 0, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: framed ? atlas.surface2 : atlas.card,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
        border: Border.all(color: slotData.isSuperset ? brand.withAlpha(90) : atlas.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: atlas.surface3,
              borderRadius: BorderRadius.circular(12),
            ),
            child: MonoText('$number', size: 15),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slotData.comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      slotData.comment,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
                    ),
                  ),
                for (final (i, e) in groups.entries.indexed) ...[
                  if (i > 0) const SizedBox(height: 14),
                  SetConfigDataWidget(exercise: e.key, configs: e.value),
                ],
              ],
            ),
          ),
          if (slotData.isSuperset)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: atlas.brandSoft, shape: BoxShape.circle),
              child: Icon(Icons.link, size: 18, color: brand),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final configs = _dayData.slots.expand((slot) => slot.setConfigs);
    final stats = dayStats(configs);

    final summary = _dayData.slots.isEmpty
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(framed ? 16 : 4, 10, 16, 12),
            child: Text(
              i18n.routineDaySummary(stats.sets, estimatedMinutesFor(configs)),
              key: ValueKey('day-summary-${_dayData.day?.id}'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
            ),
          );

    if (!framed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?summary,
            ..._dayData.slots.indexed.map((e) => getSlotDataRow(e.$2, e.$1 + 1, context)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: AtlasCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DayHeader(day: _dayData, routineId: _routineId, viewMode: _viewMode),
            ?summary,
            ..._dayData.slots.indexed.map((e) => getSlotDataRow(e.$2, e.$1 + 1, context)),
          ],
        ),
      ),
    );
  }
}

class DayHeader extends StatelessWidget {
  final DayData _dayData;
  final int _routineId;
  final bool _viewMode;

  const DayHeader({required DayData day, required int routineId, bool viewMode = false})
    : _dayData = day,
      _viewMode = viewMode,
      _routineId = routineId;

  Widget _todayChip(BuildContext context) => PillChip(
    AppLocalizations.of(context).today,
    tone: ChipTone.brand,
    height: 24,
    fontSize: 11,
  );

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    if (_dayData.day == null || _dayData.day!.isRest) {
      return ListTile(
        tileColor: context.atlas.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          i18n.restDay,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const Icon(Icons.hotel),
        trailing: _dayData.date.isSameDayAs(DateTime.now()) ? _todayChip(context) : null,
        minLeadingWidth: 8,
      );
    }

    return ListTile(
      tileColor: context.atlas.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        _dayData.day!.nameWithType,
        style: Theme.of(context).textTheme.titleMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_dayData.day!.description),
      leading: _viewMode ? null : const Icon(Icons.play_arrow),
      trailing: _viewMode
          ? (_dayData.date.isSameDayAs(DateTime.now()) ? _todayChip(context) : null)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: ValueKey('guided-mode-button-${_dayData.day!.id}'),
                  tooltip: i18n.guidedMode,
                  icon: const Icon(Icons.timer_outlined),
                  onPressed: () => Navigator.of(context).pushNamed(
                    GuidedModeScreen.routeName,
                    arguments: GymModeArguments(_routineId, _dayData.day!.id!, _dayData.iteration),
                  ),
                ),
                if (_dayData.date.isSameDayAs(DateTime.now())) _todayChip(context),
              ],
            ),
      minLeadingWidth: 8,
      onTap: () {
        if (!_viewMode) {
          Navigator.of(context).pushNamed(
            GymModeScreen.routeName,
            arguments: GymModeArguments(_routineId, _dayData.day!.id!, _dayData.iteration),
          );
        }
      },
    );
  }
}
