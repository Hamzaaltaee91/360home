import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for managing reference list options (categories, purposes,
/// rental periods, currencies).
class ManageListsScreen extends StatefulWidget {
  const ManageListsScreen({super.key});

  static const String routeName = '/admin/lists';

  @override
  State<ManageListsScreen> createState() => _ManageListsScreenState();
}

class _ManageListsScreenState extends State<ManageListsScreen> {
  static const List<String> _listNames = [
    'category',
    'purpose',
    'rental_period',
    'currency',
  ];

  final SupabaseService _service = SupabaseService();

  String _selectedList = _listNames.first;
  List<Map<String, dynamic>> _options = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final options = await _service.getListOptions(_selectedList);

      if (!mounted) return;
      setState(() {
        _options = options;
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

    final codeController = TextEditingController(
      text: existing?['code'] as String? ?? '',
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
              title: Text(isEditing ? 'Edit option' : 'Add option'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      enabled: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Code',
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

    final code = codeController.text.trim();
    final label = labelController.text.trim();
    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;

    if (code.isEmpty || label.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code and label are required')),
      );
      return;
    }

    try {
      await _service.adminUpsertListOption(
        listName: _selectedList,
        code: code,
        label: label,
        sortOrder: sortOrder,
        active: active,
      );
      await _loadOptions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupabaseErrorHandler.handle(e).message)),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final code = row['code'] as String? ?? '';
    final label = row['label'] as String? ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete option'),
        content: Text('Delete "$label" ($code)?'),
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
      await _service.adminDeleteListOption(_selectedList, code);
      await _loadOptions();
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
      appBar: AppBar(title: const Text('Manage Lists')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditDialog(null),
        tooltip: 'Add option',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('List:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedList,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedList = value);
                    _loadOptions();
                  },
                  items: _listNames
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
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
              onPressed: _loadOptions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_options.isEmpty) {
      return const Center(child: Text('No items found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadOptions,
      child: ListView.separated(
        itemCount: _options.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = _options[index];
          final code = row['code'] as String? ?? '';
          final label = row['label'] as String? ?? '';
          final sortOrder = row['sort_order'] as int? ?? 0;
          return ListTile(
            title: Text(label),
            subtitle: Text('Code: $code · Sort order: $sortOrder'),
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
