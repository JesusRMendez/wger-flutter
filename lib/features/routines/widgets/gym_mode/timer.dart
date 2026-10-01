/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2025 wger Team
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
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/countdown_alert.dart';
import 'package:wger/features/routines/widgets/gym_mode/navigation.dart';
import 'package:wger/features/routines/widgets/gym_mode/next_exercise_preview.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

class TimerWidget extends StatefulWidget {
  final PageController _controller;

  const TimerWidget(this._controller, {super.key});

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late DateTime _startTime;
  final _maxSeconds = 600;
  late Timer _uiTimer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // ignore: no-empty-block, avoid-empty-setstate
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    final displaySeconds = elapsed > _maxSeconds ? _maxSeconds : elapsed;
    final displayTime = DateTime(2000, 1, 1, 0, 0, 0).add(Duration(seconds: displaySeconds));

    return Column(
      children: [
        NavigationHeader(
          AppLocalizations.of(context).pause,
          widget._controller,
        ),
        Expanded(
          child: Center(
            child: _RestRing(
              time: DateFormat('m:ss').format(displayTime),
              progress: displaySeconds / _maxSeconds,
              label: AppLocalizations.of(context).pause,
            ),
          ),
        ),
        NavigationFooter(widget._controller),
      ],
    );
  }
}

class TimerCountdownWidget extends ConsumerStatefulWidget {
  final PageController _controller;
  final int _seconds;

  /// The slot (timer) page this countdown is shown on. It is needed to show
  /// what comes next and to know whether the page is still the current one
  /// when the countdown ends.
  final String? slotUuid;

  const TimerCountdownWidget(
    this._controller,
    this._seconds, {
    this.slotUuid,
    super.key,
  });

  @override
  _TimerCountdownWidgetState createState() => _TimerCountdownWidgetState();
}

class _TimerCountdownWidgetState extends ConsumerState<TimerCountdownWidget> {
  /// How often the remaining time is checked. This is finer than a second so
  /// that the alerts are not delayed noticeably by an unlucky tick.
  static const _checkInterval = Duration(milliseconds: 250);

  /// Pause between the two haptic pulses of the 20 second warning
  static const _doubleHapticDelay = Duration(milliseconds: 150);

  late DateTime _endTime;
  late int _remainingSeconds;

  /// What the ring drains from: the planned rest, longer if the user added time
  late int _totalSeconds;
  Timer? _uiTimer;
  Timer? _secondHapticTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _endTime = clock.now().add(Duration(seconds: widget._seconds));
    _remainingSeconds = widget._seconds;
    _totalSeconds = widget._seconds;

