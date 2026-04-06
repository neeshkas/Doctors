// Модель пользователя и перечисление ролей
// Роли соответствуют backend-системе

/// Роли пользователей в системе DoctorsHunter
enum UserRole {
  /// Координатор — полный доступ
  coordinator('coordinator'),

  /// Менеджер — широкий доступ
  manager('manager'),

  /// Менеджер перелётов
  flightsManager('flights_manager'),

  /// Менеджер отелей
  hotelsManager('hotels_manager'),

  /// Менеджер клиник
  clinicsManager('clinics_manager'),

  /// Менеджер врачей
  doctorsManager('doctors_manager'),

  /// Менеджер виз
  visasManager('visas_manager'),

  /// Менеджер экскурсий
  excursionsManager('excursions_manager'),

  /// Клиент — пациент или сопровождающий
  client('client'),

  /// Партнёр
  partner('partner');

  const UserRole(this.value);

  /// Строковое значение роли для API
  final String value;

  /// Создание роли из строки JSON
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}

/// Модель пользователя системы
class User {
  /// Уникальный идентификатор
  final int id;

  /// Электронная почта
  final String email;

  /// Полное имя пользователя
  final String fullName;

  /// Роль в системе
  final UserRole role;

  /// Активен ли аккаунт
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.isActive = true,
  });

  /// Создание из JSON-ответа API
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromString(json['role'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Преобразование в JSON для отправки на API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      'is_active': isActive,
    };
  }

  /// Является ли пользователь администратором (координатор или менеджер)
  bool get isAdmin => role == UserRole.coordinator || role == UserRole.manager;

  /// Является ли пользователь клиентом
  bool get isClient => role == UserRole.client;

  /// Является ли пользователь сотрудником CRM (не клиент и не партнёр)
  bool get isCrmUser => role != UserRole.client && role != UserRole.partner;

  /// Проверка, может ли пользователь редактировать определённое поле/раздел
  /// Координатор и менеджер имеют доступ ко всему;
  /// специализированные менеджеры — только к своему разделу
  bool canEditField(String field) {
    if (isAdmin) return true;

    // Сопоставление полей с ролями
    final fieldRoleMap = <String, UserRole>{
      'flights': UserRole.flightsManager,
      'hotels': UserRole.hotelsManager,
      'clinics': UserRole.clinicsManager,
      'doctors': UserRole.doctorsManager,
      'visas': UserRole.visasManager,
      'excursions': UserRole.excursionsManager,
    };

    final requiredRole = fieldRoleMap[field];
    if (requiredRole == null) return false;

    return role == requiredRole;
  }

  @override
  String toString() => 'User(id: $id, email: $email, role: ${role.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
