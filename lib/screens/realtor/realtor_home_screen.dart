// Realtor Home Screen - Dashboard

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/analytics_service.dart';

class RealtorHomeScreen extends StatefulWidget {
  const RealtorHomeScreen({Key? key}) : super(key: key);

  @override
  State<RealtorHomeScreen> createState() => _RealtorHomeScreenState();
}

class _RealtorHomeScreenState extends State<RealtorHomeScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  late Future<RealtorStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _analytics.getRealtorStats();
  }

  void _reload() {
    setState(() => _statsFuture = _analytics.getRealtorStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _statsFuture;
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade700,
                      Colors.indigo.shade500,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أهلا بك',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إدارة عروضك وتتبع الفرص',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                    ),
                  ],
                ),
              ),
              // Statistics Cards
              FutureBuilder<RealtorStats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text('خطأ: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _reload,
                              child: const Text('إعادة محاولة'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final stats = snapshot.data!;
                  final acceptanceRate = stats.totalOffers > 0
                      ? (stats.acceptedOffers / stats.totalOffers) * 100
                      : 0.0;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.send,
                                    label: 'العروض',
                                    value: stats.totalOffers.toString(),
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.schedule,
                                    label: 'قيد الانتظار',
                                    value: stats.pendingOffers.toString(),
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.check_circle,
                                    label: 'مقبولة',
                                    value: stats.acceptedOffers.toString(),
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.trending_up,
                                    label: 'معدل القبول',
                                    value:
                                        '${acceptanceRate.toStringAsFixed(1)}%',
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildOfferBreakdownChart(stats),
                      ),
                    ],
                  );
                },
              ),
              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإجراءات السريعة',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context,
                      icon: Icons.search,
                      label: 'البحث عن الطلبات',
                      color: Colors.blue,
                      onTap: () => context.go('/browse-requests'),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context,
                      icon: Icons.list_alt,
                      label: 'عروضي',
                      color: Colors.green,
                      onTap: () => context.go('/my-offers'),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      context,
                      icon: Icons.workspace_premium,
                      label: 'الاشتراك',
                      color: Colors.indigo,
                      onTap: () => context.go('/subscription'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
        onTap: (index) {
          if (index == 1) context.go('/browse-requests');
          if (index == 2) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildOfferBreakdownChart(RealtorStats stats) {
    final bars = <_ChartBar>[
      _ChartBar(label: 'مقبولة', value: stats.acceptedOffers, color: Colors.green),
      _ChartBar(label: 'مرفوضة', value: stats.rejectedOffers, color: Colors.red),
      _ChartBar(label: 'قيد الانتظار', value: stats.pendingOffers, color: Colors.orange),
    ];

    final maxValue = bars.fold<int>(0, (max, bar) => bar.value > max ? bar.value : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع العروض',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (maxValue == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('لا توجد بيانات بعد')),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars
                    .map((bar) => Expanded(
                          child: _buildChartBar(bar, maxValue),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartBar(_ChartBar bar, int maxValue) {
    final ratio = maxValue > 0 ? bar.value / maxValue : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            bar.value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: bar.color,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio == 0 ? 0.02 : ratio,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bar.color.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bar.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ChartBar {
  const _ChartBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}
