import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../firebase/providers.dart';

part 'auth_repository.g.dart';

/// Google Sign-In is the only way into the app — see the router's auth
/// redirect in app_router.dart, which sends anyone without a signed-in,
/// non-anonymous user to the sign-in screen. Saved words are keyed off the
/// resulting stable Firebase uid for Firestore sync (steps.md section 7).
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;
  bool _googleInitialized = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final googleAccount = await GoogleSignIn.instance.authenticate();
    final idToken = googleAccount.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(ref.watch(firebaseAuthProvider));

@riverpod
Stream<User?> authState(Ref ref) => ref.watch(authRepositoryProvider).authStateChanges();
