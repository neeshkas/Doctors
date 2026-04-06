import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import 'excursion_screen.dart';

class VisaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedServices;
  final Map<String, dynamic>? selectedFlight;
  final Map<String, dynamic>? selectedHotel;
  final Map<String, dynamic>? selectedClinic;
  final Map<String, dynamic>? selectedDoctor;

  const VisaScreen({
    super.key,
    required this.selectedServices,
    this.selectedFlight,
    this.selectedHotel,
    this.selectedClinic,
    this.selectedDoctor,
  });

  @override
  State<VisaScreen> createState() => _VisaScreenState();
}

class _VisaScreenState extends State<VisaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passportController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _passportController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitted = true;
    });

    final visaData = {
      'passport_number': _passportController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExcursionScreen(
          selectedServices: widget.selectedServices,
          selectedFlight: widget.selectedFlight,
          selectedHotel: widget.selectedHotel,
          selectedClinic: widget.selectedClinic,
          selectedDoctor: widget.selectedDoctor,
          visaData: visaData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Заявка на визу'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppTheme.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Для поездки в Корею вам потребуется виза. Заполните данные ниже, и мы поможем с оформлением.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Номер паспорта',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passportController,
                          decoration: InputDecoration(
                            hintText: 'Введите номер паспорта',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Введите номер паспорта';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Примечания',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Дополнительная информация (необязательно)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                  onPressed: _submitted ? null : _proceed,
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
      ),
    );
  }
}
