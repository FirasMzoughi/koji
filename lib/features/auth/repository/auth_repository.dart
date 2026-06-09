import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koji/core/supabase_config.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Pass via --dart-define=GOOGLE_WEB_CLIENT_ID=...
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  return AuthRepository(
    SupabaseConfig.client,
    GoogleSignIn(
      serverClientId: googleWebClientId.isNotEmpty ? googleWebClientId : null,
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
    _logger.i('🔑 [AuthRepository] Calling Supabase signInWithPassword');
    try {
      final result = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _logger.i('✅ [AuthRepository] Supabase signInWithPassword successful');
      return result;
    } catch (e) {
      _logger.e('❌ [AuthRepository] Supabase signInWithPassword failed',
          error: e);
      rethrow;
    }
  }

  Future<AuthResponse> createUserWithEmailAndPassword({
    required String email,
    required String password,
    bool isPro = false,
  }) async {
    _logger.i('📝 [AuthRepository] Calling Supabase signUp');
    try {
      final result = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://koji-admin-three.vercel.app/auth/confirm',
        // Pass isPro in user metadata so the DB trigger can read it
        data: {'is_pro': isPro},
      );
      _logger.i('✅ [AuthRepository] Supabase signUp successful');
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

      _logger.i('✅ [AuthRepository] Google account selected');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
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

  /// Per-chantier client login: verify an access code + password against the
  /// `login_with_access_code` RPC. Returns the matching quote id, or null when
  /// the pair is invalid. This does NOT create a Supabase auth session — the
  /// client is taken straight to that quote's signature view.
  Future<String?> loginWithAccessCode({
    required String code,
    required String password,
  }) async {
    _logger.i('🔑 [AuthRepository] Verifying chantier access code');
    try {
      final result = await _supabase.rpc('login_with_access_code', params: {
        'p_code': code.trim(),
        'p_password': password,
      });
      // The RPC returns the quote uuid (text) or null.
      final quoteId = result?.toString();
      if (quoteId == null || quoteId.isEmpty || quoteId == 'null') {
        _logger.w('⚠️ [AuthRepository] Invalid chantier access credentials');
        return null;
      }
      _logger.i('✅ [AuthRepository] Chantier access granted: $quoteId');
      return quoteId;
    } catch (e) {
      _logger.e('❌ [AuthRepository] Chantier access login failed', error: e);
      rethrow;
    }
  }

  /// Per-worker login: verify a worker access code + password against the
  /// `login_worker_with_code` RPC. Returns the matching worker id, or null. Like
  /// the client login, no Supabase auth session is created.
  Future<String?> loginWorkerWithCode({
    required String code,
    required String password,
  }) async {
    _logger.i('🔑 [AuthRepository] Verifying worker access code');
    try {
      final result = await _supabase.rpc('login_worker_with_code', params: {
        'p_code': code.trim(),
        'p_password': password,
      });
      final workerId = result?.toString();
      if (workerId == null || workerId.isEmpty || workerId == 'null') {
        _logger.w('⚠️ [AuthRepository] Invalid worker access credentials');
        return null;
      }
      _logger.i('✅ [AuthRepository] Worker access granted: $workerId');
      return workerId;
    } catch (e) {
      _logger.e('❌ [AuthRepository] Worker access login failed', error: e);
      rethrow;
    }
  }

  /// Tasks assigned to a worker (sessionless, via get_worker_tasks RPC).
  Future<List<Map<String, dynamic>>> getWorkerTasks(String workerId) async {
    final result =
        await _supabase.rpc('get_worker_tasks', params: {'p_worker_id': workerId});
    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  /// Worker flips a task's status (À faire / Terminé) via set_worker_task_status.
  Future<bool> setWorkerTaskStatus({
    required String workerId,
    required String taskId,
    required String status,
  }) async {
    final result = await _supabase.rpc('set_worker_task_status', params: {
      'p_worker_id': workerId,
      'p_task_id': taskId,
      'p_status': status,
    });
    return result == true;
  }

  Future<void> resetPassword({required String email}) async {
    _logger.i('🔑 [AuthRepository] Sending password reset email to $email');
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'koji://reset-password',
      );
      _logger.i('✅ [AuthRepository] Password reset email sent');
    } catch (e) {
      _logger.e('❌ [AuthRepository] Password reset failed', error: e);
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
