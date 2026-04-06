import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  final _api = ApiService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.get(ApiConfig.orders, '/');

      if (!mounted) return;

      final List<dynamic> list = data is List ? data : [];
      setState(() {
        _orders = list
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось загрузить заказы';
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
        title: const Text('Мои заказы'),
        actions: [
          IconButton(
            onPressed: () => context.go('/client/services'),
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
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
              onPressed: _loadOrders,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long,
                size: 80, color: AppTheme.secondaryText.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'У вас пока нет заказов',
              style: TextStyle(fontSize: 18, color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/client/services'),
              child: const Text('Выбрать услугу'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _statusColor(order.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          context.go('/client/orders/${order.id}');
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Заказ #${order.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(order.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: order.items.map<Widget>((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.serviceName,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.secondaryText),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Сумма',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.secondaryText),
                        ),
                        Text(
                          '\$${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Оплачено',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.secondaryText),
                        ),
                        Text(
                          '\$${order.paidAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.secondaryText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
