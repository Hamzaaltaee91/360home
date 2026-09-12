// Supabase Integration Service

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../models/pagination.dart';
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
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(_secureStorage),
      ),
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

  Future<User> getCurrentUser() {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('users')
          .select()
          .eq('auth_id', userId)
          .single();

      return User.fromJson(response);
    });
  }

  Future<User> getUserById(String userId) {
    return _guard(() async {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
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

  // ==================== Property Requests ====================

  Future<PropertyRequest> createPropertyRequest({
    required String category,
    required String title,
    required String city,
    String? description,
    String? areaName,
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
  }) {
    return _guard(() => _client.from('property_requests').update({
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (status != null) 'status': status,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (bedrooms != null) 'bedrooms': bedrooms,
          if (bathrooms != null) 'bathrooms': bathrooms,
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

  Future<void> respondToOffer({
    required String offerId,
    required String response, // 'interested', 'not_interested'
  }) {
    return _guard(() => _client.from('realtor_offers').update({
          'buyer_response': response,
        }).eq('id', offerId));
  }

  // ==================== Realtor Verifications ====================

  /// Returns the current user's verification request, or `null` if none
  /// has been submitted yet.
  Future<RealtorVerification?> getMyVerification() {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('realtor_verifications')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return RealtorVerification.fromJson(response);
    });
  }

  /// Submits a new verification request for the current user.
  Future<RealtorVerification> submitVerification({
    required String licenseNumber,
    required String documentUrl,
  }) {
    return _guard(() async {
      final userId = getCurrentUserId();
      if (userId == null) throw const AppException('المستخدم غير مسجل دخول');

      final response = await _client
          .from('realtor_verifications')
          .insert({
            'user_id': userId,
            'status': 'pending',
            'license_number': licenseNumber,
            'document_url': documentUrl,
          })
          .select()
          .single();

      return RealtorVerification.fromJson(response);
    });
  }

  /// Returns all verification requests with the given [status], newest first.
  /// Intended for the admin review screen.
  Future<List<RealtorVerification>> getVerifications({
    String status = 'pending',
  }) {
    return _guard(() async {
      final response = await _client
          .from('realtor_verifications')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => RealtorVerification.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Approves or rejects a verification request via the `verify-realtor`
  /// Edge Function. [rejectionReason] is required when rejecting.
  Future<RealtorVerification> reviewVerification({
    required String verificationId,
    required bool approve,
    String? rejectionReason,
  }) {
    return _guard(() async {
      final response = await _client.functions.invoke(
        'verify-realtor',
        body: {
          'verification_id': verificationId,
          'action': approve ? 'approve' : 'reject',
          if (rejectionReason != null) 'rejection_reason': rejectionReason,
        },
      );

      return RealtorVerification.fromJson(
        response['verification'] as Map<String, dynamic>,
      );
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

      final matches = response['matches'] as List;
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

      return response as Map<String, dynamic>;
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

      return response as Map<String, dynamic>;
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

      return response as Map<String, dynamic>;
    });
  }

  // ==================== Notifications ====================

  void subscribeToNotifications(String userId, Function(Map) onNotification) {
    _client.realtime.subscribe().on(
      'broadcast',
      ChannelFilter(event: 'notifications:$userId'),
      (payload) {
        onNotification(payload.payload as Map);
      },
    );
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
}
