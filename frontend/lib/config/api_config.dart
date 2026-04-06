// Конфигурация API — базовый URL и пути к микросервисам
// Все запросы проходят через nginx-шлюз

/// Конфигурация подключения к API DoctorsHunter
class ApiConfig {
  ApiConfig._();

  /// Базовый URL API-шлюза (nginx)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/api',
  );

  // ============================================================
  // Пути к микросервисам
  // ============================================================

  /// Сервис авторизации
  static const String auth = '/auth';

  /// Сервис клиентов
  static const String clients = '/clients';

  /// Сервис медицинских услуг
  static const String services = '/services';

  /// Сервис путешествий (перелёты, отели, клиники, врачи, визы, экскурсии)
  static const String travel = '/travel';

  /// Сервис заказов
  static const String orders = '/orders';

  /// Сервис платежей
  static const String payments = '/payments';

  /// Сервис партнёров
  static const String partners = '/partners';

  // ============================================================
  // Вспомогательные методы
  // ============================================================

  /// Полный URL для указанного пути сервиса
  static String url(String servicePath, [String endpoint = '']) {
    return '$baseUrl$servicePath$endpoint';
  }
}
