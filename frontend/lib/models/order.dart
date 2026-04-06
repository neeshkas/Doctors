// Модель заказа, статусы, позиции и привязанные клиенты
// Значения enum соответствуют бэкенду (UPPER_CASE)

/// Статус заказа
enum OrderStatus {
  notPaid('NOT_PAID'),
  active('ACTIVE'),
  fullyPaid('FULLY_PAID'),
  cancelled('CANCELLED');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.value == value.toUpperCase(),
      orElse: () => OrderStatus.notPaid,
    );
  }
}

/// Позиция в заказе (услуга)
class OrderItem {
  final String id;
  final String orderId;
  final String serviceId;
  final String serviceName;
  final double price;
  final int quantity;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      serviceId: json['service_id'].toString(),
      serviceName: json['service_name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'quantity': quantity,
    };
  }
}

/// Клиент, привязанный к заказу
class OrderClient {
  final String id;
  final String orderId;
  final String clientId;
  final String clientName;
  final bool isPrimary;

  const OrderClient({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.clientName,
    this.isPrimary = false,
  });

  factory OrderClient.fromJson(Map<String, dynamic> json) {
    return OrderClient(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      clientId: json['client_id'].toString(),
      clientName: json['client_name'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

/// Модель заказа
class Order {
  final String id;
  final OrderStatus status;
  final bool requiresTravel;
  final String? flightId;
  final String? hotelId;
  final String? clinicId;
  final String? doctorId;
  final String? visaId;
  final bool excursionConfirmed;
  final double totalAmount;
  final double paidAmount;
  final String? notes;
  final List<OrderItem> items;
  final List<OrderClient> clients;
  final String? clientNames;
  final String? serviceNames;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    this.clientNames,
    this.serviceNames,
    required this.createdAt,
    this.updatedAt,
  });

  double get remainingAmount => totalAmount - paidAmount;
  bool get isFullyPaid => paidAmount >= totalAmount && totalAmount > 0;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      status: OrderStatus.fromString(json['status'] as String),
      requiresTravel: json['requires_travel'] as bool? ?? false,
      flightId: json['flight_id']?.toString(),
      hotelId: json['hotel_id']?.toString(),
      clinicId: json['clinic_id']?.toString(),
      doctorId: json['doctor_id']?.toString(),
      visaId: json['visa_id']?.toString(),
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
      clientNames: json['client_names'] as String?,
      serviceNames: json['service_names'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
