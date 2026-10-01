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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';
import 'package:wger/features/gallery/screens/gallery_screen.dart';
import 'package:wger/features/measurements/screens/measurement_categories_screen.dart';
import 'package:wger/features/measurements/screens/weight_screen.dart';
import 'package:wger/features/trophies/screens/trophy_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// The fourth tab: weight, measurements, photos, trophies and goals in one
/// place, each row opening its own screen.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;

    Widget row(
      Key key,
      IconData icon,
      Color color,
      String title,
      String subtitle,
      String route,
    ) {
      return AtlasCard(
        key: key,
        onTap: () => Navigator.of(context).pushNamed(route),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconBadge(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: atlas.ink3),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        title: Text(i18n.labelBottomNavProgress, style: Theme.of(context).textTheme.headlineLarge),
      ),
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            row(
              const ValueKey('progress-weight'),
              Icons.monitor_weight_outlined,
              atlas.ok,
              i18n.weight,
              i18n.progressSubtitleWeight,
              WeightScreen.routeName,
            ),
            const SizedBox(height: 12),
            row(
              const ValueKey('progress-measurements'),
              Icons.straighten,
              atlas.fat,
              i18n.measurements,
              i18n.progressSubtitleMeasurements,
              MeasurementCategoriesScreen.routeName,
            ),
            const SizedBox(height: 12),
            row(
              const ValueKey('progress-gallery'),
              Icons.photo_library_outlined,
              atlas.accent,
              i18n.gallery,
              i18n.progressSubtitleGallery,
              GalleryScreen.routeName,
            ),
            const SizedBox(height: 12),
            row(
              const ValueKey('progress-trophies'),
              Icons.emoji_events_outlined,
              atlas.warn,
              i18n.trophies,
              i18n.progressSubtitleTrophies,
              TrophyScreen.routeName,
            ),
            const SizedBox(height: 12),
            row(
              const ValueKey('progress-goals'),
              Icons.flag_outlined,
              Theme.of(context).colorScheme.primary,
              i18n.coachGoalsAndIndicators,
              i18n.progressSubtitleGoals,
              GoalsScreen.routeName,
            ),
          ],
        ),
      ),
    );
  }
}
