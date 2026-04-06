// Сервис авторизации — логин, регистрация, получение текущего пользователя

import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Сервис авторизации DoctorsHunter
class AuthService extends ApiService {
  AuthService({super.client});

  /// Авторизация по email и паролю
  /// Возвращает токен доступа
  Future<String> login(String email, String password) async {
    final response = await post(
      ApiConfig.auth,
      '/login',
      body: {
        'email': email,
        'password': password,
      },
      withAuth: false,
    );

    // API возвращает access_token
    return response['access_token'] as String;
  }

  /// Регистрация нового пользователя
  Future<User> register(
    String email,
    String password,
    String fullName, {
    UserRole role = UserRole.client,
  }) async {
    final response = await post(
      ApiConfig.auth,
      '/register',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role.value,
      },
      withAuth: false,
    );

    return User.fromJson(response as Map<String, dynamic>);
  }

  /// Получение данных текущего авторизованного пользователя
  Future<User> getMe() async {
    final response = await get(ApiConfig.auth, '/me');
    return User.fromJson(response as Map<String, dynamic>);
  }
}
