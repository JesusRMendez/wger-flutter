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
import 'package:wger/features/account/widgets/settings/certs_not_verified.dart';
import 'package:wger/features/account/widgets/settings/data_privacy.dart';
import 'package:wger/features/account/widgets/settings/health_sync.dart';
import 'package:wger/features/account/widgets/settings/image_cache.dart';
import 'package:wger/features/account/widgets/settings/language.dart';
import 'package:wger/features/account/widgets/settings/theme.dart';
import 'package:wger/features/account/widgets/settings/verbose_logging.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';
import 'package:wger/features/glossary/screens/glossary_screen.dart';
import 'package:wger/features/locations/screens/locations_screen.dart';
import 'package:wger/features/routines/screens/settings_plates_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class SettingsPage extends StatelessWidget {
  static String routeName = '/SettingsPage';

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(i18n.settingsTitle)),
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Collapses to nothing unless certificates are actually going
            // unverified, so it sits above the first section rather than in one.
            const SettingsCertsNotVerified(),
            _SettingsSection(i18n.settingsCacheTitle, const [SettingsImageCache()]),
            _SettingsSection(i18n.settingsDataTitle, const [
              SettingsDataPrivacy(),
              HealthSyncSettingsTile(),
            ]),
            _SettingsSection(i18n.others, [
              const SettingsLanguage(),
              const SettingsTheme(),
              ListTile(
                title: Text(i18n.selectAvailablePlates),
                onTap: () {
                  Navigator.of(context).pushNamed(ConfigurePlatesScreen.routeName);
                },
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                title: Text(i18n.coachMyAi),
                onTap: () => Navigator.of(context).pushNamed(MyAiScreen.routeName),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                key: const ValueKey('settings-training-locations'),
                title: Text(i18n.locationsTitle),
                onTap: () => Navigator.of(context).pushNamed(LocationsScreen.routeName),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                key: const ValueKey('settings-glossary'),
                title: Text(i18n.glossaryTitle),
                onTap: () => Navigator.of(context).pushNamed(GlossaryScreen.routeName),
                trailing: const Icon(Icons.chevron_right),
              ),
              const SettingsVerboseLogging(),
            ]),
          ],
        ),
      ),
    );
  }
}

/// A group of settings: an eyebrow title over one outlined card, rows divided
/// by hairlines.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = context.atlas.line;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionEyebrow(title, padding: const EdgeInsets.fromLTRB(4, 8, 0, 8)),
          AtlasCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (i, c) in children.indexed) ...[
                  if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: line),
                  c,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
