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
import 'package:wger/core/snackbar.dart';
import 'package:wger/core/wide_screen_wrapper.dart';
import 'package:wger/features/coach/models/ai_provider_config.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/providers/coach_repository.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

/// Settings of the user's own AI ("bring your own key")
class MyAiScreen extends ConsumerWidget {
  const MyAiScreen({super.key});

  static const routeName = '/coach-my-ai';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final config = ref.watch(aiProviderSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(i18n.coachMyAi)),
      body: WidescreenWrapper(
        child: config.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(12),
            child: CoachErrorView(e, onRetry: () => ref.invalidate(aiProviderSettingsProvider)),
          ),
          data: (c) => _MyAiForm(c),
        ),
      ),
    );
  }
}

class _MyAiForm extends ConsumerStatefulWidget {
  final AiProviderConfig config;

  const _MyAiForm(this.config);

  @override
  ConsumerState<_MyAiForm> createState() => _MyAiFormState();
}

class _MyAiFormState extends ConsumerState<_MyAiForm> {
  late String _provider = aiProviders.contains(widget.config.provider)
      ? widget.config.provider
      : 'none';
  late final _model = TextEditingController(text: widget.config.model);
  final _key = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) {
        showSnackbar(context, AppLocalizations.of(context).coachSaved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final notifier = ref.read(aiProviderSettingsProvider.notifier);
    final config = ref.watch(aiProviderSettingsProvider).value ?? widget.config;
    final access = ref.watch(coachAccessProvider).value;
    final models = aiProviderModels[_provider] ?? const <String>[];

    String providerLabel(String p) => switch (p) {
      'openai' => 'OpenAI',
      'anthropic' => 'Anthropic',
      _ => i18n.coachMyAiProviderNone,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(i18n.coachMyAiHelp),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const ValueKey('my-ai-provider'),
          initialValue: _provider,
          decoration: InputDecoration(labelText: i18n.coachMyAiProvider),
          items: [
            for (final p in aiProviders) DropdownMenuItem(value: p, child: Text(providerLabel(p))),
          ],
          onChanged: (v) => setState(() => _provider = v ?? 'none'),
        ),
        if (_provider != 'none') ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('my-ai-model'),
            controller: _model,
            decoration: InputDecoration(labelText: i18n.coachMyAiModel),
          ),
          if (models.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final m in models)
                  ActionChip(label: Text(m), onPressed: () => setState(() => _model.text = m)),
              ],
            ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('my-ai-key'),
            controller: _key,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: i18n.coachMyAiApiKey,
              helperText: config.hasApiKey ? i18n.coachMyAiKeyHint : null,
            ),
          ),
          if (config.hasApiKey)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i18n.coachMyAiKeyStored(config.maskedKey)),
              trailing: TextButton(
                key: const ValueKey('my-ai-clear'),
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await notifier.clearKey();
                        _key.clear();
                      }),
                child: Text(i18n.coachMyAiClearKey),
              ),
            ),
        ],
        const SizedBox(height: 16),
        if (_error != null) CoachErrorView(_error!),
        FilledButton(
          key: const ValueKey('my-ai-save'),
          onPressed: _busy
              ? null
              : () => _run(
                  () => notifier
                      .save(
                        provider: _provider,
                        model: _provider == 'none' ? '' : _model.text.trim(),
                        // Only send the key when something was typed
                        apiKey: _key.text.isEmpty ? null : _key.text,
                      )
                      .then((_) => _key.clear()),
                ),
          child: Text(i18n.save),
        ),
        if (access != null) ...[
          const Divider(height: 32),
          SwitchListTile(
            key: const ValueKey('my-ai-memory'),
            contentPadding: EdgeInsets.zero,
            title: Text(i18n.coachMemoryEnable),
            value: access.memoryEnabled,
            onChanged: _busy
                ? null
                : (v) => _run(() async {
                    await ref.read(coachRepositoryProvider).setMemoryEnabled(access.id, v);
                    ref.invalidate(coachAccessProvider);
                  }),
          ),
        ],
      ],
    );
  }
}
