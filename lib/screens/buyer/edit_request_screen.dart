// Edit Property Request Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/validators.dart';

class EditRequestScreen extends StatefulWidget {
  const EditRequestScreen({Key? key, required this.requestId})
      : super(key: key);

  final String requestId;

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final request =
          await SupabaseService().getPropertyRequest(widget.requestId);
      if (!mounted) return;
      _populate(request);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر تحميل الطلب: $e';
        _isLoading = false;
      });
    }
  }

  void _populate(PropertyRequest request) {
    _titleController.text = request.title;
    _descriptionController.text = request.description ?? '';
    _minPriceController.text = request.minPrice?.toString() ?? '';
    _maxPriceController.text = request.maxPrice?.toString() ?? '';
    _bedroomsController.text = request.bedrooms?.toString() ?? '';
    _bathroomsController.text = request.bathrooms?.toString() ?? '';
    _status = request.status;
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await SupabaseService().updatePropertyRequest(
        requestId: widget.requestId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        status: _status,
        minPrice: _minPriceController.text.trim().isNotEmpty
            ? double.parse(_minPriceController.text.trim())
            : null,
        maxPrice: _maxPriceController.text.trim().isNotEmpty
            ? double.parse(_maxPriceController.text.trim())
            : null,
        bedrooms: _bedroomsController.text.trim().isNotEmpty
            ? int.parse(_bedroomsController.text.trim())
            : null,
        bathrooms: _bathroomsController.text.trim().isNotEmpty
            ? int.parse(_bathroomsController.text.trim())
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الطلب بنجاح')),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/buyer-home');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الطلب')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRequest,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المعلومات الأساسية',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'مثال: شقة 2 غرفة في دبي',
                label: Text('عنوان الطلب *'),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) =>
                  Validators.required(value, field: 'عنوان الطلب'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'أضف تفاصيل إضافية عن احتياجاتك',
                label: Text('الوصف'),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'الميزانية',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPriceController,
                    decoration: const InputDecoration(
                      hintText: '0',
                      label: Text('الحد الأدنى'),
                      prefixIcon: Icon(Icons.money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? null
                        : Validators.price(value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxPriceController,
                    decoration: const InputDecoration(
                      hintText: '0',
                      label: Text('الحد الأقصى'),
                      prefixIcon: Icon(Icons.money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? null
                        : Validators.price(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'المواصفات',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedroomsController,
                    decoration: const InputDecoration(
                      hintText: '0',
                      label: Text('عدد الغرف'),
                      prefixIcon: Icon(Icons.bed),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? null
                            : (int.tryParse(value.trim()) == null
                                ? 'أدخل رقماً صحيحاً'
                                : null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    decoration: const InputDecoration(
                      hintText: '0',
                      label: Text('عدد الحمامات'),
                      prefixIcon: Icon(Icons.bathtub),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? null
                            : (int.tryParse(value.trim()) == null
                                ? 'أدخل رقماً صحيحاً'
                                : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'حالة الطلب',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'active', label: Text('نشط')),
                ButtonSegment(value: 'closed', label: Text('مغلق')),
              ],
              selected: {_status},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _status = newSelection.first);
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('حفظ التعديلات'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
