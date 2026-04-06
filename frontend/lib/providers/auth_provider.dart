// Провайдер авторизации — управление состоянием текущего пользователя
// Хранит токен в SharedPreferences, уведомляет слушателей об изменениях

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Провайдер авторизации (ChangeNotifier для Provider)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  /// Текущий авторизованный пользователь
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Токен доступа
  String? _token;
  String? get token => _token;

  /// Флаг загрузки (для отображения индикатора)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке (для отображения в UI)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Авторизован ли пользователь
  bool get isLoggedIn => _token != null && _currentUser != null;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  /// Загрузка токена из хранилища при запуске приложения
  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(tokenStorageKey);

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;

        // Пытаемся получить данные пользователя по сохранённому токену
        try {
          _currentUser = await _authService.getMe();
        } catch (_) {
          // Токен недействителен — сбрасываем
          await _clearStorage();
        }
      }
    } catch (_) {
      // Ошибка чтения хранилища — игнорируем
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Вход в систему по email и паролю
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Получаем токен
      final newToken = await _authService.login(email, password);

      // Сохраняем токен
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenStorageKey, newToken);
      _token = newToken;

      // Получаем данные пользователя
      _currentUser = await _authService.getMe();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ошибка подключения к серверу';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Регистрация нового пользователя
  Future<bool> register(
    String email,
    String password,
    String fullName, {
    UserRole role = UserRole.client,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Регистрируем пользователя
      await _authService.register(email, password, fullName, role: role);

      // После успешной регистрации сразу входим
      return await login(email, password);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ошибка подключения к серверу';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    await _clearStorage();
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Очистка токена из хранилища
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenStorageKey);
  }

  /// Сброс сообщения об ошибке
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
