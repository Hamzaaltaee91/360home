// PropertyPhoto Model

class PropertyPhoto {
  final String id;
  final String requestId;
  final String? offerId;
  final String url;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;

  PropertyPhoto({
    required this.id,
    required this.requestId,
    this.offerId,
    required this.url,
    this.caption,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory PropertyPhoto.fromJson(Map<String, dynamic> json) {
    return PropertyPhoto(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      offerId: json['offer_id'] as String?,
      url: json['url'] as String,
      caption: json['caption'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'offer_id': offerId,
      'url': url,
      'caption': caption,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Whether this photo is attached to an offer rather than a request.
  bool get isOfferPhoto => offerId != null;

  PropertyPhoto copyWith({
    String? id,
    String? requestId,
    String? offerId,
    String? url,
    String? caption,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return PropertyPhoto(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      offerId: offerId ?? this.offerId,
      url: url ?? this.url,
      caption: caption ?? this.caption,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyPhoto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          requestId == other.requestId &&
          offerId == other.offerId &&
          url == other.url &&
          caption == other.caption &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        requestId,
        offerId,
        url,
        caption,
        sortOrder,
        createdAt,
      );
}
