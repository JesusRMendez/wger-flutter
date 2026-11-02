import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/progress_indicator.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/providers/exercise_filters_notifier.dart';
import 'package:wger/features/exercises/screens/add_exercise_screen.dart';
import 'package:wger/features/exercises/widgets/filter_row.dart';
import 'package:wger/features/exercises/widgets/list_tile.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  static const routeName = '/exercises';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseState = ref.watch(exerciseListFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          AppLocalizations.of(context).exercises,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          IconButton(
            key: const ValueKey('add-exercise-button'),
            tooltip: AppLocalizations.of(context).contributeExercise,
            style: IconButton.styleFrom(
              backgroundColor: context.atlas.card,
              side: BorderSide(color: context.atlas.line),
              fixedSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.add),
            onPressed: ref.watch(networkStatusProvider)
                ? () => Navigator.of(context).pushNamed(AddExerciseScreen.routeName)
                : null,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: WidescreenWrapper(
        child: Column(
          children: [
            const FilterRow(),
            Expanded(
              child: exerciseState.isLoading
                  ? const BoxedProgressIndicator()
                  : _ExercisesList(
                      exerciseList: exerciseState.filteredExercises,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisesList extends StatelessWidget {
  const _ExercisesList({required this.exerciseList});

  final List<Exercise> exerciseList;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: exerciseList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text(
              AppLocalizations.of(context).exercisesCount(exerciseList.length),
              key: const ValueKey('exercise-count'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: atlas.ink3),
            ),
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            border: index > 1 ? Border(top: BorderSide(color: atlas.line)) : null,
          ),
          child: ExerciseListTile(exercise: exerciseList[index - 1]),
        );
      },
    );
  }
}
