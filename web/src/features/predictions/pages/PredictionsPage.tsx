import ComingSoon from "../../../core/components/ComingSoon";

const PredictionsPage = () => {
  return (
    <ComingSoon
      title="Predicciones IA"
      icon="psychology"
      description="Análisis predictivo de zonas de riesgo en Lima basado en histórico de incidentes, hora del día y condiciones del entorno."
      dependsOn="Microservicio ML (Random Forest + Prophet) — pendiente integración en api/."
    />
  );
};

export default PredictionsPage;
