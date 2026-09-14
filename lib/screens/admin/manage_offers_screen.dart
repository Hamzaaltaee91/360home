import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for browsing and moderating realtor offers.
class ManageOffersScreen extends StatefulWidget {
  const ManageOffersScreen({super.key});

  static const String routeName = '/admin/offers';

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _offers = const [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final offers = await _service.adminListRealtorOffers(
        statusFilter: _statusFilter == 'all' ? null : _statusFilter,
      );

      if (!mounted) return;
      setState(() {
        _offers = offers;
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

  Future<void> _deleteOffer(Map<String, dynamic> offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete offer'),
        content: Text(
          'Delete the offer "${offer['property_title'] ?? ''}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.adminDeleteRealtorOffer(offer['id'] as String);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer deleted.')),
      );
      await _loadOffers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupabaseErrorHandler.handle(e).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOffers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _statusFilter = value);
                    _loadOffers();
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'accepted',
                      child: Text('Accepted'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'expired',
                      child: Text('Expired'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
              onPressed: _loadOffers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_offers.isEmpty) {
      return const Center(child: Text('No offers found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadOffers,
      child: ListView.separated(
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          final realtor = offer['realtor'] as Map?;
          final realtorName =
              (realtor?['full_name'] as String?) ?? 'Unknown realtor';

          return ListTile(
            title: Text('${offer['property_title'] ?? ''}'),
            subtitle: Text(
              '$realtorName\n'
              '${offer['offered_price'] ?? ''} ${offer['currency'] ?? ''} • '
              'Status: ${offer['status'] ?? ''}\n'
              '${offer['created_at'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete offer',
              onPressed: () => _deleteOffer(offer),
            ),
          );
        },
      ),
    );
  }
}
