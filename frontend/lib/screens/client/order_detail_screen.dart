import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';

class ClientOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const ClientOrderDetailScreen({super.key, required this.orderId});

  @override
  State<ClientOrderDetailScreen> createState() => _ClientOrderDetailScreenState();
}

class _ClientOrderDetailScreenState extends State<ClientOrderDetailScreen> {
  final _api = ApiService();
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.get(ApiConfig.orders, '/${widget.orderId}');

      if (!mounted) return;

      setState(() {
        _order = Order.fromJson(data as Map<String, dynamic>);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки заказа';
          _isLoading = false;
        });
      }
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.notPaid:
        return Colors.blue;
      case OrderStatus.active:
        return Colors.orange;
      case OrderStatus.fullyPaid:
        return Colors.green;
      case OrderStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.notPaid:
        return 'Не оплачен';
      case OrderStatus.active:
        return 'Активен';
      case OrderStatus.fullyPaid:
        return 'Оплачен';
      case OrderStatus.cancelled:
        return 'Отменён';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? _buildError()
              : _order != null
                  ? _buildContent(_order!)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrder,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Order order) {
    final statusColor = _statusColor(order.status);
    final remaining = order.remainingAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статус
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.buttonRadius),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заказ #${order.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(order.status),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Услуги
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Услуги'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: order.items.map<Widget>((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.serviceName,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ),
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // Клиенты
          if (order.clients.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Клиенты'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: order.clients.map<Widget>((client) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            client.isPrimary
                                ? Icons.star
                                : Icons.person_outline,
                            size: 18,
                            color: client.isPrimary
                                ? Colors.amber
                                : AppTheme.secondaryText,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            client.clientName,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // Информация о поездке
          if (order.requiresTravel) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Информация о поездке'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (order.flightId != null)
                      _buildDetailRow(
                        Icons.flight,
                        'Рейс',
                        'ID: ${order.flightId}',
                      ),
                    if (order.hotelId != null)
                      _buildDetailRow(
                        Icons.hotel,
                        'Отель',
                        'ID: ${order.hotelId}',
                      ),
                    if (order.clinicId != null)
                      _buildDetailRow(
                        Icons.local_hospital,
                        'Клиника',
                        'ID: ${order.clinicId}',
                      ),
                    if (order.doctorId != null)
                      _buildDetailRow(
                        Icons.person,
                        'Врач',
                        'ID: ${order.doctorId}',
                      ),
                    if (order.visaId != null)
                      _buildDetailRow(
                        Icons.badge,
                        'Виза',
                        'ID: ${order.visaId}',
                      ),
                    if (order.excursionConfirmed)
                      _buildDetailRow(
                        Icons.tour,
                        'Экскурсия',
                        'Подтверждена',
                      ),
                  ],
                ),
              ),
            ),
          ],

          // Оплата
          const SizedBox(height: 16),
          _buildSectionTitle('Оплата'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPaymentRow(
                      'Итого', order.totalAmount, AppTheme.darkText),
                  const SizedBox(height: 12),
                  _buildPaymentRow(
                      'Оплачено', order.paidAmount, AppTheme.primaryColor),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  _buildPaymentRow(
                    'Осталось',
                    remaining,
                    remaining > 0 ? AppTheme.errorColor : Colors.green,
                  ),
                ],
              ),
            ),
          ),

          // Заметки
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Заметки'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  order.notes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkText,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.secondaryText,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
