import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

/// Экран детализации заказа.
/// Разбит на секции: клиенты, услуги, путешествие, оплаты, заметки.
/// Редактирование — inline (внутри карточки), без модальных окон.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _order;
  List<dynamic> _receipts = [];
  bool _isLoading = true;
  String? _error;

  String _orderId = '';

  // Inline-редактирование — какое поле сейчас редактируется
  String? _editingField;
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Добавление квитанции
  bool _isAddingReceipt = false;
  final TextEditingController _receiptAmountController =
      TextEditingController();
  String _receiptMethod = 'card';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newId = GoRouterState.of(context).pathParameters['id'] ?? '';
    if (newId != _orderId) {
      _orderId = newId;
      _fetchOrder();
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _notesController.dispose();
    _receiptAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrder() async {
    if (_orderId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.get(ApiConfig.orders, '/$_orderId');
      List<dynamic> receipts = [];
      try {
        final receiptsData =
            await _api.get(ApiConfig.payments, '/by-order/$_orderId');
        receipts = receiptsData is List
            ? receiptsData
            : (receiptsData['items'] as List<dynamic>? ?? []);
      } catch (_) {
        // Квитанции могут быть недоступны — не блокируем загрузку заказа
      }

      setState(() {
        _order = data;
        _receipts = receipts;
        _notesController.text = data['notes']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить заказ: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveField(String field, dynamic value) async {
    try {
      await _api.put(ApiConfig.orders, '/$_orderId', body: {field: value});
      setState(() => _editingField = null);
      _fetchOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Future<void> _saveNotes() async {
    await _saveField('notes', _notesController.text);
  }

  Future<void> _addReceipt() async {
    final amount = double.tryParse(_receiptAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите корректную сумму')),
      );
      return;
    }

    try {
      await _api.post(ApiConfig.payments, '/by-order/$_orderId', body: {
        'amount': amount,
        'method': _receiptMethod,
      });
      setState(() {
        _isAddingReceipt = false;
        _receiptAmountController.clear();
      });
      _fetchOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Квитанция добавлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  bool _canEdit(String fieldName) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return false;
    return user.canEditField(fieldName);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.lightBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.lightBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchOrder,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final status = order['status']?.toString() ?? '';
    final shortId = _orderId.length > 8
        ? _orderId.substring(0, 8)
        : _orderId;

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кнопка назад + заголовок
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/crm/orders'),
                  tooltip: 'Назад к списку',
                ),
                const SizedBox(width: 8),
                Text(
                  'Заказ #$shortId',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 24),

            // Секции
            _buildClientsSection(order),
            const SizedBox(height: 16),
            _buildServicesSection(order),
            const SizedBox(height: 16),
            if (order['requires_travel'] == true) ...[
              _buildTravelSection(order),
              const SizedBox(height: 16),
            ],
            _buildPaymentsSection(order),
            const SizedBox(height: 16),
            _buildNotesSection(order),
          ],
        ),
      ),
    );
  }

  // -- Статус-бейдж --

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // -- Секция: Клиенты --

  Widget _buildClientsSection(Map<String, dynamic> order) {
    final clients = order['clients'] as List<dynamic>? ?? [];

    return _sectionCard(
      title: 'Клиенты',
      icon: Icons.people_outline_rounded,
      child: clients.isEmpty
          ? const Text(
              'Нет клиентов',
              style: TextStyle(color: AppTheme.secondaryText),
            )
          : Column(
              children: clients.map<Widget>((client) {
                final name = client['full_name'] ?? client['name'] ?? '—';
                final phone = client['phone'] ?? '—';
                final email = client['email'] ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppTheme.primaryColor.withOpacity(0.12),
                        child: Text(
                          name.toString().isNotEmpty
                              ? name.toString()[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              phone.toString(),
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            if (email.toString().isNotEmpty)
                              Text(
                                email.toString(),
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // -- Секция: Услуги --

  Widget _buildServicesSection(Map<String, dynamic> order) {
    final items =
        order['items'] as List<dynamic>? ?? order['order_items'] as List<dynamic>? ?? [];

    return _sectionCard(
      title: 'Услуги',
      icon: Icons.medical_services_outlined,
      child: items.isEmpty
          ? const Text(
              'Нет услуг',
              style: TextStyle(color: AppTheme.secondaryText),
            )
          : Column(
              children: [
                // Заголовок таблицы
                const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Название',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Кол-во',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Цена',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...items.map<Widget>((item) {
                  final name =
                      item['service_name'] ?? item['name'] ?? '—';
                  final qty = item['quantity'] ?? 1;
                  final price = item['price'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(name.toString()),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            qty.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$price \$',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  // -- Секция: Путешествие --

  Widget _buildTravelSection(Map<String, dynamic> order) {
    return _sectionCard(
      title: 'Путешествие',
      icon: Icons.flight_takeoff_rounded,
      child: Column(
        children: [
          _buildTravelRow(
            label: 'Авиабилеты',
            icon: Icons.flight_rounded,
            value: order['flight_details']?.toString(),
            assigned: order['flight_id'] != null,
            fieldName: 'flights',
            currentValue: order['flight_id']?.toString() ?? '',
          ),
          const Divider(height: 24),
          _buildTravelRow(
            label: 'Отель',
            icon: Icons.hotel_rounded,
            value: order['hotel_details']?.toString(),
            assigned: order['hotel_id'] != null,
            fieldName: 'hotels',
            currentValue: order['hotel_id']?.toString() ?? '',
          ),
          const Divider(height: 24),
          _buildTravelRow(
            label: 'Клиника',
            icon: Icons.local_hospital_rounded,
            value: order['clinic_details']?.toString(),
            assigned: order['clinic_id'] != null,
            fieldName: 'clinics',
            currentValue: order['clinic_id']?.toString() ?? '',
          ),
          const Divider(height: 24),
          _buildTravelRow(
            label: 'Врач',
            icon: Icons.person_rounded,
            value: order['doctor_details']?.toString(),
            assigned: order['doctor_id'] != null,
            fieldName: 'doctors',
            currentValue: order['doctor_id']?.toString() ?? '',
          ),
          const Divider(height: 24),
          _buildTravelRow(
            label: 'Виза',
            icon: Icons.badge_rounded,
            value: _visaLabel(order['visa_status']?.toString() ?? ''),
            assigned: order['visa_status'] != null &&
                order['visa_status'].toString().isNotEmpty,
            fieldName: 'visas',
            currentValue: order['visa_status']?.toString() ?? '',
          ),
          const Divider(height: 24),
          _buildExcursionRow(order),
        ],
      ),
    );
  }

  Widget _buildTravelRow({
    required String label,
    required IconData icon,
    required String? value,
    required bool assigned,
    required String fieldName,
    required String currentValue,
  }) {
    final isEditing = _editingField == fieldName;
    final canEdit = _canEdit(fieldName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.secondaryText),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 8),
            if (assigned)
              const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryColor)
            else
              const Icon(Icons.radio_button_unchecked,
                  size: 16, color: AppTheme.borderColor),
            const Spacer(),
            if (canEdit && !isEditing)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _editingField = fieldName;
                    _editController.text = currentValue;
                  });
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Изменить', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (isEditing) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _editController,
                  decoration: InputDecoration(
                    hintText: 'Введите ID или значение',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final apiField = '${fieldName}_id';
                  _saveField(apiField, _editController.text);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Сохранить', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => setState(() => _editingField = null),
                child: const Text('Отмена', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              assigned ? (value ?? '—') : 'Не назначено',
              style: TextStyle(
                color: assigned ? AppTheme.darkText : AppTheme.secondaryText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExcursionRow(Map<String, dynamic> order) {
    final confirmed = order['excursion_confirmed'] == true;
    final canEdit = _canEdit('excursions');

    return Row(
      children: [
        const Icon(Icons.tour_rounded, size: 20, color: AppTheme.secondaryText),
        const SizedBox(width: 10),
        const Text(
          'Экскурсия',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: confirmed
                ? const Color(0xFFE6F9F1)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            confirmed ? 'Подтверждено' : 'Не подтверждено',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: confirmed
                  ? const Color(0xFF0D7A4E)
                  : AppTheme.secondaryText,
            ),
          ),
        ),
        const Spacer(),
        if (canEdit)
          Switch(
            value: confirmed,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) =>
                _saveField('excursion_confirmed', val),
          ),
      ],
    );
  }

  // -- Секция: Оплаты --

  Widget _buildPaymentsSection(Map<String, dynamic> order) {
    final totalAmount = _toDouble(order['total_amount']);
    final paidAmount = _toDouble(order['paid_amount']);
    final remaining = totalAmount - paidAmount;
    final overpayment = remaining < 0 ? remaining.abs() : 0.0;

    return _sectionCard(
      title: 'Оплаты',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Сводка
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _summaryItem('Всего', _formatMoney(totalAmount)),
              _summaryItem('Оплачено', _formatMoney(paidAmount)),
              if (remaining > 0)
                _summaryItem(
                    'Остаток', _formatMoney(remaining),
                    color: AppTheme.errorColor),
              if (overpayment > 0)
                _summaryItem(
                    'Переплата', _formatMoney(overpayment),
                    color: const Color(0xFF0D7A4E)),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Список квитанций
          const Text(
            'Квитанции',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),

          if (_receipts.isEmpty)
            const Text(
              'Нет квитанций',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
            )
          else
            ..._receipts.map<Widget>((receipt) {
              final amount = _toDouble(receipt['amount']);
              final method = receipt['method']?.toString() ?? '—';
              final status = receipt['status']?.toString() ?? '—';
              final date = _formatDate(receipt['created_at']?.toString());
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(date)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatMoney(amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                        flex: 2, child: Text(_paymentMethodLabel(method))),
                    Expanded(
                      flex: 2,
                      child: _buildReceiptStatusBadge(status),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),

          // Добавить квитанцию
          if (!_isAddingReceipt)
            OutlinedButton.icon(
              onPressed: () => setState(() => _isAddingReceipt = true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить квитанцию'),
            )
          else
            _buildAddReceiptForm(),
        ],
      ),
    );
  }

  Widget _buildAddReceiptForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightBg,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Новая квитанция',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _receiptAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _receiptMethod,
                  decoration: const InputDecoration(
                    labelText: 'Метод оплаты',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'card', child: Text('Карта')),
                    DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                    DropdownMenuItem(value: 'transfer', child: Text('Перевод')),
                    DropdownMenuItem(value: 'crypto', child: Text('Крипто')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _receiptMethod = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _addReceipt,
                child: const Text('Сохранить'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  _isAddingReceipt = false;
                  _receiptAmountController.clear();
                }),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ],
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
    return Text(label, style: TextStyle(color: color, fontSize: 13));
  }

  Widget _summaryItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color ?? AppTheme.darkText,
          ),
        ),
      ],
    );
  }

  // -- Секция: Заметки --

  Widget _buildNotesSection(Map<String, dynamic> order) {
    return _sectionCard(
      title: 'Заметки',
      icon: Icons.notes_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Добавьте заметки к заказу...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveNotes,
            child: const Text('Сохранить заметки'),
          ),
        ],
      ),
    );
  }

  // -- Общая обёртка секции --

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // -- Утилиты --

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
      case '':
        return 'Не подано';
      default:
        return status;
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
