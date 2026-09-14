// Realtor Verification Screen - Document Submission

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/realtor_verification.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/image_compressor.dart';
import '../../utils/validators.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final SupabaseService _supabase = SupabaseService();
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _whatsappController = TextEditingController();

  late Future<RealtorVerification?> _verificationFuture;
  bool _submitting = false;
  DateTime? _licenseExpiry;
  String? _documentFileName;
  Uint8List? _documentBytes;

  @override
  void initState() {
    super.initState();
    _verificationFuture = _supabase.getMyVerification();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _licenseController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _verificationFuture = _supabase.getMyVerification());
  }

  Future<void> _pickLicenseExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _licenseExpiry = picked);
    }
  }

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final compressed = await ImageCompressor.compress(
        Uint8List.fromList(bytes),
      );
      if (!mounted) return;
      setState(() {
        _documentFileName = picked.name;
        _documentBytes = compressed;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار المستند: $e')),
        );
      }
    }
  }

  Future<void> _showDocumentSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختر من المعرض'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقط صورة'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await _pickDocument(source);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تاريخ انتهاء الرخصة')),
      );
      return;
    }
    if (_documentBytes == null || _documentFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء رفع مستند التوثيق')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final userId = _supabase.getCurrentUserId();
      if (userId == null) {
        throw const AppException('المستخدم غير مسجل دخول');
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$_documentFileName';
      final documentPath = await _supabase.uploadVerificationDocument(
        userId: userId,
        fileName: fileName,
        fileBytes: _documentBytes!,
      );

      await _supabase.submitVerification(
        companyName: _companyNameController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        licenseExpiry: _licenseExpiry!,
        documentUrl: documentPath,
        whatsappPhone: _whatsappController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب التوثيق بنجاح')),
      );
      _reload();
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توثيق الحساب'),
        elevation: 0,
      ),
      body: FutureBuilder<RealtorVerification?>(
        future: _verificationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('خطأ: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('إعادة محاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final verification = snapshot.data;
          if (verification != null && verification.isApproved) {
            return _buildStatusView(
              icon: Icons.verified,
              color: Colors.green,
              title: 'تم توثيق حسابك',
              message: 'حسابك موثق ويمكنك الاستفادة من جميع المزايا.',
            );
          }

          if (verification != null && verification.isPending) {
            return _buildStatusView(
              icon: Icons.hourglass_top,
              color: Colors.orange,
              title: 'طلب التوثيق قيد المراجعة',
              message: 'سيتم مراجعة طلبك وإشعارك بالنتيجة قريباً.',
            );
          }

          return _buildSubmissionForm(verification);
        },
      ),
    );
  }

  Widget _buildStatusView({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm(RealtorVerification? verification) {
    final isRejected = verification != null && verification.status == 'rejected';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تم رفض طلب التوثيق',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (verification.rejectionReason != null) ...[
                      const SizedBox(height: 8),
                      Text(verification.rejectionReason!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'بيانات التوثيق',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى إدخال بيانات الشركة والترخيص ورفع مستند التوثيق.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الشركة',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.required(value, field: 'اسم الشركة'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'رقم الترخيص',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.required(value, field: 'رقم الترخيص'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickLicenseExpiry,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ انتهاء الرخصة',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _licenseExpiry == null
                      ? '— اختر التاريخ —'
                      : '${_licenseExpiry!.year}-${_licenseExpiry!.month.toString().padLeft(2, '0')}-${_licenseExpiry!.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                labelText: 'رقم الواتساب',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showDocumentSourceSheet,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'مستند التوثيق',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.upload_file_outlined),
                ),
                child: Text(
                  _documentFileName ?? '— ارفع مستند أو التقط صورة —',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إرسال طلب التوثيق'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
