// Offer Details Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class OfferDetailsScreen extends StatefulWidget {
  final String offerId;

  const OfferDetailsScreen({Key? key, required this.offerId}) : super(key: key);

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  late Future<RealtorOffer> _offerFuture;
  late Future<AppUser> _realtorFuture;

  @override
  void initState() {
    super.initState();
    _offerFuture = _fetchOffer();
  }

  Future<RealtorOffer> _fetchOffer() async {
    final offer = await SupabaseService().getOffer(widget.offerId);
    _realtorFuture = SupabaseService().getUserById(offer.realtorId);
    return offer;
  }

  /// Opens a full-screen, zoomable gallery of the offer's photos starting at
  /// [initialIndex].
  void _openPhotoViewer(List<String> photos, int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => _PhotoViewerDialog(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }

  /// Opens the offer's location in the platform's default maps application.
  Future<void> _openInMaps(RealtorOffer offer) async {
    final latitude = offer.latitude;
    final longitude = offer.longitude;

    final Uri uri;
    if (latitude != null && longitude != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(offer.propertyAddress)}',
      );
    }

    await _launch(uri, 'تعذّر فتح تطبيق الخرائط');
  }

  /// Launches a `tel:` URI to call [phone].
  Future<void> _callRealtor(String phone) async {
    await _launch(Uri(scheme: 'tel', path: phone), 'تعذّر إجراء المكالمة');
  }

  /// Launches a WhatsApp chat with [phone].
  Future<void> _messageRealtorOnWhatsApp(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    await _launch(
      Uri.parse('https://wa.me/$normalized'),
      'تعذّر فتح واتساب',
    );
  }

  /// Launches an email compose intent to [email].
  Future<void> _emailRealtor(String email) async {
    await _launch(Uri(scheme: 'mailto', path: email), 'تعذّر فتح البريد');
  }

  Future<void> _launch(Uri uri, String errorMessage) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('launch failed');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _respondToOffer(String response) async {
    try {
      await SupabaseService().respondToOffer(
        offerId: widget.offerId,
        response: response,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response == 'interested'
              ? 'تم تحديد اهتمامك بالعرض'
              : 'تم رفض العرض'),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/browse-offers');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العرض'),
        elevation: 0,
      ),
      body: FutureBuilder<RealtorOffer>(
        future: _offerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                        _offerFuture = _fetchOffer();
                      });
                    },
                    child: const Text('إعادة محاولة'),
                  ),
                ],
              ),
            );
          }

          final offer = snapshot.data!;
          final isPending = offer.buyerResponse == null;
          final isInterested = offer.buyerResponse == 'interested';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Header with photo
                GestureDetector(
                  onTap: offer.photoUrls != null && offer.photoUrls!.isNotEmpty
                      ? () => _openPhotoViewer(offer.photoUrls!, 0)
                      : null,
                  child: Container(
                    height: 250,
                    color: Colors.grey.shade200,
                    child: offer.photoUrls != null && offer.photoUrls!.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                offer.photoUrls!.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.photo_library_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${offer.photoUrls!.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Icon(Icons.home_outlined, size: 64),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Additional photos carousel
                if (offer.photoUrls != null && offer.photoUrls!.length > 1)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: offer.photoUrls!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                _openPhotoViewer(offer.photoUrls!, index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                offer.photoUrls![index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                // Main content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              offer.propertyTitle,
                              style: Theme.of(context).textTheme.headlineSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isInterested
                                  ? Colors.green.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isInterested ? 'مهتم' : 'جديد',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isInterested
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.propertyAddress,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      // Price Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.indigo.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'السعر المقترح',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.indigo.shade700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${offer.offeredPrice.toStringAsFixed(0)} ${offer.currency}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.indigo.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            if (offer.leaseType != null)
                              Chip(
                                label: Text(
                                  offer.leaseType == 'rent' ? 'إيجار' : 'بيع',
                                ),
                                backgroundColor: Colors.white,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Property Details
                      Text(
                        'المواصفات',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          if (offer.bedrooms != null)
                            _buildDetailColumn(
                              icon: Icons.bed,
                              label: 'الغرف',
                              value: '${offer.bedrooms}',
                            ),
                          if (offer.bathrooms != null)
                            _buildDetailColumn(
                              icon: Icons.bathtub,
                              label: 'الحمامات',
                              value: '${offer.bathrooms}',
                            ),
                          if (offer.areaSqft != null)
                            _buildDetailColumn(
                              icon: Icons.square_foot,
                              label: 'المساحة',
                              value: '${offer.areaSqft} sqft',
                            ),
                          if (offer.furnished != null)
                            _buildDetailColumn(
                              icon: Icons.chair,
                              label: 'الأثاث',
                              value: offer.furnished! ? 'مفروش' : 'غير مفروش',
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Location / Map
                      Text(
                        'الموقع',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildLocationCard(offer),
                      const SizedBox(height: 24),
                      // Description
                      if (offer.propertyDescription != null) ...[
                        Text(
                          'الوصف',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          offer.propertyDescription!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Realtor Info
                      FutureBuilder<AppUser>(
                        future: _realtorFuture,
                        builder: (context, realtorSnapshot) {
                          if (!realtorSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final realtor = realtorSnapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'معلومات الوسيط',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              Colors.indigo.shade100,
                                          radius: 24,
                                          backgroundImage: realtor
                                                      .profilePictureUrl !=
                                                  null
                                              ? NetworkImage(
                                                  realtor.profilePictureUrl!)
                                              : null,
                                          child: realtor
                                                      .profilePictureUrl ==
                                                  null
                                              ? Icon(
                                                  Icons.person,
                                                  color:
                                                      Colors.indigo.shade700,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                realtor.fullName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall,
                                              ),
                                              if (realtor.phone != null)
                                                Text(
                                                  realtor.phone!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (realtor.isVerified)
                                          Tooltip(
                                            message: 'موثق',
                                            child: Icon(
                                              Icons.verified,
                                              color: Colors.green.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (realtor.phone != null) ...[
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _callRealtor(realtor.phone!),
                                              icon: const Icon(
                                                Icons.phone,
                                                size: 18,
                                              ),
                                              label: const Text('اتصال'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _messageRealtorOnWhatsApp(
                                                realtor.phone!,
                                              ),
                                              icon: const Icon(
                                                Icons.chat,
                                                size: 18,
                                              ),
                                              label: const Text('واتساب'),
                                            ),
                                          ),
                                        ] else
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _emailRealtor(realtor.email),
                                              icon: const Icon(
                                                Icons.email_outlined,
                                                size: 18,
                                              ),
                                              label: const Text('بريد'),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      if (isPending)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _respondToOffer('not_interested'),
                                child: const Text('غير مهتم'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _respondToOffer('interested'),
                                child: const Text('مهتم بالعرض'),
                              ),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Chip(
                            label: Text(
                              isInterested ? 'تم تحديد اهتمامك' : 'تم رفض العرض',
                            ),
                            backgroundColor: isInterested
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            labelStyle: TextStyle(
                              color: isInterested
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationCard(RealtorOffer offer) {
    final hasCoordinates =
        offer.latitude != null && offer.longitude != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.indigo.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  offer.propertyAddress,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (hasCoordinates) ...[
            const SizedBox(height: 8),
            Text(
              '${offer.latitude!.toStringAsFixed(5)}, '
              '${offer.longitude!.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openInMaps(offer),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('فتح في الخرائط'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo.shade700, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Full-screen, zoomable photo gallery shown when a photo is tapped.
class _PhotoViewerDialog extends StatefulWidget {
  const _PhotoViewerDialog({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.photos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
