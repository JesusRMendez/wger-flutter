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
import 'package:wger/features/coach/models/chat_message.dart';
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';
import 'package:wger/features/coach/screens/meal_plan_screen.dart';
import 'package:wger/features/coach/screens/memory_screen.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';
import 'package:wger/features/coach/screens/workout_plan_screen.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/mode_badge.dart';
import 'package:wger/l10n/generated/app_localizations.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  static const routeName = '/coach';

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    _controller.clear();
    ref.read(coachChatProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final mode = ref.watch(coachModeProvider).value ?? CoachMode.none;
    final access = ref.watch(coachAccessProvider).value;
    final chat = ref.watch(coachChatProvider);
    final nav = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.coach),
        actions: [
          if (access?.memoryEnabled ?? false)
            IconButton(
              tooltip: i18n.coachMemory,
              icon: const Icon(Icons.psychology_outlined),
              onPressed: () => nav.pushNamed(MemoryScreen.routeName),
            ),
          IconButton(
            tooltip: i18n.coachMyAi,
            icon: const Icon(Icons.tune),
            onPressed: () => nav.pushNamed(MyAiScreen.routeName),
          ),
        ],
      ),
      body: WidescreenWrapper(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Align(alignment: Alignment.centerLeft, child: CoachModeBadge()),
                  if (mode == CoachMode.none) _Unavailable(i18n: i18n),
                  const CoachUsageCard(),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.fitness_center, size: 18),
                        label: Text(i18n.coachWorkoutPlan),
                        onPressed: () => nav.pushNamed(WorkoutPlanScreen.routeName),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.restaurant, size: 18),
                        label: Text(i18n.coachMealPlan),
                        onPressed: () => nav.pushNamed(MealPlanScreen.routeName),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.flag_outlined, size: 18),
                        label: Text(i18n.coachGoalsAndIndicators),
                        onPressed: () => nav.pushNamed(GoalsScreen.routeName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (chat.messages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(i18n.coachChatEmpty, textAlign: TextAlign.center),
                    ),
                  for (final m in chat.messages) _Bubble(m),
                  if (chat.sending)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (chat.error != null) CoachErrorView(chat.error!),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    if (chat.messages.isNotEmpty)
                      IconButton(
                        tooltip: i18n.coachClearChat,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        onPressed: () => ref.read(coachChatProvider.notifier).clear(),
                      ),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('coach-chat-input'),
                        controller: _controller,
                        enabled: mode != CoachMode.none,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: i18n.coachChatHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('coach-chat-send'),
                      tooltip: i18n.coachSend,
                      icon: const Icon(Icons.send),
                      onPressed: mode == CoachMode.none || chat.sending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final AppLocalizations i18n;

  const _Unavailable({required this.i18n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i18n.coachUnavailable),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(MyAiScreen.routeName),
              child: Text(i18n.coachSetUpMyAi),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;

  const _Bubble(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        decoration: BoxDecoration(
          color: message.isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(message.content),
      ),
    );
  }
}
