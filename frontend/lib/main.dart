// Точка входа приложения DoctorsHunter CRM
// MaterialApp.router + GoRouter + Provider для управления состоянием

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DoctorsHunterApp());
}

/// Корневой виджет приложения DoctorsHunter CRM
class DoctorsHunterApp extends StatefulWidget {
  const DoctorsHunterApp({super.key});

  @override
  State<DoctorsHunterApp> createState() => _DoctorsHunterAppState();
}

class _DoctorsHunterAppState extends State<DoctorsHunterApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createRouter(_authProvider);

    // Загружаем сохранённый токен при старте
    _authProvider.loadFromStorage();
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: 'DoctorsHunter CRM',
        debugShowCheckedModeBanner: false,

        // Тема с фирменными цветами DoctorsHunter
        theme: AppTheme.themeData,

        // Маршрутизация через GoRouter
        routerConfig: _router,

        // Локализация
        locale: const Locale('ru', 'RU'),
      ),
    );
  }
}
