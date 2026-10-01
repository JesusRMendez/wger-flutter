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
      crossAxisCount = 3;
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

    // The unearned progressive trophy that is closest to done
    final next =
        (trophyState.trophyProgression
                .where((t) => !t.isEarned && t.trophy.isProgressive && t.progress > 0)
                .toList()
              ..sort((a, b) => b.progress.compareTo(a.progress)))
            .firstOrNull;
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
          if (next != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(child: _NextTrophyCard(next)),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            sliver: SliverToBoxAdapter(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    stat('trophy-stat-earned', earned, i18n.trophiesEarned),
                    const SizedBox(width: 10),
                    stat('trophy-stat-to-earn', total - earned, i18n.trophiesToEarn),
                    const SizedBox(width: 10),
                    stat(
                      'trophy-stat-prs',
                      trophyState.prTrophies.length,
                      i18n.trophiesPersonalRecords,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid.builder(
              key: const ValueKey('trophy-grid'),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.66,
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

class _NextTrophyCard extends StatelessWidget {
  final UserTrophyProgression progression;

  const _NextTrophyCard(this.progression);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final i18n = AppLocalizations.of(context);
    final progress = (progression.progress.toDouble() / 100.0).clamp(0.0, 1.0);
    final display = progression.progressDisplay ?? '${progression.progress.round()}%';

    return AtlasCard(
      key: const ValueKey('trophy-next'),
      color: Color.alphaBlend(atlas.accent.withValues(alpha: 0.10), atlas.card),
      borderColor: atlas.accent.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionEyebrow(i18n.trophyNext, color: atlas.accent),
          const SizedBox(height: 14),
          Row(
            children: [
              ProgressRing(
                size: 84,
                strokeWidth: 9,
                value: progress,
                color: atlas.accent,
                child: MonoText(display, size: 15, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progression.trophy.name,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progression.trophy.description,
                      style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
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

    final double progress = userProgression.isEarned
        ? 1.0
        : (userProgression.progress.toDouble() / 100.0).clamp(0.0, 1.0);
    final earned = userProgression.isEarned;

    return Opacity(
      opacity: earned ? 1.0 : 0.6,
      child: AtlasCard(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        borderColor: earned ? atlas.accent.withValues(alpha: 0.5) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressRing(
              size: 66,
              strokeWidth: 4,
              value: progress,
              color: earned ? atlas.accent : atlas.accent.withValues(alpha: 0.7),
              child: SizedBox(
                width: 50,
                height: 50,
                child: ClipOval(
                  child: Image.network(
                    userProgression.trophy.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.emoji_events_outlined, size: 26, color: atlas.accent),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userProgression.trophy.name,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              userProgression.trophy.description,
              style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (earned || userProgression.trophy.isProgressive)
              Tooltip(
                message: earned ? '' : 'Progress: ${userProgression.progressDisplay}',
                child: SizedBox(
                  height: 5,
                  child: AtlasBar(
                    value: progress,
                    color: earned ? atlas.accent : colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
