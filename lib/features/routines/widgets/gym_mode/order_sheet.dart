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
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/routines/logic/gym_progress.dart';
import 'package:wger/features/routines/logic/zone_order_logic.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/workout_menu.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Opens the session order sheet: the exercises of the workout in order, with
/// where the user is, a way to jump to one and to move those not started yet.
Future<void> showSessionOrderSheet(BuildContext context, PageController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SessionOrderSheet(controller),
  );
}

class SessionOrderSheet extends ConsumerWidget {
  const SessionOrderSheet(this.controller, {super.key});

  final PageController controller;

  /// Moves the exercise one position and keeps the page view on what the user
  /// is looking at, as the page indices change
  void _move(WidgetRef ref, PageEntry page, {required bool up}) {
    final notifier = ref.read(gymStateProvider.notifier);
    if (!notifier.moveSlotBy(page.uuid, up: up)) {
      return;
    }
    final currentPage = ref.read(gymStateProvider).currentPage;
    if (controller.hasClients && controller.page?.round() != currentPage) {
      controller.jumpToPage(currentPage);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final state = ref.watch(gymStateProvider);

    final setPages = state.pages.where((p) => p.type == PageType.set && p.slotPages.isNotEmpty);
    final current = state.getPageByIndex();
    final order = state.zoneOrder;

    // The zones in the order they are visited, each once per stretch
    String? route;
    if (order != null && order.hasZones) {
      final zones = <String>[];
      for (final item in order.items) {
        final name = item.zoneName;
        if (name != null && (zones.isEmpty || zones.last != name)) {
          zones.add(name);
        }
      }
      route = zones.join(' → ');
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text(i18n.gymSessionOrder, style: theme.textTheme.headlineMedium)),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  style: IconButton.styleFrom(
                    side: BorderSide(color: atlas.line),
                    fixedSize: const Size.square(44),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                if (route != null) ...[
                  AtlasCard(
                    key: const ValueKey('order-sheet-why'),
                    color: atlas.surface2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              i18n.gymWhyThisOrder,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          i18n.gymOrderZoneRoute(route, order!.zoneChangesSuggested),
                          style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final (i, page) in setPages.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OrderRow(
                      key: ValueKey('order-row-${page.uuid}'),
                      number: i + 1,
                      page: page,
                      isCurrent: current?.uuid == page.uuid,
                      languageCode: languageCode,
                      canMoveUp: state.canMovePage(page.uuid, up: true),
                      canMoveDown: state.canMovePage(page.uuid, up: false),
                      onMove: (up) => _move(ref, page, up: up),
                      onGo: () => jumpToWorkoutPage(context, controller, page),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const ValueKey('order-sheet-edit'),
                  icon: const Icon(Icons.swap_vert),
                  label: Text(i18n.gymEditExercises),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog<void>(
                      context: context,
                      builder: (_) => WorkoutMenuDialog(controller, initialIndex: 1),
                    );
                  },
                ),
                const SizedBox(height: 4),
                FilledButton.tonal(
                  key: const ValueKey('order-sheet-end'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () {
                    controller.animateToPage(
                      state.totalPages,
                      duration: DEFAULT_ANIMATION_DURATION,
                      curve: DEFAULT_ANIMATION_CURVE,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(i18n.endWorkout),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends ConsumerWidget {
  const _OrderRow({
    super.key,
    required this.number,
    required this.page,
    required this.isCurrent,
    required this.languageCode,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMove,
    required this.onGo,
  });

  final int number;
  final PageEntry page;
  final bool isCurrent;
  final String languageCode;
  final bool canMoveUp;
  final bool canMoveDown;
  final void Function(bool up) onMove;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final logs = page.slotPages.where((s) => s.type == SlotPageType.log).toList();
    final done = logs.where((s) => s.logDone).length;
    final rest = logs.firstOrNull?.setConfigData?.restTime;
    final order = ref.watch(gymStateProvider.select((s) => s.zoneOrder));
    final zone = order == null ? null : zoneItemForPage(page, order)?.zoneName;

    final details = [
      ?zone,
      i18n.gymOrderSetsDone(done, logs.length),
      if (rest != null) i18n.gymOrderRest(formatRest(rest)),
    ].join(' · ');

    return AtlasCard(
      color: isCurrent ? atlas.surface2 : null,
      borderColor: isCurrent ? scheme.primary : null,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? scheme.primary : atlas.surface3,
            ),
            child: page.allLogsDone
                ? Icon(Icons.check, size: 18, color: atlas.ok)
                : MonoText(
                    '$number',
                    size: 14,
                    color: isCurrent ? scheme.onPrimary : scheme.onSurface,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.exercises.map((e) => e.getTranslation(languageCode).name).join(' + '),
                  style: theme.textTheme.titleSmall?.copyWith(
                    decoration: page.allLogsDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(details, style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3)),
              ],
            ),
          ),
          if (page.isMovable) ...[
            _Arrow(
              key: ValueKey('order-up-${page.uuid}'),
              icon: Icons.keyboard_arrow_up,
              tooltip: i18n.gymModeMoveUp,
              onPressed: canMoveUp ? () => onMove(true) : null,
            ),
            _Arrow(
              key: ValueKey('order-down-${page.uuid}'),
              icon: Icons.keyboard_arrow_down,
              tooltip: i18n.gymModeMoveDown,
              onPressed: canMoveDown ? () => onMove(false) : null,
            ),
          ],
          const SizedBox(width: 4),
          if (isCurrent)
            PillChip(i18n.gymOrderNow, tone: ChipTone.brand, height: 32)
          else if (!page.allLogsDone)
            PillChip(
              i18n.gymOrderGoNow,
              key: ValueKey('order-go-${page.uuid}'),
              selected: true,
              height: 32,
              onTap: onGo,
            ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 22,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}
