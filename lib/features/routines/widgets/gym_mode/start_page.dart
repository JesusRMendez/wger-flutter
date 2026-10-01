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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/widgets/images.dart';
import 'package:wger/features/routines/logic/gym_progress.dart';
import 'package:wger/features/routines/models/day.dart';
import 'package:wger/features/routines/models/set_config_data.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/navigation.dart';
import 'package:wger/features/routines/widgets/gym_mode/planning_card.dart';
import 'package:wger/features/routines/widgets/music_bpm_card.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class GymModeOptions extends ConsumerStatefulWidget {
  const GymModeOptions({super.key});

  @override
  ConsumerState<GymModeOptions> createState() => _GymModeOptionsState();
}

class _GymModeOptionsState extends ConsumerState<GymModeOptions> {
  bool _showOptions = false;
  late TextEditingController _countdownController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(gymStateProvider).countdownDuration.inSeconds.toString();
    _countdownController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymState = ref.watch(gymStateProvider);
    final gymNotifier = ref.watch(gymStateProvider.notifier);
    final i18n = AppLocalizations.of(context);

    // If the value in the provider changed, update the controller text
    final currentText = gymState.countdownDuration.inSeconds.toString();
    if (_countdownController.text != currentText) {
      _countdownController.text = currentText;
    }

    return Column(
      children: [
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Card(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const ValueKey('gym-mode-option-show-exercises'),
                        title: Text(i18n.gymModeShowExercises),
                        value: gymState.showExercisePages,
                        onChanged: (value) => gymNotifier.setShowExercisePages(value),
                      ),
                      SwitchListTile(
                        key: const ValueKey('gym-mode-option-show-workout-duration'),
                        title: Text(i18n.gymModeShowWorkoutDuration),
                        value: gymState.showWorkoutDuration,
                        onChanged: (value) => gymNotifier.setShowWorkoutDuration(value),
                      ),

                      const Divider(),
                      SwitchListTile(
                        key: const ValueKey('gym-mode-option-show-timer'),
                        title: Text(i18n.gymModeShowTimer),
                        value: gymState.showTimerPages,
                        onChanged: (value) => gymNotifier.setShowTimerPages(value),
                      ),
                      ListTile(
                        key: const ValueKey('gym-mode-timer-type'),
                        enabled: gymState.showTimerPages,
                        title: Text(i18n.gymModeTimerType),
                        trailing: DropdownButton<bool>(
                          key: const ValueKey('countdown-type-dropdown'),
                          value: gymState.useCountdownBetweenSets,
                          onChanged: gymState.showTimerPages
                              ? (bool? newValue) {
                                  if (newValue != null) {
                                    gymNotifier.setUseCountdownBetweenSets(newValue);
                                  }
                                }
                              : null,
                          items: [false, true].map<DropdownMenuItem<bool>>((bool value) {
                            final label = value ? i18n.countdown : i18n.stopwatch;

                            return DropdownMenuItem<bool>(value: value, child: Text(label));
                          }).toList(),
                        ),
                        subtitle: Text(i18n.gymModeTimerTypeHelText),
                      ),
                      ListTile(
                        key: const ValueKey('gym-mode-default-countdown-time'),
                        enabled: gymState.showTimerPages,
                        title: TextFormField(
                          controller: _countdownController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: i18n.gymModeDefaultCountdownTime,
                            suffix: IconButton(
                              onPressed: gymState.showTimerPages && gymState.useCountdownBetweenSets
                                  ? () => gymNotifier.setCountdownDuration(
                                      DEFAULT_COUNTDOWN_DURATION,
                                    )
                                  : null,
                              icon: const Icon(Icons.refresh),
                            ),
                          ),
                          onChanged: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null &&
                                intValue > 0 &&
                                intValue < MAX_COUNTDOWN_DURATION) {
                              gymNotifier.setCountdownDuration(intValue);
                            }
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (String? value) {
                            final intValue = int.tryParse(value!);
                            if (intValue == null ||
                                intValue < MIN_COUNTDOWN_DURATION ||
                                intValue > MAX_COUNTDOWN_DURATION) {
                              return i18n.formMinMaxValues(
                                MIN_COUNTDOWN_DURATION,
                                MAX_COUNTDOWN_DURATION,
                              );
                            }
                            return null;
                          },
                          enabled: gymState.showTimerPages && gymState.useCountdownBetweenSets,
                        ),
                      ),

                      SwitchListTile(
                        key: const ValueKey('gym-mode-notify-countdown'),
                        title: Text(i18n.gymModeNotifyOnCountdownFinish),
                        value: gymState.alertOnCountdownEnd,
                        onChanged: (gymState.showTimerPages && gymState.useCountdownBetweenSets)
                            ? (value) => gymNotifier.setAlertOnCountdownEnd(value)
                            : null,
                      ),
                      SwitchListTile(
                        key: const ValueKey('gym-mode-alert-at-20s'),
                        title: Text(i18n.gymModeAlertAt20s),
                        value: gymState.alertAt20s,
                        onChanged: gymState.showTimerPages
                            ? (value) => gymNotifier.setAlertAt20s(value)
                            : null,
                      ),
                      SwitchListTile(
                        key: const ValueKey('gym-mode-alert-last-5s'),
                        title: Text(i18n.gymModeAlertLast5s),
                        value: gymState.alertLast5s,
                        onChanged: gymState.showTimerPages
                            ? (value) => gymNotifier.setAlertLast5s(value)
                            : null,
                      ),
                      SwitchListTile(
                        key: const ValueKey('gym-mode-auto-advance'),
                        title: Text(i18n.gymModeAutoAdvanceAfterRest),
                        value: gymState.autoAdvanceAfterRest,
                        onChanged: gymState.showTimerPages
                            ? (value) => gymNotifier.setAutoAdvanceAfterRest(value)
                            : null,
                      ),

