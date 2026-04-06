import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

/// Навигационный элемент бокового меню CRM.
class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  final List<String>? allowedRoles;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.allowedRoles,
  });
}

/// Корневой shell-layout CRM-части приложения.
/// Содержит боковое меню и область основного контента.
class CrmShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const CrmShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<CrmShell> createState() => _CrmShellState();
}

class _CrmShellState extends State<CrmShell> {
  static const double _sidebarWidth = 250.0;
  static const double _collapsedWidth = 72.0;
  static const double _responsiveBreakpoint = 900.0;

  bool _isCollapsed = false;

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Заказы',
      icon: Icons.list_alt_rounded,
      route: '/crm/orders',
    ),
    _NavItem(
      label: 'Мой рабочий стол',
      icon: Icons.dashboard_rounded,
      route: '/crm/workspace',
    ),
    _NavItem(
      label: 'Оплаты',
      icon: Icons.payments_rounded,
      route: '/crm/payments',
    ),
    _NavItem(
      label: 'Пользователи',
      icon: Icons.people_rounded,
      route: '/crm/users',
      allowedRoles: ['COORDINATOR', 'MANAGER'],
    ),
  ];

  void _navigateTo(String route) {
    if (route != widget.currentRoute) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  void _logout() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  bool _isItemVisible(_NavItem item, String? userRole) {
    if (item.allowedRoles == null) return true;
    return item.allowedRoles!.contains(userRole);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < _responsiveBreakpoint;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final userRole = user?.role;

    if (isNarrow) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('DoctorsHunter CRM'),
          backgroundColor: AppTheme.darkText,
          foregroundColor: AppTheme.white,
          iconTheme: const IconThemeData(color: AppTheme.white),
        ),
        drawer: Drawer(
          backgroundColor: AppTheme.darkText,
          child: _buildSidebarContent(
            userRole: userRole,
            userName: user?.fullName ?? 'Пользователь',
            userRoleLabel: _roleLabel(userRole),
            isCollapsed: false,
            isDrawer: true,
          ),
        ),
        body: widget.child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isCollapsed ? _collapsedWidth : _sidebarWidth,
            child: Material(
              color: AppTheme.darkText,
              child: _buildSidebarContent(
                userRole: userRole,
                userName: user?.fullName ?? 'Пользователь',
                userRoleLabel: _roleLabel(userRole),
                isCollapsed: _isCollapsed,
                isDrawer: false,
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebarContent({
    required String? userRole,
    required String userName,
    required String userRoleLabel,
    required bool isCollapsed,
    required bool isDrawer,
  }) {
    return Column(
      children: [
        // Логотип и кнопка сворачивания
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (!isCollapsed) ...[
                const Icon(
                  Icons.local_hospital_rounded,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'DoctorsHunter',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (isCollapsed)
                const Expanded(
                  child: Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                ),
              if (!isDrawer)
                IconButton(
                  icon: Icon(
                    isCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    color: AppTheme.white,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  tooltip: isCollapsed ? 'Развернуть' : 'Свернуть',
                ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF2A2D3A), height: 1),

        const SizedBox(height: 8),

        // Навигация
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: _navItems
                .where((item) => _isItemVisible(item, userRole))
                .map((item) => _buildNavTile(item, isCollapsed, isDrawer))
                .toList(),
          ),
        ),

        // Профиль пользователя
        const Divider(color: Color(0xFF2A2D3A), height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: isCollapsed
              ? Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.secondaryText,
                        size: 20,
                      ),
                      onPressed: _logout,
                      tooltip: 'Выйти',
                    ),
                  ],
                )
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userRoleLabel,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.secondaryText,
                        size: 20,
                      ),
                      onPressed: _logout,
                      tooltip: 'Выйти',
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNavTile(_NavItem item, bool isCollapsed, bool isDrawer) {
    final isActive = widget.currentRoute.startsWith(item.route);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isDrawer) Navigator.of(context).pop();
            _navigateTo(item.route);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isActive ? AppTheme.primaryColor : AppTheme.white,
                  size: 22,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color:
                            isActive ? AppTheme.primaryColor : AppTheme.white,
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'COORDINATOR':
        return 'Координатор';
      case 'MANAGER':
        return 'Менеджер';
      case 'FLIGHTS_MANAGER':
        return 'Менеджер авиабилетов';
      case 'HOTELS_MANAGER':
        return 'Менеджер отелей';
      case 'CLINICS_MANAGER':
        return 'Менеджер клиник';
      case 'DOCTORS_MANAGER':
        return 'Менеджер врачей';
      case 'VISAS_MANAGER':
        return 'Менеджер виз';
      case 'EXCURSIONS_MANAGER':
        return 'Менеджер экскурсий';
      default:
        return role ?? 'Неизвестно';
    }
  }
}
