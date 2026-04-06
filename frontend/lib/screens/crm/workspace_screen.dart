import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

/// Экран «Мой рабочий стол» — задачи, специфичные для роли пользователя.
/// Каждая роль видит заказы, требующие её внимания.
class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final ApiService _api = ApiService();

  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String? _error;

  UserRole? _userRole;
  String _userRoleLabel = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndFetch();
    });
  }

  void _initAndFetch() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    _userRole = user?.role;
    _userRoleLabel = _roleLabel(_userRole);
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (_userRole == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.get(
        ApiConfig.orders,
        '/workspace/${_userRole!.value}',
      );
      setState(() {
        _tasks = data['items'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить задачи: $e';
        _isLoading = false;
      });
    }
  }

  void _openOrder(dynamic orderId) {
    context.go('/crm/orders/$orderId');
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
            Text(
              'Мой рабочий стол — $_userRoleLabel',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _taskDescription(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Кнопка обновить
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchTasks,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Обновить'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                if (!_isLoading)
                  Text(
                    '${_tasks.length} задач(а)',
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Список задач
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _tasks.isEmpty
                          ? _buildEmpty()
                          : _buildTaskList(),
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
            onPressed: _fetchTasks,
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
          Icon(Icons.check_circle_outline_rounded,
              size: 56, color: AppTheme.primaryColor),
          SizedBox(height: 12),
          Text(
            'Все задачи выполнены!',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Нет заказов, требующих вашего внимания',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final id = task['id']?.toString() ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    final clients = _extractClients(task);
    final status = task['status']?.toString() ?? '';
    final actionNeeded = _actionNeeded();
    final createdAt = _formatDate(task['created_at']?.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () => _openOrder(id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _taskIcon(),
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Заказ #$shortId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clients,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actionNeeded,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Дата
              Text(
                createdAt,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'fullyPaid':
        bgColor = const Color(0xFFE6F9F1);
        textColor = const Color(0xFF0D7A4E);
        label = 'Оплачен';
        break;
      case 'active':
        bgColor = const Color(0xFFE3F0FF);
        textColor = const Color(0xFF1565C0);
        label = 'Активный';
        break;
      case 'notPaid':
        bgColor = const Color(0xFFF0F0F0);
        textColor = const Color(0xFF616161);
        label = 'Не оплачен';
        break;
      default:
        bgColor = const Color(0xFFF0F0F0);
        textColor = AppTheme.secondaryText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // -- Утилиты --

  String _extractClients(dynamic task) {
    final clients = task['clients'];
    if (clients is List && clients.isNotEmpty) {
      return clients.map((c) => c['full_name'] ?? c['name'] ?? '').join(', ');
    }
    return 'Клиент не указан';
  }

  String _actionNeeded() {
    switch (_userRole) {
      case UserRole.flightsManager:
        return 'Требуется назначить авиабилеты';
      case UserRole.hotelsManager:
        return 'Требуется назначить отель';
      case UserRole.clinicsManager:
        return 'Требуется назначить клинику';
      case UserRole.doctorsManager:
        return 'Требуется назначить врача';
      case UserRole.visasManager:
        return 'Требуется оформить визу';
      case UserRole.excursionsManager:
        return 'Требуется подтвердить экскурсию';
      case UserRole.coordinator:
      case UserRole.manager:
        return 'Заказ не завершён — требуется контроль';
      default:
        return 'Требуется действие';
    }
  }

  IconData _taskIcon() {
    switch (_userRole) {
      case UserRole.flightsManager:
        return Icons.flight_rounded;
      case UserRole.hotelsManager:
        return Icons.hotel_rounded;
      case UserRole.clinicsManager:
        return Icons.local_hospital_rounded;
      case UserRole.doctorsManager:
        return Icons.person_rounded;
      case UserRole.visasManager:
        return Icons.badge_rounded;
      case UserRole.excursionsManager:
        return Icons.tour_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  String _taskDescription() {
    switch (_userRole) {
      case UserRole.flightsManager:
        return 'Заказы, ожидающие назначения авиабилетов';
      case UserRole.hotelsManager:
        return 'Заказы, ожидающие назначения отеля';
      case UserRole.clinicsManager:
        return 'Заказы, ожидающие назначения клиники';
      case UserRole.doctorsManager:
        return 'Заказы, ожидающие назначения врача';
      case UserRole.visasManager:
        return 'Заказы, ожидающие оформления визы';
      case UserRole.excursionsManager:
        return 'Заказы, ожидающие подтверждения экскурсии';
      case UserRole.coordinator:
      case UserRole.manager:
        return 'Все незавершённые заказы';
      default:
        return 'Ваши текущие задачи';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _roleLabel(UserRole? role) {
    if (role == null) return 'Неизвестно';
    switch (role) {
      case UserRole.coordinator:
        return 'Координатор';
      case UserRole.manager:
        return 'Менеджер';
      case UserRole.flightsManager:
        return 'Менеджер авиабилетов';
      case UserRole.hotelsManager:
        return 'Менеджер отелей';
      case UserRole.clinicsManager:
        return 'Менеджер клиник';
      case UserRole.doctorsManager:
        return 'Менеджер врачей';
      case UserRole.visasManager:
        return 'Менеджер виз';
      case UserRole.excursionsManager:
        return 'Менеджер экскурсий';
      case UserRole.client:
        return 'Клиент';
      case UserRole.partner:
        return 'Партнёр';
    }
  }
}
