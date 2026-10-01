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

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/date.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/exercises/widgets/exercises.dart';
import 'package:wger/features/routines/logic/session_stats.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/session.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/navigation.dart';
import 'package:wger/features/trophies/models/user_trophy.dart';
import 'package:wger/features/trophies/providers/trophy_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

import '../logs/exercises_expansion_card.dart';

class WorkoutSummary extends ConsumerStatefulWidget {
  final _logger = Logger('WorkoutSummary');
  final PageController _controller;

  WorkoutSummary(this._controller);

  @override
  ConsumerState<WorkoutSummary> createState() => _WorkoutSummaryState();
}

class _WorkoutSummaryState extends ConsumerState<WorkoutSummary> {
  late Future<void> _trophyFuture;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      // Trophies are REST-only and only enrich the summary (PR count + markers).
      // Fetch them when the server is reachable; offline we skip the doomed
      // request so the local session stats render right away.
      if (ref.read(networkStatusProvider)) {
        final languageCode = Localizations.localeOf(context).languageCode;
        _trophyFuture = ref
            .read(trophyStateProvider.notifier)
            .fetchUserTrophies(language: languageCode);
      } else {
        _trophyFuture = Future<void>.value();
      }
      _didInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineId = ref.read(gymStateProvider).routine.id!;
    final routinesState = ref.watch(routinesRiverpodProvider).value;
    final routine = routinesState?.routines.firstWhereOrNull((r) => r.id == routineId);
    final trophyState = ref.watch(trophyStateProvider);
    final ownerZone = ref.watch(ownerTimeZoneProvider);

    return Column(
      children: [
        NavigationHeader(
          '',
          widget._controller,
          showEndWorkoutButton: false,
        ),
        Expanded(
          child: FutureBuilder<void>(
            future: _trophyFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // An error reaching here is a genuine, unexpected exception worth surfacing
                widget._logger.warning(
                  'Could not fetch user trophies',
                  snapshot.error,
                  snapshot.stackTrace,
                );
                return StreamErrorIndicator(snapshot.error!, stacktrace: snapshot.stackTrace);
              }
              if (snapshot.connectionState == ConnectionState.waiting || routine == null) {
                return const BoxedProgressIndicator();
              }

              // Both sides of the comparison cut in the owner's zone, so the
              // summary shows the session of the same "today" the server uses
              final session = routine.sessions.firstWhereOrNull(
                (s) => s.localDayIn(ownerZone).isSameDayAs(dayIn(clock.now(), ownerZone)),
              );
              final userTrophies = trophyState.prTrophies
                  .where((t) => t.contextData?.sessionId == session?.id)
                  .toList();

              final state = ref.read(gymStateProvider);
              final day = routine.days.firstWhereOrNull((d) => d.id == state.dayId);
              final iterations = routine.iterations;
              final i18n = AppLocalizations.of(context);
              final subtitle = [
                if (day != null) day.name,
                if (iterations.length > 1) i18n.routinesWeekOf(state.iteration, iterations.length),
              ].join(' · ');

              return WorkoutSessionStats(
                session,
                userTrophies,
                previousSessions: routine.sessions,
                plannedSets: state.pages
                    .expand((p) => p.slotPages)
                    .where((s) => s.type == SlotPageType.log)
                    .length,
                subtitle: subtitle,
              );
            },
          ),
        ),
        NavigationFooter(widget._controller, showNext: false),
      ],
    );
  }
}

class WorkoutSessionStats extends ConsumerWidget {
  final WorkoutSession? _session;
  final List<UserTrophy> _userPrTrophies;

  /// The other sessions of the routine, to find records and the volume change
  final List<WorkoutSession> previousSessions;

  /// Sets the plan had for the session, 0 when unknown
  final int plannedSets;

  /// Day and week of the session, shown under the headline
  final String subtitle;

  const WorkoutSessionStats(
    this._session,
    this._userPrTrophies, {
    this.previousSessions = const [],
    this.plannedSets = 0,
    this.subtitle = '',
    super.key,
  });

