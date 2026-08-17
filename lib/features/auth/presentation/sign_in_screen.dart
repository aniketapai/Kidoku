import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/database/providers.dart';
import '../../../core/utils/date_format.dart';
import '../../backup/data/backup_repository.dart';
import '../../reader/data/user_word_repository.dart';

/// The only screen reachable without a signed-in account — the router
/// redirects everyone else here (see app_router.dart). Successful sign-in
/// updates [authStateProvider], which the router's redirect reacts to, so
/// this screen doesn't navigate anywhere itself.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _signingIn = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      await ref.read(userWordRepositoryProvider).pullFromRemote();
      await _maybeOfferRestore();
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        setState(() => _error = _friendlyGoogleError(e.code));
      }
    } on FirebaseAuthException {
      if (mounted) {
        setState(() => _error = "Couldn't sign in with that account. Please try again.");
      }
    } catch (_) {
      // Covers pullFromRemote() failing after a successful sign-in (e.g. a
      // flaky connection) — by then the router may already have popped this
      // screen in response to the auth-state change, so guard with mounted.
      if (mounted) {
        setState(() => _error = "Couldn't sign in — check your connection and try again.");
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  /// Offers to restore a cloud backup only when this looks like a fresh
  /// device: no local review/progress history (a same-device sign-out ->
  /// sign-in keeps that data, so it never triggers this) but a backup
  /// exists in the cloud from some other device. Failures here are
  /// swallowed — a missed restore prompt shouldn't block sign-in itself,
  /// the user can still restore later... actually there's no "later" UI, so
  /// this is best-effort but silent: worst case the user just doesn't get
  /// asked and keeps a blank slate, same as before this feature existed.
  Future<void> _maybeOfferRestore() async {
    try {
      final hasLocalProgress = await ref.read(appDatabaseProvider).hasAnyLocalProgress();
      if (hasLocalProgress || !mounted) return;

      final backupRepository = ref.read(backupRepositoryProvider);
      final lastBackupAt = await backupRepository.lastBackupAt();
      if (lastBackupAt == null || !mounted) return;

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
      // See doc comment above — silently give up and leave the device as-is.
    }
  }

  String _friendlyGoogleError(GoogleSignInExceptionCode code) {
    switch (code) {
      case GoogleSignInExceptionCode.interrupted:
        return 'Sign-in was interrupted. Please try again.';
      case GoogleSignInExceptionCode.uiUnavailable:
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return "Google Sign-In isn't available right now. Please try again later.";
      default:
        return "Couldn't sign in — check your connection and try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.menu_book_rounded, size: 44, color: colorScheme.primary),
                ),
                const SizedBox(height: 24),
                Text('Kidoku', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Sign in to track your progress and sync it across devices.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _signingIn ? null : _signIn,
                    icon: _signingIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
