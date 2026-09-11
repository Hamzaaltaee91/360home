// Verify Email Screen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/validators.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({Key? key, this.email}) : super(key: key);

  /// Email address awaiting verification. When omitted, the signed-in user's
  /// email is used.
  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isChecking = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _emailController.text =
        widget.email ?? SupabaseService().client.auth.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResend() async {
    final email = _emailController.text.trim();
    if (Validators.email(email) != null) {
      setState(() => _errorMessage = 'أدخل بريداً إلكترونياً صالحاً');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await SupabaseService().client.auth.resend(
            type: OtpType.signup,
            email: email,
          );

      if (!mounted) return;
      setState(() => _infoMessage = 'تم إرسال رابط التحقق إلى بريدك الإلكتروني');
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'تعذر إرسال رابط التحقق: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCheckVerified() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final supabase = SupabaseService();
      final response = await supabase.client.auth.refreshSession();
      final user = response.user;

      if (user == null) {
        setState(() => _errorMessage = 'لم يتم العثور على جلسة نشطة');
        return;
      }

      if (user.emailConfirmedAt == null) {
        setState(() => _errorMessage = 'لم يتم تأكيد البريد الإلكتروني بعد');
        return;
      }

      await supabase.refreshCurrentUserRole();
      if (!mounted) return;

      final role = supabase.currentUserRole;
      context.go(role == 'realtor' ? '/realtor-home' : '/buyer-home');
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'تعذر التحقق من حالة البريد: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد البريد الإلكتروني'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.mark_email_unread,
                size: 72,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'تحقق من بريدك الإلكتروني',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'أرسلنا رابط تحقق إلى بريدك الإلكتروني. '
                'يرجى الضغط على الرابط لتفعيل حسابك ثم العودة هنا.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),
              if (_infoMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _infoMessage!,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              if (_infoMessage != null) const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: Validators.email,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _handleCheckVerified,
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('تحققت من بريدي'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleResend,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إعادة إرسال رابط التحقق'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('العودة لتسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
