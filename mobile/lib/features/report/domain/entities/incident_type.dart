enum IncidentType {
  robbery('ROBBERY', 'Robo/Asalto'),
  accident('ACCIDENT', 'Accidente de Tránsito'),
  suspicious('SUSPICIOUS', 'Persona Sospechosa'),
  harassment('HARASSMENT', 'Acoso'),
  extortion('EXTORTION', 'Extorsión');

  const IncidentType(this.value, this.label);
  final String value;
  final String label;

  static IncidentType fromValue(String value) =>
      IncidentType.values.firstWhere((e) => e.value == value);
}
