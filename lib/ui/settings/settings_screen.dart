import 'package:flutter/material.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/ui/settings/settings_view_model.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const int _capStep = 10;

  Future<void> _pickReminderTime(BuildContext context) async {
    final viewModel = context.read<SettingsViewModel>();
    final current =
        viewModel.uiState.reminderTime ?? SettingsViewModel.defaultReminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      await viewModel.enableReminder(
        ReminderTime(hour: picked.hour, minute: picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final state = viewModel.uiState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _SectionTitle('Appearance'),
                for (final mode in AppearanceMode.values)
                  _AppearanceOption(
                    mode: mode,
                    isSelected: mode == state.appearanceMode,
                    onSelected: () => viewModel.setAppearanceMode(mode),
                  ),
                const Divider(),
                const _SectionTitle('Study'),
                ListTile(
                  title: const Text('Daily review limit'),
                  subtitle: Text(
                    'At most ${state.dailyReviewCap} reviews a day. '
                    'Anything beyond waits for tomorrow.',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Lower the limit',
                        onPressed: state.dailyReviewCap > _capStep
                            ? () => viewModel.setDailyReviewCap(
                                state.dailyReviewCap - _capStep,
                              )
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Raise the limit',
                        onPressed: () => viewModel.setDailyReviewCap(
                          state.dailyReviewCap + _capStep,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: const Text('Daily reminder'),
                  subtitle: Text(
                    state.isReminderPermissionDenied
                        ? 'Notifications are blocked for Ippo. Allow them in '
                              'your phone\'s settings, then turn this on again.'
                        : state.isReminderOn
                        ? 'Every day at ${state.reminderTime}'
                        : 'Off',
                    style: state.isReminderPermissionDenied
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                  value: state.isReminderOn,
                  onChanged: (on) => on
                      ? viewModel.enableReminder(
                          SettingsViewModel.defaultReminderTime,
                        )
                      : viewModel.disableReminder(),
                ),
                if (state.isReminderOn)
                  ListTile(
                    title: const Text('Reminder time'),
                    trailing: Text(
                      '${state.reminderTime}',
                      style: theme.textTheme.titleMedium,
                    ),
                    onTap: () => _pickReminderTime(context),
                  ),
                const Divider(),
                const _SectionTitle('Sound'),
                ListTile(
                  leading: Icon(
                    state.isJapaneseVoiceAvailable
                        ? Icons.record_voice_over_outlined
                        : Icons.voice_over_off_outlined,
                  ),
                  title: const Text('Japanese voice'),
                  subtitle: Text(
                    state.isJapaneseVoiceAvailable
                        ? 'Available. Kana are read aloud.'
                        : 'Not installed. Add Japanese in your phone\'s '
                              'text-to-speech settings to hear the kana. '
                              'Listening reviews are paused until then.',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open-source licences'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Ippo',
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// One choice of appearance; exactly one is selected.
class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.mode,
    required this.isSelected,
    required this.onSelected,
  });

  final AppearanceMode mode;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (title, detail) = switch (mode) {
      AppearanceMode.automatic => (
        'Automatic',
        'Daylight by day, Night when your phone is in dark mode',
      ),
      AppearanceMode.daylight => ('Daylight', 'Light and soft'),
      AppearanceMode.night => ('Night', 'Dark, easy on the eyes'),
      AppearanceMode.paper => ('Paper', 'Warm paper and ink'),
    };
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      child: ListTile(
        leading: Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text(detail),
        onTap: onSelected,
      ),
    );
  }
}
