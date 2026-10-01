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
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/core/widgets/async_value_widget.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/features/locations/models/training_location.dart';
import 'package:wger/features/locations/providers/locations_repository.dart';
import 'package:wger/features/locations/screens/location_edit_screen.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

/// Lists the training locations of the user
class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  static const routeName = '/training-locations';

  Future<void> _open(BuildContext context, WidgetRef ref, [TrainingLocation? location]) async {
    await Navigator.of(context).pushNamed(LocationEditScreen.routeName, arguments: location);
    ref.invalidate(trainingLocationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final locations = ref.watch(trainingLocationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(i18n.locationsTitle)),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add-location-button'),
        tooltip: i18n.locationsAdd,
        onPressed: () => _open(context, ref),
        child: const Icon(Icons.add),
      ),
      body: WidescreenWrapper(
        child: AsyncValueWidget<List<TrainingLocation>>(
          value: locations,
          loggerName: 'LocationsScreen',
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(i18n.locationsEmpty, textAlign: TextAlign.center),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              children: [
                for (final location in items)
                  AtlasCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      key: ValueKey('location-${location.id}'),
                      contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                      leading: IconBadge(
                        location.isDefault ? Icons.star : Icons.place_outlined,
                        color: location.isDefault ? context.atlas.warn : null,
                        background: location.isDefault ? context.atlas.warnSoft : null,
                      ),
                      title: Text(location.name),
                      subtitle: Text(
                        [
                          i18n.locationsEquipmentCount(location.equipmentIds.length),
                          if (location.availableMinutes != null)
                            i18n.locationsMinutesValue(location.availableMinutes!),
                          if (location.isDefault) i18n.locationsDefault,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: i18n.delete,
                        onPressed: () => showConfirmDeleteDialog(
                          context,
                          itemName: location.name,
                          onConfirm: () async {
                            await ref
                                .read(locationsRepositoryProvider)
                                .deleteLocation(location.id!);
                            ref.invalidate(trainingLocationsProvider);
                          },
                        ),
                      ),
                      onTap: () => _open(context, ref, location),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
