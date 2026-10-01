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
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/account/providers/user_profile_notifier.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/measurements/models/unit_conversion.dart';
import 'package:wger/features/measurements/providers/body_weight_provider.dart';
import 'package:wger/features/measurements/providers/chart_range_setting.dart';
import 'package:wger/features/measurements/widgets/entries.dart';
import 'package:wger/features/measurements/widgets/weight_form.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Body weight, presented as its own tab.
///
/// The data is the official body weight category, so this is [EntriesList]
/// over it. What the category alone does not say is presentation: the values
/// are shown in the profile unit (entries can be stored in kg or lb), the
/// title is translated rather than taken from the server-created category, and
/// the entry form is the one with the quick steppers.
class WeightScreen extends ConsumerWidget {
  const WeightScreen();

  static const routeName = '/weight';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    // New entries need the official category, which the server creates and the
    // initial sync delivers; hide the FAB until it is there.
    final category = ref.watch(bodyWeightCategoryOnlyProvider).value;
    // The profile decides the display unit, so nothing can be drawn without it
    final profile = ref.watch(userProfileProvider).value;

    // The weight the user is heading for, from the body weight goal of the coach
    // (read leniently: the coach is optional and may not be reachable)
    num? target;
    if (profile != null) {
      final goals = ref.watch(coachGoalsProvider.select((a) => a.hasValue ? a.value : null));
      final goal = goals
          ?.where((g) => g.kind == 'body_weight' && g.status == 'active' && g.targetValue != null)
          .firstOrNull;
      if (goal != null) {
        final inKg = goal.unit.toLowerCase() != 'lb' && goal.unit.toLowerCase() != 'lbs';
        target = profile.isMetric == inKg
            ? goal.targetValue
            : (inKg ? goal.targetValue! * 2.20462 : goal.targetValue! / 2.20462);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: WidescreenWrapper(
          child: Column(
            children: [
              AtlasHeader(
                title: i18n.weight,
                centered: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                actions: const [SizedBox(width: 44)],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: category == null || profile == null
                      ? const BoxedProgressIndicator()
                      : EntriesList(
                          category,
                          // Shared with the whole measurements tab, see ChartRangeSetting
                          range: ref.watch(chartRangeSettingProvider),
                          onRangeChanged: (range) =>
                              ref.read(chartRangeSettingProvider.notifier).set(range),
                          title: i18n.weight,
                          showHero: true,
                          displayUnit: weightDisplayUnit(profile.isMetric),
                          displayUnitLabel: weightUnit(profile.isMetric, context),
                          editFormBuilder: (entry) => WeightForm(category, entry),
                          projectionTarget: target,
                        ),
                ),
              ),
              if (category != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(i18n.registerWeight),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          FormScreen.routeName,
                          arguments: FormScreenArguments(
                            i18n.newEntry,
                            WeightForm(category),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
