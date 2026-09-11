// Create Property Request Screen for Buyers

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/validators.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({Key? key}) : super(key: key);

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  final _imagePicker = ImagePicker();
  final _locationService = LocationService();

  String _selectedCategory = 'residential';
  bool _isUrgent = false;
  bool _isLoading = false;

  final List<XFile> _photos = [];
  Coordinates? _coordinates;

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

  Future<void> _pickPhotos() async {
    try {
      final picked = await _imagePicker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() => _photos.addAll(picked));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصور: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _pickLocation() async {
    try {
      final coordinates = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _coordinates = coordinates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديد الموقع: $e')),
        );
      }
    }
  }

  Future<void> _handleCreateRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = SupabaseService();
      final request = await service.createPropertyRequest(
        category: _selectedCategory,
        title: _titleController.text.trim(),
        city: _cityController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        latitude: _coordinates?.latitude,
        longitude: _coordinates?.longitude,
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
        isUrgent: _isUrgent,
      );

      for (var i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        final bytes = await photo.readAsBytes();
        await service.uploadPropertyPhoto(
          requestId: request.id,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          fileBytes: Uint8List.fromList(bytes),
        );
      }

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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  hintText: 'دبي، أبو ظبي، إلخ',
                  label: Text('المدينة *'),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) =>
                    Validators.required(value, field: 'المدينة'),
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
                const SizedBox(height: 16),
              ],
              // Location Picker
              Text(
                'الموقع',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickLocation,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _coordinates == null
                      ? 'تحديد موقعي الحالي'
                      : 'تم تحديد الموقع (${_coordinates!.latitude.toStringAsFixed(4)}, ${_coordinates!.longitude.toStringAsFixed(4)})',
                ),
              ),
              const SizedBox(height: 24),
              // Photos
              Text(
                'صور العقار',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (_photos.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _photos.length; i++)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _photos[i].path,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 96,
                                height: 96,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _removePhoto(i),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickPhotos,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('إضافة صور'),
              ),
              const SizedBox(height: 24),
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