  /// `52:14`, or `1:12:03` from an hour on
  static String clockText(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final nf = localizedNumberFormat(context);

    if (_session == null) {
      return Center(
        child: Text('Nothing logged yet.', style: Theme.of(context).textTheme.titleMedium),
      );
    }
    final session = _session;

    final sessionDuration = session.duration;
    final totalVolume = session.volume;

    /// We assume that users will do exercises (mostly) either in metric or imperial
    /// units so we just display the higher one.
    final metric = totalVolume['metric']! > totalVolume['imperial']!;
    final volumeValue = metric ? totalVolume['metric']! : totalVolume['imperial']!;
    final volumeUnit = metric ? i18n.kg : i18n.lb;
    final unitLabel = metric ? i18n.kg : i18n.lb;

    final change = volumeChangePercent(session, previousSessions);
    final records = deriveRecords(
      session,
      previousSessions.where((s) => s.id != session.id),
    );
    final recordCount = records.isNotEmpty ? records.length : _userPrTrophies.length;
    final setsDone = session.logs.length;
    final exerciseCount = session.exercises.length;
    final animate = !MediaQuery.of(context).disableAnimations;

    Widget tile(String label, String value, {String? unit, Widget? chip, Widget? footer}) {
      return StatTile(label: label, value: value, unit: unit, chip: chip, valueSize: 30);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0.6 : 1, end: 1),
            duration: animate ? const Duration(milliseconds: 340) : Duration.zero,
            curve: const Cubic(0.34, 1.56, 0.64, 1),
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              key: const ValueKey('summary-check'),
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: atlas.ok, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 44, color: theme.colorScheme.surface),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          i18n.workoutCompleted,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge,
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
            ),
          ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Expanded(
                child: tile(
                  i18n.duration,
                  sessionDuration != null ? clockText(sessionDuration) : '-/-',
                ),
              ),
              Expanded(
                child: tile(
                  i18n.volume,
                  nf.format(volumeValue.round()),
                  unit: volumeUnit,
                  chip: change == null
                      ? null
                      : PillChip(
                          '${change >= 0 ? '+' : ''}$change %',
                          key: const ValueKey('volume-change'),
                          tone: change >= 0 ? ChipTone.ok : ChipTone.accent,
                          height: 22,
                          fontSize: 11,
                          mono: true,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Expanded(
                child: StatTile(
                  label: i18n.sets,
                  value: plannedSets > 0 ? '$setsDone/$plannedSets' : '$setsDone',
                  valueSize: 30,
                  chip: plannedSets > 0
                      ? ProgressRing(
                          value: setsDone / plannedSets,
                          size: 26,
                          strokeWidth: 4,
                          color: atlas.ok,
                          semanticLabel: '$setsDone/$plannedSets',
                        )
                      : null,
                ),
              ),
              Expanded(
                child: tile(
                  i18n.exercises,
                  '$exerciseCount',
                ),
              ),
            ],
          ),
        ),
        if (recordCount > 0) ...[
          const SizedBox(height: 12),
          AtlasCard(
            key: const ValueKey('summary-records'),
            borderColor: atlas.accent.withAlpha(110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 20, color: atlas.accent),
                    Expanded(
                      child: Text(
                        i18n.newRecords(recordCount),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                for (final r in records) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          r.exercise
                              .getTranslation(Localizations.localeOf(context).languageCode)
                              .name,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      MonoText(
                        '${nf.format(r.weight)} $unitLabel × ${nf.format(r.repetitions)}',
                        size: 13,
                        weight: FontWeight.w500,
                        color: atlas.ink2,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: MonoText(
                      i18n.estimatedOneRepMax(nf.format(r.oneRepMax.round())),
                      size: 12,
                      weight: FontWeight.w500,
                      color: atlas.ink3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _MuscleMapCard(session.logs),
        const SizedBox(height: 12),
        ExercisesCard(session, _userPrTrophies),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              textStyle: theme.textTheme.titleMedium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () {
              ref.read(gymStateProvider.notifier).clear();
              Navigator.of(context).pop();
            },
            child: Text(i18n.endWorkout),
          ),
        ),
      ],
    );
  }
}

/// The muscles the session trained: the body map with the main and secondary
/// muscles marked, and the share of each muscle in the logged sets.
class _MuscleMapCard extends StatelessWidget {
  final List<Log> logs;

  const _MuscleMapCard(this.logs);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);

    final main = {for (final l in logs) ...l.exerciseObj.muscles}.toList();
    final secondary = {
      for (final l in logs) ...l.exerciseObj.musclesSecondary,
    }.where((m) => !main.contains(m)).toList();

    if (main.isEmpty && secondary.isEmpty) {
      return const SizedBox.shrink();
    }

    // Share of the main muscles in the sets, a set counting for every main
    // muscle of its exercise
    final counts = <String, int>{};
    for (final l in logs) {
      for (final m in l.exerciseObj.muscles) {
        final name = m.nameTranslated(context);
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final top = counts.entries.sorted((a, b) => b.value.compareTo(a.value)).take(4).toList();

    return AtlasCard(
      key: const ValueKey('summary-muscles'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionEyebrow(i18n.muscles),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: MuscleRowWidget(muscles: main, musclesSecondary: secondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    _LegendDot(COLOR_MAIN_MUSCLES, i18n.muscles),
                    _LegendDot(COLOR_SECONDARY_MUSCLES, i18n.musclesSecondary),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            for (final e in top)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        MonoText(
                          i18n.percentValue((e.value / total * 100).toStringAsFixed(0)),
                          size: 12.5,
                          color: atlas.ink3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AtlasBar(value: e.value / total, color: theme.colorScheme.primary),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const InfoCard({required this.title, required this.value, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      color: color,
      padding: EdgeInsets.zero,
      child: StatTile(
        label: title,
        value: value,
        valueSize: 26,
        // The surrounding card carries the (optional) color
        padding: const EdgeInsets.all(14),
        footer: const SizedBox.shrink(),
      ),
    );
  }
}
