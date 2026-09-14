import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';
import 'manage_governorate_areas_screen.dart';

/// Admin screen for managing governorates. Tapping a governorate opens its
/// areas in [ManageGovernorateAreasScreen].
class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  static const String routeName = '/admin/locations';

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _governorates = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final governorates = await _service.adminListGovernorates();

      if (!mounted) return;
      setState(() {
        _governorates = governorates;
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

  Future<void> _openEditDialog(Map<String, dynamic>? existing) async {
    final isEditing = existing != null;

    final slugController = TextEditingController(
      text: existing?['slug'] as String? ?? '',
    );
    final labelController = TextEditingController(
      text: existing?['label'] as String? ?? '',
    );
    final sortOrderController = TextEditingController(
      text: (existing?['sort_order'] as int? ?? 0).toString(),
    );

    var active = existing?['active'] as bool? ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit governorate' : 'Add governorate'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: slugController,
                      enabled: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Slug',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sortOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sort order',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: active,
                      onChanged: (v) => setDialogState(() => active = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final slug = slugController.text.trim();
    final label = labelController.text.trim();
    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;

    if (slug.isEmpty || label.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slug and label are required')),
      );
      return;
    }

    try {
      await _service.adminUpsertGovernorate(
        slug: slug,
        label: label,
        sortOrder: sortOrder,
        active: active,
      );
      await _loadGovernorates();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupabaseErrorHandler.handle(e).message)),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final slug = row['slug'] as String? ?? '';
    final label = row['label'] as String? ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete governorate'),
        content: Text('Delete "$label" ($slug)?'),
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
      await _service.adminDeleteGovernorate(slug);
      await _loadGovernorates();
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
      appBar: AppBar(title: const Text('Manage Locations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditDialog(null),
        tooltip: 'Add governorate',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
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
              onPressed: _loadGovernorates,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_governorates.isEmpty) {
      return const Center(child: Text('No governorates found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadGovernorates,
      child: ListView.separated(
        itemCount: _governorates.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = _governorates[index];
          final slug = row['slug'] as String? ?? '';
          final label = row['label'] as String? ?? '';
          final sortOrder = row['sort_order'] as int? ?? 0;
          final active = row['active'] as bool? ?? true;
          return ListTile(
            title: Text(label),
            subtitle: Text(
              'Slug: $slug · Sort order: $sortOrder'
              '${active ? '' : ' · Inactive'}',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ManageGovernorateAreasScreen(
                  governorateSlug: slug,
                  governorateLabel: label,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openEditDialog(row),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(row),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
