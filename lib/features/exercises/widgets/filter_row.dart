/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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
import 'package:wger/core/i18n.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/exercises/models/category.dart';
import 'package:wger/features/exercises/providers/exercise_filters_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

import 'filter_modal.dart';

class FilterRow extends ConsumerStatefulWidget {
  const FilterRow({super.key});

  @override
  _FilterRowState createState() => _FilterRowState();
}

class _FilterRowState extends ConsumerState<FilterRow> {
  late final TextEditingController _exerciseNameController;

  @override
  void initState() {
    super.initState();

    final initialSearch = ref.read(exerciseListFiltersProvider).filters.searchTerm;

    _exerciseNameController = TextEditingController(text: initialSearch)
      ..addListener(() {
        final text = _exerciseNameController.text;
        final currentFilters = ref.read(exerciseListFiltersProvider).filters;
        if (currentFilters.searchTerm != text) {
          ref
              .read(exerciseListFiltersProvider.notifier)
              .setFilters(
                currentFilters.copyWith(searchTerm: text),
                Localizations.localeOf(context).languageCode,
              );
        }
      });
  }

  /// Selects exactly [category], or nothing for null ("All")
  void _selectCategory(ExerciseCategory? category) {
    final filters = ref.read(exerciseListFiltersProvider).filters;
    final items = {
      for (final c in filters.exerciseCategories.items.keys) c: category != null && c == category,
    };
    ref
        .read(exerciseListFiltersProvider.notifier)
        .setFilters(
          filters.copyWith(
            exerciseCategories: filters.exerciseCategories.copyWith(items: items),
          ),
          Localizations.localeOf(context).languageCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;
    final state = ref.watch(exerciseListFiltersProvider);
    final categories = state.filters.exerciseCategories;
    final selected = categories.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextFormField(
            key: const ValueKey('exercise-search'),
            controller: _exerciseNameController,
            decoration: InputDecoration(
              hintText: i18n.exercisesSearchHint(state.exercises.length),
              prefixIcon: Icon(Icons.search, color: atlas.ink3),
              suffixIcon: IconButton(
                key: const ValueKey('exercise-filter-button'),
                tooltip: i18n.filter,
                icon: Icon(Icons.tune, color: atlas.ink2),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AtlasRadius.sheet),
                        topRight: Radius.circular(AtlasRadius.sheet),
                      ),
                    ),
                    builder: (context) => const ExerciseFilterModalBody(),
                  );
                },
              ),
            ),
          ),
        ),
        if (categories.items.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              key: const ValueKey('exercise-category-chips'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Center(
                  child: PillChip(
                    i18n.filterAll,
                    key: const ValueKey('category-chip-all'),
                    selected: selected.isEmpty,
                    height: 36,
                    fontSize: 14,
                    onTap: () => _selectCategory(null),
                  ),
                ),
                for (final c in categories.items.keys) ...[
                  const SizedBox(width: 8),
                  Center(
                    child: PillChip(
                      getServerStringTranslation(c.name, context),
                      key: ValueKey('category-chip-${c.id}'),
                      selected: selected.length == 1 && selected.first == c,
                      height: 36,
                      fontSize: 14,
                      onTap: () => _selectCategory(c),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    super.dispose();
  }
}
