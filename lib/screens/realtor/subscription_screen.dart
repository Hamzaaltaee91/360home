// Subscription Screen - Tier selection and payment checkout

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/subscription.dart';
import '../../services/payment_service.dart';
import '../../utils/error_handler.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PaymentService _payment = PaymentService();

  late Future<Subscription?> _subscriptionFuture;
  String? _processingPlanId;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _subscriptionFuture = _payment.getCurrentSubscription();
  }

  void _reload() {
    setState(() => _subscriptionFuture = _payment.getCurrentSubscription());
  }

  Future<void> _startCheckout(SubscriptionPlan plan) async {
    setState(() => _processingPlanId = plan.id);
    try {
      final url = await _payment.createCheckoutSession(
        planId: plan.id,
        successUrl: '${Uri.base.origin}/subscription?status=success',
        cancelUrl: '${Uri.base.origin}/subscription?status=cancelled',
      );

      final uri = Uri.tryParse(url);
      if (uri == null || !await launchUrl(uri)) {
        throw const AppException('تعذّر فتح صفحة الدفع');
      }
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(SupabaseErrorHandler.handle(error).message);
    } finally {
      if (mounted) setState(() => _processingPlanId = null);
    }
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isCancelling = true);
    try {
      await _payment.cancelSubscription();
      _showMessage('سيتم إلغاء الاشتراك في نهاية الفترة الحالية');
      _reload();
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(SupabaseErrorHandler.handle(error).message);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _resumeSubscription() async {
    setState(() => _isCancelling = true);
    try {
      await _payment.resumeSubscription();
      _showMessage('تم استئناف الاشتراك');
      _reload();
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(SupabaseErrorHandler.handle(error).message);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراك'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _subscriptionFuture;
        },
        child: FutureBuilder<Subscription?>(
          future: _subscriptionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildError(snapshot.error);
            }

            final subscription = snapshot.data;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (subscription != null) ...[
                  _buildCurrentSubscription(subscription),
                  const SizedBox(height: 24),
                ],
                Text(
                  'اختر الباقة المناسبة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...PaymentService.plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPlanCard(plan, subscription),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(Object? error) {
    final message = error is AppException
        ? error.message
        : SupabaseErrorHandler.handle(error ?? 'unknown').message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
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

  Widget _buildCurrentSubscription(Subscription subscription) {
    final isActive = subscription.isActive;
    final periodEnd = subscription.currentPeriodEnd;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.info_outline,
                color: isActive ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'اشتراكك الحالي: ${subscription.plan}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          if (periodEnd != null) ...[
            const SizedBox(height: 8),
            Text(
              subscription.cancelAtPeriodEnd
                  ? 'ينتهي في ${periodEnd.toLocal().toString().split(' ').first}'
                  : 'يتجدد في ${periodEnd.toLocal().toString().split(' ').first}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _isCancelling
                    ? null
                    : (subscription.cancelAtPeriodEnd
                        ? _resumeSubscription
                        : _cancelSubscription),
                child: _isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        subscription.cancelAtPeriodEnd
                            ? 'استئناف الاشتراك'
                            : 'إلغاء الاشتراك',
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, Subscription? subscription) {
    final isCurrent = subscription?.plan == plan.id && subscription!.isActive;
    final isProcessing = _processingPlanId == plan.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? Colors.indigo : Colors.grey.shade200,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${plan.price.toStringAsFixed(0)} ${plan.currency} / ${plan.interval == 'year' ? 'سنة' : 'شهر'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isCurrent || isProcessing)
                  ? null
                  : () => _startCheckout(plan),
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isCurrent ? 'الباقة الحالية' : 'اشترك الآن'),
            ),
          ),
        ],
      ),
    );
  }
}
