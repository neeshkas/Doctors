// Конфигурация маршрутизации приложения (GoRouter)
// Два интерфейса: клиентский (/client/*) и CRM (/crm/*)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/client/services_screen.dart';
import '../screens/client/travel/flight_selection_screen.dart';
import '../screens/client/travel/hotel_selection_screen.dart';
import '../screens/client/travel/clinic_selection_screen.dart';
import '../screens/client/travel/doctor_selection_screen.dart';
import '../screens/client/travel/visa_screen.dart';
import '../screens/client/travel/excursion_screen.dart';
import '../screens/client/checkout_screen.dart';
import '../screens/client/orders_screen.dart';
import '../screens/client/order_detail_screen.dart';
import '../screens/crm/crm_shell.dart';
import '../screens/crm/orders_list_screen.dart';
import '../screens/crm/order_detail_screen.dart';
import '../screens/crm/workspace_screen.dart';
import '../screens/crm/payments_screen.dart';
import '../screens/crm/users_screen.dart';

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

// _CrmShell removed — using CrmShell from '../screens/crm/crm_shell.dart'

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
            const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) =>
            const RegisterScreen(),
      ),

      // ============================================================
      // Клиентский интерфейс
      // ============================================================
      GoRoute(
        path: '/client/services',
        name: 'clientServices',
        builder: (context, state) =>
            const ServicesScreen(),
      ),
      GoRoute(
        path: '/client/travel/flights',
        name: 'clientFlights',
        builder: (context, state) =>
            const FlightSelectionScreen(),
      ),
      GoRoute(
        path: '/client/travel/hotels',
        name: 'clientHotels',
        builder: (context, state) =>
            const HotelSelectionScreen(),
      ),
      GoRoute(
        path: '/client/travel/clinics',
        name: 'clientClinics',
        builder: (context, state) =>
            const ClinicSelectionScreen(),
      ),
      GoRoute(
        path: '/client/travel/doctors',
        name: 'clientDoctors',
        builder: (context, state) =>
            const DoctorSelectionScreen(),
      ),
      GoRoute(
        path: '/client/travel/visa',
        name: 'clientVisa',
        builder: (context, state) =>
            const VisaScreen(),
      ),
      GoRoute(
        path: '/client/travel/excursion',
        name: 'clientExcursion',
        builder: (context, state) =>
            const ExcursionScreen(),
      ),
      GoRoute(
        path: '/client/checkout',
        name: 'clientCheckout',
        builder: (context, state) =>
            const CheckoutScreen(),
      ),
      GoRoute(
        path: '/client/orders',
        name: 'clientOrders',
        builder: (context, state) =>
            const ClientOrdersScreen(),
      ),
      GoRoute(
        path: '/client/orders/:id',
        name: 'clientOrderDetail',
        builder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return ClientOrderDetailScreen(orderId: orderId);
        },
      ),

      // ============================================================
      // CRM интерфейс (с боковой навигацией)
      // ============================================================
      ShellRoute(
        builder: (context, state, child) => CrmShell(child: child, currentRoute: state.uri.path),
        routes: [
          GoRoute(
            path: '/crm/orders',
            name: 'crmOrders',
            builder: (context, state) =>
                const OrdersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'crmOrderDetail',
                builder: (context, state) {
                  return const OrderDetailScreen();
                },
              ),
            ],
          ),
          GoRoute(
            path: '/crm/workspace',
            name: 'crmWorkspace',
            builder: (context, state) =>
                const WorkspaceScreen(),
          ),
          GoRoute(
            path: '/crm/payments',
            name: 'crmPayments',
            builder: (context, state) =>
                const PaymentsScreen(),
          ),
          GoRoute(
            path: '/crm/users',
            name: 'crmUsers',
            builder: (context, state) =>
                const UsersScreen(),
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