    _uiTimer = Timer.periodic(_checkInterval, (_) => _onTick());
  }

  @override
  void dispose() {
    // Cancelling here also guarantees that nothing (alert, auto-advance) can
    // happen after the user left the page and the widget is gone
    _uiTimer?.cancel();
    _secondHapticTimer?.cancel();
    super.dispose();
  }

  /// Remaining time, rounded up so that zero is only shown when it is over
  int _calculateRemainingSeconds() {
    final milliseconds = _endTime.difference(clock.now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  void _onTick() {
    if (!mounted) {
      return;
    }

    final remaining = _calculateRemainingSeconds();
    // A countdown that starts at zero still has to finish once
    if (remaining == _remainingSeconds && (remaining != 0 || _finished)) {
      return;
    }
    setState(() => _remainingSeconds = remaining);

    final gymState = ref.read(gymStateProvider);
    final alert = countdownAlertFor(
      remainingSeconds: remaining,
      totalSeconds: _totalSeconds,
      alertAt20s: gymState.alertAt20s,
      alertLast5s: gymState.alertLast5s,
      alertAtEnd: gymState.alertOnCountdownEnd,
    );
    _play(alert);

    // The countdown is over: stop checking, it must only end once
    if (remaining == 0) {
      _finished = true;
      _uiTimer?.cancel();
      _advanceToNextPage();
    }
  }

  void _play(CountdownAlert alert) {
    switch (alert) {
      case CountdownAlert.none:
        break;
      case CountdownAlert.warning:
        HapticFeedback.mediumImpact();
        _secondHapticTimer?.cancel();
        _secondHapticTimer = Timer(_doubleHapticDelay, HapticFeedback.mediumImpact);
        SystemSound.play(SystemSoundType.alert);
      case CountdownAlert.tick:
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
      case CountdownAlert.end:
        HapticFeedback.mediumImpact();

        // Note that this only works on desktop platforms
        SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Goes to the next page, if wanted and if the user did not navigate on
  /// their own in the meantime
  void _advanceToNextPage() {
    final gymState = ref.read(gymStateProvider);
    if (!gymState.autoAdvanceAfterRest || widget.slotUuid == null) {
      return;
    }

    // Only if this page is still the one being shown
    final slotPage = gymState.getSlotPageByUUID(widget.slotUuid!);
    if (slotPage == null || gymState.currentPage != slotPage.pageIndex) {
      return;
    }

    // Not while a dialog (e.g. the workout menu) is open on top of the page
    if (ModalRoute.of(context)?.isCurrent == false) {
      return;
    }

    // Not while the user is dragging the page or an animation is running
    final controller = widget._controller;
    if (!controller.hasClients || controller.position.isScrollingNotifier.value) {
      return;
    }

    controller.nextPage(
      duration: DEFAULT_ANIMATION_DURATION,
      curve: DEFAULT_ANIMATION_CURVE,
    );
  }

  /// Shortens or extends the rest, never below one second: ending it is what
  /// skipping is for
  void _adjust(int seconds) {
    if (_finished) {
      return;
    }
    final remaining = _calculateRemainingSeconds() + seconds;
    final next = remaining < 1 ? 1 : remaining;
    setState(() {
      _endTime = clock.now().add(Duration(seconds: next));
      _remainingSeconds = next;
      if (next > _totalSeconds) {
        _totalSeconds = next;
      }
    });
  }

  /// Ends the rest and goes to what follows
  void _skip() {
    _finished = true;
    _uiTimer?.cancel();
    widget._controller.nextPage(
      duration: DEFAULT_ANIMATION_DURATION,
      curve: DEFAULT_ANIMATION_CURVE,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final displayTime = DateTime(2000, 1, 1, 0, 0, 0).add(Duration(seconds: _remainingSeconds));

    // The exercise that was just done, the rest belongs to it
    final slotPage = widget.slotUuid == null
        ? null
        : ref.watch(gymStateProvider).getSlotPageByUUID(widget.slotUuid!);
    final exercise = slotPage?.setConfigData?.exercise
        .getTranslation(Localizations.localeOf(context).languageCode)
        .name;

    return Column(
      children: [
        NavigationHeader(
          i18n.pause,
          widget._controller,
          showSettings: true,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (exercise != null) ...[
                SectionEyebrow(i18n.gymRestTitle(exercise), key: const ValueKey('rest-eyebrow')),
                const SizedBox(height: 16),
              ],
              Flexible(
                child: _RestRing(
                  time: DateFormat('m:ss').format(displayTime),
                  progress: _totalSeconds == 0 ? 0 : _remainingSeconds / _totalSeconds,
                  label: i18n.pause,
                  urgent: _remainingSeconds > 0 && _remainingSeconds <= 5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    key: const ValueKey('rest-less'),
                    onPressed: () => _adjust(-15),
                    child: Text(i18n.gymRestLess),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    key: const ValueKey('rest-more'),
                    onPressed: () => _adjust(15),
                    child: Text(i18n.gymRestMore),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: const ValueKey('rest-skip'),
                    onPressed: _skip,
                    child: Text(i18n.gymRestSkip),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.slotUuid != null) NextExercisePreview(widget.slotUuid!),
        NavigationFooter(widget._controller),
      ],
    );
  }
}

/// The rest timer: a big ring that drains with the time and the time in the
/// middle. The last seconds turn it to the accent color.
class _RestRing extends StatelessWidget {
  const _RestRing({
    required this.time,
    required this.progress,
    required this.label,
    this.urgent = false,
  });

  final String time;
  final double progress;
  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.biggest.shortestSide - 32).clamp(120.0, 280.0);

        return ProgressRing(
          size: size,
          strokeWidth: 14,
          value: progress,
          color: urgent ? atlas.accent : theme.colorScheme.primary,
          // The ring follows the clock, it does not ease behind it
          duration: const Duration(milliseconds: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MonoText(time, size: size * 0.26, color: theme.colorScheme.onSurface),
              const SizedBox(height: 4),
              SectionEyebrow(label),
            ],
          ),
        );
      },
    );
  }
}
