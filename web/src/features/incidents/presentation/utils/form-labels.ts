/**
 * Traducción de los códigos del formulario dinámico móvil a etiquetas legibles.
 * Fuente: mobile/lib/features/report/data/schemas/report_form_schemas.dart
 *
 * Web y mobile son servicios independientes: este diccionario es una COPIA
 * intencional, no un import. Si el schema móvil cambia, actualizar aquí.
 */

/** Etiqueta de cada pregunta (key del formData). */
const FIELD_LABELS: Record<string, string> = {
  personsInvolved: 'Personas involucradas',
  weapon:          'Arma',
  stillInArea:     'Sigue en la zona',
  injured:         'Heridos visibles',
  vehicleCount:    'Vehículos involucrados',
  blocksTraffic:   'Bloquea el tráfico',
  medicalPresent:  'Presencia médica',
  notes:           'Notas',
};

/** Etiqueta de cada opción (valor del formData). */
const VALUE_LABELS: Record<string, string> = {
  // personsInvolved
  one:          '1 persona',
  two_three:    '2–3 personas',
  group:        'Grupo grande',
  // weapon
  firearm:      'Arma de fuego',
  blade:        'Arma blanca',
  // stillInArea
  yes:          'Sí',
  fled_foot:    'Huyó a pie',
  fled_vehicle: 'Huyó en vehículo',
  // vehicleCount
  two:          '2 vehículos',
  more:         'Más de 2',
  // blocksTraffic
  fully:        'Completamente',
  partially:    'Parcialmente',
  // medicalPresent
  incoming:     'En camino',
  // comunes
  none:         'No',
  no:           'No',
  unknown:      'No sé',
};

/** Códigos que representan una amenaza activa — se resaltan en rojo. */
const DANGER_VALUES = new Set(['firearm', 'blade', 'yes', 'group']);

export interface FormField {
  key:      string;
  label:    string;
  value:    string;
  isDanger: boolean;
  /** notes es texto libre del ciudadano, se renderiza distinto. */
  isFreeText: boolean;
}

export function fieldLabel(key: string): string {
  return FIELD_LABELS[key] ?? key;
}

export function valueLabel(value: string): string {
  return VALUE_LABELS[value] ?? value;
}

/**
 * Normaliza el formData crudo a una lista ordenada de campos legibles.
 * Filtra valores vacíos. `notes` siempre va al final como texto libre.
 */
export function parseFormData(formData: Record<string, unknown>): FormField[] {
  return Object.entries(formData)
    .filter(([, raw]) => raw != null && String(raw).trim() !== '')
    .map(([key, raw]) => {
      const value = String(raw);
      const isFreeText = key === 'notes';
      return {
        key,
        label:    fieldLabel(key),
        value:    isFreeText ? value : valueLabel(value),
        isDanger: !isFreeText && DANGER_VALUES.has(value),
        isFreeText,
      };
    })
    .sort((a, b) => Number(a.isFreeText) - Number(b.isFreeText));
}
