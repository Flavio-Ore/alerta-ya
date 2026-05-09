// Enumeraciones compartidas del dominio AlertaYa.
// Importar desde aquí en todos los features — evita duplicación cross-feature.
enum IncidentType {
  robbery('ROBBERY', 'Robo/Asalto'),
  accident('ACCIDENT', 'Accidente de Tránsito'),
  suspicious('SUSPICIOUS', 'Persona Sospechosa'),
  harassment('HARASSMENT', 'Acoso'),
  extortion('EXTORTION', 'Extorsión');

  const IncidentType(this.value, this.label);
  final String value;
  final String label;

  static IncidentType fromValue(String v) =>
      IncidentType.values.firstWhere((e) => e.value == v);
}

enum Severity {
  low('LOW', 'Leve'),
  medium('MEDIUM', 'Moderado'),
  high('HIGH', 'Crítico');

  const Severity(this.value, this.label);
  final String value;
  final String label;

  static Severity fromValue(String v) =>
      Severity.values.firstWhere((e) => e.value == v);
}

enum IncidentStatus {
  pending('PENDING', 'Pendiente'),
  active('ACTIVE', 'Activo'),
  attended('ATTENDED', 'Atendido'),
  dismissed('DISMISSED', 'Descartado');

  const IncidentStatus(this.value, this.label);
  final String value;
  final String label;

  static IncidentStatus fromValue(String v) =>
      IncidentStatus.values.firstWhere((e) => e.value == v);
}
