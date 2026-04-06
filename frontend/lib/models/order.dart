// Модель заказа, статусы, позиции и привязанные клиенты

/// Статус заказа
enum OrderStatus {
  /// Не оплачен
  notPaid('not_paid'),

  /// Активен (частично оплачен или в работе)
  active('active'),

  /// Полностью оплачен
  fullyPaid('fully_paid'),

  /// Отменён
  cancelled('cancelled');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => OrderStatus.notPaid,
    );
  }
}

/// Позиция в заказе (услуга)
class OrderItem {
  /// ID услуги
  final int serviceId;

  /// Название услуги
  final String serviceName;

  /// Цена за единицу
  final double price;

  /// Количество
  final int quantity;

  const OrderItem({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.quantity,
  });

  /// Итого по позиции
  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'service_name': serviceName,
      'price': price,
      'quantity': quantity,
    };
  }
}

/// Клиент, привязанный к заказу
class OrderClient {
  /// ID клиента
  final int clientId;

  /// Имя клиента
  final String clientName;

  /// Основной клиент в заказе (пациент)
  final bool isPrimary;

  const OrderClient({
    required this.clientId,
    required this.clientName,
    this.isPrimary = false,
  });

  factory OrderClient.fromJson(Map<String, dynamic> json) {
    return OrderClient(
      clientId: json['client_id'] as int,
      clientName: json['client_name'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'client_name': clientName,
      'is_primary': isPrimary,
    };
  }
}

/// Модель заказа
class Order {
  final int id;

  /// Текущий статус заказа
  final OrderStatus status;

  /// Требуется ли транспортировка (перелёт, отель и т.д.)
  final bool requiresTravel;

  /// ID перелёта (если назначен)
  final int? flightId;

  /// ID отеля (если назначен)
  final int? hotelId;

  /// ID клиники
  final int? clinicId;

  /// ID врача
  final int? doctorId;

  /// ID визовой заявки
  final int? visaId;

  /// Подтверждена ли экскурсия
  final bool excursionConfirmed;

  /// Общая сумма заказа
  final double totalAmount;

  /// Оплаченная сумма
  final double paidAmount;

  /// Заметки к заказу
  final String? notes;

  /// Список позиций (услуг) в заказе
  final List<OrderItem> items;

  /// Список клиентов, привязанных к заказу
  final List<OrderClient> clients;

  /// Дата создания
  final DateTime createdAt;

  /// Дата последнего обновления
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.status,
    this.requiresTravel = false,
    this.flightId,
    this.hotelId,
    this.clinicId,
    this.doctorId,
    this.visaId,
    this.excursionConfirmed = false,
    required this.totalAmount,
    this.paidAmount = 0,
    this.notes,
    this.items = const [],
    this.clients = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Остаток к оплате
  double get remainingAmount => totalAmount - paidAmount;

  /// Полностью ли оплачен заказ
  bool get isFullyPaid => paidAmount >= totalAmount;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      status: OrderStatus.fromString(json['status'] as String),
      requiresTravel: json['requires_travel'] as bool? ?? false,
      flightId: json['flight_id'] as int?,
      hotelId: json['hotel_id'] as int?,
      clinicId: json['clinic_id'] as int?,
      doctorId: json['doctor_id'] as int?,
      visaId: json['visa_id'] as int?,
      excursionConfirmed: json['excursion_confirmed'] as bool? ?? false,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      clients: (json['clients'] as List<dynamic>?)
              ?.map((e) => OrderClient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.value,
      'requires_travel': requiresTravel,
      'flight_id': flightId,
      'hotel_id': hotelId,
      'clinic_id': clinicId,
      'doctor_id': doctorId,
      'visa_id': visaId,
      'excursion_confirmed': excursionConfirmed,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'notes': notes,
      'items': items.map((e) => e.toJson()).toList(),
      'clients': clients.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
