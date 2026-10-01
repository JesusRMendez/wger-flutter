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

/// The abbreviations that are explained in the glossary. The texts (what it is,
/// how it helps your goal, an example) are in the l10n files.
enum GlossaryTerm {
  oneRm,
  rir,
  rpe,
  doubleProgression,
  deload,
  superset,
  amrap,
  pr,
  volume,
  kcal,
  macros,
  nutriScore,
  nova,
  movingAverage7,
  hr,
  stepsPerMin,
  bpm;

  String abbreviation(AppLocalizations i18n) {
    switch (this) {
      case GlossaryTerm.oneRm:
        return i18n.glossaryOneRmAbbr;
      case GlossaryTerm.rir:
        return i18n.glossaryRirAbbr;
      case GlossaryTerm.rpe:
        return i18n.glossaryRpeAbbr;
      case GlossaryTerm.doubleProgression:
        return i18n.glossaryDoubleProgressionAbbr;
      case GlossaryTerm.deload:
        return i18n.glossaryDeloadAbbr;
      case GlossaryTerm.superset:
        return i18n.glossarySupersetAbbr;
      case GlossaryTerm.amrap:
        return i18n.glossaryAmrapAbbr;
      case GlossaryTerm.pr:
        return i18n.glossaryPrAbbr;
      case GlossaryTerm.volume:
        return i18n.glossaryVolumeAbbr;
      case GlossaryTerm.kcal:
        return i18n.glossaryKcalAbbr;
      case GlossaryTerm.macros:
        return i18n.glossaryMacrosAbbr;
      case GlossaryTerm.nutriScore:
        return i18n.glossaryNutriScoreAbbr;
      case GlossaryTerm.nova:
        return i18n.glossaryNovaAbbr;
      case GlossaryTerm.movingAverage7:
        return i18n.glossaryMovingAverage7Abbr;
      case GlossaryTerm.hr:
        return i18n.glossaryHrAbbr;
      case GlossaryTerm.stepsPerMin:
        return i18n.glossaryStepsPerMinAbbr;
      case GlossaryTerm.bpm:
        return i18n.glossaryBpmAbbr;
    }
  }

  String fullName(AppLocalizations i18n) {
    switch (this) {
      case GlossaryTerm.oneRm:
        return i18n.glossaryOneRmName;
      case GlossaryTerm.rir:
        return i18n.glossaryRirName;
      case GlossaryTerm.rpe:
        return i18n.glossaryRpeName;
      case GlossaryTerm.doubleProgression:
        return i18n.glossaryDoubleProgressionName;
      case GlossaryTerm.deload:
        return i18n.glossaryDeloadName;
      case GlossaryTerm.superset:
        return i18n.glossarySupersetName;
      case GlossaryTerm.amrap:
        return i18n.glossaryAmrapName;
      case GlossaryTerm.pr:
        return i18n.glossaryPrName;
      case GlossaryTerm.volume:
        return i18n.glossaryVolumeName;
      case GlossaryTerm.kcal:
        return i18n.glossaryKcalName;
      case GlossaryTerm.macros:
        return i18n.glossaryMacrosName;
      case GlossaryTerm.nutriScore:
        return i18n.glossaryNutriScoreName;
      case GlossaryTerm.nova:
        return i18n.glossaryNovaName;
      case GlossaryTerm.movingAverage7:
        return i18n.glossaryMovingAverage7Name;
      case GlossaryTerm.hr:
        return i18n.glossaryHrName;
      case GlossaryTerm.stepsPerMin:
        return i18n.glossaryStepsPerMinName;
      case GlossaryTerm.bpm:
        return i18n.glossaryBpmName;
    }
  }

