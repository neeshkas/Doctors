// Модель клиента (пациента)

/// Модель клиента — пациент или сопровождающий
class Client {
  /// Уникальный идентификатор клиента
  final int id;

  /// ID пользователя в системе авторизации
  final int? userId;

  /// Имя
  final String firstName;

  /// Фамилия
  final String lastName;

  /// Отчество
  final String? middleName;

  /// Телефон
  final String? phone;

  /// Электронная почта
  final String? email;

  /// Номер паспорта
  final String? passportNumber;

  /// Дата рождения
  final DateTime? dateOfBirth;

  /// Страна
  final String? country;

  /// Город
  final String? city;

  const Client({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phone,
    this.email,
    this.passportNumber,
    this.dateOfBirth,
    this.country,
    this.city,
  });

  /// Полное имя клиента (Фамилия Имя Отчество)
  String get fullName {
    final parts = <String>[lastName, firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    return parts.join(' ');
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      middleName: json['middle_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      passportNumber: json['passport_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      country: json['country'] as String?,
      city: json['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'phone': phone,
      'email': email,
      'passport_number': passportNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'country': country,
      'city': city,
    };
  }

  @override
  String toString() => 'Client(id: $id, name: $fullName)';
}
