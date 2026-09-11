// Create Offer Screen for Realtors

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../models/models.dart';
import '../../utils/validators.dart';

class CreateOfferScreen extends StatefulWidget {
  final String requestId;

  const CreateOfferScreen({Key? key, required this.requestId})
      : super(key: key);

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  late Future<PropertyRequest> _requestFuture;

  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();

  String _leaseType = 'sale';
  int _durationMonths = 12;
  bool _furnished = false;
  bool _isLoading = false;

  final _imagePicker = ImagePicker();
  final _locationService = LocationService();

  /// Photos selected by the realtor, kept in memory until the offer is
  /// submitted and uploaded to storage.
  final List<_PickedPhoto> _photos = [];

  /// Location captured for the offered property, if any.
  Coordinates? _coordinates;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _requestFuture = _fetchRequest();
  }

  Future<PropertyRequest> _fetchRequest() async {
    final response = await SupabaseService().client
        .from('property_requests')
        .select()
        .eq('id', widget.requestId)
        .single();

    return PropertyRequest.fromJson(response);
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await _imagePicker.pickMultiImage();
      if (picked.isEmpty) return;

      final added = <_PickedPhoto>[];
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        added.add(_PickedPhoto(name: file.name, bytes: bytes));
      }

      if (!mounted) return;
      setState(() => _photos.addAll(added));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصور: $e')),
        );
      }
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isLocating = true);
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
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<List<String>> _uploadPhotos() async {
    final urls = <String>[];
    for (var i = 0; i < _photos.length; i++) {
      final photo = _photos[i];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$i_${photo.name}';
      final url = await SupabaseService().uploadPropertyPhoto(
        requestId: widget.requestId,
        fileName: fileName,
        fileBytes: photo.bytes,
      );
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submitOffer(PropertyRequest request) async {
    final titleError = Validators.required(_titleController.text,
        field: 'اسم العقار');
    final addressError = Validators.required(_addressController.text,
        field: 'العنوان');
    final priceError = Validators.price(_priceController.text);

    final error = titleError ?? addressError ?? priceError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text.trim());
      final photoUrls = await _uploadPhotos();

      await SupabaseService().createOffer(
        requestId: widget.requestId,
        propertyTitle: _titleController.text.trim(),
        propertyAddress: _addressController.text.trim(),
        offeredPrice: price,
        propertyDescription: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        latitude: _coordinates?.latitude,
        longitude: _coordinates?.longitude,
        leaseType: _leaseType,
        leaseDurationMonths: _leaseType == 'rent' ? _durationMonths : null,
        areaSqft: _areaController.text.isNotEmpty
            ? int.parse(_areaController.text)
            : null,
        bedrooms: _bedroomsController.text.isNotEmpty
            ? int.parse(_bedroomsController.text)
            : null,
        bathrooms: _bathroomsController.text.isNotEmpty
            ? int.parse(_bathroomsController.text)
            : null,
        furnished: _furnished,
        photoUrls: photoUrls.isEmpty ? null : photoUrls,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال العرض بنجاح')),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/realtor-home');
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
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء عرض جديد'),
      ),
      body: FutureBuilder<PropertyRequest>(
        future: _requestFuture,
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
                    onPressed: () {
                      setState(() {
                        _requestFuture = _fetchRequest();
                      });
                    },
                    child: const Text('إعادة محاولة'),
                  ),
                ],
              ),
            );
          }

          final request = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الطلب المطابق:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.city} • ${_getCategoryLabel(request.category)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Property Details Form
                  Text(
                    'بيانات العقار',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'اسم العقار',
                      prefixIcon: Icon(Icons.home),
                      label: Text('اسم العقار *'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Address
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'العنوان الكامل',
                      prefixIcon: Icon(Icons.location_on),
                      label: Text('العنوان الكامل *'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price and Lease Type
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.money),
                            label: Text('السعر المقترح *'),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _leaseType,
                          items: const [
                            DropdownMenuItem(value: 'sale', child: Text('بيع')),
                            DropdownMenuItem(value: 'rent', child: Text('إيجار')),
                          ],
                          onChanged: (value) {
                            setState(() => _leaseType = value ?? 'sale');
                          },
                          decoration: const InputDecoration(
                            label: Text('النوع'),
                            prefixIcon: Icon(Icons.real_estate_agent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Lease Duration (for rent)
                  if (_leaseType == 'rent') ...[
                    TextField(
                      decoration: InputDecoration(
                        label: const Text('مدة الإيجار (بالأشهر)'),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixText: 'شهر',
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _durationMonths.toString(),
                      onChanged: (value) {
                        _durationMonths = int.tryParse(value) ?? 12;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'وصف العقار والمميزات',
                      prefixIcon: Icon(Icons.description),
                      label: Text('الوصف'),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  // Property Specifications
                  Text(
                    'المواصفات',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bedroomsController,
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.bed),
                            label: Text('الغرف'),
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
                            prefixIcon: Icon(Icons.bathtub),
                            label: Text('الحمامات'),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _areaController,
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.square_foot),
                            label: Text('المساحة (sqft)'),
                            suffixText: 'sqft',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('مفروش'),
                          value: _furnished,
                          onChanged: (value) {
                            setState(() => _furnished = value ?? false);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Photos
                  Text(
                    'صور العقار',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_photos.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final photo = _photos[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  Uint8List.fromList(photo.bytes),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() => _photos.removeAt(index));
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickPhotos,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('إضافة صور'),
                  ),
                  const SizedBox(height: 24),
                  // Location
                  Text(
                    'موقع العقار',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_coordinates != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Colors.green),
                      title: Text(
                        '${_coordinates!.latitude.toStringAsFixed(5)}, '
                        '${_coordinates!.longitude.toStringAsFixed(5)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _coordinates = null),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: (_isLoading || _isLocating) ? null : _captureLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _coordinates == null
                          ? 'تحديد الموقع الحالي'
                          : 'تحديث الموقع',
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _submitOffer(request),
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
                          : const Text('إرسال العرض'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
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

/// A photo selected by the realtor, held in memory until upload.
class _PickedPhoto {
  const _PickedPhoto({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}
