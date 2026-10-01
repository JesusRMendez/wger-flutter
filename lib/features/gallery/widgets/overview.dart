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
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/form_screen.dart';
import 'package:wger/core/formatting/formatting.dart';
import 'package:wger/core/platform.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/text_prompt.dart';
import 'package:wger/core/widgets/wger_image.dart';
import 'package:wger/features/gallery/models/image.dart';
import 'package:wger/features/gallery/providers/gallery_notifier.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

import 'forms.dart';

class Gallery extends ConsumerStatefulWidget {
  const Gallery();

  @override
  ConsumerState<Gallery> createState() => _GalleryState();
}

class _GalleryState extends ConsumerState<Gallery> {
  /// 0: before / after slider, 1: all photos
  int _tab = 0;

  /// Photos picked for the slider; the oldest and the newest by default
  int? _beforeId;
  int? _afterId;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final images = [...(ref.watch(galleryProvider).value ?? const <GalleryImage>[])]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (images.isEmpty) {
      return const TextPrompt();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, label: Text(i18n.galleryCompare)),
                ButtonSegment(value: 1, label: Text(i18n.galleryAllCount(images.length))),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
        ),
        Expanded(child: _tab == 0 ? _compare(context, images) : _grid(context, images)),
      ],
    );
  }

  Widget _grid(BuildContext context, List<GalleryImage> images) {
    final newestFirst = images.reversed.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: newestFirst.length,
        itemBuilder: (context, index) {
          final currentImage = newestFirst[index];

          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                builder: (context) => ImageDetail(image: currentImage),
                context: context,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AtlasRadius.card),
              child: Stack(
                children: [
                  WgerImage(
                    key: Key('image-${currentImage.id!}'),
                    mediaPath: currentImage.imagePath,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _DateChip(currentImage.date),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _compare(BuildContext context, List<GalleryImage> images) {
    final i18n = AppLocalizations.of(context);
    if (images.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          i18n.galleryNeedTwo,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.atlas.ink3),
        ),
      );
    }
    final before = images.firstWhere((i) => i.id == _beforeId, orElse: () => images.first);
    final after = images.firstWhere((i) => i.id == _afterId, orElse: () => images.last);

    Future<GalleryImage?> pick() => showDialog<GalleryImage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(i18n.galleryPickPhoto),
        children: [
          for (final i in images.reversed)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(i),
              child: Text(
                [
                  localizedDate(context).format(i.date),
                  if (i.description.isNotEmpty) i.description,
                ].join(' · '),
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: 0.78,
          child: BeforeAfterSlider(
            before: before,
            after: after,
            onPickBefore: () async {
              final i = await pick();
              if (i != null) {
                setState(() => _beforeId = i.id);
              }
            },
            onPickAfter: () async {
              final i = await pick();
              if (i != null) {
                setState(() => _afterId = i.id);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: atlas.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
        border: Border.all(color: atlas.line),
      ),
      child: MonoText(
        localizedDate(context).format(date),
        size: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Two photos on top of each other with a draggable divider: [before] on the
/// left of it, [after] on the right.
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.before,
    required this.after,
    this.onPickBefore,
    this.onPickAfter,
  });

  final GalleryImage before;
  final GalleryImage after;
  final VoidCallback? onPickBefore;
  final VoidCallback? onPickAfter;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _pos = 0.5;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;

    Widget photo(GalleryImage i) => WgerImage(
      mediaPath: i.imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    Widget chip(GalleryImage i, VoidCallback? onTap) => Pressable(
      onTap: onTap,
      scale: 0.95,
      borderRadius: BorderRadius.circular(AtlasRadius.pill),
      child: _DateChip(i.date),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return GestureDetector(
          key: const ValueKey('gallery-compare'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) =>
              setState(() => _pos = (_pos + d.delta.dx / w).clamp(0.0, 1.0)),
          onTapDown: (d) => setState(() => _pos = (d.localPosition.dx / w).clamp(0.0, 1.0)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: atlas.card,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  photo(widget.after),
                  ClipRect(
                    clipper: _LeftClipper(_pos),
                    child: photo(widget.before),
                  ),
                  Positioned(
                    left: w * _pos - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.white),
                  ),
                  Positioned(
                    left: w * _pos - 22,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(blurRadius: 12, color: Color(0x55000000))],
                        ),
                        child: const Icon(Icons.swap_horiz, color: Colors.black87),
                      ),
                    ),
                  ),
                  Positioned(left: 14, top: 14, child: chip(widget.before, widget.onPickBefore)),
                  Positioned(right: 14, top: 14, child: chip(widget.after, widget.onPickAfter)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.fraction != fraction;
}

class ImageDetail extends ConsumerWidget {
  const ImageDetail({
    super.key,
    required this.image,
  });

  final GalleryImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: Key('image-${image.id!}-detail'),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            localizedDate(context).format(image.date),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Expanded(
            child: WgerImage(
              mediaPath: image.imagePath,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(image.description),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  ref.read(galleryProvider.notifier).deleteImage(image);
                  Navigator.of(context).pop();
                },
              ),
              if (!isDesktop)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      FormScreen.routeName,
                      arguments: FormScreenArguments(
                        AppLocalizations.of(context).edit,
                        ImageForm(image),
                        hasListView: true,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
