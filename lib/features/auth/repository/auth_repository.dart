import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koji/core/supabase_config.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    SupabaseConfig.client,
    GoogleSignIn(
      serverClientId: '516208620302-kb9m01pqo39t8h6ps9qfcaq7s88i561s.apps.googleusercontent.com',
    ),
  );
});

class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final Logger _logger = Logger();

  AuthRepository(this._supabase, this._googleSignIn);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _logger.i('🔑 [AuthRepository] Calling Supabase signInWithPassword for: $email');
    try {
      final result = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _logger.i('✅ [AuthRepository] Supabase signInWithPassword successful');
      return result;
    } catch (e) {
      _logger.e('❌ [AuthRepository] Supabase signInWithPassword failed', error: e);
      rethrow;
    }
  }

  Future<AuthResponse> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _logger.i('📝 [AuthRepository] Calling Supabase signUp for: $email');
    try {
      final result = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      _logger.i('✅ [AuthRepository] Supabase signUp successful - UID: ${result.user?.id}');
      return result;
    } catch (e) {
      _logger.e('❌ [AuthRepository] Supabase signUp failed', error: e);
      rethrow;
    }
  }

  Future<AuthResponse?> signInWithGoogle() async {
    _logger.i('🔍 [AuthRepository] Starting Google Sign-In flow');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('⚠️ [AuthRepository] Google Sign-In cancelled by user');
        return null;
      }

      _logger.i('✅ [AuthRepository] Google account selected: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      _logger.i('🔑 [AuthRepository] Got Google authentication tokens');

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Missing Google Auth Tokens');
      }

      _logger.i('🔐 [AuthRepository] Signing in with Google credential');
      final result = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      _logger.i('✅ [AuthRepository] Supabase signInWithIdToken successful');
      return result;
    } catch (e) {
      _logger.e('❌ [AuthRepository] Google Sign-In failed', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _logger.i('🚪 [AuthRepository] Signing out from Supabase and Google');
    try {
      await Future.wait([
        _supabase.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _logger.i('✅ [AuthRepository] Sign out successful');
    } catch (e) {
      _logger.e('❌ [AuthRepository] Sign out failed', error: e);
      rethrow;
    }
  }
}
