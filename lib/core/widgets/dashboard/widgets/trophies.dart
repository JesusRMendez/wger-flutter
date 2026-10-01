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
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/core.dart';
import 'package:wger/core/widgets/wger_image.dart';
import 'package:wger/features/trophies/models/trophy.dart';
import 'package:wger/features/trophies/providers/trophy_notifier.dart';
import 'package:wger/features/trophies/screens/trophy_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class DashboardTrophiesWidget extends ConsumerWidget {
  const DashboardTrophiesWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophiesState = ref.watch(trophyStateProvider);
    final isOnline = ref.watch(networkStatusProvider);
    final i18n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trophiesState.nonPrTrophies.isEmpty)
          AtlasCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHeader(
                  icon: Icons.emoji_events_outlined,
                  title: i18n.trophies,
                  trailing: isOnline
                      ? null
                      : Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.noTrophies,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.atlas.ink2,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: trophiesState.nonPrTrophies.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final userTrophy = trophiesState.nonPrTrophies[index];

                return SizedBox(
                  width: 240,
                  child: TrophyCard(trophy: userTrophy.trophy),
                );
              },
            ),
          ),
      ],
    );
  }
}

class TrophyCard extends StatelessWidget {
  const TrophyCard({
    super.key,
    required this.trophy,
  });

  final Trophy trophy;

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context).pushNamed(TrophyScreen.routeName),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WgerImage(
                mediaPath: trophy.image,
                width: 60,
                height: 60,
                cacheWidth: 180,
                borderRadius: BorderRadius.circular(30),
                errorWidget: const CircleIconAvatar(
                  Icon(Icons.emoji_events, color: Colors.grey),
                  radius: 30,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trophy.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trophy.description,
                      style: Theme.of(context).textTheme.bodySmall,
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
