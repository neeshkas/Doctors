import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

/// Мастер-панель заказов — главный экран CRM.
/// Отображает таблицу всех заказов с фильтрами, пагинацией и цветными статусами.
class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final ApiService _api = ApiService();

  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  // Пагинация
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  static const int _pageSize = 20;

  // Фильтры
  String? _statusFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _statusOptions = [
    {'value': '', 'label': 'Все статусы'},
    {'value': 'active', 'label': 'Активный'},
    {'value': 'fullyPaid', 'label': 'Оплачен'},
    {'value': 'notPaid', 'label': 'Не оплачен'},
    {'value': 'cancelled', 'label': 'Отменён'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final params = <String, String>{
        'page': _currentPage.toString(),
        'limit': _pageSize.toString(),
      };
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        params['status'] = _statusFilter!;
      }
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      final response = await _api.get('/orders', queryParams: params);
      final data = response;

      setState(() {
        _orders = data['items'] as List<dynamic>? ?? [];
        _totalItems = data['total'] as int? ?? 0;
        _totalPages = (_totalItems / _pageSize).ceil().clamp(1, 9999);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить заказы: $e';
        _isLoading = false;
      });
    }
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _statusFilter = value;
      _currentPage = 1;
    });
    _fetchOrders();
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _currentPage = 1;
    });
    _fetchOrders();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
    _fetchOrders();
  }

  void _openOrder(String orderId) {
    Navigator.of(context).pushNamed('/crm/orders/$orderId');
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
            Text(
              'Управление заказами',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Всего заказов: $_totalItems',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Фильтры
            _buildFiltersRow(),
            const SizedBox(height: 16),

            // Таблица
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _orders.isEmpty
                          ? _buildEmpty()
                          : _buildTable(),
            ),

            // Пагинация
            if (!_isLoading && _error == null) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            // Фильтр по статусу
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _statusFilter ?? '',
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _statusOptions
                    .map(
                      (opt) => DropdownMenuItem<String>(
                        value: opt['value'],
                        child: Text(opt['label']!),
                      ),
                    )
                    .toList(),
                onChanged: _onStatusFilterChanged,
              ),
            ),

            // Поиск по клиенту
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по клиенту',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    onPressed: _onSearch,
                  ),
                ),
                onSubmitted: (_) => _onSearch(),
              ),
            ),

            // Кнопка обновить
            ElevatedButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Обновить'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
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
          Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchOrders,
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
          Icon(Icons.inbox_rounded, size: 48, color: AppTheme.secondaryText),
          SizedBox(height: 12),
          Text(
            'Заказы не найдены',
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
            headingRowColor:
                WidgetStateProperty.all(AppTheme.lightBg),
            columnSpacing: 16,
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
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Статус')),
              DataColumn(label: Text('Клиент(ы)')),
              DataColumn(label: Text('Услуги')),
              DataColumn(label: Text('Путешествие')),
              DataColumn(label: Text('Авиабилеты')),
              DataColumn(label: Text('Отель')),
              DataColumn(label: Text('Клиника')),
              DataColumn(label: Text('Врач')),
              DataColumn(label: Text('Виза')),
              DataColumn(label: Text('Экскурсия')),
              DataColumn(label: Text('Сумма'), numeric: true),
              DataColumn(label: Text('Оплачено'), numeric: true),
              DataColumn(label: Text('Дата создания')),
            ],
            rows: _orders.map((order) => _buildRow(order)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(dynamic order) {
    final id = order['id']?.toString() ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    final status = order['status']?.toString() ?? '';
    final clients = _extractClients(order);
    final services = _extractServices(order);
    final requiresTravel = order['requires_travel'] == true;
    final flightAssigned = order['flight_id'] != null;
    final hotelAssigned = order['hotel_id'] != null;
    final clinicAssigned = order['clinic_id'] != null;
    final doctorAssigned = order['doctor_id'] != null;
    final visaStatus = order['visa_status']?.toString() ?? '';
    final excursionConfirmed = order['excursion_confirmed'] == true;
    final totalAmount = _toDouble(order['total_amount']);
    final paidAmount = _toDouble(order['paid_amount']);
    final createdAt = _formatDate(order['created_at']?.toString());

    return DataRow(
      onSelectChanged: (_) => _openOrder(id),
      cells: [
        DataCell(
          Text(
            shortId,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(status)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(clients, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(services, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(_buildCheckIcon(requiresTravel)),
        DataCell(_buildAssignedIcon(flightAssigned)),
        DataCell(_buildAssignedIcon(hotelAssigned)),
        DataCell(_buildAssignedIcon(clinicAssigned)),
        DataCell(_buildAssignedIcon(doctorAssigned)),
        DataCell(
          Text(
            visaStatus.isNotEmpty ? _visaLabel(visaStatus) : '—',
            style: TextStyle(
              fontSize: 12,
              color: visaStatus.isNotEmpty
                  ? AppTheme.darkText
                  : AppTheme.secondaryText,
            ),
          ),
        ),
        DataCell(_buildCheckIcon(excursionConfirmed)),
        DataCell(Text(_formatMoney(totalAmount))),
        DataCell(Text(_formatMoney(paidAmount))),
        DataCell(Text(createdAt)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
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
      case 'cancelled':
        bgColor = const Color(0xFFFFE6E6);
        textColor = AppTheme.errorColor;
        label = 'Отменён';
        break;
      default:
        bgColor = const Color(0xFFF0F0F0);
        textColor = AppTheme.secondaryText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildCheckIcon(bool value) {
    return Icon(
      value ? Icons.check_circle_rounded : Icons.remove_circle_outline,
      size: 20,
      color: value ? AppTheme.primaryColor : AppTheme.borderColor,
    );
  }

  Widget _buildAssignedIcon(bool assigned) {
    return Icon(
      assigned ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      size: 20,
      color: assigned ? AppTheme.primaryColor : AppTheme.borderColor,
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          ),
          const SizedBox(width: 8),
          ..._buildPageButtons(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            'Стр. $_currentPage из $_totalPages',
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    final pages = <int>[];
    final start = (_currentPage - 2).clamp(1, _totalPages);
    final end = (_currentPage + 2).clamp(1, _totalPages);
    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    return pages.map((page) {
      final isActive = page == _currentPage;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          width: 36,
          height: 36,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  isActive ? AppTheme.primaryColor : Colors.transparent,
              foregroundColor: isActive ? AppTheme.white : AppTheme.darkText,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _goToPage(page),
            child: Text(
              '$page',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Утилиты ──

  String _extractClients(dynamic order) {
    final clients = order['clients'];
    if (clients is List && clients.isNotEmpty) {
      return clients.map((c) => c['full_name'] ?? c['name'] ?? '').join(', ');
    }
    return '—';
  }

  String _extractServices(dynamic order) {
    final items = order['items'] ?? order['order_items'];
    if (items is List && items.isNotEmpty) {
      return items
          .map((i) => i['service_name'] ?? i['name'] ?? '')
          .join(', ');
    }
    return '—';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatMoney(double amount) {
    if (amount == amount.roundToDouble()) {
      return '${amount.toInt()} \$';
    }
    return '${amount.toStringAsFixed(2)} \$';
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

  String _visaLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Одобрена';
      case 'pending':
        return 'В обработке';
      case 'rejected':
        return 'Отказ';
      case 'submitted':
        return 'Подана';
      default:
        return status;
    }
  }
}
