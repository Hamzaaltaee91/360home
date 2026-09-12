// Realtor Offers State Provider
//
// Exposes the current realtor's submitted offers and the offers received for
// a given request, backed by [SupabaseService].

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../models/pagination.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

/// Default page size used when fetching offers.
const int kOffersPageSize = 20;

/// Provides the list of offers submitted by the currently signed-in realtor.
///
/// Rebuilds whenever the auth state changes so a new session always fetches
/// its own offers.
final realtorOffersProvider =
    AsyncNotifierProvider<RealtorOffersNotifier, List<RealtorOffer>>(
  RealtorOffersNotifier.new,
);

/// Manages the current realtor's submitted offers.
class RealtorOffersNotifier extends AsyncNotifier<List<RealtorOffer>> {
  SupabaseService get _service => ref.read(supabaseServiceProvider);

  /// Whether more offers can be loaded from the backend.
  bool _hasMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<RealtorOffer>> build() async {
    // Re-fetch whenever the signed-in user changes.
    ref.watch(authProvider);

    if (!_service.isAuthenticated()) {
      _hasMore = false;
      return const [];
    }

    final page = await _service.getRealtorOffers(limit: kOffersPageSize);
    _hasMore = page.hasMore;
    return page.items;
  }

  /// Re-fetches the realtor's offers from the backend.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page = await _service.getRealtorOffers(limit: kOffersPageSize);
      _hasMore = page.hasMore;
      return page.items;
    });
  }

  /// Loads the next page of offers and appends it to the current list.
  ///
  /// No-op when already loading, unauthenticated, or the last page was short.
  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    final current = state.valueOrNull;
    if (current == null) return;

    final page = await _service.getRealtorOffers(
      limit: kOffersPageSize,
      offset: current.length,
    );
    _hasMore = page.hasMore;
    state = AsyncValue.data([...current, ...page.items]);
  }

  /// Creates a new offer and prepends it to the current list on success.
  Future<RealtorOffer> createOffer({
    required String requestId,
    required String propertyTitle,
    required String propertyAddress,
    required double offeredPrice,
    String? propertyDescription,
    double? latitude,
    double? longitude,
    String? leaseType,
    int? leaseDurationMonths,
    int? areaSqft,
    int? bedrooms,
    int? bathrooms,
    bool? furnished,
    List<String>? photoUrls,
    List<String>? documentUrls,
    String? messageToBuyer,
  }) async {
    final offer = await _service.createOffer(
      requestId: requestId,
      propertyTitle: propertyTitle,
      propertyAddress: propertyAddress,
      offeredPrice: offeredPrice,
      propertyDescription: propertyDescription,
      latitude: latitude,
      longitude: longitude,
      leaseType: leaseType,
      leaseDurationMonths: leaseDurationMonths,
      areaSqft: areaSqft,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      furnished: furnished,
      photoUrls: photoUrls,
      documentUrls: documentUrls,
      messageToBuyer: messageToBuyer,
    );

    state = AsyncValue.data([offer, ...state.valueOrNull ?? const []]);
    return offer;
  }
}

/// Provides the offers received for a specific property request.
///
/// Keyed by `requestId` so each request's offers are cached independently.
final offersForRequestProvider =
    AsyncNotifierProvider.family<OffersForRequestNotifier, List<RealtorOffer>,
        String>(OffersForRequestNotifier.new);

/// Manages the offers received for a single property request.
class OffersForRequestNotifier
    extends FamilyAsyncNotifier<List<RealtorOffer>, String> {
  SupabaseService get _service => ref.read(supabaseServiceProvider);

  /// Whether more offers can be loaded from the backend.
  bool _hasMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<RealtorOffer>> build(String requestId) async {
    ref.watch(authProvider);

    if (!_service.isAuthenticated()) {
      _hasMore = false;
      return const [];
    }

    final page =
        await _service.getOffersForRequest(requestId, limit: kOffersPageSize);
    _hasMore = page.hasMore;
    return page.items;
  }

  /// Re-fetches the offers for this request.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page =
          await _service.getOffersForRequest(arg, limit: kOffersPageSize);
      _hasMore = page.hasMore;
      return page.items;
    });
  }

  /// Loads the next page of offers and appends it to the current list.
  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    final current = state.valueOrNull;
    if (current == null) return;

    final page = await _service.getOffersForRequest(
      arg,
      limit: kOffersPageSize,
      offset: current.length,
    );
    _hasMore = page.hasMore;
    state = AsyncValue.data([...current, ...page.items]);
  }

  /// Records the buyer's response to [offerId] and updates the local list.
  Future<void> respondToOffer({
    required String offerId,
    required String response,
  }) async {
    await _service.respondToOffer(offerId: offerId, response: response);

    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data([
      for (final offer in current)
        if (offer.id == offerId)
          offer.copyWith(buyerResponse: response)
        else
          offer,
    ]);
  }
}
