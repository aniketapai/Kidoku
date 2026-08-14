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
    final joined = user.metadata.creationTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.16),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: colorScheme.surface,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person_rounded, size: 38, color: colorScheme.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName ?? 'Signed in',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (user.email != null) ...[
            const SizedBox(height: 2),
            Text(
              user.email!,
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
          if (joined != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Learning since ${_formatMonthYear(joined)}',
                style: textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.65)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _kMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatMonthYear(DateTime date) => '${_kMonths[date.month - 1]} ${date.year}';
}
