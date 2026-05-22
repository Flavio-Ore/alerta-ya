import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import 'package:alertaya/features/report/data/schemas/report_form_schemas.dart';
import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/presentation/bloc/report_bloc.dart';

// Coordenadas del centro de Lima como fallback cuando GPS no disponible (R01 — CONSTRAINTS.md)
const _limaLat = -12.0464;
const _limaLng = -77.0428;

const _maxMediaFiles = 3;

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
  final List<XFile> _selectedMedia = [];
  final _picker = ImagePicker();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
    final notes = _notesController.text.trim();
    context.read<ReportBloc>().add(ReportSubmitted(
          type: _type,
          lat: lat,
          lng: lng,
          formData: Map.unmodifiable(_answers),
          mediaPaths: _selectedMedia.isEmpty
              ? null
              : _selectedMedia.map((f) => f.path).toList(),
          notes: notes.isEmpty ? null : notes,
        ));
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Tomar foto',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _SheetOption(
              icon: Icons.videocam_outlined,
              label: 'Grabar video (máx. 30s)',
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Desde galería',
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedMedia.length >= _maxMediaFiles) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file != null && mounted) setState(() => _selectedMedia.add(file));
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    if (_selectedMedia.length >= _maxMediaFiles) return;
    try {
      final file = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
      if (file != null && mounted) setState(() => _selectedMedia.add(file));
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    if (_selectedMedia.length >= _maxMediaFiles) return;
    try {
      final files = await _picker.pickMultipleMedia();
      if (files.isEmpty || !mounted) return;
      final remaining = _maxMediaFiles - _selectedMedia.length;
      setState(() => _selectedMedia.addAll(files.take(remaining)));
    } catch (_) {}
  }

  void _removeMedia(int index) {
    setState(() => _selectedMedia.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportSuccess) {
          context.go('/report/confirm');
        } else if (state is ReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar el reporte. Intenta de nuevo.'),
              backgroundColor: AppColors.severityCritical,
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text(_type.label, style: AppTextStyles.headlineMd.copyWith(fontSize: 17)),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.onSurface),
              onPressed: () => context.go('/map'),
            ),
          ],
        ),
        body: Column(
          children: [
            const _ProgressBar(step: 2),
            _UrgencyBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso 2 de 3 — Cuenta qué pasó',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
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
                    _EvidencePickerSection(
                      selectedMedia: _selectedMedia,
                      canAdd: _selectedMedia.length < _maxMediaFiles,
                      onAdd: () => _showPickerSheet(context),
                      onRemove: _removeMedia,
                    ),
                    const SizedBox(height: 16),
                    _NotesField(controller: _notesController),
                    const SizedBox(height: 16),
                    Text(
                      'Tu información es procesada inmediatamente por el centro de monitoreo de Lima. Procura ser lo más preciso posible.',
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
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
      backgroundColor: AppColors.surfaceContainerLow,
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
      color: AppColors.secondary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Completa en menos de 10 segundos',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidencePickerSection extends StatelessWidget {
  const _EvidencePickerSection({
    required this.selectedMedia,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> selectedMedia;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Adjuntar evidencia',
                style:
                    AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                'opcional',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          if (selectedMedia.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedMedia.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _MediaThumbnail(
                  file: selectedMedia[index],
                  onRemove: () => onRemove(index),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          canAdd
              ? OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: Text(selectedMedia.isEmpty
                      ? 'Adjuntar foto o video'
                      : 'Agregar otro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: const BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              : Text(
                  'Máximo $_maxMediaFiles archivos alcanzado',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
        ],
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  bool get _isVideo {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', '3gp', 'm4v'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _isVideo
              ? Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surface.withValues(alpha: 0.08),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: AppColors.onSurfaceVariant,
                    size: 32,
                  ),
                )
              : Image.file(
                  File(file.path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Detalles adicionales',
                style:
                    AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                'opcional',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            style: AppTextStyles.bodyLg,
            decoration: InputDecoration(
              hintText: 'Describe brevemente lo ocurrido…',
              hintStyle: AppTextStyles.bodyLg
                  .copyWith(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              counterStyle: AppTextStyles.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyLg),
      onTap: onTap,
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
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.text, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700)),
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
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.outline,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.surface : AppColors.onSurfaceVariant,
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
