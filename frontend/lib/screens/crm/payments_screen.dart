import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/api_service.dart';

/// Экран «Оплаты и квитанции».
/// Отображает таблицу квитанций и сводки оплат по заказам.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _api = ApiService();

  List<dynamic> _receipts = [];
  List<dynamic> _orderSummaries = [];
  bool _isLoadingReceipts = true;
  bool _isLoadingSummaries = true;
  String? _errorReceipts;
  String? _errorSummaries;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
    _fetchOrderSummaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReceipts() async {
    setState(() {
      _isLoadingReceipts = true;
      _errorReceipts = null;
    });

    try {
      final params = <String, String>{};
      if (_searchQuery.isNotEmpty) {
        params['order_id'] = _searchQuery;
      }
      final data = await _api.get('/receipts', queryParams: params);
      setState(() {
        _receipts =
            data['items'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoadingReceipts = false;
      });
    } catch (e) {
      setState(() {
        _errorReceipts = 'Не удалось загрузить квитанции: $e';
        _isLoadingReceipts = false;
      });
    }
  }

  Future<void> _fetchOrderSummaries() async {
    setState(() {
      _isLoadingSummaries = true;
      _errorSummaries = null;
    });

    try {
      final data = await _api.get('/payments/summaries');
      setState(() {
        _orderSummaries =
            data['items'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
        _isLoadingSummaries = false;
      });
    } catch (e) {
      setState(() {
        _errorSummaries = 'Не удалось загрузить сводки: $e';
        _isLoadingSummaries = false;
      });
    }
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _fetchReceipts();
  }

  void _openOrder(String orderId) {
    Navigator.of(context).pushNamed('/crm/orders/$orderId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Оплаты и квитанции',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),

            // Поиск
            _buildSearchBar(),
            const SizedBox(height: 24),

            // Квитанции
            Text(
              'Последние квитанции',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildReceiptsTable(),
            const SizedBox(height: 32),

            // Сводки по заказам
            Text(
              'Сводка оплат по заказам',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildSummariesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск по ID заказа',
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
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                _fetchReceipts();
                _fetchOrderSummaries();
              },
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

  Widget _buildReceiptsTable() {
    if (_isLoadingReceipts) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorReceipts != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 36, color: AppTheme.errorColor),
                const SizedBox(height: 8),
                Text(
                  _errorReceipts!,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchReceipts,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_receipts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Квитанции не найдены',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
            DataColumn(label: Text('Заказ ID')),
            DataColumn(label: Text('Клиент')),
            DataColumn(label: Text('Сумма'), numeric: true),
            DataColumn(label: Text('Метод оплаты')),
            DataColumn(label: Text('Статус')),
            DataColumn(label: Text('Дата')),
          ],
          rows: _receipts.map<DataRow>((receipt) {
            final orderId = receipt['order_id']?.toString() ?? '';
            final shortOrderId =
                orderId.length > 8 ? orderId.substring(0, 8) : orderId;
            final clientName =
                receipt['client_name']?.toString() ?? '—';
            final amount = _toDouble(receipt['amount']);
            final method = receipt['method']?.toString() ?? '—';
            final status = receipt['status']?.toString() ?? '—';
            final date = _formatDate(receipt['created_at']?.toString());

            return DataRow(
              onSelectChanged: (_) => _openOrder(orderId),
              cells: [
                DataCell(
                  Text(
                    shortOrderId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                DataCell(Text(clientName)),
                DataCell(Text(_formatMoney(amount))),
                DataCell(Text(_paymentMethodLabel(method))),
                DataCell(_buildReceiptStatusBadge(status)),
                DataCell(Text(date)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummariesTable() {
    if (_isLoadingSummaries) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorSummaries != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 36, color: AppTheme.errorColor),
                const SizedBox(height: 8),
                Text(
                  _errorSummaries!,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchOrderSummaries,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_orderSummaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Нет данных по оплатам',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
            DataColumn(label: Text('Заказ ID')),
            DataColumn(label: Text('Всего'), numeric: true),
            DataColumn(label: Text('Оплачено'), numeric: true),
            DataColumn(label: Text('Остаток'), numeric: true),
            DataColumn(label: Text('Переплата'), numeric: true),
            DataColumn(label: Text('Статус')),
          ],
          rows: _orderSummaries.map<DataRow>((summary) {
            final orderId = summary['order_id']?.toString() ?? '';
            final shortOrderId =
                orderId.length > 8 ? orderId.substring(0, 8) : orderId;
            final total = _toDouble(summary['total_amount']);
            final paid = _toDouble(summary['paid_amount']);
            final remaining =
                _toDouble(summary['remaining'] ?? (total - paid));
            final overpayment = _toDouble(summary['overpayment'] ??
                (paid > total ? paid - total : 0));
            final status = summary['status']?.toString() ?? '';

            return DataRow(
              onSelectChanged: (_) => _openOrder(orderId),
              cells: [
                DataCell(
                  Text(
                    shortOrderId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                DataCell(Text(_formatMoney(total))),
                DataCell(Text(_formatMoney(paid))),
                DataCell(
                  Text(
                    _formatMoney(remaining > 0 ? remaining : 0),
                    style: TextStyle(
                      color: remaining > 0
                          ? AppTheme.errorColor
                          : AppTheme.darkText,
                      fontWeight:
                          remaining > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatMoney(overpayment),
                    style: TextStyle(
                      color: overpayment > 0
                          ? const Color(0xFF0D7A4E)
                          : AppTheme.darkText,
                    ),
                  ),
                ),
                DataCell(_buildPaymentStatusBadge(status)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReceiptStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = const Color(0xFF0D7A4E);
        label = 'Подтверждена';
        break;
      case 'pending':
        color = const Color(0xFFE6A800);
        label = 'Ожидание';
        break;
      case 'rejected':
        color = AppTheme.errorColor;
        label = 'Отклонена';
        break;
      default:
        color = AppTheme.secondaryText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'fullyPaid':
        bgColor = const Color(0xFFE6F9F1);
        textColor = const Color(0xFF0D7A4E);
        label = 'Оплачен';
        break;
      case 'partiallyPaid':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE6A800);
        label = 'Частично';
        break;
      case 'notPaid':
        bgColor = const Color(0xFFF0F0F0);
        textColor = const Color(0xFF616161);
        label = 'Не оплачен';
        break;
      case 'overpaid':
        bgColor = const Color(0xFFE3F0FF);
        textColor = const Color(0xFF1565C0);
        label = 'Переплата';
        break;
      default:
        bgColor = const Color(0xFFF0F0F0);
        textColor = AppTheme.secondaryText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  // ── Утилиты ──

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

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'card':
        return 'Карта';
      case 'cash':
        return 'Наличные';
      case 'transfer':
        return 'Перевод';
      case 'crypto':
        return 'Крипто';
      default:
        return method;
    }
  }
}
