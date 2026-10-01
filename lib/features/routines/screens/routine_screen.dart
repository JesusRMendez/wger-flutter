/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2025 wger Team
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/core/widgets/object_gone_redirect.dart';
import 'package:wger/features/routines/models/day_data.dart';
import 'package:wger/features/routines/models/routine.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';
import 'package:wger/features/routines/widgets/app_bar.dart';
import 'package:wger/features/routines/widgets/routine_detail.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  static const routeName = '/routine-detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineId = ModalRoute.of(context)!.settings.arguments as int;

    return AsyncValueWidget<RoutinesState>(
      value: ref.watch(routinesRiverpodProvider),
      loggerName: 'RoutineScreen',
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
      errorBuilder: (e, st) => Scaffold(
        body: Center(child: StreamErrorIndicator(e, stacktrace: st)),
      ),
      data: (state) {
        final routine = state.findByIdOrNull(routineId);
        if (routine == null) {
          return objectGoneRedirect(context);
        }
        return _RoutineBody(routine);
      },
    );
  }
}

/// The routine with a bottom button that starts the day that is shown
class _RoutineBody extends StatefulWidget {
  final Routine routine;

  const _RoutineBody(this.routine);

  @override
  State<_RoutineBody> createState() => _RoutineBodyState();
}

class _RoutineBodyState extends State<_RoutineBody> {
  final _selected = ValueNotifier<DayData?>(null);

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final routine = widget.routine;

    return Scaffold(
      appBar: RoutineDetailAppBar(routine),
      body: WidescreenWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: RoutineDetail(routine, selectedDay: _selected),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<DayData?>(
        valueListenable: _selected,
        builder: (context, day, _) {
          if (day == null || day.day == null || day.day!.isRest || day.slots.isEmpty) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                key: const ValueKey('routine-start-day'),
                icon: const Icon(Icons.play_arrow),
                label: Text(i18n.routineStartDay(day.day!.name)),
                onPressed: () => Navigator.of(context).pushNamed(
                  GymModeScreen.routeName,
                  arguments: GymModeArguments(routine.id!, day.day!.id!, day.iteration),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
