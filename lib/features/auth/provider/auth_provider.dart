import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final Logger _logger = Logger();

  AuthNotifier(this._authRepository, this._userRepository)
      : super(const AsyncValue.loading()) {
    _logger.i('🔧 AuthNotifier initialized');
    _authRepository.authStateChanges.listen((authState) async {
      final user = authState.session?.user;
      if (user != null) {
        _logger.i('✅ Auth state changed: User logged in');
        state = AsyncValue.data(user);
      } else {
        _logger.i('🚪 Auth state changed: User logged out');
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _logger.i('🔐 Attempting email/password sign in');
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailAndPassword(
          email: email, password: password);
      _logger.i('✅ Email/password sign in successful');
    } catch (e, st) {
      _logger.e('❌ Email/password sign in failed', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password,
      {bool isPro = false}) async {
    _logger.i('📝 Attempting email/password signup (isPro: $isPro)');
    state = const AsyncValue.loading();
    try {
      final response = await _authRepository.createUserWithEmailAndPassword(
          email: email, password: password);
      _logger.i('✅ Supabase Auth account created');

      if (response.user != null) {
        _logger.i('💾 Saving user to Supabase');
        await _userRepository.saveUser(response.user!.id, email, isPro: isPro);
        _logger.i('✅ User saved to Supabase successfully');
      }
    } catch (e, st) {
      _logger.e('❌ Signup failed', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle({bool isPro = false}) async {
    _logger.i('🔍 Attempting Google Sign-In (isPro: $isPro)');
    state = const AsyncValue.loading();
    try {
      final response = await _authRepository.signInWithGoogle();
      final user = response?.user;
      if (user != null) {
        _logger.i('✅ Google Sign-In successful');

        // Check if user exists, if not save them
        _logger.i('🔍 Checking if user exists in Supabase');
        final userDoc = await _userRepository.getUser(user.id);
        if (userDoc == null) {
          _logger.i('💾 New Google user — saving to Supabase (isPro: $isPro)');
          await _userRepository.saveUser(user.id, user.email ?? '',
              isPro: isPro);
          _logger.i('✅ New Google user saved to Supabase');
        } else {
          _logger.i('✅ Existing Google user found in Supabase');
        }
      } else {
        _logger.w('⚠️ Google Sign-In cancelled by user');
      }
    } catch (e, st) {
      _logger.e('❌ Google Sign-In failed', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    _logger.i('🚪 Signing out user');
    try {
      await _authRepository.signOut();
      _logger.i('✅ Sign out successful');
    } catch (e, st) {
      _logger.e('❌ Sign out failed', error: e, stackTrace: st);
    }
  }
}
