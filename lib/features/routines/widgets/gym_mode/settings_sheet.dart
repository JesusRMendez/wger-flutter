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
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Opens the gym mode settings sheet: the alerts of the rest timer and what
/// the pages show, i.e. the options the start page offers, within reach while
/// training.
Future<void> showGymSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const GymSettingsSheet(),
  );
}

class GymSettingsSheet extends ConsumerWidget {
  const GymSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(gymStateProvider);
    final notifier = ref.read(gymStateProvider.notifier);

    final timers = state.showTimerPages;
    final countdown = timers && state.useCountdownBetweenSets;

    Widget option(
      String key,
      String title,
      bool value,
      ValueChanged<bool>? onChanged, {
      String? subtitle,
    }) {
      return SwitchListTile(
        key: ValueKey(key),
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: context.atlas.ink3)),
        value: value,
        onChanged: onChanged,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(i18n.gymSettingsSheetTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          option(
            'gym-sheet-notify-countdown',
            i18n.gymModeNotifyOnCountdownFinish,
            state.alertOnCountdownEnd,
            countdown ? notifier.setAlertOnCountdownEnd : null,
          ),
          option(
            'gym-sheet-alert-at-20s',
            i18n.gymModeAlertAt20s,
            state.alertAt20s,
            timers ? notifier.setAlertAt20s : null,
          ),
          option(
            'gym-sheet-alert-last-5s',
            i18n.gymModeAlertLast5s,
            state.alertLast5s,
            timers ? notifier.setAlertLast5s : null,
          ),
          option(
            'gym-sheet-auto-advance',
            i18n.gymModeAutoAdvanceAfterRest,
            state.autoAdvanceAfterRest,
            timers ? notifier.setAutoAdvanceAfterRest : null,
          ),
          option(
            'gym-sheet-show-duration',
            i18n.gymModeShowWorkoutDuration,
            state.showWorkoutDuration,
            notifier.setShowWorkoutDuration,
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('gym-sheet-done'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(i18n.gymSettingsDone),
          ),
        ],
      ),
    );
  }
}
