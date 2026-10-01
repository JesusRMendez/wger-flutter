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
import 'package:wger/features/glossary/glossary_term.dart';
import 'package:wger/features/glossary/screens/glossary_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Explains [term] in a bottom sheet: what it is, how it helps and an example
Future<void> showGlossarySheet(BuildContext context, GlossaryTerm term) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => GlossarySheet(term),
  );
}

class GlossarySheet extends StatelessWidget {
  final GlossaryTerm term;

  const GlossarySheet(this.term, {super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget section(String title, String text, {Key? key}) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 2),
          Text(text, key: key),
        ],
      ),
    );

    return SingleChildScrollView(
      key: const ValueKey('glossary-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term.abbreviation(i18n), style: theme.textTheme.headlineSmall),
          if (term.fullName(i18n) != term.abbreviation(i18n))
            Text(term.fullName(i18n), style: theme.textTheme.titleSmall),
          section(i18n.glossaryWhat, term.what(i18n), key: const ValueKey('glossary-what')),
          section(i18n.glossaryHow, term.how(i18n), key: const ValueKey('glossary-how')),
          section(
            i18n.glossaryExample,
            term.example(i18n),
            key: const ValueKey('glossary-example'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('glossary-open-all'),
              onPressed: () {
                Navigator.of(context).pop();
                openGlossary(context, term: term);
              },
              child: Text(i18n.glossaryOpenAll),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small tappable abbreviation (e.g. "RIR") that opens its explanation.
/// Shows the abbreviation of the [term] unless a [label] is given.
class AbbreviationChip extends StatelessWidget {
  final GlossaryTerm term;
  final String? label;
  final TextStyle? style;

  const AbbreviationChip(this.term, {super.key, this.label, this.style});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = label ?? term.abbreviation(i18n);

    return Semantics(
      button: true,
      label: i18n.glossaryExplain(text),
      child: InkWell(
        key: ValueKey('abbreviation-${term.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => showGlossarySheet(context, term),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: (style ?? theme.textTheme.labelMedium)?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.help_outline, size: 12, color: theme.colorScheme.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the full glossary, optionally scrolled to / expanded at [term]
void openGlossary(BuildContext context, {GlossaryTerm? term}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => GlossaryScreen(initialTerm: term)),
  );
}

/// The "?" action that opens the glossary
class GlossaryHelpButton extends StatelessWidget {
  const GlossaryHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('glossary-help-button'),
      icon: const Icon(Icons.help_outline),
      tooltip: AppLocalizations.of(context).glossaryHelp,
      onPressed: () => openGlossary(context),
    );
  }
}
