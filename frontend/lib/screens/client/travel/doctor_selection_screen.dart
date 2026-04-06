import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../models/travel.dart';
import '../../../services/api_service.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final _api = ApiService();
  List<Doctor> _doctors = [];
  int? _selectedIndex;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.get(ApiConfig.travel, '/doctors/');

      if (!mounted) return;

      final List<dynamic> list = data is List ? data : [];
      setState(() {
        _doctors = list
            .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось загрузить врачей';
          _isLoading = false;
        });
      }
    }
  }

  void _proceed() {
    context.go('/client/travel/visa');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Выбор врача'),
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
              onPressed: _loadDoctors,
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
          child: _doctors.isEmpty
              ? const Center(
                  child: Text(
                    'Нет доступных врачей',
                    style:
                        TextStyle(fontSize: 16, color: AppTheme.secondaryText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) => _buildDoctorCard(index),
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

  Widget _buildDoctorCard(int index) {
    final doctor = _doctors[index];
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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person,
                      color: AppTheme.primaryColor, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialization,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (doctor.experienceYears != null) ...[
                            const Icon(Icons.work_outline,
                                size: 14, color: AppTheme.secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              '${doctor.experienceYears} лет',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.secondaryText),
                            ),
                          ],
                        ],
                      ),
                      if (doctor.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          doctor.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.secondaryText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
