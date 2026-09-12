// Authentication State Provider
//
// Exposes global authentication state backed by [SupabaseService] and keeps
// it in sync with Supabase's realtime auth stream.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../services/supabase_service.dart';

/// Provides the shared [SupabaseService] singleton.
///
/// Override this in tests to inject a fake service:
/// `ProviderScope(overrides: [supabaseServiceProvider.overrideWithValue(fake)])`.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Emits the current Supabase [AuthState] whenever the session changes
/// (sign-in, sign-out, token refresh).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseServiceProvider).authStateChanges;
});

/// Global authentication state.
///
/// Holds the currently signed-in Supabase [User] (or `null` when signed out)
/// and exposes the auth actions used across the app.
class AuthNotifier extends AsyncNotifier<User?> {
  SupabaseService get _service => ref.read(supabaseServiceProvider);

  @override
  Future<User?> build() async {
    // Rebuild whenever the underlying auth session changes.
    ref.watch(authStateChangesProvider);

    final user = _service.client.auth.currentUser;
    if (user != null) {
      await _service.refreshCurrentUserRole();
    }
    return user;
  }

  /// Signs in with [email] and [password], updating state on success.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _service.signIn(email: email, password: password);
      return response.user;
    });
  }

  /// Registers a new account and updates state with the resulting user.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _service.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      return response.user;
    });
  }

  /// Signs the current user out and clears auth state.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.signOut();
      return null;
    });
  }
}

/// Global authentication state provider.
final authProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

/// Convenience selector for the current user's role, or `null` when signed out.
final currentUserRoleProvider = Provider<String?>((ref) {
  ref.watch(authProvider);
  return ref.watch(supabaseServiceProvider).currentUserRole;
});
