// Notifications State Provider
//
// Exposes the current user's notifications, unread count, and a realtime
// subscription that keeps the list in sync with the backend.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

/// Provides the shared [NotificationService] singleton.
///
/// Override this in tests to inject a fake service:
/// `ProviderScope(overrides: [notificationServiceProvider.overrideWithValue(fake)])`.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});

/// Manages the current user's notifications.
class NotificationsNotifier extends AsyncNotifier<List<Notification>> {
  NotificationService get _service => ref.read(notificationServiceProvider);

  RealtimeChannel? _channel;

  @override
  Future<List<Notification>> build() async {
    // Re-fetch whenever the signed-in user changes.
    ref.watch(authProvider);

    // Tear down any previous realtime subscription when rebuilding.
    ref.onDispose(_cancelSubscription);

    if (!_service.isAuthenticated()) return const [];

    _subscribeToRealtime();
    return _service.getNotifications();
  }

  /// Subscribes to realtime inserts and prepends new notifications.
  void _subscribeToRealtime() {
    _channel = _service.subscribeToNotifications(
      (notification) {
        final current = state.valueOrNull;
        if (current == null) return;
        state = AsyncValue.data([notification, ...current]);
      },
      onError: (_) {
        // Ignore malformed realtime payloads; the next refresh will reconcile.
      },
    );
  }

  Future<void> _cancelSubscription() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await _service.unsubscribe(channel);
    }
  }

  /// Re-fetches notifications from the backend.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getNotifications());
  }

  /// Marks a single notification as read and updates the local list.
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);

    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data([
      for (final notification in current)
        if (notification.id == notificationId)
          notification.copyWith(isRead: true)
        else
          notification,
    ]);
  }

  /// Marks all notifications as read and updates the local list.
  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();

    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data([
      for (final notification in current) notification.copyWith(isRead: true),
    ]);
  }

  /// Deletes a notification and removes it from the local list.
  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);

    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data([
      for (final notification in current)
        if (notification.id != notificationId) notification,
    ]);
  }
}

/// Provides the current user's notifications.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<Notification>>(
  NotificationsNotifier.new,
);

/// Provides the number of unread notifications for the current user.
///
/// Derived from [notificationsProvider] so it stays in sync with local
/// read/unread updates without an extra network round-trip.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.isRead).length;
});
