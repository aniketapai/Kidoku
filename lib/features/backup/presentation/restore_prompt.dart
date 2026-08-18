import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/providers.dart';
import '../../../core/utils/date_format.dart';
import '../data/backup_repository.dart';

const _kRestoreOfferedKey = 'backup_restore_offered_v1';

/// Offers to restore a cloud backup once per local install, the moment the
/// signed-in app is entered — whether that's from an explicit "Sign in with
/// Google" tap or an auth session the platform silently restored on its own.
/// Firebase Auth's own session persistence (iOS Keychain, Android's default
/// Auto Backup) commonly survives a plain app delete+reinstall even though
/// this app's local database does not, so a user can land right back in the
/// signed-in shell with an empty database and no local progress — [AppShell]
/// calling this on entry is what catches that case; [SignInScreen]'s button
/// handler alone would miss it entirely.
///
/// Only ever asks once per device (tracked via [SharedPreferences], not the
/// local database — the whole point is this must still work when that
/// database is empty): there's no "later" UI, so once answered (restore or
/// skip) we don't ask again. Failures are swallowed — a missed restore
/// prompt shouldn't block using the app.
Future<void> maybeOfferRestore(BuildContext context, WidgetRef ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kRestoreOfferedKey) ?? false) return;

    final hasLocalProgress = await ref.read(appDatabaseProvider).hasAnyLocalProgress();
    if (hasLocalProgress) return;

    final backupRepository = ref.read(backupRepositoryProvider);
    final lastBackupAt = await backupRepository.lastBackupAt();
    if (lastBackupAt == null) return;
    if (!context.mounted) return;

    // Marked before the dialog resolves, not after — this is the only call
    // site, so there's no cross-call race, but a fast double-entry (e.g. a
    // rebuild) shouldn't be able to queue a second dialog while this one is
    // still awaiting the user's answer.
    await prefs.setBool(_kRestoreOfferedKey, true);
    if (!context.mounted) return;

    final shouldRestore = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Restore your backup?'),
        content: Text(
          'This device has no saved progress. You backed up your data on '
          '${formatDateTime(lastBackupAt)} — restore it now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (shouldRestore == true) {
      await backupRepository.restoreBackup();
    }
  } catch (_) {
    // See doc comment above.
  }
}
