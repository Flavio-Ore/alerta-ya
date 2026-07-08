import { z } from 'zod';

// Pregunta de la autoridad + la data histórica real que sirve de contexto (grounding).
export const analyzeSchema = z.object({
  question: z.string().min(1).max(500),
  context: z.object({
    districts: z
      .array(z.object({ district: z.string(), risk: z.number(), count: z.number() }))
      .max(60),
    types: z.array(z.object({ type: z.string(), count: z.number() })).max(30),
  }),
});

export type AnalyzeBody = z.infer<typeof analyzeSchema>;
