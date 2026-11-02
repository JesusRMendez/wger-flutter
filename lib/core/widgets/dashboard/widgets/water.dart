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

import 'package:clock/clock.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/app_settings_notifier.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// One glass, in millilitres
const waterGlassMl = 250;

/// The daily goal in glasses, 2.5 l
const waterGoalGlasses = 10;

String _key(DateTime day) => 'water-${DateFormat('yyyy-MM-dd').format(day)}';

/// The glasses of water drunk today.
///
/// There is no water entry on the server, so the count lives in the local
/// preferences, per day, and is neither synced nor part of a backup.
class WaterNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    return await ref.read(appSettingsPrefsProvider).getInt(_key(clock.now())) ?? 0;
  }

  Future<void> change(int delta) async {
    final next = ((state.value ?? 0) + delta).clamp(0, 2 * waterGoalGlasses);
    state = AsyncData(next);
    await ref.read(appSettingsPrefsProvider).setInt(_key(clock.now()), next);
  }
}

final waterProvider = AsyncNotifierProvider<WaterNotifier, int>(WaterNotifier.new);

/// Dashboard card: litres drunk against the goal, a block per glass and the
/// plus that adds one (a long press takes one back).
class DashboardWaterWidget extends ConsumerWidget {
  const DashboardWaterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final litres = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2);

    final glasses = ref.watch(waterProvider).value ?? 0;
    final notifier = ref.read(waterProvider.notifier);

    String l(num ml) => litres.format(ml / 1000).replaceFirst(RegExp(r'[.,]?0+$'), '');

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 20, color: atlas.protein),
              const SizedBox(width: 10),
              Expanded(child: Text(i18n.dashboardWater, style: theme.textTheme.titleSmall)),
              MonoText(
                i18n.waterValue(l(glasses * waterGlassMl), l(waterGoalGlasses * waterGlassMl)),
                key: const ValueKey('water-value'),
                size: 13,
                color: atlas.ink3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < waterGoalGlasses; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == waterGoalGlasses - 1 ? 0 : 4),
                    child: AnimatedContainer(
                      key: ValueKey('water-glass-$i'),
                      duration: AtlasMotion.of(context),
                      height: 30,
                      decoration: BoxDecoration(
                        color: i < glasses ? atlas.protein : atlas.surface3,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Semantics(
                label: i18n.waterAddGlass,
                // No tooltip: its long press would take the one that removes a glass
                customSemanticsActions: {
                  CustomSemanticsAction(label: i18n.waterRemoveGlass): () => notifier.change(-1),
                },
                child: GestureDetector(
                  onLongPress: () => notifier.change(-1),
                  child: IconButton.filled(
                    key: const ValueKey('water-add'),
                    style: IconButton.styleFrom(
                      backgroundColor: atlas.protein,
                      foregroundColor: Colors.white,
                      fixedSize: const Size.square(44),
                    ),
                    icon: const Icon(Icons.add),
                    onPressed: () => notifier.change(1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            i18n.waterLocalOnly,
            style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
          ),
        ],
      ),
    );
  }
}
