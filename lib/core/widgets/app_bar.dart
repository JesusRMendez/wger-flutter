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

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/network/auth_http_client.dart';
import 'package:wger/core/network/auth_notifier.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/network/wger_base.dart';
import 'package:wger/core/settings_dashboard_widgets_screen.dart';
import 'package:wger/core/widgets/about.dart';
import 'package:wger/core/widgets/sync_status_dialog.dart';
import 'package:wger/database/powersync/powersync.dart'
    show builtPowerSyncInstance, connectPowerSync, syncStatus, syncWatchdogProvider;
import 'package:wger/features/account/providers/account_notifier.dart';
import 'package:wger/features/account/widgets/forms.dart';
import 'package:wger/features/account/widgets/settings.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String _title;

  /// A muted line above the title, e.g. the date on the dashboard
  final String? subtitle;

  const MainAppBar(this._title, {this.subtitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatus);
    final status = syncStatusIconAndLabel(
      syncState,
      AppLocalizations.of(context),
      deviceOnline: ref.watch(networkStatusProvider),
    );

    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.atlas.ink3, fontSize: 13),
            ),
          Text(_title, style: Theme.of(context).textTheme.headlineLarge),
        ],
      ),
      actions: [
        IconButton(
          style: _actionStyle(context),
          icon: const Icon(Icons.widgets_outlined),
          onPressed: () {
            Navigator.of(context).pushNamed(ConfigureDashboardWidgetsScreen.routeName);
          },
        ),
        IconButton(
          style: _actionStyle(context),
          icon: Icon(status.icon),
          onPressed: () {
            // The dialog watches the sync state itself; the server URL and
            // adapter gate are tap-time snapshots. The route builder runs
            // during build, where a dirty provider read forces a mid-build
            // refresh. Reconnect gates on the adapter, a platform fact,
            // never on the reachability status (it exists for when that
            // status is wrong).
            final serverUrl = ref.read(wgerBaseProvider).serverUrl;
            final adapterAvailable = ref.read(networkAdapterAvailableProvider);

            showDialog<void>(
              context: context,
              builder: (_) => SyncStatusDialog(
                serverUrl: serverUrl,
                onReconnect: !adapterAvailable
                    ? null
                    : () {
                        unawaited(ref.read(networkStatusProvider.notifier).check(optimistic: true));

                        final db = builtPowerSyncInstance;
                        final url = ref.read(wgerBaseProvider).serverUrl;
                        // The adapter re-check covers it disappearing while
                        // the dialog was open.
                        if (db == null ||
                            url == null ||
                            !ref.read(networkAdapterAvailableProvider)) {
                          return;
                        }
                        // A manual reconnect is a deliberate new connection epoch.
                        final watchdog = ref.read(syncWatchdogProvider);
                        watchdog.reset();
                        connectPowerSync(
                          db,
                          url,
                          ref.read(authenticatedHttpClientProvider),
                          watchdog,
                          reason: 'manual retry',
                        );
                      },
              ),
            );
          },
        ),
        IconButton(
          style: _actionStyle(context),
          icon: const Icon(Icons.settings),
          onPressed: () async {
            return showDialog(
              context: context,
              builder: (BuildContext context) {
                return const MainSettingsDialog();
              },
            );
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  /// Round 44px button with a 1px line, the "ib" of the design
  static ButtonStyle _actionStyle(BuildContext context) {
    final atlas = context.atlas;
    return IconButton.styleFrom(
      backgroundColor: atlas.card,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      side: BorderSide(color: atlas.line),
      fixedSize: const Size(44, 44),
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      iconSize: 20,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 68 : 80);
}

class MainSettingsDialog extends ConsumerWidget {
  const MainSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);

    return AlertDialog(
      title: Text(AppLocalizations.of(context).optionsLabel),
      actions: [
        TextButton(
          child: Text(
            MaterialLocalizations.of(context).closeButtonLabel,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            //dense: true,
            leading: const Icon(Icons.person),
            title: Text(AppLocalizations.of(context).userProfile),
            enabled: isOnline,
            trailing: isOnline
                ? null
                : Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.outline),
            onTap: () {
              Navigator.pushNamed(
                context,
                FormScreen.routeName,
                arguments: FormScreenArguments(
                  AppLocalizations.of(context).userProfile,
                  const UserProfileForm(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            onTap: () => Navigator.of(context).pushNamed(SettingsPage.routeName),
            title: Text(AppLocalizations.of(context).settingsTitle),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            onTap: () => Navigator.of(context).pushNamed(AboutPage.routeName),
            title: Text(AppLocalizations.of(context).aboutPageTitle),
          ),
          const Divider(),
          ListTile(
            //dense: true,
            leading: const Icon(Icons.exit_to_app),
            title: Text(AppLocalizations.of(context).logout),
            onTap: () async {
              final navigator = Navigator.of(context);

              // Auth logout wipes the local PowerSync DB as part of its
              // lifecycle. Await it so we don't race the navigation. Gallery
              // state lives in PowerSync now and gets cleared along with the
              // rest of the synced tables.
              await ref.read(authProvider.notifier).logout();
              ref.read(accountProvider.notifier).clear();

              navigator.pop();
              navigator.pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }
}

/// App bar that only displays a title
class EmptyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String _title;

  const EmptyAppBar(this._title);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(_title), actions: const []);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
