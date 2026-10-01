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
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/routines/providers/plate_weights.dart';
import 'package:wger/features/routines/screens/settings_plates_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

enum WeightVisualKind { barbell, dumbbell, bodyweight, other }

WeightVisualKind weightVisualKindFor(Exercise exercise, num? weight) {
  final ids = exercise.equipmentIds;
  if (ids.contains(ID_EQUIPMENT_BARBELL)) {
    return WeightVisualKind.barbell;
  }
  if (ids.contains(ID_EQUIPMENT_DUMBBELL)) {
    return WeightVisualKind.dumbbell;
  }
  if (ids.isEmpty && (weight == null || weight == 0)) {
    return WeightVisualKind.bodyweight;
  }
  return WeightVisualKind.other;
}

/// What is being lifted: the loaded barbell with its plates, a dumbbell, the
/// body, or just the load for anything else. It redraws as [weight] changes.
class WeightVisual extends ConsumerWidget {
  const WeightVisual({super.key, required this.exercise, required this.weight});

  final Exercise exercise;
  final num? weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = weightVisualKindFor(exercise, weight);

    return AnimatedSwitcher(
      duration: AtlasMotion.of(context),
      child: switch (kind) {
        WeightVisualKind.barbell => _Barbell(key: const ValueKey('visual-barbell'), weight: weight),
        WeightVisualKind.dumbbell => _Dumbbell(
          key: const ValueKey('visual-dumbbell'),
          weight: weight,
        ),
        WeightVisualKind.bodyweight => const _Body(key: ValueKey('visual-body')),
        WeightVisualKind.other => const _Machine(key: ValueKey('visual-other')),
      },
    );
  }
}

const _steel = Color(0xFF4A5674);
const _steelLight = Color(0xFF5D6A8A);

/// Height of a plate relative to the heaviest one, so a 25 looks twice a 2.5
double _plateHeight(num plate, bool metric) {
  final max = metric ? 25 : 55;
  final ratio = (plate / max).clamp(0.05, 1.0);
  return 34 + 66 * ratio;
}

class _Barbell extends ConsumerWidget {
  const _Barbell({super.key, required this.weight});

  final num? weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final state = ref.watch(plateCalculatorProvider).copyWith(totalWeight: weight ?? 0);
    final plates = state.calculatePlates;

    final sorted = plates.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    final flat = [
      for (final e in sorted)
        for (var i = 0; i < e.value; i++) e.key,
    ];

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(ConfigurePlatesScreen.routeName),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                height: 110,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _steel,
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(3)),
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _steelLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    for (final (i, plate) in flat.indexed)
                      _Plate(
                        key: ValueKey('plate-$i-$plate'),
                        value: plate,
                        index: i,
                        height: _plateHeight(plate, state.isMetric),
                        color: state.getColor(plate),
                      ),
                    Container(
                      width: 110,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _steel,
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.hasPlates || (weight ?? 0) <= state.barWeight
                ? '${i18n.barWeight} ${state.barWeight} ${state.isMetric ? i18n.kg : i18n.lb}'
                : i18n.plateCalculatorNotDivisible,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({
    super.key,
    required this.value,
    required this.index,
    required this.height,
    required this.color,
  });

  final num value;
  final int index;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    // New plates slide in from the side, 200 ms, skipped with reduced motion
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AtlasMotion.of(context),
      curve: AtlasMotion.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset((1 - t) * 14, 0), child: child),
      ),
      child: Container(
        width: 17,
        height: height,
        margin: const EdgeInsets.only(left: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            value.toString(),
            maxLines: 1,
            style: AtlasText.mono(null, size: 9, color: onColor),
          ),
        ),
      ),
    );
  }
}

class _Dumbbell extends StatelessWidget {
  const _Dumbbell({super.key, required this.weight});

  final num? weight;

  @override
  Widget build(BuildContext context) {
    const head = Color(0xFF26324A);
    const edge = Color(0xFF3A4766);
    // The heads grow a little with the load, between 0.85 and 1.15
    final scale = 0.85 + ((weight ?? 0) / 60).clamp(0, 1) * 0.3;

    Widget side() => TweenAnimationBuilder<double>(
      tween: Tween(end: scale),
      duration: AtlasMotion.of(context),
      curve: AtlasMotion.curve,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 50,
        height: 86,
        decoration: BoxDecoration(
          color: head,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: edge),
        ),
      ),
    );

    return FittedBox(
      fit: BoxFit.contain,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          side(),
          Container(
            width: 108,
            height: 12,
            decoration: BoxDecoration(color: _steel, borderRadius: BorderRadius.circular(6)),
          ),
          side(),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.accessibility_new, size: 72, color: context.atlas.ink2),
    );
  }
}

class _Machine extends StatelessWidget {
  const _Machine({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.fitness_center, size: 64, color: context.atlas.ink3),
    );
  }
}
