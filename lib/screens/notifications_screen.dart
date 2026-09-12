// Notifications Screen

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../models/pagination.dart';
import '../services/notification_service.dart';
import '../utils/error_handler.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();

  late Future<PaginatedResult<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _service.getNotifications();
  }

  void _reload() {
    setState(() {
      _notificationsFuture = _service.getNotifications();
    });
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _service.markAsRead(notification.id);
      _reload();
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _reload();
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'تعليم الكل كمقروء',
          ),
        ],
      ),
      body: FutureBuilder<PaginatedResult<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is AppException
                ? error.message
                : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.items ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 48),
                  SizedBox(height: 16),
                  Text('لا توجد إشعارات'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _markAsRead(notification),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? theme.colorScheme.surfaceVariant
            : theme.colorScheme.primaryContainer,
        child: Icon(
          _iconForType(notification.type),
          color: notification.isRead
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight:
              notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy/MM/dd HH:mm').format(notification.createdAt),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'offer_received':
        return Icons.local_offer_outlined;
      case 'offer_accepted':
        return Icons.check_circle_outline;
      case 'verification':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
