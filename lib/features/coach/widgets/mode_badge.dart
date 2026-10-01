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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Badge showing which AI backs the coach. When none is available it links to
/// the My AI settings.
class CoachModeBadge extends ConsumerWidget {
  const CoachModeBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final mode = ref.watch(coachModeProvider).value ?? CoachMode.none;

    final (label, icon) = switch (mode) {
      CoachMode.server => (i18n.coachModeServer, Icons.cloud_outlined),
      CoachMode.byo => (i18n.coachModeByo, Icons.key),
      CoachMode.none => (i18n.coachModeNone, Icons.block),
    };

    return ActionChip(
      key: const ValueKey('coach-mode-badge'),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: mode == CoachMode.none
          ? () => Navigator.of(context).pushNamed(MyAiScreen.routeName)
          : null,
    );
  }
}

/// Monthly token usage of the coach
class CoachUsageCard extends ConsumerWidget {
  const CoachUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final usage = ref.watch(coachUsageProvider).value;
    if (usage == null) {
      return const SizedBox.shrink();
    }

    final used = usage.totalTokens.toString();
    final text = usage.limit == null
        ? i18n.coachUsageUnlimited(used)
        : i18n.coachUsageWithLimit(used, usage.limit.toString());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i18n.coachUsageTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(text),
            if (usage.usedFraction != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: usage.usedFraction),
            ],
          ],
        ),
      ),
    );
  }
}
