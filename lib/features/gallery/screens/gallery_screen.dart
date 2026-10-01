/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
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
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/network/network_provider.dart';
import 'package:wger/core/platform.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/gallery/widgets/forms.dart';
import 'package:wger/features/gallery/widgets/overview.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class GalleryScreen extends ConsumerWidget {
  static const routeName = '/gallery';

  const GalleryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Adding an image is a binary REST upload, so it needs connectivity.
    final isOnline = ref.watch(networkStatusProvider);

    final i18n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: WidescreenWrapper(
          child: Column(
            children: [
              AtlasHeader(
                title: i18n.galleryTitle,
                centered: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                actions: [
                  if (!isDesktop)
                    RoundIconButton(
                      icon: Icons.photo_camera_outlined,
                      tooltip: i18n.addImage,
                      // Adding an image is a binary REST upload, so it needs connectivity
                      onPressed: isOnline
                          ? () {
                              Navigator.pushNamed(
                                context,
                                FormScreen.routeName,
                                arguments: FormScreenArguments(
                                  i18n.addImage,
                                  ImageForm(),
                                  hasListView: true,
                                ),
                              );
                            }
                          : null,
                    )
                  else
                    const SizedBox(width: 44),
                ],
              ),
              const Expanded(child: Gallery()),
            ],
          ),
        ),
      ),
    );
  }
}
