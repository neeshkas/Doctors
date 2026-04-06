import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../services/api_service.dart';
import '../checkout_screen.dart';

class ExcursionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, dynamic>? selectedFlight;
  final Map<String, dynamic>? selectedHotel;
  final Map<String, dynamic>? selectedClinic;
  final Map<String, dynamic>? selectedDoctor;
  final Map<String, dynamic>? visaData;

  const ExcursionScreen({
    super.key,
    required this.selectedServices,
    this.selectedFlight,
    this.selectedHotel,
    this.selectedClinic,
    this.selectedDoctor,
    this.visaData,
  });

  @override
  State<ExcursionScreen> createState() => _ExcursionScreenState();
}

class _ExcursionScreenState extends State<ExcursionScreen> {
  List<Map<String, dynamic>> _excursions = [];
  int? _selectedIndex;
  bool _wantsExcursion = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExcursions();
  }

  Future<void> _loadExcursions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('${ApiConfig.excursionsUrl}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _excursions = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Не удалось загрузить экскурсии';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка соединения с сервером';
          _isLoading = false;
        });
      }
    }
  }

  void _proceed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          selectedServices: widget.selectedServices,
          selectedFlight: widget.selectedFlight,
          selectedHotel: widget.selectedHotel,
          selectedClinic: widget.selectedClinic,
          selectedDoctor: widget.selectedDoctor,
          visaData: widget.visaData,
          selectedExcursion: (_wantsExcursion && _selectedIndex != null)
              ? _excursions[_selectedIndex!]
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Экскурсия по городу'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
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
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadExcursions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _wantsExcursion,
                          onChanged: (val) {
                            setState(() {
                              _wantsExcursion = val ?? false;
                              if (!_wantsExcursion) {
                                _selectedIndex = null;
                              }
                            });
                          },
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Хочу добавить экскурсию по городу',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_wantsExcursion) ...[
                  const SizedBox(height: 8),
                  if (_excursions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Нет доступных экскурсий',
                        style: TextStyle(fontSize: 16, color: AppTheme.secondaryText),
                      ),
                    )
                  else
                    ...List.generate(
                      _excursions.length,
                      (index) => _buildExcursionCard(index),
                    ),
                ],
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
                onPressed: (!_wantsExcursion || _selectedIndex != null) ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Далее',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExcursionCard(int index) {
    final excursion = _excursions[index];
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.transparent,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<int>(
                  value: index,
                  groupValue: _selectedIndex,
                  onChanged: (val) {
                    setState(() {
                      _selectedIndex = val;
                    });
                  },
                  activeColor: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.tour, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        excursion['name'] ?? 'Экскурсия',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      if (excursion['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          excursion['description'],
                          style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (excursion['duration'] != null) ...[
                            Icon(Icons.schedule, size: 14, color: AppTheme.secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              excursion['duration'],
                              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Text(
                            '\$${excursion['price'] ?? '—'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
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
