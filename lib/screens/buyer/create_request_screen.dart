// Create Property Request Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({Key? key}) : super(key: key);

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  String _selectedCategory = 'residential';
  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRequest() async {
    if (_titleController.text.isEmpty || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService().createPropertyRequest(
        category: _selectedCategory,
        title: _titleController.text,
        city: _cityController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        minPrice: _minPriceController.text.isNotEmpty
            ? double.parse(_minPriceController.text)
            : null,
        maxPrice: _maxPriceController.text.isNotEmpty
            ? double.parse(_maxPriceController.text)
            : null,
        bedrooms: _bedroomsController.text.isNotEmpty
            ? int.parse(_bedroomsController.text)
            : null,
        bathrooms: _bathroomsController.text.isNotEmpty
            ? int.parse(_bathroomsController.text)
            : null,
        isUrgent: _isUrgent,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الطلب بنجاح')),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب عقار جديد')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              Text(
                'نوع العقار',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'residential',
                    label: Text('سكني'),
                  ),
                  ButtonSegment(
                    value: 'commercial',
                    label: Text('تجاري'),
                  ),
                  ButtonSegment(
                    value: 'land',
                    label: Text('أراضي'),
                  ),
                ],
                selected: {_selectedCategory},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedCategory = newSelection.first);
                },
              ),
              const SizedBox(height: 24),
              // Basic Information
              Text(
                'المعلومات الأساسية',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'مثال: شقة 2 غرفة في دبي',
                  label: Text('عنوان الطلب *'),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  hintText: 'دبي، أبو ظبي، إلخ',
                  label: Text('المدينة *'),
                  prefixIcon: Icon(Icons.location_on),
                ),
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
              // Budget
              Text(
                'الميزانية',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      decoration: const InputDecoration(
                        hintText: '0',
                        label: Text('الحد الأدنى'),
                        prefixIcon: Icon(Icons.money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      decoration: const InputDecoration(
                        hintText: '0',
                        label: Text('الحد الأقصى'),
                        prefixIcon: Icon(Icons.money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Property Specifications
              if (_selectedCategory == 'residential') ...[
                Text(
                  'المواصفات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bedroomsController,
                        decoration: const InputDecoration(
                          hintText: '0',
                          label: Text('عدد الغرف'),
                          prefixIcon: Icon(Icons.bed),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _bathroomsController,
                        decoration: const InputDecoration(
                          hintText: '0',
                          label: Text('عدد الحمامات'),
                          prefixIcon: Icon(Icons.bathtub),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // Urgent Flag
              CheckboxListTile(
                title: const Text('هذا طلب عاجل'),
                subtitle: const Text('سيظهر الطلب بأولوية عالية'),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() => _isUrgent = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateRequest,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('إنشاء الطلب'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
