// Supabase Integration Service

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../models/pagination.dart';
import '../models/realtor_verification.dart';
import '../utils/error_handler.dart';
import 'secure_storage_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late final SupabaseClient _client;

  /// Secure storage used to persist sensitive session data.
  ///
  /// Overridable for tests via [secureStorageOverride].
  SecureStorage _secureStorage = SecureStorageService();

  /// Overrides the secure storage implementation (used in tests).
  set secureStorageOverride(SecureStorage storage) {
    _secureStorage = storage;
  }

  SupabaseClient get client => _client;

  /// Emits whenever the auth session changes (sign-in, sign-out, token
  /// refresh). Used by the router to re-evaluate route guards.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Cached role of the currently signed-in user, populated on auth changes.
  /// `null` when signed out or not yet resolved.
  String? _currentUserRole;

  String? get currentUserRole => _currentUserRole;

  /// Fetches and caches the role for the current user from the `users` table.
  /// Returns `null` when signed out.
  Future<String?> refreshCurrentUserRole() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      _currentUserRole = null;
      return null;
    }

    try {
      final response = await _client
          .from('users')
          .select('role')
          .eq('auth_id', userId)
          .single();
      _currentUserRole = response['role'] as String?;
      if (_currentUserRole != null) {
        await _secureStorage.write(
          SecureStorageKeys.userRole,
          _currentUserRole!,
        );
      }
    } catch (_) {
      _currentUserRole = null;
    }
    return _currentUserRole;
  }

  /// Runs [action], translating any thrown error into a standardized
  /// [AppException] with a user-friendly message.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw SupabaseErrorHandler.handle(error);
    }
  }

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Persist the auth session in the platform secure store rather than
      // the default (plain) local storage.
      localStorage: SecureLocalStorage(_secureStorage),
    );
    _client = Supabase.instance.client;
  }

  // ==================== Authentication ====================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) {
    return _guard(() => _client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': role,
          },
        ));
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await refreshCurrentUserRole();
      return response;
    });
  }

  Future<void> signOut() {
    return _guard(() async {
      await _client.auth.signOut();
      _currentUserRole = null;
      await _secureStorage.delete(SecureStorageKeys.userRole);
    });
  }

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // ==================== User Management ====================

  Future<AppUser> getCurrentUser() {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('users')
          .select()
          .eq('auth_id', userId)
          .single();

      return AppUser.fromJson(response);
    });
  }

  Future<AppUser> getUserById(String userId) {
    return _guard(() async {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return AppUser.fromJson(response);
    });
  }

  Future<void> updateUserProfile({
    required String fullName,
    String? phone,
    String? bio,
    String? profilePictureUrl,
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      await _client.from('users').update({
        'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      }).eq('auth_id', userId);
    });
  }

  /// Fetches the user directory for the admin screen.
  ///
  /// [role] filters by role when provided (e.g. 'buyer', 'realtor',
  /// 'admin'). [search] performs a case-insensitive match against the
  /// user's full name or email. Results are ordered newest first.
  Future<List<AppUser>> listUsers({
    String? role,
    String? search,
  }) {
    return _guard(() async {
      var query = _client.from('users').select();

      if (role != null && role.isNotEmpty) {
        query = query.eq('role', role);
      }

      final trimmed = search?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        query = query.or(
          'full_name.ilike.%$trimmed%,email.ilike.%$trimmed%',
        );
      }

      final response =
          await query.order('created_at', ascending: false);

      return (response as List)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Updates the role of the user identified by [userId].
  ///
  /// Changes a user's role via the `admin_set_user_role` RPC. All
  /// authorization and validation (admin-only, valid role, no self-change)
  /// happens server-side in that SECURITY DEFINER function — see
  /// supabase/migrations/20260914000001_admin_set_user_role.sql.
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) {
    return _guard(
      () => _client.rpc('admin_set_user_role', params: {
        'p_user_id': userId,
        'p_role': role,
      }),
    );
  }

  // ==================== Property Requests ====================

  Future<PropertyRequest> createPropertyRequest({
    required String category,
    required String title,
    required String city,
    String? description,
    String? areaName,
    String? purpose,
    String? governorate,
    String? area,
    String? propertySubtype,
    String? rentalPeriod,
    double? latitude,
    double? longitude,
    double? minPrice,
    double? maxPrice,
    int? minAreaSqft,
    int? maxAreaSqft,
    int? bedrooms,
    int? bathrooms,
    bool? furnished,
    bool isUrgent = false,
    List<String>? preferredContact,
    DateTime? expiresAt,
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('property_requests')
          .insert({
            'buyer_id': userId,
            'category': category,
            'title': title,
            'city': city,
            'description': description,
            'area_name': areaName,
            if (purpose != null) 'purpose': purpose,
            if (governorate != null) 'governorate': governorate,
            if (area != null) 'area': area,
            if (propertySubtype != null) 'property_subtype': propertySubtype,
            if (rentalPeriod != null) 'rental_period': rentalPeriod,
            'latitude': latitude,
            'longitude': longitude,
            'min_price': minPrice,
            'max_price': maxPrice,
            'min_area_sqft': minAreaSqft,
            'max_area_sqft': maxAreaSqft,
            'bedrooms': bedrooms,
            'bathrooms': bathrooms,
            'furnished': furnished,
            'is_urgent': isUrgent,
            'preferred_contact': preferredContact,
            'expires_at': expiresAt?.toIso8601String(),
          })
          .select()
          .single();

      return PropertyRequest.fromJson(response);
    });
  }

  /// Fetches a page of active property requests (any buyer), newest first.
  ///
  /// Used by realtors browsing the request marketplace.
  Future<PaginatedResult<PropertyRequest>> getActiveRequests({
    int limit = 20,
    int offset = 0,
  }) {
    return _guard(() async {
      final response = await _client
          .from('property_requests')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final items = (response as List)
          .map((e) => PropertyRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResult.fromItems(items, offset: offset, limit: limit);
    });
  }

  /// Fetches a page of the current buyer's property requests, newest first.
  Future<PaginatedResult<PropertyRequest>> getUserRequests({
    int limit = 20,
    int offset = 0,
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('property_requests')
          .select()
          .eq('buyer_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final items = (response as List)
          .map((e) => PropertyRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResult.fromItems(items, offset: offset, limit: limit);
    });
  }

  Future<PropertyRequest> getPropertyRequest(String requestId) {
    return _guard(() async {
      final response = await _client
          .from('property_requests')
          .select()
          .eq('id', requestId)
          .single();

      return PropertyRequest.fromJson(response);
    });
  }

  Future<void> updatePropertyRequest({
    required String requestId,
    String? title,
    String? description,
    String? status,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    String? purpose,
    String? governorate,
    String? area,
    String? propertySubtype,
    String? rentalPeriod,
  }) {
    return _guard(() => _client.from('property_requests').update({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (status != null) 'status': status,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (bedrooms != null) 'bedrooms': bedrooms,
          if (bathrooms != null) 'bathrooms': bathrooms,
          if (purpose != null) 'purpose': purpose,
          if (governorate != null) 'governorate': governorate,
          if (area != null) 'area': area,
          if (propertySubtype != null) 'property_subtype': propertySubtype,
          if (rentalPeriod != null) 'rental_period': rentalPeriod,
        }).eq('id', requestId));
  }

  Future<void> deletePropertyRequest(String requestId) {
    return _guard(
      () => _client.from('property_requests').delete().eq('id', requestId),
    );
  }

  // ==================== Realtor Offers ====================

  /// Fetches a page of offers received for [requestId], newest first.
  Future<PaginatedResult<RealtorOffer>> getOffersForRequest(
    String requestId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _guard(() async {
      final response = await _client
          .from('realtor_offers')
          .select()
          .eq('request_id', requestId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final items = (response as List)
          .map((e) => RealtorOffer.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResult.fromItems(items, offset: offset, limit: limit);
    });
  }

  /// Fetches a page of all offers received across the current buyer's
  /// requests, newest first.
  ///
  /// Uses an inner join on `property_requests` so only offers belonging to
  /// the buyer's own requests are returned, in a single query.
  Future<PaginatedResult<RealtorOffer>> getBuyerOffers({
    int limit = 20,
    int offset = 0,
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('realtor_offers')
          .select('*, property_requests!inner(buyer_id)')
          .eq('property_requests.buyer_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final items = (response as List)
          .map((e) => RealtorOffer.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResult.fromItems(items, offset: offset, limit: limit);
    });
  }

  /// Fetches a page of the current realtor's submitted offers, newest first.
  Future<PaginatedResult<RealtorOffer>> getRealtorOffers({
    int limit = 20,
    int offset = 0,
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('realtor_offers')
          .select()
          .eq('realtor_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final items = (response as List)
          .map((e) => RealtorOffer.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResult.fromItems(items, offset: offset, limit: limit);
    });
  }

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
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('realtor_offers')
          .insert({
            'realtor_id': userId,
            'request_id': requestId,
            'property_title': propertyTitle,
            'property_address': propertyAddress,
            'offered_price': offeredPrice,
            'property_description': propertyDescription,
            'latitude': latitude,
            'longitude': longitude,
            'lease_type': leaseType,
            'lease_duration_months': leaseDurationMonths,
            'area_sqft': areaSqft,
            'bedrooms': bedrooms,
            'bathrooms': bathrooms,
            'furnished': furnished,
            'photo_urls': photoUrls,
            'document_urls': documentUrls,
            'message_to_buyer': messageToBuyer,
          })
          .select()
          .single();

      return RealtorOffer.fromJson(response);
    });
  }

  Future<RealtorOffer> getOffer(String offerId) {
    return _guard(() async {
      final response = await _client
          .from('realtor_offers')
          .select()
          .eq('id', offerId)
          .single();

      return RealtorOffer.fromJson(response);
    });
  }

  Future<void> respondToOffer({
    required String offerId,
    required String response, // 'interested', 'not_interested'
  }) {
    return _guard(() => _client.from('realtor_offers').update({
          'buyer_response': response,
        }).eq('id', offerId));
  }

  // ==================== Realtor Verifications ====================
  //
  // All privilege logic (the is_admin() check and the role flip on
  // approval) lives server-side in these SECURITY DEFINER RPCs, defined in
  // supabase/migrations/20260911000009_realtor_application_approval.sql
  // and 20260908000008_realtor_verifications.sql. No client code here ever
  // reads or writes a role, or touches the realtor_verifications table
  // directly.

  /// Returns the current user's latest verification request, or `null` if
  /// none has been submitted yet.
  Future<RealtorVerification?> getMyVerification() {
    return _guard(() async {
      final response =
          await _client.rpc('get_my_verification_status') as List;
      if (response.isEmpty) return null;
      return RealtorVerification.fromJson(
        response.first as Map<String, dynamic>,
      );
    });
  }

  /// Submits a new realtor application for the current user.
  Future<void> submitVerification({
    required String companyName,
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String documentUrl,
  }) {
    return _guard(() async {
      await _client.rpc('submit_realtor_application', params: {
        'p_company_name': companyName,
        'p_license_number': licenseNumber,
        'p_license_expiry': licenseExpiry.toIso8601String().split('T').first,
        'p_document_url': documentUrl,
      });
    });
  }

  /// Returns all pending realtor applications, oldest first.
  /// Intended for the admin review screen.
  Future<List<RealtorVerification>> getVerifications({
    String status = 'pending',
  }) {
    return _guard(() async {
      final response =
          await _client.rpc('list_pending_realtor_applications') as List;
      return response
          .map((e) => RealtorVerification.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Approves or rejects a realtor application. [rejectionReason] is
  /// required when rejecting.
  Future<void> reviewVerification({
    required String verificationId,
    required bool approve,
    String? rejectionReason,
  }) {
    return _guard(() async {
      if (approve) {
        await _client.rpc('approve_realtor_application', params: {
          'p_verification_id': verificationId,
        });
      } else {
        await _client.rpc('reject_realtor_application', params: {
          'p_verification_id': verificationId,
          'p_reason': rejectionReason,
        });
      }
    });
  }

  // ==================== Search & Matching ====================

  Future<List<PropertyMatch>> getMatchingOffers({
    String? category,
    int limit = 10,
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client.functions.invoke(
        'match-offers',
        body: {
          'realtor_id': userId,
          'category': category,
          'limit': limit,
        },
      );

      final matches = (response.data as Map<String, dynamic>)['matches'] as List;
      return matches
          .map((e) => PropertyMatch.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Map<String, dynamic>> searchRequests({
    String? category,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    double? latitude,
    double? longitude,
    int radiusKm = 10,
    String sortBy = 'recent',
    int limit = 20,
    int offset = 0,
  }) {
    return _guard(() async {
      final response = await _client.functions.invoke(
        'search-requests',
        body: {
          'category': category,
          'city': city,
          'min_price': minPrice,
          'max_price': maxPrice,
          'bedrooms': bedrooms,
          'bathrooms': bathrooms,
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          'sort_by': sortBy,
          'limit': limit,
          'offset': offset,
        },
      );

      return response.data as Map<String, dynamic>;
    });
  }

  // ==================== Analytics ====================

  Future<Map<String, dynamic>> getRealtorStats() {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client.functions.invoke(
        'analytics',
        body: {
          'type': 'realtor',
          'user_id': userId,
        },
      );

      return response.data as Map<String, dynamic>;
    });
  }

  Future<Map<String, dynamic>> getBuyerStats() {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client.functions.invoke(
        'analytics',
        body: {
          'type': 'buyer',
          'user_id': userId,
        },
      );

      return response.data as Map<String, dynamic>;
    });
  }

  // ==================== Storage ====================

  Future<String> uploadPropertyPhoto({
    required String requestId,
    required String fileName,
    required List<int> fileBytes,
  }) {
    return _guard(() async {
      final filePath = 'property-photos/$requestId/$fileName';
      await _client.storage.from('dabberli').uploadBinary(
            filePath,
            Uint8List.fromList(fileBytes),
          );

      return _client.storage.from('dabberli').getPublicUrl(filePath);
    });
  }

  Future<String> uploadProfilePicture({
    required String userId,
    required String fileName,
    required List<int> fileBytes,
  }) {
    return _guard(() async {
      final filePath = 'profile-pictures/$userId/$fileName';
      await _client.storage.from('dabberli').uploadBinary(
            filePath,
            Uint8List.fromList(fileBytes),
          );

      return _client.storage.from('dabberli').getPublicUrl(filePath);
    });
  }

  // ==================== Realtor Reviews ====================

  /// Submits a review for the offer identified by [offerId].
  Future<void> submitReview({
    required String offerId,
    required int rating,
    String? comment,
  }) {
    return _guard(
      () => _client.rpc('submit_realtor_review', params: {
        'p_offer_id': offerId,
        'p_rating': rating,
        'p_comment': comment,
      }),
    );
  }

  /// Returns the reviews written for the realtor identified by [realtorId].
  Future<List<Map<String, dynamic>>> listRealtorReviews(String realtorId) {
    return _guard(() async {
      final response =
          await _client.rpc('list_realtor_reviews', params: {
        'p_realtor_id': realtorId,
      }) as List;
      return response
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    });
  }

  /// Returns the current user's review for [offerId], or `null` when none
  /// has been submitted yet.
  Future<Map<String, dynamic>?> getMyReviewForOffer(String offerId) {
    return _guard(() async {
      final response =
          await _client.rpc('get_my_review_for_offer', params: {
        'p_offer_id': offerId,
      }) as List;
      if (response.isEmpty) return null;
      return (response.first as Map).cast<String, dynamic>();
    });
  }

  // ==================== Messages ====================

  /// Sends a message on the offer identified by [offerId].
  Future<void> sendMessage({
    required String offerId,
    required String body,
  }) {
    return _guard(
      () => _client.rpc('send_message', params: {
        'p_offer_id': offerId,
        'p_body': body,
      }),
    );
  }

  /// Returns the messages on the offer identified by [offerId], oldest
  /// first.
  Future<List<Map<String, dynamic>>> listMessages(String offerId) {
    return _guard(() async {
      final response =
          await _client.rpc('list_messages', params: {
        'p_offer_id': offerId,
      }) as List;
      return response
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    });
  }

  /// Marks every message on the offer identified by [offerId] as read for
  /// the current user.
  Future<void> markMessagesRead(String offerId) {
    return _guard(
      () => _client.rpc('mark_messages_read', params: {
        'p_offer_id': offerId,
      }),
    );
  }

  /// Returns the number of unread messages for the current user.
  Future<int> unreadMessageCount() {
    return _guard(() async {
      final response =
          await _client.rpc('unread_message_count') as int;
      return response;
    });
  }
}
