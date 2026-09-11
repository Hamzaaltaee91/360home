// Secure Storage Service
//
// Thin, testable wrapper around [FlutterSecureStorage] used to persist
// sensitive values (auth tokens, session data) in the platform's secure
// keystore (Keychain on iOS/macOS, EncryptedSharedPreferences on Android,
// and an encrypted store on web/desktop).
//
// All reads/writes are guarded so a storage failure never crashes the app;
// failures are surfaced as `null` reads / no-op writes.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keys used for persisted secure values.
class SecureStorageKeys {
  const SecureStorageKeys._();

  /// Serialized Supabase auth session (access + refresh tokens).
  static const String supabaseSession = 'supabase_session';

  /// Cached role of the signed-in user.
  static const String userRole = 'user_role';
}

/// Abstraction over secure key/value storage.
///
/// Implemented by [SecureStorageService] in production and by fakes in tests.
abstract class SecureStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<void> deleteAll();
}

/// Default [SecureStorage] implementation backed by [FlutterSecureStorage].
class SecureStorageService implements SecureStorage {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Swallow: a failed secure write must not break the auth flow.
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Swallow: best-effort cleanup.
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Swallow: best-effort cleanup.
    }
  }
}

/// Adapts a [SecureStorage] to Supabase's [LocalStorage] interface so the
/// auth session is persisted in the platform secure store.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage(this._storage);

  final SecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _storage.read(SecureStorageKeys.supabaseSession);

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(SecureStorageKeys.supabaseSession)) != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(SecureStorageKeys.supabaseSession, persistSessionString);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(SecureStorageKeys.supabaseSession);
}
