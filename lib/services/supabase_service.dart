// Supabase Integration Service

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // ==================== Authentication ====================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // ==================== User Management ====================

  Future<User> getCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

    final response = await _client
        .from('users')
        .select()
        .eq('auth_id', userId)
        .single();

    return User.fromJson(response);
  }

  Future<User> getUserById(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return User.fromJson(response);
  }

  Future<void> updateUserProfile({
    required String fullName,
    String? phone,
    String? bio,
    String? profilePictureUrl,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

    await _client.from('users').update({
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
    }).eq('auth_id', userId);
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
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

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
  }

  Future<List<PropertyRequest>> getUserRequests() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

    final response = await _client
        .from('property_requests')
        .select()
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PropertyRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PropertyRequest> getPropertyRequest(String requestId) async {
    final response = await _client
        .from('property_requests')
        .select()
        .eq('id', requestId)
        .single();

    return PropertyRequest.fromJson(response);
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
  }) async {
    await _client.from('property_requests').update({
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
    }).eq('id', requestId);
  }

  // ==================== Realtor Offers ====================

  Future<List<RealtorOffer>> getOffersForRequest(String requestId) async {
    final response = await _client
        .from('realtor_offers')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => RealtorOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RealtorOffer>> getRealtorOffers() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

    final response = await _client
        .from('realtor_offers')
        .select()
        .eq('realtor_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => RealtorOffer.fromJson(e as Map<String, dynamic>))
        .toList();
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
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

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
  }

  Future<void> respondToOffer({
    required String offerId,
    required String response, // 'interested', 'not_interested'
  }) async {
    await _client.from('realtor_offers').update({
      'buyer_response': response,
    }).eq('id', offerId);
  }

  // ==================== Search & Matching ====================

  Future<List<PropertyMatch>> getMatchingOffers({
    String? category,
    int limit = 10,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

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
  }) async {
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
  }

  // ==================== Analytics ====================

  Future<Map<String, dynamic>> getRealtorStats() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

    final response = await _client.functions.invoke(
      'analytics',
      body: {
        'type': 'realtor',
        'user_id': userId,
      },
    );

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBuyerStats() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('المستخدم غير مسجل دخول');

    final response = await _client.functions.invoke(
      'analytics',
      body: {
        'type': 'buyer',
        'user_id': userId,
      },
    );

    return response as Map<String, dynamic>;
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
  }) async {
    final filePath = 'property-photos/$requestId/$fileName';
    await _client.storage.from('dabberli').uploadBinary(
          filePath,
          Uint8List.fromList(fileBytes),
        );

    return _client.storage.from('dabberli').getPublicUrl(filePath);
  }

  Future<String> uploadProfilePicture({
    required String userId,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final filePath = 'profile-pictures/$userId/$fileName';
    await _client.storage.from('dabberli').uploadBinary(
          filePath,
          Uint8List.fromList(fileBytes),
        );

    return _client.storage.from('dabberli').getPublicUrl(filePath);
  }
}
