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
import 'package:wger/l10n/generated/app_localizations.dart';

/// Localized labels for the enum-like strings of the coach API.
extension CoachLabels on AppLocalizations {
  String periodLabel(String period) => switch (period) {
    'weekly' => coachPeriodWeekly,
    'monthly' => coachPeriodMonthly,
    'quarterly' => coachPeriodQuarterly,
    'plan' => coachPeriodPlan,
    _ => period,
  };

  String kindLabel(String kind) => switch (kind) {
    'strength' => coachKindStrength,
    'body_weight' => coachKindBodyWeight,
    'body_fat' => coachKindBodyFat,
    'habit' => coachKindHabit,
    'nutrition' => coachKindNutrition,
    'endurance' => coachKindEndurance,
    'steps' => coachKindSteps,
    _ => kind,
  };

  String statusLabel(String status) => switch (status) {
    'active' => coachStatusActive,
    'achieved' => coachStatusAchieved,
    'missed' => coachStatusMissed,
    'paused' => coachStatusPaused,
    _ => status,
  };

  String indicatorLabel(String key, {String? fallback}) => switch (key) {
    'sessions_per_week' => coachIndicatorSessionsPerWeek,
    'weekly_volume_sets' => coachIndicatorWeeklyVolumeSets,
    'est_1rm' => coachIndicatorEst1rm,
    'body_weight_avg7' => coachIndicatorBodyWeightAvg7,
    'kcal_adherence' => coachIndicatorKcalAdherence,
    'protein_avg' => coachIndicatorProteinAvg,
    _ => fallback ?? key,
  };

  String phaseLabel(String key, {String? fallback}) => switch (key) {
    'adaptation' => coachPhaseAdaptation,
    'progression' => coachPhaseProgression,
    'deload' => coachPhaseDeload,
    'consolidation' => coachPhaseConsolidation,
    _ => fallback ?? key,
  };

  String memoryCategoryLabel(String c) => switch (c) {
    'preference' => coachMemoryCategoryPreference,
    'behavior' => coachMemoryCategoryBehavior,
    'constraint' => coachMemoryCategoryConstraint,
    'injury' => coachMemoryCategoryInjury,
    _ => c,
  };

  String memorySourceLabel(String s) => switch (s) {
    'user' => coachMemorySourceUser,
    'ai' => coachMemorySourceAi,
    'system' => coachMemorySourceSystem,
    _ => s,
  };
}
