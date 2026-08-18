import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../core/auth/auth_repository.dart';
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

  static const _valueProps = [
    (icon: Icons.cloud_sync_rounded, label: 'Sync progress across every device'),
    (icon: Icons.style_rounded, label: 'Save your vocabulary and review decks'),
    (icon: Icons.local_fire_department_rounded, label: 'Keep your reading streak safe'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -140,
            left: -120,
            child: _GlowCircle(color: colorScheme.primary, size: 320),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: _GlowCircle(color: colorScheme.secondary, size: 360),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colorScheme.primary, colorScheme.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.secondary.withValues(alpha: 0.28),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_stories_rounded, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Kidoku',
                        style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Graded Japanese reading, from N5 to N1',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 36),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colorScheme.surfaceContainerHighest),
                        ),
                        child: Column(
                          children: [
                            for (final (index, prop) in _valueProps.indexed) ...[
                              if (index != 0) const SizedBox(height: 14),
                              _ValuePropRow(
                                icon: prop.icon,
                                label: prop.label,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _GoogleSignInButton(loading: _signingIn, onPressed: _signingIn ? null : _signIn),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: _error!, colorScheme: colorScheme, textTheme: textTheme),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Your data stays private and synced only to your account.',
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft off-canvas gradient blob used to echo the app icon's indigo/vermillion
/// gradient behind the sign-in content without competing with it.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _ValuePropRow extends StatelessWidget {
  const _ValuePropRow({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.colorScheme, required this.textTheme});

  final String message;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// A "Sign in with Google" button that follows Google's brand guidelines:
/// a fixed white surface with the official multicolor "G" mark, regardless
/// of the app's own light/dark theme.
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDADCE0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF757575)),
                  )
                else
                  const _GoogleLogo(size: 20),
                const SizedBox(width: 12),
                Text(
                  loading ? 'Signing in…' : 'Continue with Google',
                  style: const TextStyle(
                    color: Color(0xFF3C4043),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GoogleLogoPainter()));
  }
}

/// Draws Google's official four-color "G" mark from its SVG path data
/// (48x48 viewBox) so the sign-in button matches Google's brand guidelines
/// without shipping an image asset.
class _GoogleLogoPainter extends CustomPainter {
  static final _blue = parseSvgPathData(
    'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 6.64v5.52h7.11'
    'c4.16-3.83 6.56-9.47 6.56-16.17z',
  );
  static final _green = parseSvgPathData(
    'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.11-7.45 2.11-5.73 0-10.58-3.87-12.31-9.07'
    'H4.34v5.7C7.96 41.07 15.4 46 24 46z',
  );
  static final _yellow = parseSvgPathData(
    'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 17.09 2 20.45 2 24'
    's.85 6.91 2.34 9.88l7.35-5.7z',
  );
  static final _red = parseSvgPathData(
    'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 15.4 2 7.96 6.93 4.34 14.12'
    'l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z',
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    canvas.drawPath(_blue, Paint()..color = const Color(0xFF4285F4));
    canvas.drawPath(_green, Paint()..color = const Color(0xFF34A853));
    canvas.drawPath(_yellow, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawPath(_red, Paint()..color = const Color(0xFFEA4335));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
