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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/date.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/core.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/widgets/exercises.dart';
import 'package:wger/features/exercises/widgets/images.dart';
import 'package:wger/features/routines/logic/gym_progress.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/slot_data.dart';
import 'package:wger/features/routines/screens/guided_mode.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// One exercise of a slot: its number in the day, the name (opens the exercise)
/// and what is planned, with a small picture on the right.
class SetConfigDataWidget extends StatelessWidget {
  final Exercise exercise;
  final Widget textRepetitionsWidget;

  /// 1-based position of the slot in the day, null for no badge
  final int? number;

  const SetConfigDataWidget({
    required this.exercise,
    required this.textRepetitionsWidget,
    this.number,
  });

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final atlas = context.atlas;

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      leading: number == null
          ? null
          : Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: atlas.surface3, shape: BoxShape.circle),
              child: MonoText('$number', size: 14),
            ),
      trailing: InkWell(
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: ExerciseImageWidget(image: exercise.getMainImage),
          ),
        ),
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
      ),
      title: Text(
        exercise.getTranslation(languageCode).name,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: DefaultTextStyle.merge(
        style: TextStyle(color: atlas.ink2),
        child: textRepetitionsWidget,
      ),
    );
  }
}

class RoutineDayWidget extends StatelessWidget {
  final DayData _dayData;
  final int _routineId;
  final bool _viewMode;

  const RoutineDayWidget(this._dayData, this._routineId, this._viewMode);

  Widget getSlotDataRow(SlotData slotData, int number, BuildContext context) {
    final atlas = context.atlas;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: atlas.surface2,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
        border: Border.all(color: atlas.line),
      ),
      child: Column(
        children: [
          if (slotData.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: MutedText(slotData.comment),
            ),

          // If there's a single exercise with different sets, group them all into
          // the one exercise and don't show separate rows for each one.
          ...slotData.setConfigs
              .fold<Map<Exercise, List<String>>>({}, (acc, entry) {
                acc.putIfAbsent(entry.exercise, () => []).add(entry.textReprWithType);
                return acc;
              })
              .entries
              .map((entry) {
                return SetConfigDataWidget(
                  exercise: entry.key,
                  number: number,
                  textRepetitionsWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.value.map((text) => Text(text)).toList(),
                  ),
                );
              }),
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

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: AtlasCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DayHeader(day: _dayData, routineId: _routineId, viewMode: _viewMode),
            if (_dayData.slots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(
                  i18n.routineDaySummary(stats.sets, estimatedMinutesFor(configs)),
                  key: ValueKey('day-summary-${_dayData.day?.id}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
                ),
              ),
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
