// Browse Offers Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class BrowseOffersScreen extends StatefulWidget {
  const BrowseOffersScreen({Key? key}) : super(key: key);

  @override
  State<BrowseOffersScreen> createState() => _BrowseOffersScreenState();
}

class _BrowseOffersScreenState extends State<BrowseOffersScreen> {
  late Future<List<RealtorOffer>> _offersFuture;
  String _selectedFilter = 'all'; // 'all', 'pending', 'interested'

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  void _loadOffers() {
    _offersFuture = _fetchAllOffers();
  }

  Future<List<RealtorOffer>> _fetchAllOffers() async {
    try {
      final requests = await SupabaseService().getUserRequests();
      final List<RealtorOffer> allOffers = [];

      for (final request in requests) {
        final offers = await SupabaseService().getOffersForRequest(request.id);
        allOffers.addAll(offers);
      }

      // Sort by creation date, newest first
      allOffers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allOffers;
    } catch (e) {
      rethrow;
    }
  }

  List<RealtorOffer> _filterOffers(List<RealtorOffer> offers) {
    switch (_selectedFilter) {
      case 'interested':
        return offers.where((o) => o.buyerResponse == 'interested').toList();
      case 'not_interested':
        return offers
            .where((o) => o.buyerResponse == 'not_interested')
            .toList();
      case 'pending':
      default:
        return offers.where((o) => o.buyerResponse == null).toList();
    }
  }

  Future<void> _respondToOffer(
    String offerId,
    String response,
  ) async {
    try {
      await SupabaseService().respondToOffer(offerId, response);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response == 'interested'
              ? 'تم تحديد اهتمامك بالعرض'
              : 'تم رفض العرض'),
        ),
      );

      setState(() => _loadOffers());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العروض الواردة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  value: 'all',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'قيد الانتظار',
                  value: 'pending',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'مهتم',
                  value: 'interested',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'غير مهتم',
                  value: 'not_interested',
                ),
              ],
            ),
          ),
          // Offers List
          Expanded(
            child: FutureBuilder<List<RealtorOffer>>(
              future: _offersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.loading) {
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
                          onPressed: () => setState(() => _loadOffers()),
                          child: const Text('إعادة محاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final allOffers = snapshot.data ?? [];
                final filteredOffers = _selectedFilter == 'all'
                    ? allOffers
                    : _filterOffers(allOffers);

                if (filteredOffers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
                              ? 'لا توجد عروض بعد'
                              : 'لا توجد عروض في هذه الفئة',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ستظهر هنا العروض التي تتطابق مع طلباتك',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOffers.length,
                  itemBuilder: (context, index) {
                    final offer = filteredOffers[index];
                    return _buildOfferCard(context, offer);
                  },
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
            label: 'العروض',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
        onTap: (index) {
          if (index == 0) context.go('/buyer-home');
          if (index == 2) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildFilterChip(
    {required String label, required String value}) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor:
          isSelected ? Colors.indigo.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, RealtorOffer offer) {
    final isInterested = offer.buyerResponse == 'interested';
    final isRejected = offer.buyerResponse == 'not_interested';
    final isPending = offer.buyerResponse == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/offer/${offer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.propertyTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.propertyAddress,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isInterested
                          ? Colors.green.shade100
                          : isRejected
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isInterested
                          ? 'مهتم'
                          : isRejected
                              ? 'مرفوض'
                              : 'جديد',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isInterested
                            ? Colors.green.shade700
                            : isRejected
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Property details grid
              Row(
                children: [
                  if (offer.bedrooms != null) ...[
                    _buildDetailItem(
                      icon: Icons.bed,
                      label: '${offer.bedrooms}',
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (offer.bathrooms != null) ...[
                    _buildDetailItem(
                      icon: Icons.bathtub,
                      label: '${offer.bathrooms}',
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (offer.areaSqft != null) ...[
                    _buildDetailItem(
                      icon: Icons.square_foot,
                      label: '${offer.areaSqft} sqft',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Price and lease type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر المقترح',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${offer.offeredPrice.toStringAsFixed(0)} ${offer.currency}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (offer.leaseType != null)
                    Chip(
                      label: Text(
                        offer.leaseType == 'rent' ? 'إيجار' : 'بيع',
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToOffer(offer.id, 'rejected'),
                        child: const Text('رفض'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _respondToOffer(offer.id, 'interested'),
                        child: const Text('مهتم'),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    isInterested ? 'تم تحديد اهتمامك' : 'تم رفض العرض',
                    style: TextStyle(
                      color: isInterested
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
