import { ComingSoon } from '../../../core/components/ComingSoon';

export default function StatisticsPage() {
  return (
    <ComingSoon
      title="Estadísticas e Insights"
      icon="bar_chart"
      description="Tendencias históricas de incidentes por distrito, tipo, severidad y tiempo de respuesta. Comparativas por semana, mes y año."
      dependsOn="Agregaciones pesadas en backend — endpoint /stats pendiente."
    />
  );
}
