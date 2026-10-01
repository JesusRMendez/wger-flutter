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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/core/misc.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/widgets/exercises.dart';
import 'package:wger/features/exercises/widgets/images.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Formats a single number, or a range if there is a different maximum
String _formatRange(num value, num? max) {
  final out = formatNum(value).toString();
  if (max == null || max == value) {
    return out;
  }
  return '$out-${formatNum(max)}';
}

/// Short summary of the planned set, e.g. "8-10 × 50 lb" or "30 Seconds".
///
/// The units are the ones of the [config], nothing is assumed: the repetition
/// unit is only left out for plain repetitions together with a weight (where
/// "8 × 50 kg" is clear enough). [translate] localizes the unit names that
/// come from the server.
///
/// Falls back to the server's text representation if the units are not
/// available (not hydrated) or there is nothing to show.
String plannedSetSummary(SetConfigData config, {required String Function(String) translate}) {
  final repUnit = config.repetitionsUnit;
  final weightUnit = config.weightUnit;
  final hasReps = config.repetitions != null;
  final hasWeight = config.weight != null && config.weight != 0;

  // kg and lb say nothing without a value, other units such as "Body Weight"
  // are the information themselves
  final valuelessWeightUnit =
      !hasWeight &&
      weightUnit != null &&
      weightUnit.id != WEIGHT_UNIT_KG &&
      weightUnit.id != WEIGHT_UNIT_LB;

  final repUnitMissing =
      repUnit == null &&
      config.repetitionsUnitId != null &&
      config.repetitionsUnitId != REP_UNIT_REPETITIONS_ID;
  final weightUnitMissing = weightUnit == null && hasWeight && config.weightUnitId != null;
  if (repUnitMissing || weightUnitMissing) {
    return config.textReprWithType;
  }

  final parts = <String>[];

  if (hasReps) {
    parts.add(_formatRange(config.repetitions!, config.maxRepetitions));
    // The default unit is left out if there is a weight, "8 × 50 kg" is clear
    // enough. Every other unit is always shown.
    if (repUnit != null &&
        (repUnit.id != REP_UNIT_REPETITIONS_ID || !(hasWeight || valuelessWeightUnit))) {
      parts.add(translate(repUnit.name));
    }
  } else if (repUnit != null && repUnit.id != REP_UNIT_REPETITIONS_ID) {
    // Units without a value, e.g. "Until Failure"
    parts.add(translate(repUnit.name));
  }

  if (hasWeight) {
    parts.add('×');
    parts.add(_formatRange(config.weight!, config.maxWeight));
    parts.add(translate(weightUnit!.name));
  } else if (valuelessWeightUnit) {
    if (parts.isNotEmpty) {
      parts.add('×');
    }
    parts.add(translate(weightUnit.name));
  }

  return parts.isEmpty ? config.textReprWithType : parts.join(' ');
}

/// Opens the full exercise (images, videos, description, ...) in a bottom sheet
Future<void> showExerciseDetailsSheet(BuildContext context, Exercise exercise) {
  final languageCode = Localizations.localeOf(context).languageCode;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.85,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                  child: Text(
                    exercise.getTranslation(languageCode).name,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('exercise-details-close'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ExerciseDetail(exercise),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shows what comes after the current rest: the exercise (image, name), the
/// planned set and a button to open the exercise's details.
///
/// [slotUuid] is the timer page the preview is shown on. The preview is the
/// first log page after it. Shows nothing at the end of the workout.
class NextExercisePreview extends ConsumerWidget {
  final String slotUuid;

  const NextExercisePreview(this.slotUuid, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymStateProvider);
    final timerPage = gymState.getSlotPageByUUID(slotUuid);
    if (timerPage == null) {
      return const SizedBox.shrink();
    }

    final next = gymState.nextLogSlotPageAfter(timerPage.pageIndex);
    final nextConfig = next?.setConfigData;
    if (nextConfig == null) {
      return const SizedBox.shrink();
    }

    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercise = nextConfig.exercise;
    final isNewExercise = timerPage.setConfigData?.exercise.id != exercise.id;
    final name = exercise.getTranslation(Localizations.localeOf(context).languageCode).name;

    return Card(
      key: const ValueKey('next-exercise-preview'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ExerciseImageWidget(image: exercise.getMainImage, height: 64),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNewExercise ? i18n.gymModeNextExercise : i18n.gymModeNextSet,
                    key: const ValueKey('next-exercise-label'),
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                  Text(name, style: theme.textTheme.titleMedium),
                  Text(
                    plannedSetSummary(
                      nextConfig,
                      translate: (value) => getServerStringTranslation(value, context),
                    ),
                    key: const ValueKey('next-exercise-summary'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('next-exercise-details-button'),
              tooltip: i18n.gymModeExerciseDetails,
              icon: const Icon(Icons.info_outline),
              onPressed: () => showExerciseDetailsSheet(context, exercise),
            ),
          ],
        ),
      ),
    );
  }
}
