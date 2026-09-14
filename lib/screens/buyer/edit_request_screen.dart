// Edit Property Request Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/iraq_locations.dart';
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
  final _areaOtherController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String _status = 'active';
  String _category = 'residential';
  String _selectedPurpose = 'buy';
  String? _selectedGovernorate;
  String? _selectedArea;
  String? _selectedPropertySubtype;
  String? _selectedRentalPeriod;

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
    _areaOtherController.dispose();
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
    _category = request.category;
    _selectedPurpose = request.purpose ?? 'buy';
    _selectedGovernorate = request.governorate;
    _selectedPropertySubtype = request.propertySubtype;
    _selectedRentalPeriod = request.rentalPeriod;

    final areas = _areaOptionsFor(request.governorate);
    final knownValues = areas.map((a) => a['value'] as String).toSet();
    if (request.area != null && knownValues.contains(request.area)) {
      _selectedArea = request.area;
    } else if (request.area != null) {
      _selectedArea = 'other';
      _areaOtherController.text = request.area!;
    }
  }

  List<Map> _areaOptionsFor(String? governorate) {
    if (governorate == null || iraqLocations[governorate] == null) {
      return const <Map>[];
    }
    return (iraqLocations[governorate]!['areas'] as List).cast<Map>();
  }

  List<Map> get _areaOptions => _areaOptionsFor(_selectedGovernorate);

  void _onGovernorateChanged(String? value) {
    setState(() {
      _selectedGovernorate = value;
      _selectedArea = null;
      _areaOtherController.clear();
    });
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
        purpose: _selectedPurpose,
        governorate: _selectedGovernorate,
        area: _selectedArea == 'other'
            ? _areaOtherController.text.trim()
            : _selectedArea,
        propertySubtype:
            _category == 'residential' ? _selectedPropertySubtype : null,
        rentalPeriod:
            _selectedPurpose == 'rent' ? _selectedRentalPeriod : null,
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
            const SizedBox(height: 24),
            Text(
              'الغرض',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'buy', label: Text('شراء')),
                ButtonSegment(value: 'rent', label: Text('إيجار')),
              ],
              selected: {_selectedPurpose},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedPurpose = newSelection.first);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGovernorate,
              decoration: const InputDecoration(
                labelText: 'المحافظة *',
                prefixIcon: Icon(Icons.map),
              ),
              items: iraqLocations.entries
                  .map<DropdownMenuItem<String>>((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value['label'] as String),
                      ))
                  .toList(),
              onChanged: _isSaving ? null : _onGovernorateChanged,
              validator: (value) =>
                  Validators.required(value, field: 'المحافظة'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedArea,
              decoration: const InputDecoration(
                labelText: 'المنطقة *',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _areaOptions
                  .map<DropdownMenuItem<String>>((a) => DropdownMenuItem<String>(
                        value: a['value'] as String,
                        child: Text(a['label'] as String),
                      ))
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedArea = value;
                        if (value != 'other') {
                          _areaOtherController.clear();
                        }
                      });
                    },
              validator: (value) =>
                  Validators.required(value, field: 'المنطقة'),
            ),
            if (_selectedArea == 'other') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaOtherController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنطقة *',
                  prefixIcon: Icon(Icons.edit_location),
                ),
                validator: (value) =>
                    Validators.required(value, field: 'اسم المنطقة'),
              ),
            ],
            if (_selectedPurpose == 'rent') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRentalPeriod,
                decoration: const InputDecoration(
                  labelText: 'مدة الإيجار *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('يومي')),
                  DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                  DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                  DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) =>
                        setState(() => _selectedRentalPeriod = value),
                validator: (value) =>
                    Validators.required(value, field: 'مدة الإيجار'),
              ),
            ],
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
            if (_category == 'residential') ...[
              DropdownButtonFormField<String>(
                value: _selectedPropertySubtype,
                decoration: const InputDecoration(
                  labelText: 'نوع العقار *',
                  prefixIcon: Icon(Icons.house),
                ),
                items: const [
                  DropdownMenuItem(value: 'apartment', child: Text('شقة')),
                  DropdownMenuItem(value: 'house', child: Text('بيت')),
                  DropdownMenuItem(value: 'villa', child: Text('فيلا')),
                  DropdownMenuItem(value: 'duplex', child: Text('دوبلكس')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) =>
                        setState(() => _selectedPropertySubtype = value),
                validator: (value) =>
                    Validators.required(value, field: 'نوع العقار'),
              ),
              const SizedBox(height: 16),
            ],
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
