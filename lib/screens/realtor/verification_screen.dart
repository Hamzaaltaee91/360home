// Realtor Verification Screen - Document Submission

import 'package:flutter/material.dart';

import '../../models/realtor_verification.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/validators.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final SupabaseService _supabase = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _documentUrlController = TextEditingController();

  late Future<RealtorVerification?> _verificationFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _verificationFuture = _supabase.getMyVerification();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _documentUrlController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _verificationFuture = _supabase.getMyVerification());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _supabase.submitVerification(
        licenseNumber: _licenseController.text.trim(),
        documentUrl: _documentUrlController.text.trim(),
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
              'يرجى إدخال رقم الترخيص ورابط مستند التوثيق.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
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
            TextFormField(
              controller: _documentUrlController,
              decoration: const InputDecoration(
                labelText: 'رابط مستند التوثيق',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.required(value, field: 'رابط المستند'),
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
