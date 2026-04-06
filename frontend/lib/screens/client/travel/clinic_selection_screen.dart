import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../models/travel.dart';
import '../../../services/api_service.dart';

class ClinicSelectionScreen extends StatefulWidget {
  const ClinicSelectionScreen({super.key});

  @override
  State<ClinicSelectionScreen> createState() => _ClinicSelectionScreenState();
}

class _ClinicSelectionScreenState extends State<ClinicSelectionScreen> {
  final _api = ApiService();
  List<Clinic> _clinics = [];
  int? _selectedIndex;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.get(ApiConfig.travel, '/clinics/');

      if (!mounted) return;

      final List<dynamic> list = data is List ? data : [];
      setState(() {
        _clinics = list
            .map((e) => Clinic.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось загрузить клиники';
          _isLoading = false;
        });
      }
    }
  }

  void _proceed() {
    context.go('/client/travel/doctors');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Выбор клиники'),
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
              onPressed: _loadClinics,
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
          child: _clinics.isEmpty
              ? const Center(
                  child: Text(
                    'Нет доступных клиник',
                    style:
                        TextStyle(fontSize: 16, color: AppTheme.secondaryText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clinics.length,
                  itemBuilder: (context, index) => _buildClinicCard(index),
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
                onPressed: _selectedIndex != null ? _proceed : null,
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

  Widget _buildClinicCard(int index) {
    final clinic = _clinics[index];
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
                  child: const Icon(
                    Icons.local_hospital,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      if (clinic.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          clinic.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: AppTheme.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            clinic.city,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.secondaryText),
                          ),
                          if (clinic.specialization.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.medical_services,
                                size: 14, color: AppTheme.secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              clinic.specialization,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.secondaryText),
                            ),
                          ],
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
