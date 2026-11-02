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
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/glossary/glossary_term.dart';
import 'package:wger/features/glossary/widgets/glossary_widgets.dart';
import 'package:wger/features/routines/logic/music_bpm.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

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

  Widget _tile(BuildContext context, String label, MusicPhase phase, {Key? key}) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: atlas.surface2,
        borderRadius: BorderRadius.circular(AtlasRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                MonoText(phase.range, size: 20, color: theme.colorScheme.onSurface),
                const SizedBox(width: 4),
                Text('BPM', style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _service(
    BuildContext context, {
    required Key key,
    required String name,
    required String hint,
    required VoidCallback onOpen,
  }) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: atlas.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.volume_up_outlined, size: 20, color: atlas.ink2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleSmall),
              Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: atlas.ink3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          key: key,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(AppLocalizations.of(context).musicOpen),
          onPressed: onOpen,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final atlas = context.atlas;

    // The phase the user plays against: work against rest
    final contrast = _phase == MusicPhase.rest ? MusicPhase.strength : MusicPhase.rest;

    return AtlasCard(
      key: const ValueKey('music-bpm-card'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(i18n.musicByBpm, style: Theme.of(context).textTheme.titleMedium),
              ),
              const AbbreviationChip(GlossaryTerm.bpm),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (final phase in MusicPhase.values)
                  PillChip(
                    musicPhaseLabel(i18n, phase),
                    key: ValueKey('music-phase-${phase.name}'),
                    selected: phase == _phase,
                    height: 36,
                    fontSize: 13,
                    onTap: () => setState(() => _phase = phase),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _tile(
                  context,
                  musicPhaseLabel(i18n, _phase),
                  _phase,
                  key: const ValueKey('music-tile-phase'),
                ),
              ),
              Expanded(
                child: _tile(
                  context,
                  musicPhaseLabel(i18n, contrast),
                  contrast,
                  key: const ValueKey('music-tile-contrast'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            i18n.musicRecommendation(_phase.range),
            key: const ValueKey('music-recommendation'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: atlas.ink3),
          ),
          const SizedBox(height: 14),
          _service(
            context,
            key: const ValueKey('music-spotify'),
            name: 'Spotify',
            hint: i18n.musicServiceHint(_phase.range),
            onOpen: () => _open(spotifySearchUri(_phase)),
          ),
          const SizedBox(height: 12),
          _service(
            context,
            key: const ValueKey('music-youtube'),
            name: 'YouTube Music',
            hint: i18n.musicServiceHint(_phase.range),
            onOpen: () => _open(youtubeMusicSearchUri(_phase)),
          ),
        ],
      ),
    );
  }
}
