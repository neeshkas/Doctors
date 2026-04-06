// Модель медицинской услуги и категории

/// Категория медицинской услуги
enum ServiceCategory {
  /// Диагностика
  diagnostics('diagnostics'),

  /// Лечение
  treatment('treatment'),

  /// Хирургия
  surgery('surgery'),

  /// Консультация
  consultation('consultation'),

  /// Реабилитация
  rehabilitation('rehabilitation'),

  /// Прочее
  other('other');

  const ServiceCategory(this.value);
  final String value;

  static ServiceCategory fromString(String value) {
    return ServiceCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ServiceCategory.other,
    );
  }
}

/// Модель медицинской услуги
class MedicalService {
  /// Уникальный идентификатор
  final int id;

  /// Категория услуги
  final ServiceCategory category;

  /// Название услуги
  final String name;

  /// Описание
  final String? description;

  /// Требуется ли транспортировка для данной услуги
  final bool requiresTravel;

  /// Базовая стоимость
  final double basePrice;

  /// Активна ли услуга (доступна для заказа)
  final bool isActive;

  const MedicalService({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    this.requiresTravel = false,
    required this.basePrice,
    this.isActive = true,
  });

  factory MedicalService.fromJson(Map<String, dynamic> json) {
    return MedicalService(
      id: json['id'] as int,
      category: ServiceCategory.fromString(json['category'] as String),
      name: json['name'] as String,
      description: json['description'] as String?,
      requiresTravel: json['requires_travel'] as bool? ?? false,
      basePrice: (json['base_price'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.value,
      'name': name,
      'description': description,
      'requires_travel': requiresTravel,
      'base_price': basePrice,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'MedicalService(id: $id, name: $name)';
}
