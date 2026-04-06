// Конфигурация маршрутизации приложения (GoRouter)
// Два интерфейса: клиентский (/client/*) и CRM (/crm/*)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user.dart';

// ============================================================
// Заглушки экранов — будут заменены реальными виджетами
// ============================================================

/// Экран-заглушка с названием маршрута (для разработки)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
    );
  }
}

/// Оболочка CRM с боковой навигацией
class _CrmShell extends StatelessWidget {
  final Widget child;
  const _CrmShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final currentPath = GoRouterState.of(context).uri.path;

    // Определяем выбранный пункт меню по текущему пути
    int selectedIndex = 0;
    if (currentPath.startsWith('/crm/orders')) {
      selectedIndex = 0;
    } else if (currentPath.startsWith('/crm/workspace')) {
      selectedIndex = 1;
    } else if (currentPath.startsWith('/crm/payments')) {
      selectedIndex = 2;
    } else if (currentPath.startsWith('/crm/users')) {
      selectedIndex = 3;
    }

    // Пункты навигации
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: Text('Заказы'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.work_outline),
        selectedIcon: Icon(Icons.work),
        label: Text('Рабочее место'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.payment_outlined),
        selectedIcon: Icon(Icons.payment),
        label: Text('Платежи'),
      ),
      // Управление пользователями — только для администраторов
      if (user != null && user.isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Пользователи'),
        ),
    ];

    // Ограничиваем индекс количеством доступных пунктов
    if (selectedIndex >= destinations.length) {
      selectedIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1200,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/crm/orders');
                case 1:
                  context.go('/crm/workspace');
                case 2:
                  context.go('/crm/payments');
                case 3:
                  context.go('/crm/users');
              }
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // Логотип (сетевое изображение)
                  Image.network(
                    'https://doctorshunter.com/logo.svg',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_hospital,
                      size: 40,
                      color: Color(0xFF40BCA0),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Выйти',
                    onPressed: () {
                      authProvider.logout();
                      context.go('/login');
                    },
                  ),
                ),
              ),
            ),
            destinations: destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Создание роутера приложения
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Перенаправление на основе состояния авторизации
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isLoading = authProvider.isLoading;
      final currentPath = state.uri.path;

      // Пока идёт загрузка — не перенаправляем
      if (isLoading) return null;

      // Страницы авторизации
      final isAuthRoute =
          currentPath == '/login' || currentPath == '/register';

      // Не авторизован — перенаправляем на логин
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Авторизован, но на странице логина/регистрации — перенаправляем
      if (isLoggedIn && isAuthRoute) {
        return _defaultRouteForUser(authProvider.currentUser);
      }

      // Корневой путь — перенаправляем на основной экран
      if (isLoggedIn && currentPath == '/') {
        return _defaultRouteForUser(authProvider.currentUser);
      }

      // Клиент пытается попасть в CRM — перенаправляем
      if (isLoggedIn &&
          authProvider.currentUser?.isClient == true &&
          currentPath.startsWith('/crm')) {
        return '/client/services';
      }

      // Сотрудник CRM пытается попасть в клиентский интерфейс — перенаправляем
      if (isLoggedIn &&
          authProvider.currentUser?.isCrmUser == true &&
          currentPath.startsWith('/client')) {
        return '/crm/orders';
      }

      return null;
    },

    // Обновление роутера при изменении состояния авторизации
    refreshListenable: authProvider,

    routes: [
      // ============================================================
      // Авторизация
      // ============================================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Вход в систему'),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Регистрация'),
      ),

      // ============================================================
      // Клиентский интерфейс
      // ============================================================
      GoRoute(
        path: '/client/services',
        name: 'clientServices',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Выбор услуг'),
      ),
      GoRoute(
        path: '/client/travel/flights',
        name: 'clientFlights',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Выбор перелёта'),
      ),
      GoRoute(
        path: '/client/travel/hotels',
        name: 'clientHotels',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Выбор отеля'),
      ),
      GoRoute(
        path: '/client/travel/clinics',
        name: 'clientClinics',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Выбор клиники'),
      ),
      GoRoute(
        path: '/client/travel/doctors',
        name: 'clientDoctors',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Выбор врача'),
      ),
      GoRoute(
        path: '/client/travel/visa',
        name: 'clientVisa',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Визовая заявка'),
      ),
      GoRoute(
        path: '/client/travel/excursion',
        name: 'clientExcursion',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Подтверждение экскурсии'),
      ),
      GoRoute(
        path: '/client/checkout',
        name: 'clientCheckout',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Оформление заказа'),
      ),
      GoRoute(
        path: '/client/orders',
        name: 'clientOrders',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Мои заказы'),
      ),

      // ============================================================
      // CRM интерфейс (с боковой навигацией)
      // ============================================================
      ShellRoute(
        builder: (context, state, child) => _CrmShell(child: child),
        routes: [
          GoRoute(
            path: '/crm/orders',
            name: 'crmOrders',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Панель заказов'),
            routes: [
              GoRoute(
                path: ':id',
                name: 'crmOrderDetail',
                builder: (context, state) {
                  final orderId = state.pathParameters['id'] ?? '';
                  return _PlaceholderScreen(title: 'Заказ #$orderId');
                },
              ),
            ],
          ),
          GoRoute(
            path: '/crm/workspace',
            name: 'crmWorkspace',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Рабочее место'),
          ),
          GoRoute(
            path: '/crm/payments',
            name: 'crmPayments',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Платежи'),
          ),
          GoRoute(
            path: '/crm/users',
            name: 'crmUsers',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Управление пользователями'),
          ),
        ],
      ),
    ],
  );
}

/// Маршрут по умолчанию в зависимости от роли пользователя
String _defaultRouteForUser(User? user) {
  if (user == null) return '/login';

  if (user.isClient) return '/client/services';

  // Все сотрудники CRM и партнёры → панель заказов
  return '/crm/orders';
}
