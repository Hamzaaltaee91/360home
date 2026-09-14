// Browse Requests Screen for Realtors

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../models/models.dart';
import '../../utils/iraq_locations.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({Key? key}) : super(key: key);

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen> {
  final ScrollController _scrollController = ScrollController();

  /// All requests loaded so far, accumulated across pages.
  final List<PropertyRequest> _requests = [];

  /// Whether the initial page is still loading.
  bool _isLoading = true;

  /// Whether a subsequent page is currently loading.
  bool _isLoadingMore = false;

  /// Whether the backend may have more pages.
  bool _hasMore = true;

  /// Error from the most recent load attempt, if any.
  Object? _error;

  /// Page size used when fetching requests.
  static const int _pageSize = 20;

  String _selectedCategory = 'all';
  String _selectedPurpose = 'all';
  String _selectedGovernorate = 'all';
  String _sortBy = 'recent';

  /// Whether the map view is shown instead of the list view.
  bool _showMap = false;

  /// Radius (in km) used by the "near me" filter. `null` disables it.
  double? _radiusKm;

  /// The device location captured for the "near me" filter.
  Coordinates? _userLocation;

  /// Whether a location lookup is currently in progress.
  bool _isLocating = false;

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadRequests();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasMore = true;
      _requests.clear();
    });

    try {
      final page = await SupabaseService().getActiveRequests(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _requests.addAll(page.items);
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

  /// Appends the next page of requests, if any remain.
  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final page = await SupabaseService().getActiveRequests(
        limit: _pageSize,
        offset: _requests.length,
      );
      if (!mounted) return;
      setState(() {
        _requests.addAll(page.items);
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

  /// Prompts for the device location and enables the radius filter.
  Future<void> _enableNearMeFilter() async {
    setState(() => _isLocating = true);
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _radiusKm ??= 10;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديد الموقع: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Clears the "near me" filter.
  void _clearNearMeFilter() {
    setState(() {
      _userLocation = null;
      _radiusKm = null;
    });
  }

  List<PropertyRequest> _filterRequests(List<PropertyRequest> requests) {
    var filtered = requests;

    if (_selectedCategory != 'all') {
      filtered =
          filtered.where((r) => r.category == _selectedCategory).toList();
    }

    if (_selectedPurpose != 'all') {
      filtered =
          filtered.where((r) => r.purpose == _selectedPurpose).toList();
    }

    if (_selectedGovernorate != 'all') {
      filtered = filtered
          .where((r) => r.governorate == _selectedGovernorate)
          .toList();
    }

    // Radius filter: only keep requests with coordinates within range.
    final userLocation = _userLocation;
    final radiusKm = _radiusKm;
    if (userLocation != null && radiusKm != null) {
      filtered = filtered.where((r) {
        if (r.latitude == null || r.longitude == null) return false;
        return _locationService.isWithinRadius(
          center: userLocation,
          point: Coordinates(r.latitude!, r.longitude!),
          radiusKm: radiusKm,
        );
      }).toList();
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
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'عرض القائمة' : 'عرض الخريطة',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
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
                // Purpose + governorate filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedPurpose,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('الغرض: الكل')),
                          DropdownMenuItem(value: 'buy', child: Text('شراء')),
                          DropdownMenuItem(value: 'rent', child: Text('إيجار')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPurpose = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedGovernorate,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('المحافظة: الكل'),
                          ),
                          ...iraqLocations.entries.map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value['label'] as String),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedGovernorate = value);
                          }
                        },
                      ),
                    ),
                  ],
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
                const SizedBox(height: 12),
                // Near-me radius filter
                _buildNearMeFilter(),
              ],
            ),
          ),
          // Requests List
          Expanded(child: _buildRequestsBody()),
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

  Widget _buildRequestsBody() {
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
              onPressed: _loadRequests,
              child: const Text('إعادة محاولة'),
            ),
          ],
        ),
      );
    }

    final filteredRequests = _filterRequests(_requests);

    if (_showMap) {
      return _buildMapView(filteredRequests);
    }

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
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredRequests.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filteredRequests.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final request = filteredRequests[index];
        return _buildRequestCard(context, request);
      },
    );
  }

  Widget _buildNearMeFilter() {
    final isActive = _userLocation != null && _radiusKm != null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLocating
                ? null
                : (isActive ? _clearNearMeFilter : _enableNearMeFilter),
            icon: _isLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isActive ? Icons.location_off : Icons.my_location),
            label: Text(isActive ? 'إلغاء القريب مني' : 'القريب مني'),
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<double>(
              value: _radiusKm,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 5, child: Text('٥ كم')),
                DropdownMenuItem(value: 10, child: Text('١٠ كم')),
                DropdownMenuItem(value: 25, child: Text('٢٥ كم')),
                DropdownMenuItem(value: 50, child: Text('٥٠ كم')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _radiusKm = value);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMapView(List<PropertyRequest> requests) {
    final located = requests
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    if (located.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات بموقع محدد',
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

    final center = _userLocation != null
        ? LatLng(_userLocation!.latitude, _userLocation!.longitude)
        : LatLng(located.first.latitude!, located.first.longitude!);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dabberli.app',
        ),
        MarkerLayer(
          markers: [
            if (_userLocation != null)
              Marker(
                point: LatLng(
                  _userLocation!.latitude,
                  _userLocation!.longitude,
                ),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
            for (final request in located)
              Marker(
                point: LatLng(request.latitude!, request.longitude!),
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => context.push('/create-offer/${request.id}'),
                  child: Tooltip(
                    message: request.title,
                    child: Icon(
                      Icons.location_on,
                      color: request.isUrgent
                          ? Colors.red.shade700
                          : Colors.indigo.shade700,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
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
        onTap: () => context.push('/create-offer/${request.id}'),
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
                        if (request.purpose != null ||
                            request.governorate != null) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (request.purpose != null)
                                _buildSpecChip(
                                  icon: Icons.sell,
                                  label: request.purpose == 'rent'
                                      ? 'إيجار'
                                      : 'شراء',
                                ),
                              if (request.governorate != null)
                                _buildSpecChip(
                                  icon: Icons.map,
                                  label: iraqLocations[request.governorate]
                                          ?['label'] as String? ??
                                      request.governorate!,
                                ),
                            ],
                          ),
                        ],
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
                        context.push('/create-offer/${request.id}'),
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
