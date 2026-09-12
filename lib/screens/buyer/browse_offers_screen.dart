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
  final ScrollController _scrollController = ScrollController();

  /// All offers loaded so far, accumulated across pages.
  final List<RealtorOffer> _offers = [];

  /// Whether the initial page is still loading.
  bool _isLoading = true;

  /// Whether a subsequent page is currently loading.
  bool _isLoadingMore = false;

  /// Whether the backend may have more pages.
  bool _hasMore = true;

  /// Error from the most recent load attempt, if any.
  Object? _error;

  /// Page size used when fetching offers.
  static const int _pageSize = 20;

  String _selectedFilter = 'all'; // 'all', 'pending', 'interested'
  String _sortBy = 'newest'; // 'newest', 'price_asc', 'price_desc'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadOffers();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Triggers loading the next page when the user nears the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  /// Loads the first page, resetting any accumulated state.
  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasMore = true;
      _offers.clear();
    });

    try {
      final page = await SupabaseService().getBuyerOffers(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _offers.addAll(page.items);
        _hasMore = page.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  /// Appends the next page of offers, if any remain.
  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final page = await SupabaseService().getBuyerOffers(
        limit: _pageSize,
        offset: _offers.length,
      );
      if (!mounted) return;
      setState(() {
        _offers.addAll(page.items);
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل المزيد: $e')),
      );
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

  List<RealtorOffer> _searchOffers(List<RealtorOffer> offers) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return offers;

    return offers.where((o) {
      return o.propertyTitle.toLowerCase().contains(query) ||
          o.propertyAddress.toLowerCase().contains(query);
    }).toList();
  }

  List<RealtorOffer> _sortOffers(List<RealtorOffer> offers) {
    final sorted = List<RealtorOffer>.from(offers);
    switch (_sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => a.offeredPrice.compareTo(b.offeredPrice));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.offeredPrice.compareTo(a.offeredPrice));
        break;
      case 'newest':
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
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

      await _loadOffers();
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
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ابحث بالعنوان أو الموقع',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          // Sort Dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('الأحدث'),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('السعر: من الأقل للأعلى'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('السعر: من الأعلى للأقل'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sortBy = value);
                    },
                  ),
                ),
              ],
            ),
          ),
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
          Expanded(child: _buildOffersBody()),
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

  Widget _buildOffersBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('خطأ: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOffers,
              child: const Text('إعادة محاولة'),
            ),
          ],
        ),
      );
    }

    final statusFiltered =
        _selectedFilter == 'all' ? _offers : _filterOffers(_offers);
    final filteredOffers = _sortOffers(_searchOffers(statusFiltered));

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
              _searchQuery.isNotEmpty
                  ? 'لا توجد نتائج مطابقة'
                  : _selectedFilter == 'all'
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
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredOffers.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filteredOffers.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final offer = filteredOffers[index];
        return _buildOfferCard(context, offer);
      },
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
