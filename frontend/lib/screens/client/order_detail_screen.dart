import 'package:flutter/material.dart';

import '../../config/theme.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'NEW':
      case 'НОВЫЙ':
        return Colors.blue;
      case 'CONFIRMED':
      case 'ПОДТВЕРЖДЁН':
        return AppTheme.primary;
      case 'IN_PROGRESS':
      case 'В РАБОТЕ':
        return Colors.orange;
      case 'COMPLETED':
      case 'ЗАВЕРШЁН':
        return Colors.green;
      case 'CANCELLED':
      case 'ОТМЕНЁН':
        return AppTheme.error;
      default:
        return AppTheme.secondaryText;
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'NEW':
        return 'Новый';
      case 'CONFIRMED':
        return 'Подтверждён';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'COMPLETED':
        return 'Завершён';
      case 'CANCELLED':
        return 'Отменён';
      default:
        return status ?? 'Неизвестно';
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString();
    final totalAmount = _toDouble(order['total_amount']);
    final paidAmount = _toDouble(order['paid_amount']);
    final remaining = totalAmount - paidAmount;
    final services = order['services'] as List<dynamic>?;
    final flight = order['flight'] as Map<String, dynamic>?;
    final hotel = order['hotel'] as Map<String, dynamic>?;
    final clinic = order['clinic'] as Map<String, dynamic>?;
    final doctor = order['doctor'] as Map<String, dynamic>?;
    final visa = order['visa'] as Map<String, dynamic>?;
    final excursion = order['excursion'] as Map<String, dynamic>?;
    final receipts = order['receipts'] as List<dynamic>?;

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: Text('Заказ #${order['id'] ?? ''}'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: _statusColor(status),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Заказ #${order['id'] ?? ''}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(status),
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

            // Services
            if (services != null && services.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Услуги'),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: services.map<Widget>((s) {
                      final name = (s is Map) ? (s['name'] ?? '') : s.toString();
                      final price = (s is Map) ? s['price'] : null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.darkText,
                                ),
                              ),
                            ),
                            if (price != null)
                              Text(
                                '\$$price',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
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

            // Travel info
            if (flight != null || hotel != null || clinic != null || doctor != null || visa != null || excursion != null) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Информация о поездке'),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (flight != null)
                        _buildDetailRow(
                          Icons.flight,
                          'Рейс',
                          '${flight['airline'] ?? ''} ${flight['flight_number'] ?? ''}\n${flight['departure_city'] ?? ''} — ${flight['arrival_city'] ?? ''}',
                        ),
                      if (hotel != null)
                        _buildDetailRow(
                          Icons.hotel,
                          'Отель',
                          '${hotel['name'] ?? ''}\n${hotel['city'] ?? ''}',
                        ),
                      if (clinic != null)
                        _buildDetailRow(
                          Icons.local_hospital,
                          'Клиника',
                          '${clinic['name'] ?? ''}\n${clinic['city'] ?? ''}',
                        ),
                      if (doctor != null)
                        _buildDetailRow(
                          Icons.person,
                          'Врач',
                          '${doctor['name'] ?? ''}\n${doctor['specialization'] ?? ''}',
                        ),
                      if (visa != null)
                        _buildDetailRow(
                          Icons.badge,
                          'Виза',
                          'Паспорт: ${visa['passport_number'] ?? ''}',
                        ),
                      if (excursion != null)
                        _buildDetailRow(
                          Icons.tour,
                          'Экскурсия',
                          excursion['name'] ?? '',
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Payment summary
            const SizedBox(height: 16),
            _buildSectionTitle('Оплата'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPaymentRow('Итого', totalAmount, AppTheme.darkText),
                    const SizedBox(height: 12),
                    _buildPaymentRow('Оплачено', paidAmount, AppTheme.primary),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    _buildPaymentRow(
                      'Осталось',
                      remaining,
                      remaining > 0 ? AppTheme.error : Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            // Receipts
            if (receipts != null && receipts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Квитанции'),
              ...receipts.map<Widget>((receipt) {
                final r = receipt as Map<String, dynamic>;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt, color: AppTheme.primary, size: 22),
                    ),
                    title: Text(
                      r['description'] ?? 'Квитанция #${r['id'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    subtitle: Text(
                      r['date'] ?? '',
                      style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                    ),
                    trailing: Text(
                      '\$${r['amount'] ?? '0'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
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
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
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
          style: TextStyle(
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
