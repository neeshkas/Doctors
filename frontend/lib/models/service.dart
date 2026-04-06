// Модель медицинской услуги и категории
// Категории соответствуют бэкенду

/// Категория медицинской услуги
enum ServiceCategory {
  onlineConsultation('ONLINE_CONSULTATION'),
  offlineConsultation('OFFLINE_CONSULTATION'),
  checkupKorea('CHECKUP_KOREA'),
  treatmentKorea('TREATMENT_KOREA'),
  examinationKorea('EXAMINATION_KOREA');

  const ServiceCategory(this.value);
  final String value;

  static ServiceCategory fromString(String value) {
    return ServiceCategory.values.firstWhere(
      (c) => c.value == value.toUpperCase(),
      orElse: () => ServiceCategory.onlineConsultation,
    );
  }
}

/// Модель медицинской услуги
class MedicalService {
  final String id;
  final ServiceCategory category;
  final String name;
  final String? description;
  final bool requiresTravel;
  final double basePrice;
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
      id: json['id'].toString(),
      category: ServiceCategory.fromString(json['category'] as String),
      name: json['name'] as String,
      description: json['description'] as String?,
      requiresTravel: json['requires_travel'] as bool? ?? false,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
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
}
