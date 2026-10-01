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
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/atlas_life.dart';
import 'package:wger/features/coach/models/chat_message.dart';
import 'package:wger/features/coach/models/coach_access.dart';
import 'package:wger/features/coach/providers/coach_providers.dart';
import 'package:wger/features/coach/screens/follow_up_screen.dart';
import 'package:wger/features/coach/screens/goals_screen.dart';
import 'package:wger/features/coach/screens/meal_plan_screen.dart';
import 'package:wger/features/coach/screens/memory_screen.dart';
import 'package:wger/features/coach/screens/my_ai_screen.dart';
import 'package:wger/features/coach/screens/workout_plan_screen.dart';
import 'package:wger/features/coach/widgets/coach_error_view.dart';
import 'package:wger/features/coach/widgets/mode_badge.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  static const routeName = '/coach';

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
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
    // Keep the newest message (or the error) in view
    ref.listen(coachChatProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: AtlasMotion.of(context),
            curve: AtlasMotion.curve,
          );
        }
      });
    });
    final nav = Navigator.of(context);

    return Scaffold(
      body: WidescreenWrapper(
        child: Column(
          children: [
            AtlasHeader(
              title: i18n.coach,
              subtitle: i18n.coachSubtitle,
              actions: [
                if (access?.memoryEnabled ?? false)
                  RoundIconButton(
                    tooltip: i18n.coachMemory,
                    icon: Icons.psychology_outlined,
                    onPressed: () => nav.pushNamed(MemoryScreen.routeName),
                  ),
                RoundIconButton(
                  tooltip: i18n.coachMyAi,
                  icon: Icons.tune,
                  onPressed: () => nav.pushNamed(MyAiScreen.routeName),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  const Align(alignment: Alignment.centerLeft, child: CoachModeBadge()),
                  const SizedBox(height: 10),
                  if (mode == CoachMode.none) ...[
                    _Unavailable(i18n: i18n),
                    const SizedBox(height: 10),
                  ],
                  const CoachUsageCard(),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.fitness_center,
                          label: i18n.coachWorkoutPlan,
                          hint: i18n.coachWorkoutPlanHint,
                          color: context.atlas.ok,
                          onTap: () => nav.pushNamed(WorkoutPlanScreen.routeName),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.restaurant,
                          label: i18n.coachMealPlan,
                          hint: i18n.coachMealPlanHint,
                          color: context.atlas.carbs,
                          onTap: () => nav.pushNamed(MealPlanScreen.routeName),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.flag_outlined,
                          label: i18n.coachGoalsAndIndicators,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => nav.pushNamed(GoalsScreen.routeName),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.insights,
                          label: i18n.coachFollowUp,
                          color: context.atlas.fat,
                          onTap: () => nav.pushNamed(FollowUpScreen.routeName),
                        ),
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
                  if (chat.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: context.atlas.ink3),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              i18n.coachDisclaimer,
                              key: const ValueKey('coach-disclaimer'),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: context.atlas.ink3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (mode != CoachMode.none)
              SizedBox(
                height: 44,
                child: ListView(
                  key: const ValueKey('coach-suggestions'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final text in [
                      i18n.coachSuggestShortWeek,
                      i18n.coachSuggestProtein,
                      i18n.coachSuggestDeload,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PillChip(
                          text,
                          height: 36,
                          fontSize: 13,
                          onTap: chat.sending
                              ? null
                              : () => ref.read(coachChatProvider.notifier).send(text),
                        ),
                      ),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AtlasRadius.pill),
                            borderSide: BorderSide(color: context.atlas.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AtlasRadius.pill),
                            borderSide: BorderSide(color: context.atlas.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AtlasRadius.pill),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const ValueKey('coach-chat-send'),
                      tooltip: i18n.coachSend,
                      style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
                      icon: const Icon(Icons.arrow_upward),
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
    return AtlasCard(
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
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? hint;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final badge = IconBadge(
      icon,
      size: 40,
      color: color,
      background: color.withValues(alpha: 0.14),
    );
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badge,
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.titleSmall),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: context.atlas.ink3)),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;

  const _Bubble(this.message);

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        decoration: BoxDecoration(
          color: user ? atlas.hero : atlas.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 4),
            bottomRight: Radius.circular(user ? 4 : 18),
          ),
          border: user ? null : Border.all(color: atlas.line),
        ),
        child: SelectableText(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(color: user ? atlas.onHero : null),
        ),
      ),
    );
  }
}
