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

/// Workout phases with a recommended music tempo
enum MusicPhase {
  warmUp(100, 120),
  strength(120, 140),
  hiit(150, 170),
  rest(90, 110);

  final int minBpm;
  final int maxBpm;

  const MusicPhase(this.minBpm, this.maxBpm);

  String get range => '$minBpm-$maxBpm';
}

/// Search term that finds playlists for the tempo of the phase
String musicSearchTerm(MusicPhase phase) => 'workout ${phase.minBpm}-${phase.maxBpm} bpm';

/// Spotify search (a universal link, opens the app if it is installed)
Uri spotifySearchUri(MusicPhase phase) =>
    Uri.https('open.spotify.com', '/search/${musicSearchTerm(phase)}');

/// YouTube Music search
Uri youtubeMusicSearchUri(MusicPhase phase) =>
    Uri.https('music.youtube.com', '/search', {'q': musicSearchTerm(phase)});
