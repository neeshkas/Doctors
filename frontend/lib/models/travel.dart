// Модели для travel-сервиса: перелёты, отели, клиники, врачи, визы, экскурсии

/// Статус визовой заявки
enum VisaStatus {
  /// Черновик — заявка создана, но не подана
  draft('draft'),

  /// Подана — заявка отправлена на рассмотрение
  submitted('submitted'),

  /// На рассмотрении
  processing('processing'),

  /// Одобрена
  approved('approved'),

  /// Отклонена
  rejected('rejected'),

  /// Отменена
  cancelled('cancelled');

  const VisaStatus(this.value);
  final String value;

  static VisaStatus fromString(String value) {
    return VisaStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => VisaStatus.draft,
    );
  }
}

/// Модель перелёта
class Flight {
  final int id;

  /// Авиакомпания
  final String airline;

  /// Номер рейса
  final String flightNumber;

  /// Город вылета
  final String departureCity;

  /// Город прилёта
  final String arrivalCity;

  /// Дата и время вылета
  final DateTime departureAt;

  /// Дата и время прилёта
  final DateTime arrivalAt;

  /// Стоимость
  final double price;

  /// Доступные места
  final int? availableSeats;

  const Flight({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureAt,
    required this.arrivalAt,
    required this.price,
    this.availableSeats,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'] as int,
      airline: json['airline'] as String,
      flightNumber: json['flight_number'] as String,
      departureCity: json['departure_city'] as String,
      arrivalCity: json['arrival_city'] as String,
      departureAt: DateTime.parse(json['departure_at'] as String),
      arrivalAt: DateTime.parse(json['arrival_at'] as String),
      price: (json['price'] as num).toDouble(),
      availableSeats: json['available_seats'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airline': airline,
      'flight_number': flightNumber,
      'departure_city': departureCity,
      'arrival_city': arrivalCity,
      'departure_at': departureAt.toIso8601String(),
      'arrival_at': arrivalAt.toIso8601String(),
      'price': price,
      'available_seats': availableSeats,
    };
  }
}

/// Модель отеля
class Hotel {
  final int id;

  /// Название отеля
  final String name;

  /// Город
  final String city;

  /// Адрес
  final String? address;

  /// Количество звёзд (1–5)
  final int? stars;

  /// Стоимость за ночь
  final double pricePerNight;

  /// Описание
  final String? description;

  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    this.address,
    this.stars,
    required this.pricePerNight,
    this.description,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as int,
      name: json['name'] as String,
      city: json['city'] as String,
      address: json['address'] as String?,
      stars: json['stars'] as int?,
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'stars': stars,
      'price_per_night': pricePerNight,
      'description': description,
    };
  }
}

/// Модель клиники
class Clinic {
  final int id;

  /// Название клиники
  final String name;

  /// Город
  final String city;

  /// Адрес
  final String? address;

  /// Описание / специализация
  final String? description;

  /// Контактный телефон
  final String? phone;

  /// Активна ли клиника
  final bool isActive;

  const Clinic({
    required this.id,
    required this.name,
    required this.city,
    this.address,
    this.description,
    this.phone,
    this.isActive = true,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as int,
      name: json['name'] as String,
      city: json['city'] as String,
      address: json['address'] as String?,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'description': description,
      'phone': phone,
      'is_active': isActive,
    };
  }
}

/// Модель врача
class Doctor {
  final int id;

  /// Полное имя врача
  final String fullName;

  /// Специализация
  final String specialization;

  /// ID клиники, к которой прикреплён врач
  final int? clinicId;

  /// Стаж работы (лет)
  final int? experienceYears;

  /// Описание / квалификация
  final String? description;

  /// Активен ли врач
  final bool isActive;

  const Doctor({
    required this.id,
    required this.fullName,
    required this.specialization,
    this.clinicId,
    this.experienceYears,
    this.description,
    this.isActive = true,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      specialization: json['specialization'] as String,
      clinicId: json['clinic_id'] as int?,
      experienceYears: json['experience_years'] as int?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'specialization': specialization,
      'clinic_id': clinicId,
      'experience_years': experienceYears,
      'description': description,
      'is_active': isActive,
    };
  }
}

/// Модель визовой заявки
class VisaApplication {
  final int id;

  /// ID клиента
  final int clientId;

  /// Тип визы (например, медицинская)
  final String visaType;

  /// Статус заявки
  final VisaStatus status;

  /// Дата подачи
  final DateTime? submittedAt;

  /// Дата одобрения / отказа
  final DateTime? resolvedAt;

  /// Комментарий / заметки
  final String? notes;

  /// Дата создания записи
  final DateTime createdAt;

  const VisaApplication({
    required this.id,
    required this.clientId,
    required this.visaType,
    required this.status,
    this.submittedAt,
    this.resolvedAt,
    this.notes,
    required this.createdAt,
  });

  factory VisaApplication.fromJson(Map<String, dynamic> json) {
    return VisaApplication(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      visaType: json['visa_type'] as String,
      status: VisaStatus.fromString(json['status'] as String),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'visa_type': visaType,
      'status': status.value,
      'submitted_at': submittedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Модель экскурсии
class Excursion {
  final int id;

  /// Название экскурсии
  final String name;

  /// Описание
  final String? description;

  /// Город
  final String city;

  /// Продолжительность (часов)
  final double? durationHours;

  /// Стоимость
  final double price;

  /// Активна ли экскурсия
  final bool isActive;

  const Excursion({
    required this.id,
    required this.name,
    this.description,
    required this.city,
    this.durationHours,
    required this.price,
    this.isActive = true,
  });

  factory Excursion.fromJson(Map<String, dynamic> json) {
    return Excursion(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      city: json['city'] as String,
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'city': city,
      'duration_hours': durationHours,
      'price': price,
      'is_active': isActive,
    };
  }
}
