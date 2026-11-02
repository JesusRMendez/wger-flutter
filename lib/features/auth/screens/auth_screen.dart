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

import 'package:material_ui/material_ui.dart';
import 'package:wger/features/auth/widgets/auth_card.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen();

  static const routeName = '/auth';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final i18n = AppLocalizations.of(context);

    final headline = theme.textTheme.displaySmall?.copyWith(
      fontSize: 38,
      height: 1.08,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.4,
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // A soft glow of the brand colour behind the headline
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.2, -1.1),
                  radius: 1.0,
                  colors: [
                    scheme.primary.withValues(alpha: 0.22),
                    scheme.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: atlas.hero,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(Icons.fitness_center, color: atlas.onHero, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Text('wger', style: theme.textTheme.headlineMedium),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(i18n.authHero1, style: headline),
                      Text(i18n.authHero2, style: headline),
                      Text(
                        i18n.authHero3,
                        style: headline?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        i18n.authSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(color: atlas.ink2),
                      ),
                      const SizedBox(height: 24),
                      const AuthCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
