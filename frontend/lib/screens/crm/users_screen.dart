import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

/// Экран управления пользователями (только для администраторов).
/// Таблица пользователей с возможностью изменения роли.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ApiService _api = ApiService();

  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  // Роль, которая редактируется inline — userId -> true
  final Set<String> _editingRoles = {};

  static const List<Map<String, String>> _allRoles = [
    {'value': 'manager', 'label': 'Менеджер'},
    {'value': 'coordinator', 'label': 'Координатор'},
    {'value': 'flights_manager', 'label': 'Менеджер авиабилетов'},
    {'value': 'hotels_manager', 'label': 'Менеджер отелей'},
    {'value': 'clinics_manager', 'label': 'Менеджер клиник'},
    {'value': 'doctors_manager', 'label': 'Менеджер врачей'},
    {'value': 'visas_manager', 'label': 'Менеджер виз'},
    {'value': 'excursions_manager', 'label': 'Менеджер экскурсий'},
    {'value': 'client', 'label': 'Клиент'},
  ];

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetch();
  }

  void _checkAccessAndFetch() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || !user.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/crm/orders');
        }
      });
      return;
    }
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.get(ApiConfig.auth, '/users');
      setState(() {
        _users =
            data['items'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить пользователей: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await _api.put(
        ApiConfig.auth,
        '/users/$userId/role',
        body: {'role': newRole},
      );
      setState(() => _editingRoles.remove(userId));
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Роль обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления роли: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Управление пользователями',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _fetchUsers,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Обновить'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_users.length} пользователей',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Таблица
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _users.isEmpty
                          ? _buildEmpty()
                          : _buildTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchUsers,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: AppTheme.secondaryText),
          SizedBox(height: 12),
          Text(
            'Пользователи не найдены',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.lightBg),
            columnSpacing: 24,
            horizontalMargin: 16,
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppTheme.darkText,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              color: AppTheme.darkText,
            ),
            columns: const [
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Имя')),
              DataColumn(label: Text('Роль')),
              DataColumn(label: Text('Статус')),
            ],
            rows: _users.map<DataRow>((user) => _buildRow(user)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(dynamic user) {
    final userId = user['id']?.toString() ?? '';
    final email = user['email']?.toString() ?? '—';
    final fullName = user['full_name']?.toString() ?? '—';
    final role = user['role']?.toString() ?? '—';
    final isActive = user['is_active'] == true;
    final isEditingRole = _editingRoles.contains(userId);

    return DataRow(
      cells: [
        DataCell(Text(email)),
        DataCell(Text(fullName)),
        DataCell(
          isEditingRole
              ? SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _allRoles.any((r) => r['value'] == role) ? role : null,
                    isDense: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _allRoles
                        .map(
                          (r) => DropdownMenuItem<String>(
                            value: r['value'],
                            child: Text(
                              r['label']!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (newRole) {
                      if (newRole != null && newRole != role) {
                        _updateRole(userId, newRole);
                      }
                    },
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRoleBadge(role),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () =>
                          setState(() => _editingRoles.add(userId)),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit, size: 14, color: AppTheme.secondaryText),
                      ),
                    ),
                  ],
                ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE6F9F1)
                  : const Color(0xFFFFE6E6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'Активен' : 'Неактивен',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF0D7A4E)
                    : AppTheme.errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final label = _allRoles.firstWhere(
      (r) => r['value'] == role,
      orElse: () => {'label': role},
    )['label']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
