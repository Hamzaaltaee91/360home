// Browse Requests Screen for Realtors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({Key? key}) : super(key: key);

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen> {
  late Future<List<PropertyRequest>> _requestsFuture;
  String _selectedCategory = 'all';
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = _fetchRequests();
  }

  Future<List<PropertyRequest>> _fetchRequests() async {
    try {
      // For now, fetch all active requests
      // In production, this could use the search-requests edge function
      final response = await SupabaseService().client
          .from('property_requests')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((e) => PropertyRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  List<PropertyRequest> _filterRequests(List<PropertyRequest> requests) {
    var filtered = requests;

    if (_selectedCategory != 'all') {
      filtered =
          filtered.where((r) => r.category == _selectedCategory).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price_high':
        filtered.sort((a, b) =>
            (b.maxPrice ?? 0).compareTo(a.maxPrice ?? 0));
        break;
      case 'price_low':
        filtered.sort((a, b) =>
            (a.minPrice ?? 0).compareTo(b.minPrice ?? 0));
        break;
      case 'urgent':
        filtered.sort((a, b) => (b.isUrgent ? 1 : 0).compareTo(a.isUrgent ? 1 : 0));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات المشترين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and Sort
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('الكل', 'all'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('سكني', 'residential'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('تجاري', 'commercial'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('أراضي', 'land'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Sort dropdown
                DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('الأحدث')),
                    DropdownMenuItem(value: 'urgent', child: Text('الطلبات العاجلة')),
                    DropdownMenuItem(value: 'price_high', child: Text('أعلى سعر')),
                    DropdownMenuItem(value: 'price_low', child: Text('أقل سعر')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                    }
                  },
                ),
              ],
            ),
          ),
          // Requests List
          Expanded(
            child: FutureBuilder<List<PropertyRequest>>(
              future: _requestsFuture,
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
                          onPressed: () => setState(() => _loadRequests()),
                          child: const Text('إعادة محاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final allRequests = snapshot.data ?? [];
                final filteredRequests = _filterRequests(allRequests);

                if (filteredRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات متاحة',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جرب تغيير معايير البحث',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    return _buildRequestCard(context, request);
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
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
        onTap: (index) {
          if (index == 0) context.go('/realtor-home');
          if (index == 2) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = value);
      },
      backgroundColor:
          isSelected ? Colors.indigo.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, PropertyRequest request) {
    final categoryLabel = _getCategoryLabel(request.category);
    final daysAgo = DateTime.now().difference(request.createdAt).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/create-offer/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.city,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Chip(
                        label: Text(categoryLabel),
                        backgroundColor: Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11,
                        ),
                      ),
                      if (request.isUrgent) ...[
                        const SizedBox(height: 4),
                        Chip(
                          label: const Text('عاجل'),
                          backgroundColor: Colors.red.shade100,
                          labelStyle: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Budget and specs
              Row(
                children: [
                  if (request.minPrice != null && request.maxPrice != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الميزانية',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${request.minPrice?.toStringAsFixed(0)} - ${request.maxPrice?.toStringAsFixed(0)} ${request.currency}',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Property requirements
              if (request.bedrooms != null ||
                  request.bathrooms != null ||
                  request.minAreaSqft != null)
                Wrap(
                  spacing: 8,
                  children: [
                    if (request.bedrooms != null)
                      _buildSpecChip(
                        icon: Icons.bed,
                        label: '${request.bedrooms} غرفة',
                      ),
                    if (request.bathrooms != null)
                      _buildSpecChip(
                        icon: Icons.bathtub,
                        label: '${request.bathrooms} حمام',
                      ),
                    if (request.minAreaSqft != null)
                      _buildSpecChip(
                        icon: Icons.square_foot,
                        label: '${request.minAreaSqft} sqft',
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              // Footer
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
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/create-offer/${request.id}'),
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء عرض'),
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

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'residential':
        return 'سكني';
      case 'commercial':
        return 'تجاري';
      case 'land':
        return 'أراضي';
      default:
        return category;
    }
  }
}
