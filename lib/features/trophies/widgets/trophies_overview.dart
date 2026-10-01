/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2025 - 2026 wger Team
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
import 'package:wger/core/material.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/trophies/models/user_trophy_progression.dart';
import 'package:wger/features/trophies/providers/trophy_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class TrophiesOverview extends ConsumerWidget {
  const TrophiesOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophyState = ref.watch(trophyStateProvider);
    final i18n = AppLocalizations.of(context);

    // Responsive grid: determine columns based on screen width
    final width = MediaQuery.widthOf(context);
    int crossAxisCount = 1;
    if (width <= MATERIAL_XS_BREAKPOINT) {
      crossAxisCount = 2;
    } else if (width > MATERIAL_XS_BREAKPOINT && width < MATERIAL_MD_BREAKPOINT) {
      crossAxisCount = 3;
    } else if (width >= MATERIAL_MD_BREAKPOINT && width < MATERIAL_LG_BREAKPOINT) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 5;
    }

    // If empty, show placeholder
    if (trophyState.trophyProgression.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            i18n.noTrophies,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final earned = trophyState.trophyProgression.where((t) => t.isEarned).length;
    final total = trophyState.trophyProgression.length;

    Widget stat(String key, int value, String label) {
      return Expanded(
        child: AtlasCard(
          key: ValueKey(key),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoText('$value', size: 24),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.atlas.ink3),
                maxLines: 2,
              ),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  stat('trophy-stat-earned', earned, i18n.trophiesEarned),
                  const SizedBox(width: 8),
                  stat('trophy-stat-to-earn', total - earned, i18n.trophiesToEarn),
                  const SizedBox(width: 8),
                  stat(
                    'trophy-stat-prs',
                    trophyState.prTrophies.length,
                    i18n.trophiesPersonalRecords,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            sliver: SliverGrid.builder(
              key: const ValueKey('trophy-grid'),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: total,
              itemBuilder: (context, index) {
                return _TrophyCardImage(userProgression: trophyState.trophyProgression[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyCardImage extends StatelessWidget {
  final UserTrophyProgression userProgression;

  const _TrophyCardImage({required this.userProgression});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final atlas = context.atlas;

    final double progress = (userProgression.progress.toDouble() / 100.0).clamp(0.0, 1.0);

    return Opacity(
      opacity: userProgression.isEarned ? 1.0 : 0.5,
      child: AtlasCard(
        padding: EdgeInsets.zero,
        borderColor: userProgression.isEarned ? atlas.accent.withValues(alpha: 0.5) : null,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: ClipOval(
                      child: Image.network(
                        userProgression.trophy.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.emoji_events, size: 28, color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ),

                  Text(
                    userProgression.trophy.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  Text(
                    userProgression.trophy.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  if (userProgression.trophy.isProgressive && !userProgression.isEarned)
                    Tooltip(
                      message: 'Progress: ${userProgression.progressDisplay}',
                      child: SizedBox(
                        height: 6,
                        child: AtlasBar(value: progress, color: atlas.accent),
                      ),
                    ),
                ],
              ),
            ),
            if (userProgression.isEarned)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: atlas.ok, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 16, color: atlas.onHero),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
