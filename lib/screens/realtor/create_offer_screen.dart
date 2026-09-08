// Create Offer Screen for Realtors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

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

  Future<void> _submitOffer(PropertyRequest request) async {
    if (_titleController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = double.parse(_priceController.text);

      await SupabaseService().createOffer(
        requestId: widget.requestId,
        propertyTitle: _titleController.text,
        propertyAddress: _addressController.text,
        offeredPrice: price,
        propertyDescription: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
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
