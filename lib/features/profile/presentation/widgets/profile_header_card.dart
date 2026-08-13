import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Read-only account summary — sign-in happens on a dedicated screen before
/// the app shell is ever reached, so there's nothing to edit here.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final photoUrl = user.photoURL;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Icon(Icons.person_rounded, size: 36, color: colorScheme.primary)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName ?? 'Signed in',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (user.email != null) ...[
            const SizedBox(height: 2),
            Text(
              user.email!,
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }
}
