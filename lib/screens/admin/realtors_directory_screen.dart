import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen listing every realtor with their linked user profile.
///
/// Read-only: no role or verification field is ever modified here.
class RealtorsDirectoryScreen extends StatefulWidget {
  const RealtorsDirectoryScreen({super.key});

  static const String routeName = '/admin/realtors-directory';

  @override
  State<RealtorsDirectoryScreen> createState() =>
      _RealtorsDirectoryScreenState();
}

class _RealtorsDirectoryScreenState extends State<RealtorsDirectoryScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  static const Duration _searchDebounce = Duration(milliseconds: 300);
  Timer? _debounce;

  List<Map<String, dynamic>> _realtors = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRealtors();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, _loadRealtors);
  }

  Future<void> _loadRealtors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final search = _searchController.text.trim();
      final realtors = await _service.adminListRealtors(
        searchText: search.isEmpty ? null : search,
      );

      if (!mounted) return;
      setState(() {
        _realtors = realtors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = SupabaseErrorHandler.handle(e).message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtors Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRealtors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _loadRealtors(),
              decoration: InputDecoration(
                hintText: 'Search by company name or license number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadRealtors();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadRealtors,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_realtors.isEmpty) {
      return const Center(child: Text('No realtors found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRealtors,
      child: ListView.builder(
        itemCount: _realtors.length,
        itemBuilder: (context, index) => _buildRealtorCard(_realtors[index]),
      ),
    );
  }

  Widget _buildRealtorCard(Map<String, dynamic> realtor) {
    final user = (realtor['user'] as Map?)?.cast<String, dynamic>();
    final fullName = (user?['full_name'] as String?) ?? 'Unknown realtor';
    final email = (user?['email'] as String?) ?? '';
    final isVerified = (user?['is_verified'] as bool?) ?? false;

    final companyName = realtor['company_name'] as String?;
    final licenseNumber = realtor['license_number'] as String?;
    final licenseExpiry = realtor['license_expiry'] as String?;
    final averageRating = (realtor['average_rating'] as num?)?.toDouble();
    final totalOffers = realtor['total_offers'] as int?;

    final ratingText =
        averageRating != null ? averageRating.toStringAsFixed(1) : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (isVerified)
                        const Icon(
                          Icons.verified,
                          size: 18,
                          color: Colors.blue,
                          semanticLabel: 'Verified',
                        ),
                    ],
                  ),
                  if (email.isNotEmpty) Text(email),
                  if (companyName != null && companyName.isNotEmpty)
                    Text('Company: $companyName'),
                  if (licenseNumber != null && licenseNumber.isNotEmpty)
                    Text('License: $licenseNumber'),
                  if (licenseExpiry != null && licenseExpiry.isNotEmpty)
                    Text('Expires: $licenseExpiry'),
                  Text('Rating: $ratingText  •  Offers: ${totalOffers ?? 0}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