  String what(AppLocalizations i18n) {
    switch (this) {
      case GlossaryTerm.oneRm:
        return i18n.glossaryOneRmWhat;
      case GlossaryTerm.rir:
        return i18n.glossaryRirWhat;
      case GlossaryTerm.rpe:
        return i18n.glossaryRpeWhat;
      case GlossaryTerm.doubleProgression:
        return i18n.glossaryDoubleProgressionWhat;
      case GlossaryTerm.deload:
        return i18n.glossaryDeloadWhat;
      case GlossaryTerm.superset:
        return i18n.glossarySupersetWhat;
      case GlossaryTerm.amrap:
        return i18n.glossaryAmrapWhat;
      case GlossaryTerm.pr:
        return i18n.glossaryPrWhat;
      case GlossaryTerm.volume:
        return i18n.glossaryVolumeWhat;
      case GlossaryTerm.kcal:
        return i18n.glossaryKcalWhat;
      case GlossaryTerm.macros:
        return i18n.glossaryMacrosWhat;
      case GlossaryTerm.nutriScore:
        return i18n.glossaryNutriScoreWhat;
      case GlossaryTerm.nova:
        return i18n.glossaryNovaWhat;
      case GlossaryTerm.movingAverage7:
        return i18n.glossaryMovingAverage7What;
      case GlossaryTerm.hr:
        return i18n.glossaryHrWhat;
      case GlossaryTerm.stepsPerMin:
        return i18n.glossaryStepsPerMinWhat;
      case GlossaryTerm.bpm:
        return i18n.glossaryBpmWhat;
    }
  }

  String how(AppLocalizations i18n) {
    switch (this) {
      case GlossaryTerm.oneRm:
        return i18n.glossaryOneRmHow;
      case GlossaryTerm.rir:
        return i18n.glossaryRirHow;
      case GlossaryTerm.rpe:
        return i18n.glossaryRpeHow;
      case GlossaryTerm.doubleProgression:
        return i18n.glossaryDoubleProgressionHow;
      case GlossaryTerm.deload:
        return i18n.glossaryDeloadHow;
      case GlossaryTerm.superset:
        return i18n.glossarySupersetHow;
      case GlossaryTerm.amrap:
        return i18n.glossaryAmrapHow;
      case GlossaryTerm.pr:
        return i18n.glossaryPrHow;
      case GlossaryTerm.volume:
        return i18n.glossaryVolumeHow;
      case GlossaryTerm.kcal:
        return i18n.glossaryKcalHow;
      case GlossaryTerm.macros:
        return i18n.glossaryMacrosHow;
      case GlossaryTerm.nutriScore:
        return i18n.glossaryNutriScoreHow;
      case GlossaryTerm.nova:
        return i18n.glossaryNovaHow;
      case GlossaryTerm.movingAverage7:
        return i18n.glossaryMovingAverage7How;
      case GlossaryTerm.hr:
        return i18n.glossaryHrHow;
      case GlossaryTerm.stepsPerMin:
        return i18n.glossaryStepsPerMinHow;
      case GlossaryTerm.bpm:
        return i18n.glossaryBpmHow;
    }
  }

  String example(AppLocalizations i18n) {
    switch (this) {
      case GlossaryTerm.oneRm:
        return i18n.glossaryOneRmExample;
      case GlossaryTerm.rir:
        return i18n.glossaryRirExample;
      case GlossaryTerm.rpe:
        return i18n.glossaryRpeExample;
      case GlossaryTerm.doubleProgression:
        return i18n.glossaryDoubleProgressionExample;
      case GlossaryTerm.deload:
        return i18n.glossaryDeloadExample;
      case GlossaryTerm.superset:
        return i18n.glossarySupersetExample;
      case GlossaryTerm.amrap:
        return i18n.glossaryAmrapExample;
      case GlossaryTerm.pr:
        return i18n.glossaryPrExample;
      case GlossaryTerm.volume:
        return i18n.glossaryVolumeExample;
      case GlossaryTerm.kcal:
        return i18n.glossaryKcalExample;
      case GlossaryTerm.macros:
        return i18n.glossaryMacrosExample;
      case GlossaryTerm.nutriScore:
        return i18n.glossaryNutriScoreExample;
      case GlossaryTerm.nova:
        return i18n.glossaryNovaExample;
      case GlossaryTerm.movingAverage7:
        return i18n.glossaryMovingAverage7Example;
      case GlossaryTerm.hr:
        return i18n.glossaryHrExample;
      case GlossaryTerm.stepsPerMin:
        return i18n.glossaryStepsPerMinExample;
      case GlossaryTerm.bpm:
        return i18n.glossaryBpmExample;
    }
  }
}
