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
import 'package:wger/core/app_settings_notifier.dart';
import 'package:wger/core/settings_dashboard_widgets_screen.dart';
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

class SettingsPage extends ConsumerWidget {
  static String routeName = '/SettingsPage';

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              HealthSyncSettingsTile(topDivider: true),
            ]),
            _SettingsSection(i18n.settingsAppearance, const [
              SettingsTheme(),
              SettingsLanguage(),
            ]),
            _SettingsSection(i18n.settingsTraining, [
              _SettingsLink(
                key: const ValueKey('settings-plates'),
                icon: Icons.album_outlined,
                title: i18n.selectAvailablePlates,
                route: ConfigurePlatesScreen.routeName,
              ),
              _SettingsLink(
                key: const ValueKey('settings-training-locations'),
                icon: Icons.place_outlined,
                title: i18n.locationsTitle,
                route: LocationsScreen.routeName,
              ),
              _SettingsLink(
                key: const ValueKey('settings-dashboard-widgets'),
                icon: Icons.widgets_outlined,
                title: i18n.dashboardWidgets,
                route: ConfigureDashboardWidgetsScreen.routeName,
                value: i18n.settingsDashboardWidgetsValue(
                  ref
                      .watch(appSettingsProvider)
                      .maybeWhen(
                        data: (s) => s.dashboardItems.visibleWidgets.length,
                        orElse: () => defaultDashboardItems.length,
                      ),
                ),
              ),
              _SettingsLink(
                key: const ValueKey('settings-my-ai'),
                icon: Icons.auto_awesome_outlined,
                title: i18n.coachMyAi,
                route: MyAiScreen.routeName,
              ),
              _SettingsLink(
                key: const ValueKey('settings-glossary'),
                icon: Icons.menu_book_outlined,
                title: i18n.glossaryTitle,
                route: GlossaryScreen.routeName,
              ),
            ]),
            _SettingsSection(i18n.others, const [SettingsVerboseLogging()]),
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
                  if (i > 0 && c is! HealthSyncSettingsTile)
                    Divider(height: 1, indent: 16, endIndent: 16, color: line),
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

/// A row that opens another screen: a round icon, the title, what is set now
/// (when there is something to say) and a chevron.
class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    super.key,
    required this.icon,
    required this.title,
    required this.route,
    this.value,
  });

  final IconData icon;
  final String title;
  final String route;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            IconBadge(icon, size: 40, color: atlas.ink2),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            if (value != null) ...[
              Text(value!, style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3)),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, color: atlas.ink3),
          ],
        ),
      ),
    );
  }
}
