import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for managing the areas of a single governorate.
class ManageGovernorateAreasScreen extends StatefulWidget {
  const ManageGovernorateAreasScreen({
    super.key,
    required this.governorateSlug,
    required this.governorateLabel,
  });

  final String governorateSlug;
  final String governorateLabel;

  @override
  State<ManageGovernorateAreasScreen> createState() =>
      _ManageGovernorateAreasScreenState();
}

class _ManageGovernorateAreasScreenState
    extends State<ManageGovernorateAreasScreen> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _areas = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final areas = await _service.adminListAreas(widget.governorateSlug);

      if (!mounted) return;
      setState(() {
        _areas = areas;
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

    final valueController = TextEditingController(
      text: existing?['value'] as String? ?? '',
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
              title: Text(isEditing ? 'Edit area' : 'Add area'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
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

    final value = valueController.text.trim();
    final label = labelController.text.trim();
    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;

    if (value.isEmpty || label.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Value and label are required')),
      );
      return;
    }

    try {
      await _service.adminUpsertArea(
        id: existing?['id'] as String?,
        governorateSlug: widget.governorateSlug,
        value: value,
        label: label,
        sortOrder: sortOrder,
        active: active,
      );
      await _loadAreas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupabaseErrorHandler.handle(e).message)),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final id = row['id'] as String? ?? '';
    final label = row['label'] as String? ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete area'),
        content: Text('Delete "$label"?'),
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
      await _service.adminDeleteArea(id);
      await _loadAreas();
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
      appBar: AppBar(title: Text(widget.governorateLabel)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditDialog(null),
        tooltip: 'Add area',
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
              onPressed: _loadAreas,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_areas.isEmpty) {
      return const Center(child: Text('No areas found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadAreas,
      child: ListView.separated(
        itemCount: _areas.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = _areas[index];
          final value = row['value'] as String? ?? '';
          final label = row['label'] as String? ?? '';
          final sortOrder = row['sort_order'] as int? ?? 0;
          final active = row['active'] as bool? ?? true;
          return ListTile(
            title: Text(label),
            subtitle: Text(
              'Value: $value · Sort order: $sortOrder'
              '${active ? '' : ' · Inactive'}',
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
