// Модель квитанции (чека) об оплате и сводка платежей

/// Способ оплаты
enum PaymentMethod {
  /// Наличные
  cash('cash'),

  /// Банковский перевод
  bankTransfer('bank_transfer'),

  /// Банковская карта
  card('card'),

  /// Онлайн-оплата
  online('online');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Статус платежа
enum PaymentStatus {
  /// Ожидает обработки
  pending('pending'),

  /// Подтверждён
  confirmed('confirmed'),

  /// Отклонён
  rejected('rejected'),

  /// Возвращён
  refunded('refunded');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Модель квитанции (чека) об оплате
class Receipt {
  /// Уникальный идентификатор
  final int id;

  /// ID заказа, к которому относится платёж
  final int orderId;

  /// Сумма платежа
  final double amount;

  /// Способ оплаты
  final PaymentMethod paymentMethod;

  /// Статус платежа
  final PaymentStatus status;

  /// Описание / комментарий к платежу
  final String? description;

  /// Дата фактической оплаты
  final DateTime? paidAt;

  /// Дата создания записи
  final DateTime createdAt;

  const Receipt({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.description,
    this.paidAt,
    required this.createdAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod:
          PaymentMethod.fromString(json['payment_method'] as String),
      status: PaymentStatus.fromString(json['status'] as String),
      description: json['description'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod.value,
      'status': status.value,
      'description': description,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Сводка по платежам для заказа
class PaymentSummary {
  /// ID заказа
  final int orderId;

  /// Общая сумма заказа
  final double totalAmount;

  /// Оплаченная сумма
  final double paidAmount;

  /// Остаток к оплате
  final double remainingAmount;

  /// Переплата (если есть)
  final double overpayment;

  /// Количество квитанций
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
      orderId: json['order_id'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      overpayment: (json['overpayment'] as num?)?.toDouble() ?? 0,
      receiptsCount: json['receipts_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'overpayment': overpayment,
      'receipts_count': receiptsCount,
    };
  }
}
