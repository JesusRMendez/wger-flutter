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

import 'package:material_ui/material_ui.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/glossary/glossary_term.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// All explained abbreviations, with a search field
class GlossaryScreen extends StatefulWidget {
  final GlossaryTerm? initialTerm;

  const GlossaryScreen({super.key, this.initialTerm});

  static const routeName = '/glossary';

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _query = '';
  GlossaryCategory? _category;

  bool _matches(GlossaryTerm term, AppLocalizations i18n) {
    if (_category != null && term.category != _category) {
      return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return term.abbreviation(i18n).toLowerCase().contains(query) ||
        term.fullName(i18n).toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;
    final terms = GlossaryTerm.values.where((t) => _matches(t, i18n)).toList()
      ..sort(
        (a, b) => a.abbreviation(i18n).toLowerCase().compareTo(b.abbreviation(i18n).toLowerCase()),
      );
    final categoryLabels = {
      GlossaryCategory.training: i18n.glossaryCategoryTraining,
      GlossaryCategory.nutrition: i18n.glossaryCategoryNutrition,
      GlossaryCategory.progress: i18n.glossaryCategoryProgress,
      GlossaryCategory.health: i18n.glossaryCategoryHealth,
    };

    return Scaffold(
      body: SafeArea(
        child: WidescreenWrapper(
          child: Column(
            children: [
              AtlasHeader(
                title: i18n.glossaryTitle,
                subtitle: i18n.glossarySubtitle,
                centered: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                actions: const [SizedBox(width: 44)],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  key: const ValueKey('glossary-search'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: i18n.glossarySearchHint,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 8,
                  children: [
                    PillChip(
                      i18n.glossaryCategoryAll,
                      height: 38,
                      fontSize: 14,
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final c in GlossaryCategory.values)
                      PillChip(
                        categoryLabels[c]!,
                        height: 38,
                        fontSize: 14,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    i18n.glossaryTermCount(terms.length),
                    style: theme.textTheme.bodyMedium?.copyWith(color: atlas.ink3),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    for (final term in terms)
                      AtlasCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.zero,
                        borderColor: term == widget.initialTerm ? theme.colorScheme.primary : null,
                        child: ExpansionTile(
                          key: ValueKey('glossary-${term.name}'),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          initiallyExpanded: term == widget.initialTerm,
                          leading: term.fullName(i18n) == term.abbreviation(i18n)
                              ? null
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: atlas.brandSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: MonoText(
                                    term.abbreviation(i18n),
                                    size: 13,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                          title: Text(
                            term.fullName(i18n),
                            style: theme.textTheme.titleSmall,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            _Block(i18n.glossaryWhat, term.what(i18n), theme),
                            _Block(i18n.glossaryHow, term.how(i18n), theme),
                            _Block(i18n.glossaryExample, term.example(i18n), theme),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: atlas.ink3),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              i18n.glossaryFooter,
                              style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String text;
  final ThemeData theme;

  const _Block(this.title, this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          Text(text),
        ],
      ),
    );
  }
}
