// Модель квитанции об оплате и сводка платежей
// Enum-значения соответствуют бэкенду (payments-service)

/// Способ оплаты (соответствует PaymentMethod бэкенда)
enum PaymentMethod {
  cash('cash'),
  card('card'),
  transfer('transfer'),
  other('other');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.value == value.toLowerCase(),
      orElse: () => PaymentMethod.other,
    );
  }
}

/// Статус платежа (соответствует PaymentStatus бэкенда)
enum PaymentStatus {
  pending('pending'),
  completed('completed'),
  refunded('refunded');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (s) => s.value == value.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Модель квитанции (чека) об оплате
class Receipt {
  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String? description;
  final DateTime paidAt;
  final DateTime createdAt;

  const Receipt({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.description,
    required this.paidAt,
    required this.createdAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String),
      status: PaymentStatus.fromString(json['status'] as String),
      description: json['description'] as String?,
      paidAt: DateTime.parse(json['paid_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Сводка по платежам для заказа
class PaymentSummary {
  final String orderId;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final double overpayment;
  final int receiptsCount;

  const PaymentSummary({
    required this.orderId,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.overpayment = 0,
    required this.receiptsCount,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      orderId: json['order_id'].toString(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      overpayment: (json['overpayment'] as num?)?.toDouble() ?? 0,
      receiptsCount: json['receipts_count'] as int,
    );
  }
}
