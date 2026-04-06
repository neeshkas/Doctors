// Универсальный HTTP-клиент для работы с API
// Автоматически добавляет Authorization-заголовок из SharedPreferences

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Ключ для хранения токена в SharedPreferences
const String tokenStorageKey = 'auth_token';

/// Базовый API-сервис с поддержкой авторизации
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Получение сохранённого токена из SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenStorageKey);
  }

  /// Формирование заголовков запроса с авторизацией
  Future<Map<String, String>> _buildHeaders({
    bool withAuth = true,
    Map<String, String>? extra,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extra != null) {
      headers.addAll(extra);
    }

    return headers;
  }

  /// Полный URL из пути сервиса и эндпоинта
  String _buildUrl(String servicePath, String endpoint) {
    return ApiConfig.url(servicePath, endpoint);
  }

  // ============================================================
  // HTTP-методы
  // ============================================================

  /// GET-запрос
  Future<dynamic> get(
    String servicePath,
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(servicePath, endpoint)).replace(
      queryParameters: queryParams,
    );
    final headers = await _buildHeaders(withAuth: withAuth);

    final response = await _client.get(uri, headers: headers);
    return _handleResponse(response);
  }

  /// POST-запрос
  Future<dynamic> post(
    String servicePath,
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(servicePath, endpoint));
    final headers = await _buildHeaders(withAuth: withAuth);

    final response = await _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT-запрос
  Future<dynamic> put(
    String servicePath,
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(servicePath, endpoint));
    final headers = await _buildHeaders(withAuth: withAuth);

    final response = await _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// DELETE-запрос
  Future<dynamic> delete(
    String servicePath,
    String endpoint, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(servicePath, endpoint));
    final headers = await _buildHeaders(withAuth: withAuth);

    final response = await _client.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  // ============================================================
  // Обработка ответа
  // ============================================================

  /// Обработка HTTP-ответа: декодирование JSON и проверка статуса
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Пустое тело (например, 204 No Content)
    if (response.body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) return null;
      throw ApiException(statusCode, 'Пустой ответ сервера');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(statusCode, 'Ошибка декодирования ответа');
    }

    // Успешный ответ
    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    // Извлечение сообщения об ошибке из тела ответа
    final errorMessage = decoded is Map<String, dynamic>
        ? (decoded['detail'] ?? decoded['message'] ?? 'Неизвестная ошибка')
            .toString()
        : 'Ошибка сервера';

    throw ApiException(statusCode, errorMessage);
  }

  /// Освобождение ресурсов HTTP-клиента
  void dispose() {
    _client.close();
  }
}

/// Исключение при ошибке API
class ApiException implements Exception {
  /// HTTP-код ответа
  final int statusCode;

  /// Сообщение об ошибке
  final String message;

  const ApiException(this.statusCode, this.message);

  /// Ошибка авторизации (401)
  bool get isUnauthorized => statusCode == 401;

  /// Доступ запрещён (403)
  bool get isForbidden => statusCode == 403;

  /// Не найдено (404)
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
