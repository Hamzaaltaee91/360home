// RealtorVerification Model

class RealtorVerification {
  final String id;
  final String userId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? licenseNumber;
  final String? documentUrl;
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RealtorVerification({
    required this.id,
    required this.userId,
    required this.status,
    this.licenseNumber,
    this.documentUrl,
    this.rejectionReason,
    this.verifiedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RealtorVerification.fromJson(Map<String, dynamic> json) {
    return RealtorVerification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      licenseNumber: json['license_number'] as String?,
      documentUrl: json['document_url'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      verifiedBy: json['verified_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'license_number': licenseNumber,
      'document_url': documentUrl,
      'rejection_reason': rejectionReason,
      'verified_by': verifiedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Whether the verification has been approved.
  bool get isApproved => status == 'approved';

  /// Whether the verification is still awaiting review.
  bool get isPending => status == 'pending';

  RealtorVerification copyWith({
    String? id,
    String? userId,
    String? status,
    String? licenseNumber,
    String? documentUrl,
    String? rejectionReason,
    String? verifiedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RealtorVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      documentUrl: documentUrl ?? this.documentUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealtorVerification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          status == other.status &&
          licenseNumber == other.licenseNumber &&
          documentUrl == other.documentUrl &&
          rejectionReason == other.rejectionReason &&
          verifiedBy == other.verifiedBy &&
          reviewedAt == other.reviewedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        status,
        licenseNumber,
        documentUrl,
        rejectionReason,
        verifiedBy,
        reviewedAt,
        createdAt,
        updatedAt,
      );
}
