// Конфигурация API — базовый URL и пути к микросервисам
// API проксируется через nginx фронтенда → нет CORS проблем

import 'dart:html' show window;

/// Конфигурация подключения к API DoctorsHunter
class ApiConfig {
  ApiConfig._();

  /// Базовый URL API — строится из текущего origin браузера + /api
  /// В Docker: фронтенд на :3000, nginx проксирует /api/ → gateway
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    // Берём origin из браузера (http://localhost:3000) и добавляем /api
    return '${window.location.origin}/api';
  }

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
