// Messages Screen

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/supabase_service.dart';
import '../utils/error_handler.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    Key? key,
    required this.offerId,
    this.title = 'المحادثة',
  }) : super(key: key);

  final String offerId;
  final String title;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Future<List<Map<String, dynamic>>> _messagesFuture;
  List<Map<String, dynamic>>? _loadedMessages;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMessages() async {
    final messages = await _service.listMessages(widget.offerId);
    _loadedMessages = messages;
    if (mounted) setState(() {});
    // Best-effort: mark messages as read once loaded.
    try {
      await _service.markMessagesRead(widget.offerId);
    } catch (_) {
      // Ignore read-receipt failures; they should not block the UI.
    }
    return messages;
  }

  void _reload() {
    setState(() {
      _messagesFuture = _loadMessages();
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _service.sendMessage(offerId: widget.offerId, body: text);
      _controller.clear();
      _reload();
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// يشتقّ معرّف الطرف الآخر من أول رسالة محمّلة.
  /// `null` إذا لم تُحمَّل رسائل بعد أو تعذّر التحديد.
  String? _otherUserId() {
    final messages = _loadedMessages;
    if (messages == null || messages.isEmpty) return null;
    final currentUserId = _service.getCurrentUserId();
    final first = messages.first;
    final senderId = first['sender_id'] as String?;
    if (senderId != null && senderId != currentUserId) {
      return senderId;
    }
    return first['recipient_id'] as String?;
  }

  void _handleMenuAction(String action, String? otherUserId) {
    if (otherUserId == null) return;
    if (action == 'report') {
      _showReportDialog(otherUserId);
    } else if (action == 'block') {
      _confirmBlock(otherUserId);
    }
  }

  Future<void> _showReportDialog(String reportedUserId) async {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('الإبلاغ عن المستخدم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'السبب *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'تفاصيل إضافية (اختياري)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('إرسال'),
            ),
          ],
        );
      },
    );

    final reason = reasonController.text.trim();
    final details = detailsController.text.trim();
    reasonController.dispose();
    detailsController.dispose();

    if (confirmed != true || reason.isEmpty) return;

    try {
      await _service.reportContent(
        reportedUserId: reportedUserId,
        reason: reason,
        details: details.isEmpty ? null : details,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الإبلاغ')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmBlock(String otherUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حظر المستخدم'),
          content: const Text('هل أنت متأكد من حظر هذا المستخدم؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حظر'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.blockUser(otherUserId);
      if (!mounted) return;
      Navigator.of(context).pop();
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
    final currentUserId = _service.getCurrentUserId();
    final otherUserId = _otherUserId();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (otherUserId != null)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, otherUserId),
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'report',
                  child: Text('الإبلاغ عن المستخدم'),
                ),
                PopupMenuItem<String>(
                  value: 'block',
                  child: Text('حظر المستخدم'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messagesFuture,
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

                final messages = snapshot.data ?? const <Map<String, dynamic>>[];
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48),
                        SizedBox(height: 16),
                        Text('لا توجد رسائل بعد'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderId = message['sender_id'] as String?;
                    final isMine = senderId != null &&
                        currentUserId != null &&
                        senderId == currentUserId;
                    return _MessageBubble(
                      body: (message['body'] as String?) ?? '',
                      createdAt: _parseDate(message['created_at']),
                      isMine: isMine,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    tooltip: 'إرسال',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.body,
    required this.createdAt,
    required this.isMine,
  });

  final String body;
  final DateTime? createdAt;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceVariant;
    final textColor = isMine
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(body, style: TextStyle(color: textColor)),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(createdAt!.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
