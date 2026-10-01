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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/providers/exercises_notifier.dart';
import 'package:wger/features/exercises/widgets/detail/aliases_section.dart';
import 'package:wger/features/exercises/widgets/detail/description_section.dart';
import 'package:wger/features/exercises/widgets/detail/images_section.dart';
import 'package:wger/features/exercises/widgets/detail/muscles_section.dart';
import 'package:wger/features/exercises/widgets/detail/notes_section.dart';
import 'package:wger/features/exercises/widgets/detail/videos_section.dart';
import 'package:wger/features/exercises/widgets/list_tile.dart';
import 'package:wger/features/routines/logic/session_stats.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

enum ExerciseTab { technique, history, alternatives }

/// The exercise page: media on top, the name with its muscles and equipment as
/// chips, and tabs for the technique, your own history with the exercise and
/// its variations.
class ExerciseDetailBody extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseDetailBody(this.exercise, {super.key});

  @override
  ConsumerState<ExerciseDetailBody> createState() => _ExerciseDetailBodyState();
}

class _ExerciseDetailBodyState extends ConsumerState<ExerciseDetailBody> {
  ExerciseTab _tab = ExerciseTab.technique;

  Exercise get _exercise => widget.exercise;

  Widget _tabs(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final animate = !MediaQuery.of(context).disableAnimations;
    final labels = {
      ExerciseTab.technique: i18n.exerciseTabTechnique,
      ExerciseTab.history: i18n.exerciseTabHistory,
      ExerciseTab.alternatives: i18n.exerciseTabAlternatives,
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: atlas.card,
        borderRadius: BorderRadius.circular(AtlasRadius.input),
        border: Border.all(color: atlas.line),
      ),
      child: Row(
        children: [
          for (final t in ExerciseTab.values)
            Expanded(
              child: Pressable(
                key: ValueKey('exercise-tab-${t.name}'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _tab = t),
                child: AnimatedContainer(
                  duration: animate ? AtlasMotion.base : Duration.zero,
                  curve: AtlasMotion.curve,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t == _tab ? atlas.surface3 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[t]!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: t == _tab ? theme.colorScheme.onSurface : atlas.ink3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _technique(BuildContext context) {
    final translation = _exercise.getTranslation(Localizations.localeOf(context).languageCode);
    return Column(
      key: const ValueKey('exercise-technique'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        AtlasCard(child: MusclesSection(exercise: _exercise)),
        AtlasCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DescriptionSection(translation: translation),
              NotesSection(translation: translation),
            ],
          ),
        ),
      ],
    );
  }

  Widget _history(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final nf = localizedNumberFormat(context);

    final sessions = [
      for (final s in ref.watch(routinesRiverpodProvider).value?.sessions ?? const [])
        if (s.logs.any((l) => l.exerciseId == _exercise.id)) s,
    ]..sort((a, b) => b.datetimeStart.compareTo(a.datetimeStart));

    if (sessions.isEmpty) {
      return AtlasCard(
        key: const ValueKey('exercise-history-empty'),
        child: Text(
          i18n.exerciseHistoryEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
        ),
      );
    }

    num best = 0;
    final rows = <Widget>[];
    for (final s in sessions) {
      final logs = s.logs.where((l) => l.exerciseId == _exercise.id).toList();
      final sets = logs.where((l) => (l.weight ?? 0) > 0 && (l.repetitions ?? 0) > 0).toList();
      var top = sets.isEmpty ? null : sets.first;
      for (final l in sets) {
        if (estimatedOneRepMax(l.weight!, l.repetitions!) >
            estimatedOneRepMax(top!.weight!, top.repetitions!)) {
          top = l;
        }
      }
      if (top != null) {
        final e = estimatedOneRepMax(top.weight!, top.repetitions!);
        if (e > best) {
          best = e;
        }
      }
      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: atlas.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMd(locale).format(s.datetimeStart),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              MonoText(
                top == null
                    ? '${logs.length} ×'
                    : '${nf.format(top.weight)} ${top.weightUnitObj?.name ?? ''} × ${nf.format(top.repetitions)}'
                          .trim(),
                size: 13,
                weight: FontWeight.w500,
                color: atlas.ink2,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey('exercise-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: StatTile(
                label: i18n.exerciseHistorySessions,
                value: '${sessions.length}',
                valueSize: 28,
              ),
            ),
            Expanded(
              child: StatTile(
                label: i18n.exerciseHistoryBest,
                value: best > 0 ? nf.format(best.round()) : '-',
                valueSize: 28,
              ),
            ),
          ],
        ),
        AtlasCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _alternatives(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final state = ref.watch(exercisesProvider).value ?? ExerciseState(const []);
    final variations = _exercise.variationGroup == null
        ? const <Exercise>[]
        : state.findByVariationGroup(_exercise.variationGroup, exerciseIdToExclude: _exercise.id);

    if (variations.isEmpty) {
      return AtlasCard(
        key: const ValueKey('exercise-alternatives-empty'),
        child: Text(
          i18n.exerciseAlternativesEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: atlas.ink3),
        ),
      );
    }
    return AtlasCard(
      key: const ValueKey('exercise-alternatives'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(children: [for (final e in variations) ExerciseListTile(exercise: e)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translation = _exercise.getTranslation(Localizations.localeOf(context).languageCode);
    final hasMedia = _exercise.images.isNotEmpty || _exercise.videos.isNotEmpty;

    final chips = <Widget>[
      for (final m in _exercise.muscles)
        PillChip(m.nameTranslated(context), tone: ChipTone.brand, height: 32, fontSize: 13),
      for (final m in _exercise.musclesSecondary)
        PillChip(m.nameTranslated(context), height: 32, fontSize: 13),
      for (final e in _exercise.equipment)
        PillChip(getServerStringTranslation(e.name, context), height: 32, fontSize: 13),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (hasMedia)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              key: const ValueKey('exercise-media'),
              borderRadius: BorderRadius.circular(AtlasRadius.card),
              child: Column(
                children: [
                  VideosSection(exercise: _exercise),
                  ImagesSection(exercise: _exercise),
                ],
              ),
            ),
          ),
        Text(translation.name, style: theme.textTheme.headlineLarge),
        const SizedBox(height: 4),
        AliasesSection(translation: translation),
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: chips),
          ),
        _tabs(context),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: MediaQuery.of(context).disableAnimations ? Duration.zero : AtlasMotion.base,
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: switch (_tab) {
              ExerciseTab.technique => _technique(context),
              ExerciseTab.history => _history(context),
              ExerciseTab.alternatives => _alternatives(context),
            },
          ),
        ),
      ],
    );
  }
}
