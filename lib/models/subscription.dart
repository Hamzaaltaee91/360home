// Subscription Model

class Subscription {
  final String id;
  final String userId;
  final String plan; // 'free', 'basic', 'pro'
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
    required this.userId,
    required this.plan,
    required this.status,
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
      userId: json['user_id'] as String,
      plan: json['plan'] as String,
      status: json['status'] as String,
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
      'user_id': userId,
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

  /// Whether the subscription currently grants paid access.
  bool get isActive => status == 'active';

  Subscription copyWith({
    String? id,
    String? userId,
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
      userId: userId ?? this.userId,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          plan == other.plan &&
          status == other.status &&
          currentPeriodStart == other.currentPeriodStart &&
          currentPeriodEnd == other.currentPeriodEnd &&
          cancelAtPeriodEnd == other.cancelAtPeriodEnd &&
          paymentProvider == other.paymentProvider &&
          externalSubscriptionId == other.externalSubscriptionId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        plan,
        status,
        currentPeriodStart,
        currentPeriodEnd,
        cancelAtPeriodEnd,
        paymentProvider,
        externalSubscriptionId,
        createdAt,
        updatedAt,
      );
}
