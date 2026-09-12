// Notification Service

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../models/pagination.dart';
import '../utils/error_handler.dart';
import 'supabase_service.dart';

class NotificationService {
  NotificationService({SupabaseService? supabaseService})
      : _supabase = supabaseService ?? SupabaseService();

  final SupabaseService _supabase;

  SupabaseClient get _client => _supabase.client;

  /// Runs [action], translating any thrown error into a standardized
  /// [AppException] with a user-friendly message.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw SupabaseErrorHandler.handle(error);
    }
  }

  String _requireUserId() {
    final userId = _supabase.getCurrentUserId();
    if (userId == null) throw const AppException('المستخدم غير مسجل دخول');
    return userId;
  }

  /// Fetches a page of notifications for the current user, newest first.
  Future<PaginatedResult<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) {
    return _guard(() async {
      final userId = _requireUserId();

      var query = _client
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final items = (response as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResult.fromItems(items, offset: offset, limit: limit);
    });
  }

  /// Returns the number of unread notifications for the current user.
  Future<int> getUnreadCount() {
    return _guard(() async {
      final userId = _requireUserId();

      final response = await _client
          .from('notifications')
          .select<PostgrestResponse>(
            'id',
            const FetchOptions(count: CountOption.exact),
          )
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.count ?? 0;
    });
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId) {
    return _guard(() => _client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId));
  }

  /// Marks all notifications for the current user as read.
  Future<void> markAllAsRead() {
    return _guard(() async {
      final userId = _requireUserId();

      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    });
  }

  /// Deletes a single notification.
  Future<void> deleteNotification(String notificationId) {
    return _guard(
        () => _client.from('notifications').delete().eq('id', notificationId));
  }

  /// Subscribes to realtime inserts for the current user's notifications.
  ///
  /// Returns the [RealtimeChannel] so callers can unsubscribe when done.
  RealtimeChannel subscribeToNotifications(
    void Function(AppNotification notification) onNotification, {
    void Function(Object error)? onError,
  }) {
    final userId = _requireUserId();

    final channel = _client.channel('notifications:$userId').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: 'user_id=eq.$userId',
      ),
      (payload, [ref]) {
        try {
          final newRecord =
              Map<String, dynamic>.from((payload as Map)['new'] as Map);
          onNotification(AppNotification.fromJson(newRecord));
        } catch (error) {
          onError?.call(error);
        }
      },
    );
    channel.subscribe();
    return channel;
  }

  /// Cancels a realtime subscription created by [subscribeToNotifications].
  Future<void> unsubscribe(RealtimeChannel channel) {
    return _guard(() => _client.removeChannel(channel));
  }
}