                      const Divider(),
                      ListTile(
                        key: const ValueKey('gym-mode-log-scope'),
                        title: Text(i18n.gymModeLogScope),
                        subtitle: Text(i18n.gymModeLogScopeHelp),
                        trailing: DropdownButton<int?>(
                          key: const ValueKey('log-scope-dropdown'),
                          value: gymState.logScopeWeeks,
                          onChanged: (value) => gymNotifier.setLogScopeWeeks(value),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(i18n.gymModeLogScopeCurrentRoutine),
                            ),
                            ...[8, 12, 25, 50].map(
                              (weeks) => DropdownMenuItem<int?>(
                                value: weeks,
                                child: Text(i18n.gymModeLogScopeWeeks(weeks)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        key: const ValueKey('gym-mode-distinct-logs'),
                        title: Text(i18n.gymModeDistinctLogs),
                        value: gymState.showDistinctLogs,
                        onChanged: (value) => gymNotifier.setShowDistinctLogs(value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          crossFadeState: _showOptions ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        ListTile(
          key: const ValueKey('gym-mode-options-tile'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 22),
          title: Text(i18n.settingsTitle),
          leading: const Icon(Icons.settings),
          onTap: () => setState(() => _showOptions = !_showOptions),
        ),
      ],
    );
  }
}

class StartPage extends ConsumerWidget {
  final PageController _controller;

  const StartPage(this._controller);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymStateProvider);
    final dayDataDisplay = gymState.dayDataDisplay;
    final minutes = estimatedMinutesLeft(gymState);
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        NavigationHeader(
          AppLocalizations.of(context).todaysWorkout,
          _controller,
          showEndWorkoutButton: false,
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            children: [
              SectionEyebrow(i18n.todaysWorkout),
              const SizedBox(height: 4),
              Text(
                dayDataDisplay.day!.nameWithType,
                style: theme.textTheme.headlineLarge,
              ),
              if (dayDataDisplay.day!.description.isNotEmpty)
                Text(
                  dayDataDisplay.day!.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: context.atlas.ink2),
                ),
              const SizedBox(height: 12),
              if (dayDataDisplay.day!.isSpecialType)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PillChip(
                    '${dayDataDisplay.day!.type.name.toUpperCase()} · ${dayDataDisplay.day!.type.i18Label(i18n)}',
                    tone: ChipTone.brand,
                  ),
                ),
              AtlasCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final (i, entry)
                        in dayDataDisplay.slots
                            .expand((slot) => slot.setConfigs)
                            .fold<Map<Exercise, List<String>>>({}, (acc, entry) {
                              acc.putIfAbsent(entry.exercise, () => []).add(entry.textReprWithType);
                              return acc;
                            })
                            .entries
                            .indexed) ...[
                      if (i > 0) Divider(indent: 16, endIndent: 16, color: context.atlas.line),
                      ListTile(
                        leading: SizedBox(
                          width: 44,
                          height: 44,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ExerciseImageWidget(image: entry.key.getMainImage),
                          ),
                        ),
                        title: Text(
                          entry.key
                              .getTranslation(Localizations.localeOf(context).languageCode)
                              .name,
                          style: theme.textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          entry.value.toList().join('\n'),
                          style: TextStyle(color: context.atlas.ink2),
                        ),
                        trailing: MonoText(
                          '${i + 1}',
                          size: 13,
                          color: context.atlas.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DayStatsRow(dayDataDisplay.slots.expand((slot) => slot.setConfigs)),
              const SizedBox(height: 12),
              const GymPlanningCard(),
              const MusicBpmCard(),
            ],
          ),
        ),
        const GymModeOptions(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(
                minutes > 0 ? i18n.gymStartMinutes(minutes) : i18n.start,
                key: const ValueKey('start-label'),
              ),
              style: FilledButton.styleFrom(
                textStyle: theme.textTheme.titleMedium,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () {
                ref.read(gymStateProvider.notifier).startWorkout();
                _controller.nextPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.bounceIn,
                );
              },
            ),
          ),
        ),
        NavigationFooter(_controller, showPrevious: false, showElapsedTime: false),
      ],
    );
  }
}

/// The sets, the mean rest and the volume the day plans
class _DayStatsRow extends StatelessWidget {
  const _DayStatsRow(this.configs);

  final Iterable<SetConfigData> configs;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final stats = dayStats(configs);

    Widget tile(String key, String value, String label) {
      return Expanded(
        child: AtlasCard(
          key: ValueKey(key),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoText(value, size: 22),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.atlas.ink3),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('day-stat-sets', '${stats.sets}', i18n.gymStatSets),
        if (stats.averageRestSeconds != null) ...[
          const SizedBox(width: 8),
          tile('day-stat-rest', formatRest(stats.averageRestSeconds!), i18n.gymStatRest),
        ],
        if (stats.volumeKg != null) ...[
          const SizedBox(width: 8),
          tile('day-stat-volume', formatVolume(stats.volumeKg!), i18n.gymStatVolume),
        ],
      ],
    );
  }
}
