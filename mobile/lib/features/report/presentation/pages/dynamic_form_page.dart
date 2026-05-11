import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import 'package:alertaya/features/report/data/schemas/report_form_schemas.dart';
import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import '../bloc/report_bloc.dart';

// Coordenadas del centro de Lima como fallback cuando GPS no disponible (R01 — CONSTRAINTS.md)
const _limaLat = -12.0464;
const _limaLng = -77.0428;

class DynamicFormPage extends StatefulWidget {
  const DynamicFormPage({super.key, required this.incidentType});
  final String incidentType;

  @override
  State<DynamicFormPage> createState() => _DynamicFormPageState();
}

class _DynamicFormPageState extends State<DynamicFormPage> {
  late final IncidentType _type;
  late final DynamicFormSchema _schema;
  final Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _type = IncidentType.fromValue(widget.incidentType);
    _schema = ReportFormSchemas.schemaFor(_type);
  }

  bool get _canSubmit => _answers.containsKey(_schema.questions.first.id);

  Future<void> _submit() async {
    if (!_canSubmit) return;

    double lat = _limaLat;
    double lng = _limaLng;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      // GPS no disponible — usa centro de Lima como fallback
    }

    if (!mounted) return;
    context.read<ReportBloc>().add(ReportSubmitted(
          type: _type,
          lat: lat,
          lng: lng,
          formData: Map.unmodifiable(_answers),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportSuccess) {
          context.go('/report/confirm');
        } else if (state is ReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al enviar el reporte. Intentá de nuevo.'),
              backgroundColor: AppColors.severityCritical,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.bgLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(_type.label, style: AppTextStyles.h2.copyWith(fontSize: 17)),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => context.go('/map'),
            ),
          ],
        ),
        body: Column(
          children: [
            _ProgressBar(step: 2),
            _UrgencyBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso 2 de 3 — Contá qué pasó',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._schema.questions.asMap().entries.map((entry) {
                      final question = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _QuestionCard(
                          question: question,
                          selectedOptionId: _answers[question.id],
                          onOptionSelected: (optionId) {
                            setState(() => _answers[question.id] = optionId);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      'Tu información es procesada inmediatamente por el centro de monitoreo de Lima. Procurá ser lo más preciso posible.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: AlertaYaButton(
              label: 'Enviar Reporte',
              onPressed: (_canSubmit && state is! ReportSubmitting) ? _submit : null,
              isLoading: state is ReportSubmitting,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: step / 3,
      backgroundColor: AppColors.bgGray,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 3,
    );
  }
}

class _UrgencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.accent.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            'Completa en menos de 10 segundos',
            style: AppTextStyles.label.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedOptionId,
    required this.onOptionSelected,
  });
  final FormQuestion question;
  final String? selectedOptionId;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.text, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: question.options.map((option) {
              final isSelected = selectedOptionId == option.id;
              return GestureDetector(
                onTap: () => onOptionSelected(option.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.bgLight : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
