import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../models/travel.dart';
import '../../../services/api_service.dart';

class FlightSelectionScreen extends StatefulWidget {
  const FlightSelectionScreen({super.key});

  @override
  State<FlightSelectionScreen> createState() => _FlightSelectionScreenState();
}

class _FlightSelectionScreenState extends State<FlightSelectionScreen> {
  final _api = ApiService();
  List<Flight> _flights = [];
  int? _selectedIndex;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.get(ApiConfig.travel, '/flights/');

      if (!mounted) return;

      final List<dynamic> list = data is List ? data : [];
      setState(() {
        _flights = list
            .map((e) => Flight.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось загрузить авиабилеты';
          _isLoading = false;
        });
      }
    }
  }

  void _proceed({bool skip = false}) {
    context.go('/client/travel/hotels');
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'ru').format(date);
    } catch (_) {
      return date.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Выбор авиабилетов'),
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
              onPressed: _loadFlights,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: _flights.isEmpty
              ? const Center(
                  child: Text(
                    'Нет доступных рейсов',
                    style:
                        TextStyle(fontSize: 16, color: AppTheme.secondaryText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flights.length,
                  itemBuilder: (context, index) => _buildFlightCard(index),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _proceed(skip: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryText,
                      side: BorderSide(
                          color: AppTheme.secondaryText.withOpacity(0.3)),
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text(
                      'Пропустить',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedIndex != null ? _proceed : null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor:
                          AppTheme.primaryColor.withOpacity(0.3),
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text(
                      'Далее',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightCard(int index) {
    final flight = _flights[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _selectedIndex,
                      onChanged: (val) {
                        setState(() {
                          _selectedIndex = val;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.flight,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        flight.airline,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        flight.flightNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Откуда',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.secondaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.departureCity,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            _formatDate(flight.departureDate),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward,
                        color: AppTheme.secondaryText, size: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Куда',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.secondaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.arrivalCity,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            _formatDate(flight.arrivalDate),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '\$${flight.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
