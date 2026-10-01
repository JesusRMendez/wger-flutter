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
import 'package:wger/core/widgets/confirm_delete_dialog.dart';
import 'package:wger/features/coach/models/coach_memory.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/coach_labels.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// What the coach remembers about the user. Only used when memory is enabled.
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  static const routeName = '/coach-memory';

  Future<void> _edit(BuildContext context, WidgetRef ref, CoachMemory? memory) async {
    final saved = await showDialog<CoachMemory>(
      context: context,
      builder: (_) => _MemoryDialog(memory: memory),
    );
    if (saved == null) {
      return;
    }
    final notifier = ref.read(coachMemoryListProvider.notifier);
    if (saved.id == null) {
      await notifier.addMemory(saved);
    } else {
      await notifier.editMemory(saved);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final access = ref.watch(coachAccessProvider);
    final memories = ref.watch(coachMemoryListProvider);
    final enabled = access.value?.memoryEnabled ?? true;

    return Scaffold(
      appBar: AppBar(title: Text(i18n.coachMemory)),
      floatingActionButton: enabled
          ? FloatingActionButton(
              key: const ValueKey('memory-add'),
              tooltip: i18n.coachMemoryAdd,
              onPressed: () => _edit(context, ref, null),
              child: const Icon(Icons.add),
            )
          : null,
      body: WidescreenWrapper(
        child: !enabled
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i18n.coachMemoryDisabled),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pushNamed(MyAiScreen.routeName),
                      child: Text(i18n.coachMyAi),
                    ),
                  ],
                ),
              )
            : memories.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: CoachErrorView(e, onRetry: () => ref.invalidate(coachMemoryListProvider)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(i18n.coachMemoryEmpty, textAlign: TextAlign.center),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final m = list[index];
                      return Card(
                        child: ListTile(
                          title: Text(m.text),
                          subtitle: Text(
                            '${i18n.memoryCategoryLabel(m.category)} · '
                            '${i18n.memorySourceLabel(m.source)}',
                          ),
                          onTap: () => _edit(context, ref, m),
                          trailing: IconButton(
                            tooltip: i18n.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => showConfirmDeleteDialog(
                              context,
                              itemName: m.text,
                              onConfirm: () =>
                                  ref.read(coachMemoryListProvider.notifier).deleteMemory(m.id!),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _MemoryDialog extends StatefulWidget {
  final CoachMemory? memory;

  const _MemoryDialog({this.memory});

  @override
  State<_MemoryDialog> createState() => _MemoryDialogState();
}

class _MemoryDialogState extends State<_MemoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.memory?.text ?? '');
  late String _category = widget.memory?.category ?? 'preference';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.memory == null ? i18n.coachMemoryAdd : i18n.coachMemoryEdit),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('memory-text'),
              controller: _text,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: i18n.coachMemoryText),
              validator: (v) => (v ?? '').trim().isEmpty ? i18n.enterValue : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(labelText: i18n.category),
              items: [
                for (final c in memoryCategories)
                  DropdownMenuItem(value: c, child: Text(i18n.memoryCategoryLabel(c))),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('memory-save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                CoachMemory(
                  id: widget.memory?.id,
                  text: _text.text.trim(),
                  category: _category,
                ),
              );
            }
          },
          child: Text(i18n.save),
        ),
      ],
    );
  }
}
