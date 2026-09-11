import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../utils/error_handler.dart';

/// Admin dashboard displaying core platform metric summaries.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const String routeName = '/admin';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  AppException? _error;
  PlatformStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _analyticsService.getPlatformStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
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
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    final stats = _stats;
    if (stats == null) {
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(child: Text('لا توجد بيانات متاحة')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _MetricCard(
              label: 'إجمالي المستخدمين',
              value: '${stats.newUsersTotal}',
              icon: Icons.people_outline,
            ),
            _MetricCard(
              label: 'المشترون الجدد',
              value: '${stats.newUsersBuyers}',
              icon: Icons.shopping_bag_outlined,
            ),
            _MetricCard(
              label: 'الوسطاء الجدد',
              value: '${stats.newUsersRealtors}',
              icon: Icons.badge_outlined,
            ),
            _MetricCard(
              label: 'طلبات العقارات',
              value: '${stats.propertyRequests}',
              icon: Icons.request_page_outlined,
            ),
            _MetricCard(
              label: 'عروض الوسطاء',
              value: '${stats.realtorOffers}',
              icon: Icons.local_offer_outlined,
            ),
            _MetricCard(
              label: 'نسبة قبول العروض',
              value: '${stats.offerAcceptanceRate.toStringAsFixed(1)}%',
              icon: Icons.thumb_up_outlined,
            ),
            _MetricCard(
              label: 'متوسط العروض لكل طلب',
              value: stats.averageOffersPerRequest.toStringAsFixed(1),
              icon: Icons.insights_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
