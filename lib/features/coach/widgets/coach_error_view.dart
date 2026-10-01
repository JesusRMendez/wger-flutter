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
import 'package:wger/features/coach/providers/coach_errors.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Shows a failed coach request: 403 ai_not_available and 429 ai_quota_exceeded
/// get their own explanation, everything else a generic message with retry.
class CoachErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const CoachErrorView(this.error, {this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final kind = coachErrorKind(error);
    final scheme = Theme.of(context).colorScheme;

    final message = switch (kind) {
      CoachErrorKind.notAvailable => i18n.coachErrorNotAvailable,
      CoachErrorKind.quotaExceeded => i18n.coachErrorQuota,
      CoachErrorKind.other => i18n.coachErrorGeneric,
    };

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(color: scheme.onErrorContainer)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (kind == CoachErrorKind.notAvailable)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed(MyAiScreen.routeName),
                    child: Text(i18n.coachSetUpMyAi),
                  ),
                if (kind == CoachErrorKind.other && onRetry != null)
                  TextButton(onPressed: onRetry, child: Text(i18n.coachRetry)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
