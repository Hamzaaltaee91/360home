import 'package:flutter/material.dart';

import '../../models/realtor_verification.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for reviewing and approving realtor verification requests.
class VerifyRealtorsScreen extends StatefulWidget {
  const VerifyRealtorsScreen({super.key});

  static const String routeName = '/admin/verifications';

  @override
  State<VerifyRealtorsScreen> createState() => _VerifyRealtorsScreenState();
}

class _VerifyRealtorsScreenState extends State<VerifyRealtorsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = true;
  AppException? _error;
  List<RealtorVerification> _verifications = const [];

  /// Ids of verifications currently being reviewed, to disable their actions.
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verifications = await _supabaseService.getVerifications();
      if (!mounted) return;
      setState(() {
        _verifications = verifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = SupabaseErrorHandler.handle(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _review(
    RealtorVerification verification, {
    required bool approve,
  }) async {
    String? rejectionReason;
    if (!approve) {
      rejectionReason = await _promptRejectionReason();
      if (rejectionReason == null) return;
    }

    setState(() => _processingIds.add(verification.id));

    try {
      await _supabaseService.reviewVerification(
        verificationId: verification.id,
        approve: approve,
        rejectionReason: rejectionReason,
      );
      if (!mounted) return;
      setState(() {
        _verifications =
            _verifications.where((v) => v.id != verification.id).toList();
      });
      _showMessage(approve ? 'تم اعتماد الوسيط' : 'تم رفض الطلب');
    } catch (error) {
      if (!mounted) return;
      _showMessage(SupabaseErrorHandler.handle(error).message);
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(verification.id));
      }
    }
  }

  Future<String?> _promptRejectionReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'أدخل سبب رفض طلب التوثيق',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(dialogContext).pop(reason);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توثيق الوسطاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadVerifications,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVerifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!.message,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadVerifications,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (_verifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(child: Text('لا توجد طلبات توثيق معلقة')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _verifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final verification = _verifications[index];
        return _VerificationCard(
          verification: verification,
          isProcessing: _processingIds.contains(verification.id),
          onApprove: () => _review(verification, approve: true),
          onReject: () => _review(verification, approve: false),
        );
      },
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.verification,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  final RealtorVerification verification;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verification.licenseNumber ?? 'رقم رخصة غير متوفر',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'تاريخ الطلب: ${_formatDate(verification.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (verification.documentUrl != null) ...[
              const SizedBox(height: 4),
              Text(
                verification.documentUrl!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            if (isProcessing)
              const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('اعتماد'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
