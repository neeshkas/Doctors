import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../models/travel.dart';
import '../../../services/api_service.dart';

class ExcursionScreen extends StatefulWidget {
  const ExcursionScreen({super.key});

  @override
  State<ExcursionScreen> createState() => _ExcursionScreenState();
}

class _ExcursionScreenState extends State<ExcursionScreen> {
  final _api = ApiService();
  List<Excursion> _excursions = [];
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
      final data = await _api.get(ApiConfig.travel, '/excursions/');

      if (!mounted) return;

      final List<dynamic> list = data is List ? data : [];
      setState(() {
        _excursions = list
            .map((e) => Excursion.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось загрузить экскурсии';
          _isLoading = false;
        });
      }
    }
  }

  void _proceed() {
    context.go('/client/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Экскурсия по городу'),
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
              onPressed: _loadExcursions,
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
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
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
                          activeColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
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
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Нет доступных экскурсий',
                        style: TextStyle(
                            fontSize: 16, color: AppTheme.secondaryText),
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
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (!_wantsExcursion || _selectedIndex != null)
                    ? _proceed
                    : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor:
                      AppTheme.primaryColor.withOpacity(0.3),
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
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                  child: const Icon(Icons.tour,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        excursion.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      if (excursion.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          excursion.description!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.secondaryText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (excursion.durationHours != null) ...[
                            const Icon(Icons.schedule,
                                size: 14, color: AppTheme.secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              '${excursion.durationHours!.toStringAsFixed(0)} ч',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.secondaryText),
                            ),
                            const SizedBox(width: 16),
                          ],
                          const Icon(Icons.location_on,
                              size: 14, color: AppTheme.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            excursion.city,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.secondaryText),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '\$${excursion.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
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
