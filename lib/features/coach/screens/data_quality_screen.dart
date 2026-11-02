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
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/data_quality_view.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// "Data for your coach": the quality score and what is still missing for the
/// recommendations to be reliable.
class DataQualityScreen extends ConsumerWidget {
  const DataQualityScreen({super.key});

  static const routeName = '/coach-data-quality';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final indicators = ref.watch(coachIndicatorsProvider(28));

    return Scaffold(
      body: WidescreenWrapper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            AtlasHeader(
              title: i18n.coachDataTitle,
              subtitle: i18n.coachDataSubtitle,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            ),
            indicators.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  CoachErrorView(e, onRetry: () => ref.invalidate(coachIndicatorsProvider(28))),
              data: (data) => data.dataQuality == null
                  ? Text(i18n.coachNoIndicators)
                  : DataQualityView(data.dataQuality!),
            ),
          ],
        ),
      ),
    );
  }
}
