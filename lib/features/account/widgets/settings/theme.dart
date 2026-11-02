import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wger/core/app_settings_notifier.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/dynamic_color.dart';

class SettingsTheme extends ConsumerWidget {
  const SettingsTheme({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context);
    final currentMode = ref.watch(
      appSettingsProvider.select((s) => s.value?.themeMode ?? ThemeMode.system),
    );
    final useDynamicColor = ref.watch(
      appSettingsProvider.select((s) => s.value?.useDynamicColor ?? USE_DYNAMIC_COLOR_DEFAULT),
    );
    // Hidden while the probe is still running and where it comes back negative:
    // the toggle does nothing on a platform without a dynamic palette.
    final showDynamicColor = ref.watch(dynamicColorAvailableProvider).value ?? false;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(i18n.themeMode, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  key: const ValueKey('themeModeSegmented'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(i18n.themeSystemShort)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(i18n.themeDarkShort)),
                    ButtonSegment(value: ThemeMode.light, label: Text(i18n.themeLightShort)),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (selection) =>
                      ref.read(appSettingsProvider.notifier).setThemeMode(selection.first),
                ),
              ),
            ],
          ),
        ),
        if (showDynamicColor)
          SwitchListTile(
            key: const ValueKey('useDynamicColorSwitch'),
            title: Text(i18n.useDynamicColor),
            value: useDynamicColor,
            onChanged: (bool value) {
              ref.read(appSettingsProvider.notifier).setUseDynamicColor(value);
            },
          ),
      ],
    );
  }
}
