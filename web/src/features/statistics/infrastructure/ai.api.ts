import { useMutation } from "@tanstack/react-query";

import { apiClient } from "../../../core/lib/axios";

export interface AnalyzeContext {
  districts: { district: string; risk: number; count: number }[];
  types:     { type: string; count: number }[];
}

async function analyze(question: string, context: AnalyzeContext): Promise<string> {
  const { data } = await apiClient.post<{ answer: string }>("/ai/analyze", { question, context });
  return data.answer;
}

/** Chat de análisis IA anclado a la data histórica (GLM, vía backend). */
export function useAnalyze() {
  return useMutation({
    mutationFn: ({ question, context }: { question: string; context: AnalyzeContext }) =>
      analyze(question, context),
  });
}
