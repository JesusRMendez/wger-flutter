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

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/build_safety.dart';
import 'package:wger/core/errors.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/error.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/routines/logic/guided_engine.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/providers/routines_notifier.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';
import 'package:wger/features/routines/widgets/guided/guided_view.dart';

/// The guided timed routine: a routine day as work/rest intervals
class GuidedModeScreen extends ConsumerStatefulWidget {
  const GuidedModeScreen({super.key});

  static const routeName = '/guided-mode';

  @override
  ConsumerState<GuidedModeScreen> createState() => _GuidedModeScreenState();
}

class _GuidedModeScreenState extends ConsumerState<GuidedModeScreen> {
  final _logger = Logger('GuidedModeScreen');
  Future<List<GuidedStep>>? _steps;

  Future<List<GuidedStep>> _load(GymModeArguments args) async {
    await yieldPastBuild();

    final notifier = ref.read(routinesRiverpodProvider.notifier);
    final routine = await serverWithLocalFallback(
      isOnline: ref.read(networkStatusProvider),
      server: () => notifier.fetchAndSetRoutineFull(args.routineId),
      local: () {
        final cached = ref
            .read(routinesRiverpodProvider)
            .value
            ?.routines
            .firstWhereOrNull((r) => r.id == args.routineId);
        if (cached == null || !cached.isHydrated) {
          throw StateError('Routine ${args.routineId} is not available offline');
        }
        return cached;
      },
      logger: _logger,
      fallbackLog: 'Server unreachable, starting from the local routine',
    );

    // Same alert settings as the gym mode
    await ref.read(gymStateProvider.notifier).loadPrefs();

    final day = routine.dayDataGym.firstWhere(
      (d) => d.iteration == args.iteration && d.day?.id == args.dayId,
    );
    return buildGuidedSteps(day);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as GymModeArguments;
    _steps ??= _load(args);

    return Scaffold(
      body: SafeArea(
        child: WidescreenWrapper(
          child: FutureBuilder<List<GuidedStep>>(
            future: _steps,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const BoxedProgressIndicator();
              }
              if (snapshot.hasError) {
                return Center(
                  child: StreamErrorIndicator(snapshot.error!, stacktrace: snapshot.stackTrace),
                );
              }
              return GuidedRoutineView(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }
}
