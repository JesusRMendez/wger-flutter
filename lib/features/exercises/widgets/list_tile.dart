/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/i18n.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/screens/exercise_screen.dart';
import 'package:wger/features/exercises/widgets/images.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    const double IMG_SIZE = 54;
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final i18n = AppLocalizations.of(context);
    final equipment = exercise.equipment
        .map((e) => getServerStringTranslation(e.name, context))
        .join(', ');

    return Pressable(
      borderRadius: BorderRadius.circular(AtlasRadius.card),
      onTap: () {
        Navigator.pushNamed(context, ExerciseDetailScreen.routeName, arguments: exercise);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              height: IMG_SIZE,
              width: IMG_SIZE,
              decoration: BoxDecoration(
                color: atlas.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: atlas.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExerciseImageWidget(image: exercise.getMainImage),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.getTranslation(Localizations.localeOf(context).languageCode).name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      getServerStringTranslation(exercise.category.name, context),
                      if (equipment.isNotEmpty) equipment,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                  ),
                ],
              ),
            ),
            if (exercise.videos.isNotEmpty) ...[
              const SizedBox(width: 10),
              PillChip(
                i18n.video,
                key: const ValueKey('exercise-video-chip'),
                icon: Icons.play_arrow,
                height: 28,
                fontSize: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
