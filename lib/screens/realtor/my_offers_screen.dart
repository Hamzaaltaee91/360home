// My Offers Screen for Realtors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../models/pagination.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({Key? key}) : super(key: key);

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  late Future<PaginatedResult<RealtorOffer>> _offersFuture;

  /// Selected status filter. `all` shows every offer.
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  void _loadOffers() {
    _offersFuture = SupabaseService().getRealtorOffers();
  }

  Future<void> _refresh() async {
    setState(_loadOffers);
    await _offersFuture;
  }

  List<RealtorOffer> _filterOffers(List<RealtorOffer> offers) {
    if (_statusFilter == 'all') return offers;
    return offers.where((o) => o.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عروضي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go(RouteNames.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('الكل', 'all'),
                  const SizedBox(width: 8),
                  _buildStatusChip('قيد الانتظار', 'pending'),
                  const SizedBox(width: 8),
                  _buildStatusChip('مقبولة', 'accepted'),
                  const SizedBox(width: 8),
                  _buildStatusChip('مرفوضة', 'rejected'),
                  const SizedBox(width: 8),
                  _buildStatusChip('منتهية', 'expired'),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<PaginatedResult<RealtorOffer>>(
              future: _offersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('خطأ: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(_loadOffers),
                          child: const Text('إعادة محاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final offers = _filterOffers(snapshot.data?.items ?? []);

                if (offers.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد عروض',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تصفح الطلبات وقدّم عرضك الأول',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => context
                                      .go(RouteNames.browseRequests),
                                  icon: const Icon(Icons.search),
                                  label: const Text('تصفح الطلبات'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: offers.length,
                    itemBuilder: (context, index) =>
                        _buildOfferCard(context, offers[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          if (index == 0) context.go(RouteNames.realtorHome);
          if (index == 1) context.go(RouteNames.browseRequests);
          if (index == 2) context.go(RouteNames.profile);
        },
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      backgroundColor:
          isSelected ? Colors.indigo.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, RealtorOffer offer) {
    final statusColor = _statusColor(offer.status);
    final daysAgo = DateTime.now().difference(offer.createdAt).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go(
          RouteNames.requestDetailsPath(offer.requestId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      offer.propertyTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(_statusLabel(offer.status)),
                    backgroundColor: statusColor.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                offer.propertyAddress,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                '${offer.offeredPrice.toStringAsFixed(0)} ${offer.currency}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (offer.bedrooms != null)
                    _buildSpecChip(
                      icon: Icons.bed,
                      label: '${offer.bedrooms} غرفة',
                    ),
                  if (offer.bathrooms != null)
                    _buildSpecChip(
                      icon: Icons.bathtub,
                      label: '${offer.bathrooms} حمام',
                    ),
                  if (offer.areaSqft != null)
                    _buildSpecChip(
                      icon: Icons.square_foot,
                      label: '${offer.areaSqft} sqft',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'منذ $daysAgo ${daysAgo == 1 ? 'يوم' : 'أيام'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(
                      RouteNames.requestDetailsPath(offer.requestId),
                    ),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('عرض الطلب'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/messages/${offer.id}'),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('الرسائل'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'expired':
        return 'منتهي';
      case 'pending':
      default:
        return 'قيد الانتظار';
    }
  }
}
