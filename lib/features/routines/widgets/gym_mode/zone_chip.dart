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
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/routines/logic/zone_order_logic.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Shows the zone of the exercise(s) of a page at the selected training
/// location, and a warning if equipment for it is missing there. Shows nothing
/// if no zone order is loaded.
class ZoneChip extends ConsumerWidget {
  final PageEntry page;

  const ZoneChip(this.page, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(gymStateProvider.select((s) => s.zoneOrder));
    if (order == null) {
      return const SizedBox.shrink();
    }

    final item = zoneItemForPage(page, order);
    final exerciseIds = {for (final e in page.exercises) e.id};
    final missing = order.missingEquipment.where((m) => exerciseIds.contains(m.exerciseId));
    final zoneName = item?.zoneName;
    if (zoneName == null && missing.isEmpty) {
      return const SizedBox.shrink();
    }

    final i18n = AppLocalizations.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (zoneName != null)
          PillChip(
            zoneName,
            key: ValueKey('zone-chip-${page.uuid}'),
            icon: Icons.place_outlined,
            height: 26,
          ),
        if (missing.isNotEmpty)
          Tooltip(
            message: i18n.gymModeMissingEquipmentShort,
            child: PillChip(
              i18n.gymModeMissingEquipmentShort,
              key: ValueKey('missing-equipment-chip-${page.uuid}'),
              icon: Icons.warning_amber,
              tone: ChipTone.accent,
              height: 26,
            ),
          ),
      ],
    );
  }
}
