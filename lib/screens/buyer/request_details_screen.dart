// Request Details Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/formatters.dart';
import '../../utils/iraq_locations.dart';

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({Key? key, required this.requestId})
      : super(key: key);

  final String requestId;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late Future<PropertyRequest> _requestFuture;

  @override
  void initState() {
    super.initState();
    _requestFuture = SupabaseService().getPropertyRequest(widget.requestId);
  }

  void _reload() {
    setState(() {
      _requestFuture = SupabaseService().getPropertyRequest(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        actions: [
          IconButton(
            tooltip: 'تعديل الطلب',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/edit-request/${widget.requestId}'),
          ),
        ],
      ),
      body: FutureBuilder<PropertyRequest>(
        future: _requestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is AppException
                ? error.message
                : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final request = snapshot.data;
          if (request == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _StatusBadge(status: request.status),
                  ],
                ),
                if (request.isUrgent) ...[
                  const SizedBox(height: 8),
                  const Chip(
                    label: Text('عاجل'),
                    backgroundColor: Color(0xFFFFE0E0),
                    labelStyle: TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                if (request.description != null &&
                    request.description!.isNotEmpty) ...[
                  Text(
                    request.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                _DetailTile(
                  icon: Icons.category_outlined,
                  label: 'الفئة',
                  value: _categoryLabel(request.category),
                ),
                if (request.purpose != null)
                  _DetailTile(
                    icon: Icons.sell_outlined,
                    label: 'الغرض',
                    value: request.purpose == 'rent' ? 'إيجار' : 'شراء',
                  ),
                _DetailTile(
                  icon: Icons.location_on_outlined,
                  label: 'الموقع',
                  value: _locationLabel(request),
                ),
                if (request.minPrice != null || request.maxPrice != null)
                  _DetailTile(
                    icon: Icons.attach_money,
                    label: 'الميزانية',
                    value:
                        '${Formatters.formatPrice(request.minPrice)} - ${Formatters.formatPrice(request.maxPrice)} ${request.currency}',
                  ),
                if (request.rentalPeriod != null)
                  _DetailTile(
                    icon: Icons.event_repeat_outlined,
                    label: 'مدة الإيجار',
                    value: _rentalPeriodLabel(request.rentalPeriod!),
                  ),
                if (request.minAreaSqft != null || request.maxAreaSqft != null)
                  _DetailTile(
                    icon: Icons.square_foot_outlined,
                    label: 'المساحة',
                    value:
                        '${request.minAreaSqft ?? '-'} - ${request.maxAreaSqft ?? '-'} قدم²',
                  ),
                if (request.bedrooms != null)
                  _DetailTile(
                    icon: Icons.bed_outlined,
                    label: 'غرف النوم',
                    value: '${request.bedrooms}',
                  ),
                if (request.bathrooms != null)
                  _DetailTile(
                    icon: Icons.bathtub_outlined,
                    label: 'الحمامات',
                    value: '${request.bathrooms}',
                  ),
                if (request.furnished != null)
                  _DetailTile(
                    icon: Icons.chair_outlined,
                    label: 'مفروش',
                    value: request.furnished! ? 'نعم' : 'لا',
                  ),
                _DetailTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'تاريخ الإنشاء',
                  value: DateFormat('yyyy/MM/dd').format(request.createdAt),
                ),
                if (request.expiresAt != null)
                  _DetailTile(
                    icon: Icons.event_busy_outlined,
                    label: 'تاريخ الانتهاء',
                    value: DateFormat('yyyy/MM/dd').format(request.expiresAt!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'residential':
        return 'سكني';
      case 'commercial':
        return 'تجاري';
      case 'land':
        return 'أرض';
      default:
        return category;
    }
  }

  String _rentalPeriodLabel(String period) {
    switch (period) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      case 'yearly':
        return 'سنوي';
      default:
        return period;
    }
  }

  String _locationLabel(PropertyRequest request) {
    final governorateLabel = request.governorate != null
        ? iraqLocations[request.governorate]?['label'] as String?
        : null;
    final parts = [
      if (governorateLabel != null) governorateLabel else request.city,
      if (request.area != null && request.area!.isNotEmpty) request.area,
      if ((request.area == null || request.area!.isEmpty) &&
          request.areaName != null &&
          request.areaName!.isNotEmpty)
        request.areaName,
    ];
    return parts.whereType<String>().join(' - ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'inactive':
        return 'غير نشط';
      case 'sold':
        return 'تم البيع';
      case 'rented':
        return 'تم التأجير';
      default:
        return status;
    }
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
