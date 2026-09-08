// Offer Details Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  late Future<User> _realtorFuture;

  @override
  void initState() {
    super.initState();
    _offerFuture = _fetchOffer();
  }

  Future<RealtorOffer> _fetchOffer() async {
    final offer = await SupabaseService().client
        .from('realtor_offers')
        .select()
        .eq('id', widget.offerId)
        .single();

    final realtorOffer = RealtorOffer.fromJson(offer);
    _realtorFuture = SupabaseService().getUserById(realtorOffer.realtorId);
    return realtorOffer;
  }

  Future<void> _respondToOffer(String response) async {
    try {
      await SupabaseService().respondToOffer(widget.offerId, response);
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
                Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: offer.photoUrls != null && offer.photoUrls!.isNotEmpty
                      ? Image.network(
                          offer.photoUrls!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.image_not_supported),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.home_outlined, size: 64),
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
                              icon: Icons.furniture,
                              label: 'الأثاث',
                              value: offer.furnished! ? 'مفروش' : 'غير مفروش',
                            ),
                        ],
                      ),
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
                      FutureBuilder<User>(
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
