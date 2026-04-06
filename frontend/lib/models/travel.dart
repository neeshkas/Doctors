// Модели travel-сервиса: перелёты, отели, клиники, врачи, визы, экскурсии
// Все ID — String (UUID с бэкенда), поля соответствуют backend-схемам

/// Статус визовой заявки (соответствует backend VisaStatus)
enum VisaStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  approved('APPROVED'),
  rejected('REJECTED');

  const VisaStatus(this.value);
  final String value;

  static VisaStatus fromString(String value) {
    return VisaStatus.values.firstWhere(
      (s) => s.value == value.toUpperCase(),
      orElse: () => VisaStatus.pending,
    );
  }
}

/// Модель перелёта
class Flight {
  final String id;
  final String partnerId;
  final String airline;
  final String flightNumber;
  final String departureCity;
  final String arrivalCity;
  final DateTime departureDate;
  final DateTime arrivalDate;
  final double price;
  final int seatsAvailable;
  final bool isActive;

  const Flight({
    required this.id,
    required this.partnerId,
    required this.airline,
    required this.flightNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureDate,
    required this.arrivalDate,
    required this.price,
    this.seatsAvailable = 0,
    this.isActive = true,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'].toString(),
      partnerId: json['partner_id'].toString(),
      airline: json['airline'] as String,
      flightNumber: json['flight_number'] as String,
      departureCity: json['departure_city'] as String,
      arrivalCity: json['arrival_city'] as String,
      departureDate: DateTime.parse(json['departure_date'] as String),
      arrivalDate: DateTime.parse(json['arrival_date'] as String),
      price: (json['price'] as num).toDouble(),
      seatsAvailable: json['seats_available'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Модель отеля
class Hotel {
  final String id;
  final String partnerId;
  final String name;
  final String city;
  final String address;
  final int starRating;
  final double pricePerNight;
  final String? description;
  final bool isActive;

  const Hotel({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.city,
    required this.address,
    required this.starRating,
    required this.pricePerNight,
    this.description,
    this.isActive = true,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'].toString(),
      partnerId: json['partner_id'].toString(),
      name: json['name'] as String,
      city: json['city'] as String,
      address: json['address'] as String? ?? '',
      starRating: json['star_rating'] as int? ?? 0,
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Модель клиники
class Clinic {
  final String id;
  final String partnerId;
  final String name;
  final String city;
  final String address;
  final String specialization;
  final String? description;
  final double rating;
  final bool isActive;

  const Clinic({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.city,
    required this.address,
    required this.specialization,
    this.description,
    this.rating = 0.0,
    this.isActive = true,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'].toString(),
      partnerId: json['partner_id'].toString(),
      name: json['name'] as String,
      city: json['city'] as String,
      address: json['address'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Модель врача
class Doctor {
  final String id;
  final String clinicId;
  final String fullName;
  final String specialization;
  final int experienceYears;
  final String? description;
  final double rating;
  final bool isActive;

  const Doctor({
    required this.id,
    required this.clinicId,
    required this.fullName,
    required this.specialization,
    this.experienceYears = 0,
    this.description,
    this.rating = 0.0,
    this.isActive = true,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'].toString(),
      clinicId: json['clinic_id'].toString(),
      fullName: json['full_name'] as String,
      specialization: json['specialization'] as String,
      experienceYears: json['experience_years'] as int? ?? 0,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Модель визовой заявки
class VisaApplication {
  final String id;
  final String clientId;
  final String orderId;
  final VisaStatus status;
  final String passportNumber;
  final DateTime appliedAt;
  final DateTime? resolvedAt;
  final String? notes;

  const VisaApplication({
    required this.id,
    required this.clientId,
    required this.orderId,
    required this.status,
    required this.passportNumber,
    required this.appliedAt,
    this.resolvedAt,
    this.notes,
  });

  factory VisaApplication.fromJson(Map<String, dynamic> json) {
    return VisaApplication(
      id: json['id'].toString(),
      clientId: json['client_id'].toString(),
      orderId: json['order_id'].toString(),
      status: VisaStatus.fromString(json['status'] as String),
      passportNumber: json['passport_number'] as String,
      appliedAt: DateTime.parse(json['applied_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

/// Модель экскурсии
class Excursion {
  final String id;
  final String partnerId;
  final String name;
  final String city;
  final String? description;
  final double price;
  final double durationHours;
  final bool isActive;

  const Excursion({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.city,
    this.description,
    required this.price,
    required this.durationHours,
    this.isActive = true,
  });

  factory Excursion.fromJson(Map<String, dynamic> json) {
    return Excursion(
      id: json['id'].toString(),
      partnerId: json['partner_id'].toString(),
      name: json['name'] as String,
      city: json['city'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      durationHours: (json['duration_hours'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
