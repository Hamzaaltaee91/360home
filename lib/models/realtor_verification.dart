// RealtorVerification Model

class RealtorVerification {
  final String id;
  final String? realtorId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? fullName;
  final String? email;
  final String? companyName;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? documentUrl;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  RealtorVerification({
    required this.id,
    this.realtorId,
    required this.status,
    this.fullName,
    this.email,
    this.companyName,
    this.licenseNumber,
    this.licenseExpiry,
    this.documentUrl,
    this.rejectionReason,
    this.reviewedAt,
    required this.createdAt,
  });

  /// Parses rows from both `list_pending_realtor_applications` (always
  /// pending; no `verification_status` column) and
  /// `get_my_verification_status` (has `verification_status`, no
  /// company_name/license_expiry/full_name/email).
  factory RealtorVerification.fromJson(Map<String, dynamic> json) {
    return RealtorVerification(
      id: (json['verification_id'] ?? json['id']) as String,
      realtorId: json['realtor_id'] as String?,
      status:
          (json['verification_status'] ?? json['status'] ?? 'pending')
              as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      companyName: json['company_name'] as String?,
      licenseNumber: json['license_number'] as String?,
      licenseExpiry: json['license_expiry'] != null
          ? DateTime.parse(json['license_expiry'] as String)
          : null,
      documentUrl: json['document_url'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Whether the verification has been approved.
  bool get isApproved => status == 'approved';

  /// Whether the verification is still awaiting review.
  bool get isPending => status == 'pending';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealtorVerification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          realtorId == other.realtorId &&
          status == other.status &&
          fullName == other.fullName &&
          email == other.email &&
          companyName == other.companyName &&
          licenseNumber == other.licenseNumber &&
          licenseExpiry == other.licenseExpiry &&
          documentUrl == other.documentUrl &&
          rejectionReason == other.rejectionReason &&
          reviewedAt == other.reviewedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        realtorId,
        status,
        fullName,
        email,
        Object.hash(
          companyName,
          licenseNumber,
          licenseExpiry,
          documentUrl,
          rejectionReason,
        ),
        reviewedAt,
        createdAt,
      );
}
