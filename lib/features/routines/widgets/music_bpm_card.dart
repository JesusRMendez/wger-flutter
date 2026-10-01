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
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/features/glossary/glossary_term.dart';
import 'package:wger/features/glossary/widgets/glossary_widgets.dart';
import 'package:wger/features/routines/logic/music_bpm.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

String musicPhaseLabel(AppLocalizations i18n, MusicPhase phase) {
  switch (phase) {
    case MusicPhase.warmUp:
      return i18n.musicPhaseWarmUp;
    case MusicPhase.strength:
      return i18n.musicPhaseStrength;
    case MusicPhase.hiit:
      return i18n.musicPhaseHiit;
    case MusicPhase.rest:
      return i18n.musicPhaseRest;
  }
}

/// Recommends a tempo (BPM) for the workout phase and links to searches for
/// matching playlists. Only opens links, there is no playback integration.
class MusicBpmCard extends StatefulWidget {
  final MusicPhase initialPhase;

  /// Opens a link; replaceable for tests
  final Future<bool> Function(Uri uri)? launcher;

  const MusicBpmCard({super.key, this.initialPhase = MusicPhase.strength, this.launcher});

  @override
  State<MusicBpmCard> createState() => _MusicBpmCardState();
}

class _MusicBpmCardState extends State<MusicBpmCard> {
  late MusicPhase _phase = widget.initialPhase;

  @override
  void didUpdateWidget(covariant MusicBpmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhase != widget.initialPhase) {
      _phase = widget.initialPhase;
    }
  }

  Future<void> _open(Uri uri) async {
    final launch = widget.launcher ?? (Uri u) => launchUrl(u, mode: LaunchMode.externalApplication);
    try {
      await launch(uri);
    } catch (_) {
      // Nothing to open the link with, the BPM recommendation is still shown
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Card(
      key: const ValueKey('music-bpm-card'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(i18n.musicByBpm, style: Theme.of(context).textTheme.titleMedium),
                ),
                const AbbreviationChip(GlossaryTerm.bpm),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final phase in MusicPhase.values)
                  ChoiceChip(
                    key: ValueKey('music-phase-${phase.name}'),
                    label: Text(musicPhaseLabel(i18n, phase)),
                    selected: phase == _phase,
                    onSelected: (_) => setState(() => _phase = phase),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              i18n.musicRecommendation(_phase.range),
              key: const ValueKey('music-recommendation'),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey('music-spotify'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(i18n.musicOpenSpotify),
                  onPressed: () => _open(spotifySearchUri(_phase)),
                ),
                TextButton.icon(
                  key: const ValueKey('music-youtube'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(i18n.musicOpenYoutubeMusic),
                  onPressed: () => _open(youtubeMusicSearchUri(_phase)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
