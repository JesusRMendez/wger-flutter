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

import 'package:flutter_test/flutter_test.dart';
import 'package:wger/features/routines/logic/music_bpm.dart';

void main() {
  test('BPM ranges per phase', () {
    expect(MusicPhase.warmUp.range, '100-120');
    expect(MusicPhase.strength.range, '120-140');
    expect(MusicPhase.hiit.range, '150-170');
    expect(MusicPhase.rest.range, '90-110');
  });

  test('deep links', () {
    final spotify = spotifySearchUri(MusicPhase.hiit);
    expect(spotify.host, 'open.spotify.com');
    expect(spotify.path, '/search/workout%20150-170%20bpm');

    final youtube = youtubeMusicSearchUri(MusicPhase.rest);
    expect(youtube.host, 'music.youtube.com');
    expect(youtube.queryParameters['q'], 'workout 90-110 bpm');
  });
}
