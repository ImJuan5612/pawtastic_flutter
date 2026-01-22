class UserPaymentMethod {
  final String id;
  final String userId;
  final String paymentGatewayMethodId;
  final String? cardBrand;
  final String? lastFourDigits;
  final int? expiryMonth;
  final int? expiryYear;
  final String? cardholderName;
  bool isDefault;
  final DateTime createdAt;
  DateTime updatedAt;

  UserPaymentMethod({
    required this.id,
    required this.userId,
    required this.paymentGatewayMethodId,
    this.cardBrand,
    this.lastFourDigits,
    this.expiryMonth,
    this.expiryYear,
    this.cardholderName,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPaymentMethod.fromJson(Map<String, dynamic> json) {
    return UserPaymentMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      paymentGatewayMethodId: json['payment_gateway_method_id'] as String,
      cardBrand: json['card_brand'] as String?,
      lastFourDigits: json['last_four_digits'] as String?,
      expiryMonth: json['expiry_month'] as int?,
      expiryYear: json['expiry_year'] as int?,
      cardholderName: json['cardholder_name'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'payment_gateway_method_id': paymentGatewayMethodId,
      'card_brand': cardBrand,
      'last_four_digits': lastFourDigits,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cardholder_name': cardholderName,
      'is_default': isDefault,
      // 'created_at' y 'updated_at' son manejados por la DB usualmente al insertar/actualizar
    };
  }

  String get maskedCardNumber {
    return '**** **** **** $lastFourDigits';
  }
}
