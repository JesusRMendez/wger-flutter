// /*
//  * This file is part of wger Workout Manager <https://github.com/wger-project>.
//  * Copyright (C) 2020, 2025 wger Team
//  *
//  * wger Workout Manager is free software: you can redistribute it and/or modify
//  * it under the terms of the GNU Affero General Public License as published by
//  * the Free Software Foundation, either version 3 of the License, or
//  * (at your option) any later version.
//  *
//  * wger Workout Manager is distributed in the hope that it will be useful,
//  * but WITHOUT ANY WARRANTY; without even the implied warranty of
//  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  * GNU Affero General Public License for more details.
//  *
//  * You should have received a copy of the GNU Affero General Public License
//  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
//  */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/features/exercises/widgets/autocompleter.dart';
import 'package:wger/features/glossary/glossary_term.dart';
import 'package:wger/features/glossary/widgets/glossary_widgets.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/zone_chip.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Animates to the given set page and closes the menu. If this skips exercises
/// that are not done yet, a short, non-blocking warning is shown.
void _jumpToPage(BuildContext context, PageController controller, PageEntry page) {
  final skipsAhead = ProviderScope.containerOf(
    context,
  ).read(gymStateProvider).wouldSkipAhead(page.uuid);
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).gymModeSkippingAheadWarning;

  controller.animateToPage(
    page.pageIndex,
    duration: DEFAULT_ANIMATION_DURATION,
    curve: DEFAULT_ANIMATION_CURVE,
  );
  Navigator.of(context).pop();

  if (skipsAhead) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class WorkoutMenu extends StatelessWidget {
  final PageController _controller;
  final int initialIndex;

  const WorkoutMenu(this._controller, {this.initialIndex = 0, super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: initialIndex,
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.menu_open)),
              Tab(icon: Icon(Icons.stacked_bar_chart)),
            ],
          ),
          Flexible(
            child: TabBarView(
              children: [
                NavigationTab(_controller),
                ProgressionTab(_controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationTab extends ConsumerWidget {
  final PageController _controller;

  const NavigationTab(this._controller);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gymStateProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          ...state.pages.where((pageEntry) => pageEntry.type == PageType.set).map((page) {
            return ListTile(
              leading: page.allLogsDone ? const Icon(Icons.check) : null,
              title: Text(
                page.exercises
                    .map(
                      (exercise) => exercise
                          .getTranslation(Localizations.localeOf(context).languageCode)
                          .name,
                    )
                    .toList()
                    .join('\n'),
                style: TextStyle(
                  decoration: page.allLogsDone ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              subtitle: ZoneChip(page),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _jumpToPage(context, _controller, page),
            );
          }),
        ],
      ),
    );
  }
}

class ProgressionTab extends ConsumerStatefulWidget {
  final _logger = Logger('ProgressionTab');
  final PageController _controller;

  ProgressionTab(this._controller, {super.key});

  @override
  ConsumerState<ProgressionTab> createState() => _ProgressionTabState();
}

class _ProgressionTabState extends ConsumerState<ProgressionTab> {
  String? showSwapWidgetToPage;
  String? showAddExerciseWidgetToPage;

  /// Whether the user changed the order of the exercises in this menu
  bool _orderChanged = false;

  _ProgressionTabState();

  /// Moves the exercise one position and keeps the page view on what the
  /// user is looking at, as the page indices change
  void _movePage(PageEntry page, {required bool up}) {
    final notifier = ref.read(gymStateProvider.notifier);
    if (!notifier.moveSlotBy(page.uuid, up: up)) {
      return;
    }

    final currentPage = ref.read(gymStateProvider).currentPage;
    if (widget._controller.hasClients && widget._controller.page?.round() != currentPage) {
      widget._controller.jumpToPage(currentPage);
    }
    setState(() => _orderChanged = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gymStateProvider);
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final i18n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            ...state.pages.where((page) => page.type == PageType.set).map((page) {
              if (page.exercises.isEmpty) {
                widget._logger.warning('Page ${page.uuid} has no exercises, skipping');
                return Container();
              }

              // For supersets, prefix the exercise with A, B, C so it can be identified
              // in the set list below
              final isSuperset = page.exercises.length > 1;
              final pageExerciseTitle = isSuperset
                  ? page.exercises
                        .asMap()
                        .entries
                        .map((entry) {
                          final label = String.fromCharCode(65 + entry.key);
                          final name = entry.value
                              .getTranslation(Localizations.localeOf(context).languageCode)
                              .name;
                          return '$label: $name';
                        })
                        .join('\n')
                  : page.exercises.first.getTranslation(languageCode).name;

              return Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pageExerciseTitle, style: Theme.of(context).textTheme.bodyLarge),
                  if (isSuperset)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AbbreviationChip(GlossaryTerm.superset),
                    ),
                  ZoneChip(page),
                  ...page.slotPages.where((slotPage) => slotPage.type == SlotPageType.log).map(
                    (slotPage) {
                      String setPrefix = '';
                      if (isSuperset) {
                        final exerciseIndex = page.exercises.indexWhere(
                          (ex) => ex.id == slotPage.setConfigData!.exercise.id,
                        );
                        if (exerciseIndex != -1) {
                          setPrefix = '${String.fromCharCode(65 + exerciseIndex)}: ';
                        }
                      }

                      // Sets that are done are marked with a strikethrough
                      final decoration = slotPage.logDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none;

                      // Sets that are done have a lighter color
                      final color = slotPage.logDone
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                          : null;

                      // The row for the current page is highlighted in bold
                      final fontWeight = state.currentPage == slotPage.pageIndex
                          ? FontWeight.bold
                          : null;

                      IconData icon = Icons.circle_outlined;
                      if (slotPage.logDone) {
                        icon = Icons.check_circle_rounded;
                      } else if (state.currentPage == slotPage.pageIndex) {
                        icon = Icons.play_circle_fill;
                      }

                      return Row(
                        children: [
                          Icon(icon, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$setPrefix${slotPage.setConfigData!.textReprWithType}',
                            style: theme.textTheme.bodyMedium!.copyWith(
                              decoration: decoration,
                              fontWeight: fontWeight,
                              color: color,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.max,
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: page.allLogsDone
                            ? null
                            : () {
                                if (showSwapWidgetToPage == page.uuid) {
                                  setState(() {
                                    showSwapWidgetToPage = null;
                                  });
                                } else {
                                  setState(() {
                                    showSwapWidgetToPage = page.uuid;
                                    showAddExerciseWidgetToPage = null;
                                  });
                                }
                              },
                        icon: Icon(
                          key: ValueKey('swap-icon-${page.uuid}'),
                          showSwapWidgetToPage == page.uuid
                              ? Icons.change_circle
                              : Icons.change_circle_outlined,
                        ),
                      ),
                      IconButton(
                        onPressed: page.allLogsDone
                            ? null
                            : () {
                                if (showAddExerciseWidgetToPage == page.uuid) {
                                  setState(() {
                                    showAddExerciseWidgetToPage = null;
                                  });
                                } else {
                                  setState(() {
                                    showAddExerciseWidgetToPage = page.uuid;
                                    showSwapWidgetToPage = null;
                                  });
                                }
                              },
                        icon: Icon(
                          key: ValueKey('add-icon-${page.uuid}'),
                          showAddExerciseWidgetToPage == page.uuid ? Icons.add_circle : Icons.add,
                        ),
                      ),
                      Expanded(child: Container()),
                      if (page.isMovable) ...[
                        IconButton(
                          key: ValueKey('move-up-${page.uuid}'),
                          tooltip: i18n.gymModeMoveUp,
                          onPressed: state.canMovePage(page.uuid, up: true)
                              ? () => _movePage(page, up: true)
                              : null,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          key: ValueKey('move-down-${page.uuid}'),
                          tooltip: i18n.gymModeMoveDown,
                          onPressed: state.canMovePage(page.uuid, up: false)
                              ? () => _movePage(page, up: false)
                              : null,
                          icon: const Icon(Icons.arrow_downward),
                        ),
                      ],
                      IconButton(
                        onPressed: () => _jumpToPage(context, widget._controller, page),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  if (showSwapWidgetToPage == page.uuid)
                    ExerciseSwapWidget(
                      page.uuid,
                      onDone: () {
                        setState(() {
                          showSwapWidgetToPage = null;
                        });
                      },
                    ),
                  if (showAddExerciseWidgetToPage == page.uuid)
                    ExerciseAddWidget(
                      page.uuid,
                      onDone: () {
                        setState(() {
                          showAddExerciseWidgetToPage = null;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              );
            }),
            if (_orderChanged)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  i18n.gymModeOrderChangedWarning,
                  key: const ValueKey('order-changed-warning'),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Swapping or adding an exercise only affects the current workout, '
                'no changes are saved.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseSwapWidget extends ConsumerWidget {
  final _logger = Logger('ExerciseSwapWidget');

  final String pageUUID;
  final VoidCallback? onDone;

  ExerciseSwapWidget(this.pageUUID, {this.onDone, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gymStateProvider);
    final gymProvider = ref.read(gymStateProvider.notifier);
    final page = state.pages.firstWhere((p) => p.uuid == pageUUID);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              ...page.exercises.map((e) {
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      e.getTranslation(Localizations.localeOf(context).languageCode).name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Icon(Icons.swap_vert),
                    ExerciseAutocompleter(
                      onExerciseSelected: (exercise) {
                        gymProvider.replaceExercises(
                          page.uuid,
                          originalExerciseId: e.id,
                          newExercise: exercise,
                        );
                        onDone?.call();
                        _logger.fine('Replaced exercise ${e.id} with ${exercise.id}');
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class ExerciseAddWidget extends ConsumerWidget {
  final _logger = Logger('ExerciseAddWidget');

  final String pageUUID;
  final VoidCallback? onDone;

  ExerciseAddWidget(this.pageUUID, {this.onDone, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gymStateProvider);
    final gymProvider = ref.read(gymStateProvider.notifier);
    final page = state.pages.firstWhere((p) => p.uuid == pageUUID);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              ExerciseAutocompleter(
                onExerciseSelected: (exercise) {
                  gymProvider.addExerciseAfterPage(
                    page.uuid,
                    newExercise: exercise,
                  );
                  onDone?.call();
                  _logger.fine('Added exercise ${exercise.id} after page $pageUUID');
                },
              ),
              const Icon(Icons.arrow_downward),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutMenuDialog extends ConsumerWidget {
  final PageController controller;
  final bool showEndWorkoutButton;
  final int initialIndex;

  const WorkoutMenuDialog(
    this.controller, {
    super.key,
    this.showEndWorkoutButton = true,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymStateProvider);

    final endWorkoutButton = showEndWorkoutButton
        ? TextButton(
            child: Text(AppLocalizations.of(context).endWorkout),
            onPressed: () {
              controller.animateToPage(
                gymState.totalPages,
                duration: DEFAULT_ANIMATION_DURATION,
                curve: DEFAULT_ANIMATION_CURVE,
              );

              Navigator.of(context).pop();
            },
          )
        : null;

    return AlertDialog(
      title: Text(
        AppLocalizations.of(context).jumpTo,
        textAlign: TextAlign.center,
      ),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: WorkoutMenu(controller, initialIndex: initialIndex),
      ),
      actions: [
        ?endWorkoutButton,
        TextButton(
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
