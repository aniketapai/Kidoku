import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../profile/presentation/widgets/profile_section_card.dart';
import '../application/notification_providers.dart';

/// Reached from Settings — toggles for every notification type the app
/// sends (study reminder, review-due nudge, motivational messages) plus
/// the master switch and the study reminder's time-of-day picker.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Notifications')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text("Couldn't load notification settings.")),
        data: (settings) => _NotificationSettingsBody(settings: settings),
      ),
    );
  }
}

class _NotificationSettingsBody extends ConsumerStatefulWidget {
  const _NotificationSettingsBody({required this.settings});

  final NotificationSettingsData settings;

  @override
  ConsumerState<_NotificationSettingsBody> createState() =>
      _NotificationSettingsBodyState();
}

class _NotificationSettingsBodyState
    extends ConsumerState<_NotificationSettingsBody> {
  bool _checkingPermission = true;
  bool _osPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await ref
        .read(notificationServiceProvider)
        .hasPermission();
    if (mounted) {
      setState(() {
        _osPermissionDenied = !hasPermission;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _setEnabled(bool value) async {
    final granted = await ref
        .read(notificationSettingsActionsProvider)
        .setNotificationsEnabled(value);
    if (!mounted) return;
    if (value && !granted) {
      setState(() => _osPermissionDenied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are turned off for Kidoku in system settings.',
          ),
        ),
      );
    } else {
      setState(() => _osPermissionDenied = false);
    }
  }

  Future<void> _pickStudyReminderTime() async {
    final settings = widget.settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.studyReminderHour,
        minute: settings.studyReminderMinute,
      ),
    );
    if (picked == null) return;
    await ref
        .read(notificationSettingsActionsProvider)
        .setStudyReminderTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = widget.settings;
    final actions = ref.read(notificationSettingsActionsProvider);
    final enabled = settings.notificationsEnabled;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (!_checkingPermission && _osPermissionDenied) ...[
          _PermissionWarningCard(
            onOpenSettings: () =>
                ref.read(notificationServiceProvider).openAppSettings(),
          ),
          const SizedBox(height: 16),
        ],
        ProfileSectionCard(
          title: 'All notifications',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable notifications'),
            subtitle: const Text(
              'Turns every reminder below on or off at once.',
            ),
            value: enabled,
            onChanged: _setEnabled,
          ),
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: enabled ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !enabled,
            child: Column(
              children: [
                ProfileSectionCard(
                  title: 'Study reminder',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Daily reminder to study'),
                        value: settings.studyReminderEnabled,
                        onChanged: (v) => actions.setStudyReminderEnabled(v),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Time'),
                        trailing: Text(
                          TimeOfDay(
                            hour: settings.studyReminderHour,
                            minute: settings.studyReminderMinute,
                          ).format(context),
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        onTap: settings.studyReminderEnabled
                            ? _pickStudyReminderTime
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ProfileSectionCard(
                  title: 'Review due',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notify when reviews are due'),
                    subtitle: const Text(
                      "Sent the moment your next batch of deck cards falls due.",
                    ),
                    value: settings.reviewDueRemindersEnabled,
                    onChanged: (v) => actions.setReviewDueRemindersEnabled(v),
                  ),
                ),
                const SizedBox(height: 16),
                ProfileSectionCard(
                  title: 'Motivation',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Motivational messages'),
                    subtitle: const Text(
                      'A rotating weekly nudge to keep your streak alive.',
                    ),
                    value: settings.motivationalRemindersEnabled,
                    onChanged: (v) =>
                        actions.setMotivationalRemindersEnabled(v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionWarningCard extends StatelessWidget {
  const _PermissionWarningCard({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_off_rounded,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notifications are disabled for Kidoku in system settings.',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onOpenSettings,
              child: const Text('Open system settings'),
            ),
          ),
        ],
      ),
    );
  }
}
