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

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/app_settings_notifier.dart';
import 'package:wger/core/material.dart';
import 'package:wger/core/widgets/app_bar.dart';
import 'package:wger/core/widgets/dashboard/calendar.dart';
import 'package:wger/core/widgets/dashboard/widgets/activity.dart';
import 'package:wger/core/widgets/dashboard/widgets/coach.dart';
import 'package:wger/core/widgets/dashboard/widgets/measurements.dart';
import 'package:wger/core/widgets/dashboard/widgets/nutrition.dart';
import 'package:wger/core/widgets/dashboard/widgets/routines.dart';
import 'package:wger/core/widgets/dashboard/widgets/trophies.dart';
import 'package:wger/core/widgets/dashboard/widgets/water.dart';
import 'package:wger/core/widgets/dashboard/widgets/weight.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  Widget _getDashboardWidget(DashboardWidget widget) {
    switch (widget) {
      case DashboardWidget.activity:
        return const DashboardActivityWidget();
      case DashboardWidget.routines:
        return const DashboardRoutineWidget();
      case DashboardWidget.water:
        return const DashboardWaterWidget();
      case DashboardWidget.weight:
        return const DashboardWeightWidget();
      case DashboardWidget.measurements:
        return const DashboardMeasurementWidget();
      case DashboardWidget.calendar:
        return const DashboardCalendarWidget();
      case DashboardWidget.nutrition:
        return const DashboardNutritionWidget();
      case DashboardWidget.trophies:
        return const DashboardTrophiesWidget();
      case DashboardWidget.coach:
        return const DashboardCoachWidget();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < MATERIAL_XS_BREAKPOINT;
    final visibleWidgets = ref.watch(
      appSettingsProvider.select(
        (s) => (s.value?.dashboardItems ?? defaultDashboardItems).visibleWidgets,
      ),
    );

    late final int crossAxisCount;
    if (width < MATERIAL_XS_BREAKPOINT) {
      crossAxisCount = 1;
    } else if (width < MATERIAL_MD_BREAKPOINT) {
      crossAxisCount = 2;
    } else if (width < MATERIAL_LG_BREAKPOINT) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Scaffold(
      appBar: MainAppBar(
        AppLocalizations.of(context).labelDashboard,
        subtitle: DateFormat.MMMMEEEEd(Localizations.localeOf(context).languageCode).format(
          clock.now(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: MATERIAL_LG_BREAKPOINT),
          child: isMobile
              ? ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemBuilder: (context, index) => _getDashboardWidget(visibleWidgets[index]),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemCount: visibleWidgets.length,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) => SingleChildScrollView(
                    child: _getDashboardWidget(visibleWidgets[index]),
                  ),
                  itemCount: visibleWidgets.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
        ),
      ),
    );
  }
}
