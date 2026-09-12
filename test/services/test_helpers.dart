import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabberli/services/supabase_service.dart';

/// A mocked [SupabaseService] whose [client] returns a mocked [SupabaseClient].
class MockSupabaseService extends Mock implements SupabaseService {}

/// A mocked [SupabaseClient].
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// A mocked [SupabaseQueryBuilder] used to stub fluent query chains.
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// A mocked [PostgrestFilterBuilder] returned by query builders.
class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

/// A mocked [PostgrestTransformBuilder] for `.single()` / `.maybeSingle()`.
class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

/// A mocked [FunctionsClient] for Edge Function invocations.
class MockFunctionsClient extends Mock implements FunctionsClient {}

/// A mocked [GoTrueClient] for auth access.
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// A mocked [User].
class MockUser extends Mock implements User {}

/// A mocked [RealtimeChannel].
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

/// A mocked [RealtimeClient].
class MockRealtimeClient extends Mock implements RealtimeClient {}

/// A mocked [SupabaseStorageClient].
class MockStorageClient extends Mock implements SupabaseStorageClient {}

/// A mocked [StorageFileApi].
class MockStorageFileApi extends Mock implements StorageFileApi {}

/// Registers fallback values required by mocktail for non-nullable types.
void registerServiceFallbacks() {
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(Uri.parse('https://example.com'));
  registerFallbackValue(const FetchOptions());
}

/// A stand-in for a `PostgrestFilterBuilder`/`PostgrestTransformBuilder`
/// result that behaves like a real [Future] when awaited.
///
/// In postgrest 1.5.x these builders `implements Future<T>` instead of
/// returning one, so a query chain's terminal call (`.eq(...)`,
/// `.maybeSingle()`, ...) must return something Future-shaped. Mocktail's
/// usual `thenAnswer((_) async => value)` produces a `Future<T>`, which
/// doesn't satisfy that builder return type and fails to compile; this fake
/// forwards `then` to a real [Future] so `await` works without depending on
/// mocktail's dynamic dispatch for it.
class FakeAwaitable<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeAwaitable(T value) : _future = Future<T>.value(value);

  final Future<T> _future;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) =>
      _future.then(onValue, onError: onError);
}
