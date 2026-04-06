import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, dynamic>? selectedFlight;
  final Map<String, dynamic>? selectedHotel;
  final Map<String, dynamic>? selectedClinic;
  final Map<String, dynamic>? selectedDoctor;
  final Map<String, dynamic>? visaData;
  final Map<String, dynamic>? selectedExcursion;

  const CheckoutScreen({
    super.key,
    required this.selectedServices,
    this.selectedFlight,
    this.selectedHotel,
    this.selectedClinic,
    this.selectedDoctor,
    this.visaData,
    this.selectedExcursion,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final List<Map<String, dynamic>> _clients = [];
  final _clientNameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _clients.add({
        'name': user['fullName'] ?? user['full_name'] ?? 'Основной клиент',
        'id': user['id'],
      });
    } else {
      _clients.add({'name': 'Основной клиент'});
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = 0;
    for (final service in widget.selectedServices) {
      total += _toDouble(service['price']);
    }
    if (widget.selectedFlight != null) {
      total += _toDouble(widget.selectedFlight!['price']);
    }
    if (widget.selectedHotel != null) {
      total += _toDouble(widget.selectedHotel!['price_per_night']);
    }
    if (widget.selectedExcursion != null) {
      total += _toDouble(widget.selectedExcursion!['price']);
    }
    return total;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  void _addClient() {
    final name = _clientNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _clients.add({'name': name});
      _clientNameController.clear();
    });
  }

  void _removeClient(int index) {
    if (index == 0) return;
    setState(() {
      _clients.removeAt(index);
    });
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'services': widget.selectedServices.map((s) => s['id']).toList(),
        'clients': _clients,
        'total_amount': _totalPrice,
      };

      if (widget.selectedFlight != null) {
        body['flight_id'] = widget.selectedFlight!['id'];
      }
      if (widget.selectedHotel != null) {
        body['hotel_id'] = widget.selectedHotel!['id'];
      }
      if (widget.selectedClinic != null) {
        body['clinic_id'] = widget.selectedClinic!['id'];
      }
      if (widget.selectedDoctor != null) {
        body['doctor_id'] = widget.selectedDoctor!['id'];
      }
      if (widget.visaData != null) {
        body['visa'] = widget.visaData;
      }
      if (widget.selectedExcursion != null) {
        body['excursion_id'] = widget.selectedExcursion!['id'];
      }

      final response = await ApiService.post(
        '${ApiConfig.ordersUrl}',
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
          (route) => false,
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Ошибка оформления заказа';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка соединения с сервером';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Подтверждение заказа'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppTheme.error, fontSize: 14),
                      ),
                    ),
                  ],
                  _buildSectionTitle('Услуги'),
                  ...widget.selectedServices.map(
                    (s) => _buildSummaryItem(
                      icon: Icons.medical_services,
                      title: s['name'] ?? '',
                      subtitle: '\$${s['price'] ?? '0'}',
                    ),
                  ),
                  if (widget.selectedFlight != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Авиабилет'),
                    _buildSummaryItem(
                      icon: Icons.flight,
                      title: '${widget.selectedFlight!['airline'] ?? ''} ${widget.selectedFlight!['flight_number'] ?? ''}',
                      subtitle: '${widget.selectedFlight!['departure_city'] ?? ''} — ${widget.selectedFlight!['arrival_city'] ?? ''}\n\$${widget.selectedFlight!['price'] ?? '0'}',
                    ),
                  ],
                  if (widget.selectedHotel != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Отель'),
                    _buildSummaryItem(
                      icon: Icons.hotel,
                      title: widget.selectedHotel!['name'] ?? '',
                      subtitle: '${widget.selectedHotel!['city'] ?? ''}\n\$${widget.selectedHotel!['price_per_night'] ?? '0'} / ночь',
                    ),
                  ],
                  if (widget.selectedClinic != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Клиника'),
                    _buildSummaryItem(
                      icon: Icons.local_hospital,
                      title: widget.selectedClinic!['name'] ?? '',
                      subtitle: widget.selectedClinic!['city'] ?? '',
                    ),
                  ],
                  if (widget.selectedDoctor != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Врач'),
                    _buildSummaryItem(
                      icon: Icons.person,
                      title: widget.selectedDoctor!['name'] ?? '',
                      subtitle: widget.selectedDoctor!['specialization'] ?? '',
                    ),
                  ],
                  if (widget.visaData != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Виза'),
                    _buildSummaryItem(
                      icon: Icons.badge,
                      title: 'Паспорт: ${widget.visaData!['passport_number'] ?? ''}',
                      subtitle: widget.visaData!['notes']?.toString().isNotEmpty == true
                          ? widget.visaData!['notes']
                          : 'Без примечаний',
                    ),
                  ],
                  if (widget.selectedExcursion != null) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Экскурсия'),
                    _buildSummaryItem(
                      icon: Icons.tour,
                      title: widget.selectedExcursion!['name'] ?? '',
                      subtitle: '\$${widget.selectedExcursion!['price'] ?? '0'}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionTitle('Клиенты'),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ..._clients.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.darkText,
                                      ),
                                    ),
                                  ),
                                  if (entry.key > 0)
                                    IconButton(
                                      icon: Icon(Icons.close, size: 20, color: AppTheme.error),
                                      onPressed: () => _removeClient(entry.key),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _clientNameController,
                                  decoration: InputDecoration(
                                    hintText: 'Имя дополнительного клиента',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addClient,
                                icon: Icon(Icons.add_circle, color: AppTheme.primary, size: 32),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    color: AppTheme.primary.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Итого:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            '\$${_totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Оформить заказ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
