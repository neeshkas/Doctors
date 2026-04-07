// Конфигурация API — базовый URL и пути к микросервисам
// API проксируется через nginx фронтенда → нет CORS проблем

/// Конфигурация подключения к API DoctorsHunter
class ApiConfig {
  ApiConfig._();

  /// Базовый URL API.
  /// Фронтенд nginx проксирует /api/ → gateway.
  /// http пакет в Dart требует абсолютный URL,
  /// поэтому используем http://localhost:3000/api (порт фронтенда).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // Пути к микросервисам
  static const String auth = '/auth';
  static const String clients = '/clients';
  static const String services = '/services';
  static const String travel = '/travel';
  static const String orders = '/orders';
  static const String payments = '/payments';
  static const String partners = '/partners';

  /// Полный URL для указанного пути сервиса
  static String url(String servicePath, [String endpoint = '']) {
    return '$baseUrl$servicePath$endpoint';
  }
}
