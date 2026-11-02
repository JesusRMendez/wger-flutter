/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/coach/screens/coach_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Dashboard card that opens the AI coach
class DashboardCoachWidget extends StatelessWidget {
  const DashboardCoachWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return AtlasCard(
      key: const ValueKey('dashboard-coach'),
      onTap: () => Navigator.of(context).pushNamed(CoachScreen.routeName),
      child: CardHeader(
        icon: Icons.auto_awesome,
        title: i18n.coach,
        subtitle: i18n.coachDashboardText,
        trailing: Icon(Icons.chevron_right, color: context.atlas.ink3),
      ),
    );
  }
}
