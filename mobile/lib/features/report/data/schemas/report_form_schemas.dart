import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';

/// Schemas de formulario dinámico hardcodeados para el MVP.
/// Solo ROBBERY y ACCIDENT activos (R07 — CONSTRAINTS.md).
/// Máximo 4 preguntas, solo opciones múltiples, siempre incluye "No sé" (CONSTRAINTS.md).
class ReportFormSchemas {
  ReportFormSchemas._();

  static DynamicFormSchema schemaFor(IncidentType type) {
    return switch (type) {
      IncidentType.robbery => _robbery,
      IncidentType.accident => _accident,
      _ => throw UnsupportedError('Tipo de incidente no disponible en MVP: ${type.value}'),
    };
  }

  static const _robbery = DynamicFormSchema(questions: [
    FormQuestion(
      id: 'personsInvolved',
      text: '¿Cuántas personas involucradas?',
      options: [
        FormOption(id: 'one', label: '1 persona'),
        FormOption(id: 'two_three', label: '2–3 personas'),
        FormOption(id: 'group', label: 'Grupo grande'),
        FormOption(id: 'unknown', label: 'No sé'),
      ],
    ),
    FormQuestion(
      id: 'weapon',
      text: '¿El agresor tenía arma?',
      options: [
        FormOption(id: 'firearm', label: 'Arma de fuego'),
        FormOption(id: 'blade', label: 'Arma blanca'),
        FormOption(id: 'none', label: 'No'),
        FormOption(id: 'unknown', label: 'No vi'),
      ],
    ),
    FormQuestion(
      id: 'stillInArea',
      text: '¿Sigue en la zona?',
      options: [
        FormOption(id: 'yes', label: 'Sí, está aquí'),
        FormOption(id: 'fled_foot', label: 'Huyó a pie'),
        FormOption(id: 'fled_vehicle', label: 'Huyó en vehículo'),
        FormOption(id: 'unknown', label: 'No sé'),
      ],
    ),
  ]);

  static const _accident = DynamicFormSchema(questions: [
    FormQuestion(
      id: 'injured',
      text: '¿Hay heridos visibles?',
      options: [
        FormOption(id: 'yes', label: 'Sí'),
        FormOption(id: 'no', label: 'No'),
        FormOption(id: 'unknown', label: 'No sé'),
      ],
    ),
    FormQuestion(
      id: 'vehicleCount',
      text: '¿Cuántos vehículos involucrados?',
      options: [
        FormOption(id: 'one', label: '1 vehículo'),
        FormOption(id: 'two', label: '2 vehículos'),
        FormOption(id: 'more', label: 'Más de 2'),
      ],
    ),
    FormQuestion(
      id: 'blocksTraffic',
      text: '¿Bloquea el tráfico?',
      options: [
        FormOption(id: 'fully', label: 'Completamente'),
        FormOption(id: 'partially', label: 'Parcialmente'),
        FormOption(id: 'no', label: 'No'),
      ],
    ),
    FormQuestion(
      id: 'medicalPresent',
      text: '¿Hay presencia médica?',
      options: [
        FormOption(id: 'yes', label: 'Ya llegaron'),
        FormOption(id: 'incoming', label: 'En camino'),
        FormOption(id: 'no', label: 'No'),
      ],
    ),
  ]);
}
