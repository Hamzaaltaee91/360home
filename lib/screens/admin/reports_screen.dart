import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for reviewing and resolving user reports.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static const String routeName = '/admin/reports';

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = true;
  AppException? _error;
  List<Map<String, dynamic>> _reports = const [];

  /// Ids of reports currently being resolved, to disable their actions.
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports =
          await _supabaseService.adminListReports(status: 'open');
      if (!mounted) return;
      setState(() {
        _reports = reports;
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

  Future<void> _resolve(
    Map<String, dynamic> report, {
    required String status,
  }) async {
    final reportId = report['id'] as String;

    setState(() => _processingIds.add(reportId));

    try {
      await _supabaseService.adminResolveReport(
        reportId: reportId,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _reports = _reports.where((r) => r['id'] != reportId).toList();
      });
      _showMessage(
        status == 'reviewed' ? 'تمت مراجعة البلاغ' : 'تم رفض البلاغ',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(SupabaseErrorHandler.handle(error).message);
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(reportId));
      }
    }
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
        title: const Text('بلاغات المستخدمين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReports,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
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
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (_reports.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(child: Text('لا توجد بلاغات مفتوحة')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _ReportCard(
          report: report,
          isProcessing: _processingIds.contains(report['id'] as String),
          onReviewed: () => _resolve(report, status: 'reviewed'),
          onDismissed: () => _resolve(report, status: 'dismissed'),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.isProcessing,
    required this.onReviewed,
    required this.onDismissed,
  });

  final Map<String, dynamic> report;
  final bool isProcessing;
  final VoidCallback onReviewed;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reporterName = _joinedFullName(report['reporter']);
    final reportedName = _joinedFullName(report['reported']);
    final reason = report['reason'] as String? ?? '—';
    final details = report['details'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'بلاغ ضد: ${reportedName.isEmpty ? 'مستخدم غير معروف' : reportedName}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'المُبلِّغ: ${reporterName.isEmpty ? 'مستخدم غير معروف' : reporterName}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'السبب: $reason',
              style: theme.textTheme.bodyMedium,
            ),
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(details, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Text(
              'تاريخ البلاغ: ${_formatDate(report['created_at'])}',
              style: theme.textTheme.bodySmall,
            ),
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
                    onPressed: onDismissed,
                    icon: const Icon(Icons.close),
                    label: const Text('رفض البلاغ'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onReviewed,
                    icon: const Icon(Icons.check),
                    label: const Text('تمت المراجعة'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _joinedFullName(dynamic joined) {
    if (joined is Map) {
      return joined['full_name'] as String? ?? '';
    }
    return '';
  }

  String _formatDate(dynamic raw) {
    if (raw is! String) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
