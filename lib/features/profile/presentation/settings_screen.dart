import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/database/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/date_format.dart';
import '../../backup/data/backup_repository.dart';
import '../../reader/data/user_word_repository.dart';
import 'widgets/profile_section_card.dart';

/// Reached from the settings button on ProfileScreen. Everything shown here
/// is real (account info, live app version, sign out, account deletion,
/// notifications) — no placeholder toggles for features the app doesn't
/// have yet (theme).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// Minimum gap enforced between manual backups — see [_BackupSection].
const _kBackupCooldown = Duration(days: 1);

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;
  bool _deletingAccount = false;
  bool _backingUp = false;
  bool _loadingBackupStatus = true;
  DateTime? _lastBackupAt;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  Future<void> _loadBackupStatus() async {
    try {
      final lastBackupAt = await ref
          .read(backupRepositoryProvider)
          .lastBackupAt();
      if (mounted) {
        setState(() {
          _lastBackupAt = lastBackupAt;
          _loadingBackupStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBackupStatus = false);
    }
  }

  bool get _canBackUpNow =>
      _lastBackupAt == null ||
      DateTime.now().difference(_lastBackupAt!) >= _kBackupCooldown;

  Future<void> _backUpNow() async {
    setState(() => _backingUp = true);
    try {
      await ref.read(backupRepositoryProvider).performBackup();
      if (mounted) {
        setState(() {
          _lastBackupAt = DateTime.now();
          _backingUp = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup complete.')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _backingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't back up — check your connection and try again.",
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          "You'll need to sign in again to access your progress.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      // No manual navigation needed — the router's auth redirect reacts to
      // the resulting authStateChanges event and sends us to sign-in.
    } catch (_) {
      if (mounted) {
        setState(() => _signingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't sign out — check your connection and try again.",
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          "This permanently deletes your account and all synced progress. "
          "You'll be asked to sign in again to confirm. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      // Firebase requires a recent sign-in for account deletion — this
      // re-runs the Google sign-in flow, which also doubles as a second
      // confirmation step for such a destructive action.
      await authRepository.reauthenticateWithGoogle();
      await ref.read(userWordRepositoryProvider).deleteAllRemoteWords();
      await ref.read(appDatabaseProvider).clearUserData();
      await authRepository.deleteAccount();
      // No manual navigation needed — the router's auth redirect reacts to
      // the resulting authStateChanges event and sends us to sign-in.
    } on GoogleSignInException catch (e) {
      if (mounted) setState(() => _deletingAccount = false);
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't verify your account — please try again."),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't delete account — check your connection and try again.",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          if (user != null) ...[
            ProfileSectionCard(
              title: 'Account',
              child: _AccountRow(user: user),
            ),
            const SizedBox(height: 16),
          ],
          ProfileSectionCard(
            title: 'Notifications',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.notifications_rounded,
                color: colorScheme.primary,
              ),
              title: const Text('Study & review reminders'),
              subtitle: const Text(
                'Reminders, review-due nudges, and motivational messages.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.notificationSettings),
            ),
          ),
          const SizedBox(height: 16),
          ProfileSectionCard(
            title: 'Backup',
            child: _BackupSection(
              lastBackupAt: _lastBackupAt,
              loading: _loadingBackupStatus,
              backingUp: _backingUp,
              canBackUpNow: _canBackUpNow,
              onBackUpNow: _backUpNow,
            ),
          ),
          const SizedBox(height: 16),
          const ProfileSectionCard(title: 'About', child: _AboutSection()),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signingOut ? null : _confirmSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(
                  color: colorScheme.error.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _signingOut
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: _deletingAccount ? null : _confirmDeleteAccount,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error.withValues(alpha: 0.8),
              ),
              icon: _deletingAccount
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final photoUrl = user.photoURL;

    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(Icons.person_rounded, size: 26, color: colorScheme.primary)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Signed in',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (user.email != null) ...[
                const SizedBox(height: 2),
                Text(
                  user.email!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Version', style: textTheme.bodyMedium),
            Text(
              '1.0.0',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: colorScheme.surfaceContainerHighest, height: 1),
        const SizedBox(height: 14),
        Text(
          'Dictionary data from JMdict/EDICT (Electronic Dictionary Research '
          'and Development Group), used under CC BY-SA 4.0.',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Manual, once-a-day cloud backup — see [BackupRepository]. No automatic
/// backup exists by design; everything else stays local-only until the user
/// explicitly taps this button.
class _BackupSection extends StatelessWidget {
  const _BackupSection({
    required this.lastBackupAt,
    required this.loading,
    required this.backingUp,
    required this.canBackUpNow,
    required this.onBackUpNow,
  });

  final DateTime? lastBackupAt;
  final bool loading;
  final bool backingUp;
  final bool canBackUpNow;
  final VoidCallback onBackUpNow;

  String _statusText() {
    if (loading) return 'Checking backup status…';
    if (lastBackupAt == null) return 'Never backed up';
    return 'Last backed up ${formatDateTime(lastBackupAt!)}';
  }

  String? _cooldownText() {
    if (canBackUpNow || lastBackupAt == null) return null;
    final remaining =
        _kBackupCooldown - DateTime.now().difference(lastBackupAt!);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return 'You can back up again in ${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cooldownText = _cooldownText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saves your words, review progress, achievements, and reading '
          'history to the cloud so you can restore them after signing in on '
          'a new device. Only happens when you tap the button below.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Text(_statusText(), style: textTheme.bodyMedium),
        if (cooldownText != null) ...[
          const SizedBox(height: 2),
          Text(
            cooldownText,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (loading || backingUp || !canBackUpNow)
                ? null
                : onBackUpNow,
            icon: backingUp
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_rounded),
            label: const Text('Back up now'),
          ),
        ),
      ],
    );
  }
}
