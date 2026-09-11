// Data Models for Dabberli

class User {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'buyer', 'realtor', 'admin'
  final bool isVerified;
  final String? profilePictureUrl;
  final String? phone;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.isVerified = false,
    this.profilePictureUrl,
    this.phone,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      profilePictureUrl: json['profile_picture_url'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_verified': isVerified,
      'profile_picture_url': profilePictureUrl,
      'phone': phone,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    bool? isVerified,
    String? profilePictureUrl,
    String? phone,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PropertyRequest {
  final String id;
  final String buyerId;
  final String category; // 'residential', 'commercial', 'land'
  final String title;
  final String? description;
  final String city;
  final String? areaName;
  final double? latitude;
  final double? longitude;
  final double? minPrice;
  final double? maxPrice;
  final String currency;
  final int? minAreaSqft;
  final int? maxAreaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final bool? furnished;
  final String status; // 'active', 'inactive', 'sold', 'rented'
  final bool isUrgent;
  final List<String>? preferredContact;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  PropertyRequest({
    required this.id,
    required this.buyerId,
    required this.category,
    required this.title,
    this.description,
    required this.city,
    this.areaName,
    this.latitude,
    this.longitude,
    this.minPrice,
    this.maxPrice,
    this.currency = 'AED',
    this.minAreaSqft,
    this.maxAreaSqft,
    this.bedrooms,
    this.bathrooms,
    this.furnished,
    this.status = 'active',
    this.isUrgent = false,
    this.preferredContact,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory PropertyRequest.fromJson(Map<String, dynamic> json) {
    return PropertyRequest(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      city: json['city'] as String,
      areaName: json['area_name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'AED',
      minAreaSqft: json['min_area_sqft'] as int?,
      maxAreaSqft: json['max_area_sqft'] as int?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      furnished: json['furnished'] as bool?,
      status: json['status'] as String? ?? 'active',
      isUrgent: json['is_urgent'] as bool? ?? false,
      preferredContact: (json['preferred_contact'] as List?)?.cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'category': category,
      'title': title,
      'description': description,
      'city': city,
      'area_name': areaName,
      'latitude': latitude,
      'longitude': longitude,
      'min_price': minPrice,
      'max_price': maxPrice,
      'currency': currency,
      'min_area_sqft': minAreaSqft,
      'max_area_sqft': maxAreaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'furnished': furnished,
      'status': status,
      'is_urgent': isUrgent,
      'preferred_contact': preferredContact,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  PropertyRequest copyWith({
    String? id,
    String? buyerId,
    String? category,
    String? title,
    String? description,
    String? city,
    String? areaName,
    double? latitude,
    double? longitude,
    double? minPrice,
    double? maxPrice,
    String? currency,
    int? minAreaSqft,
    int? maxAreaSqft,
    int? bedrooms,
    int? bathrooms,
    bool? furnished,
    String? status,
    bool? isUrgent,
    List<String>? preferredContact,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return PropertyRequest(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      areaName: areaName ?? this.areaName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      currency: currency ?? this.currency,
      minAreaSqft: minAreaSqft ?? this.minAreaSqft,
      maxAreaSqft: maxAreaSqft ?? this.maxAreaSqft,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      furnished: furnished ?? this.furnished,
      status: status ?? this.status,
      isUrgent: isUrgent ?? this.isUrgent,
      preferredContact: preferredContact ?? this.preferredContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class RealtorOffer {
  final String id;
  final String realtorId;
  final String requestId;
  final String propertyTitle;
  final String? propertyDescription;
  final String propertyAddress;
  final double? latitude;
  final double? longitude;
  final double offeredPrice;
  final String currency;
  final String? leaseType; // 'rent', 'sale'
  final int? leaseDurationMonths;
  final int? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final bool? furnished;
  final List<String>? photoUrls;
  final List<String>? documentUrls;
  final String status; // 'pending', 'accepted', 'rejected', 'expired'
  final String? buyerResponse; // 'interested', 'not_interested'
  final String? messageToBuyer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;

  RealtorOffer({
    required this.id,
    required this.realtorId,
    required this.requestId,
    required this.propertyTitle,
    this.propertyDescription,
    required this.propertyAddress,
    this.latitude,
    this.longitude,
    required this.offeredPrice,
    this.currency = 'AED',
    this.leaseType,
    this.leaseDurationMonths,
    this.areaSqft,
    this.bedrooms,
    this.bathrooms,
    this.furnished,
    this.photoUrls,
    this.documentUrls,
    this.status = 'pending',
    this.buyerResponse,
    this.messageToBuyer,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory RealtorOffer.fromJson(Map<String, dynamic> json) {
    return RealtorOffer(
      id: json['id'] as String,
      realtorId: json['realtor_id'] as String,
      requestId: json['request_id'] as String,
      propertyTitle: json['property_title'] as String,
      propertyDescription: json['property_description'] as String?,
      propertyAddress: json['property_address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      offeredPrice: (json['offered_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'AED',
      leaseType: json['lease_type'] as String?,
      leaseDurationMonths: json['lease_duration_months'] as int?,
      areaSqft: json['area_sqft'] as int?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      furnished: json['furnished'] as bool?,
      photoUrls: (json['photo_urls'] as List?)?.cast<String>(),
      documentUrls: (json['document_urls'] as List?)?.cast<String>(),
      status: json['status'] as String? ?? 'pending',
      buyerResponse: json['buyer_response'] as String?,
      messageToBuyer: json['message_to_buyer'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'realtor_id': realtorId,
      'request_id': requestId,
      'property_title': propertyTitle,
      'property_description': propertyDescription,
      'property_address': propertyAddress,
      'latitude': latitude,
      'longitude': longitude,
      'offered_price': offeredPrice,
      'currency': currency,
      'lease_type': leaseType,
      'lease_duration_months': leaseDurationMonths,
      'area_sqft': areaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'furnished': furnished,
      'photo_urls': photoUrls,
      'document_urls': documentUrls,
      'status': status,
      'buyer_response': buyerResponse,
      'message_to_buyer': messageToBuyer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  RealtorOffer copyWith({
    String? id,
    String? realtorId,
    String? requestId,
    String? propertyTitle,
    String? propertyDescription,
    String? propertyAddress,
    double? latitude,
    double? longitude,
    double? offeredPrice,
    String? currency,
    String? leaseType,
    int? leaseDurationMonths,
    int? areaSqft,
    int? bedrooms,
    int? bathrooms,
    bool? furnished,
    List<String>? photoUrls,
    List<String>? documentUrls,
    String? status,
    String? buyerResponse,
    String? messageToBuyer,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return RealtorOffer(
      id: id ?? this.id,
      realtorId: realtorId ?? this.realtorId,
      requestId: requestId ?? this.requestId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyDescription: propertyDescription ?? this.propertyDescription,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      currency: currency ?? this.currency,
      leaseType: leaseType ?? this.leaseType,
      leaseDurationMonths: leaseDurationMonths ?? this.leaseDurationMonths,
      areaSqft: areaSqft ?? this.areaSqft,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      furnished: furnished ?? this.furnished,
      photoUrls: photoUrls ?? this.photoUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      status: status ?? this.status,
      buyerResponse: buyerResponse ?? this.buyerResponse,
      messageToBuyer: messageToBuyer ?? this.messageToBuyer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class Subscription {
  final String id;
  final String realtorId;
  final String plan; // 'free', 'basic', 'premium'
  final String status; // 'active', 'past_due', 'canceled', 'expired'
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final String? paymentProvider;
  final String? externalSubscriptionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.realtorId,
    required this.plan,
    this.status = 'active',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.paymentProvider,
    this.externalSubscriptionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      realtorId: json['realtor_id'] as String,
      plan: json['plan'] as String,
      status: json['status'] as String? ?? 'active',
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'] as String)
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      paymentProvider: json['payment_provider'] as String?,
      externalSubscriptionId: json['external_subscription_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'realtor_id': realtorId,
      'plan': plan,
      'status': status,
      'current_period_start': currentPeriodStart?.toIso8601String(),
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'cancel_at_period_end': cancelAtPeriodEnd,
      'payment_provider': paymentProvider,
      'external_subscription_id': externalSubscriptionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Subscription copyWith({
    String? id,
    String? realtorId,
    String? plan,
    String? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    bool? cancelAtPeriodEnd,
    String? paymentProvider,
    String? externalSubscriptionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      realtorId: realtorId ?? this.realtorId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      externalSubscriptionId:
          externalSubscriptionId ?? this.externalSubscriptionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Notification {
  final String id;
  final String userId;
  final String type; // 'offer_received', 'offer_accepted', 'verification', etc.
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map?)?.cast<String, dynamic>(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          type == other.type &&
          title == other.title &&
          body == other.body &&
          isRead == other.isRead &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        type,
        title,
        body,
        isRead,
        createdAt,
      );
}

class PropertyMatch {
  final String requestId;
  final String buyerId;
  final String category;
  final String title;
  final String city;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final int? bathrooms;
  final int matchScore;

  PropertyMatch({
    required this.requestId,
    required this.buyerId,
    required this.category,
    required this.title,
    required this.city,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    required this.matchScore,
  });

  factory PropertyMatch.fromJson(Map<String, dynamic> json) {
    return PropertyMatch(
      requestId: json['request_id'] as String,
      buyerId: json['buyer_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      matchScore: json['match_score'] as int? ?? 0,
    );
  }

  PropertyMatch copyWith({
    String? requestId,
    String? buyerId,
    String? category,
    String? title,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    int? matchScore,
  }) {
    return PropertyMatch(
      requestId: requestId ?? this.requestId,
      buyerId: buyerId ?? this.buyerId,
      category: category ?? this.category,
      title: title ?? this.title,
      city: city ?? this.city,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}
