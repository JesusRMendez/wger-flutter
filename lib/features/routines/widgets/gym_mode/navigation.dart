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
import 'package:wger/core/consts.dart';
import 'package:wger/features/glossary/widgets/glossary_widgets.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/elapsed_time.dart';
import 'package:wger/features/routines/widgets/gym_mode/order_sheet.dart';
import 'package:wger/features/routines/widgets/gym_mode/settings_sheet.dart';
import 'package:wger/features/routines/widgets/gym_mode/workout_menu.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class NavigationHeader extends StatelessWidget {
  final PageController _controller;
  final String _title;
  final bool showEndWorkoutButton;

  /// Replaces the title, e.g. with the elapsed time
  final Widget? center;

  /// Adds the button that opens the settings sheet (alerts and what the pages
  /// show). The pages used while training turn it on.
  final bool showSettings;

  const NavigationHeader(
    this._title,
    this._controller, {
    this.showEndWorkoutButton = true,
    this.center,
    this.showSettings = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final style = IconButton.styleFrom(
      backgroundColor: atlas.card,
      side: BorderSide(color: atlas.line),
      fixedSize: const Size(40, 40),
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          IconButton(
            style: style,
            icon: const Icon(Icons.close, size: 20),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child:
                center ??
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          ),
          const GlossaryHelpButton(),
          if (showSettings) ...[
            const SizedBox(width: 6),
            IconButton(
              key: const ValueKey('gym-settings-button'),
              style: style,
              icon: const Icon(Icons.tune, size: 20),
              tooltip: AppLocalizations.of(context).settingsTitle,
              onPressed: () => showGymSettingsSheet(context),
            ),
          ],
          const SizedBox(width: 6),
          IconButton(
            key: const ValueKey('gym-order-button'),
            style: style,
            icon: const Icon(Icons.format_list_bulleted, size: 20),
            tooltip: AppLocalizations.of(context).gymSessionOrder,
            onPressed: () => showSessionOrderSheet(context, _controller),
          ),
        ],
      ),
    );
  }
}

class NavigationFooter extends ConsumerWidget {
  final PageController _controller;
  final bool showPrevious;
  final bool showNext;
  final bool showElapsedTime;

  const NavigationFooter(
    this._controller, {
    this.showPrevious = true,
    this.showNext = true,
    this.showElapsedTime = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymStateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(
        children: [
          if (showPrevious)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _controller.previousPage(
                  duration: DEFAULT_ANIMATION_DURATION,
                  curve: DEFAULT_ANIMATION_CURVE,
                );
              },
            )
          else
            const SizedBox(width: 48),
          if (showElapsedTime && gymState.showWorkoutDuration) ...[
            const ElapsedWorkoutTimer(),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => WorkoutMenuDialog(_controller, initialIndex: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AtlasRadius.pill),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: gymState.ratioCompleted,
                  ),
                ),
              ),
            ),
          ),
          if (showNext)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _controller.nextPage(
                  duration: DEFAULT_ANIMATION_DURATION,
                  curve: DEFAULT_ANIMATION_CURVE,
                );
              },
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
