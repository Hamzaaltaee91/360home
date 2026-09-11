import 'package:dabberli/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [SecureStorage] fake for tests.
class _FakeSecureStorage implements SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> deleteAll() async => _store.clear();
}

void main() {
  group('SecureLocalStorage', () {
    late _FakeSecureStorage storage;
    late SecureLocalStorage localStorage;

    setUp(() {
      storage = _FakeSecureStorage();
      localStorage = SecureLocalStorage(storage);
    });

    test('hasAccessToken is false when nothing is persisted', () async {
      expect(await localStorage.hasAccessToken(), isFalse);
    });

    test('persistSession stores the session and accessToken reads it back',
        () async {
      await localStorage.persistSession('{"access_token":"abc"}');

      expect(await localStorage.hasAccessToken(), isTrue);
      expect(
        await localStorage.accessToken(),
        '{"access_token":"abc"}',
      );
    });

    test('removePersistedSession clears the stored session', () async {
      await localStorage.persistSession('{"access_token":"abc"}');
      await localStorage.removePersistedSession();

      expect(await localStorage.hasAccessToken(), isFalse);
      expect(await localStorage.accessToken(), isNull);
    });
  });
}
