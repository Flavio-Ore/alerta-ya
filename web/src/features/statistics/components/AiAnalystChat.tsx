import { FC, useState } from "react";

import { useAnalyze, type AnalyzeContext } from "../infrastructure/ai.api";

interface Msg {
  role: "user" | "ai";
  text: string;
}

const SUGGESTIONS = [
  "¿Qué distritos priorizar para patrullaje?",
  "¿Qué tipo de delito predomina?",
  "¿Dónde se concentran los robos?",
];

/**
 * Chat de análisis IA para autoridades. Ancla las respuestas a la data histórica real
 * (rankings + tipos), que se pasa como contexto. La IA es asesor — la autoridad decide.
 */
export const AiAnalystChat: FC<AnalyzeContext> = ({ districts, types }) => {
  const [messages, setMessages] = useState<Msg[]>([]);
  const [input, setInput] = useState("");
  const analyze = useAnalyze();

  function ask(raw: string) {
    const question = raw.trim();
    if (!question || analyze.isPending) return;
    setMessages((m) => [...m, { role: "user", text: question }]);
    setInput("");
    analyze.mutate(
      { question, context: { districts, types } },
      {
        onSuccess: (answer) => setMessages((m) => [...m, { role: "ai", text: answer }]),
        onError: () =>
          setMessages((m) => [
            ...m,
            { role: "ai", text: "Asistente IA no disponible (configurá GLM_API_KEY en el backend)." },
          ]),
      },
    );
  }

  return (
    <section className="bg-stitch-surface-container rounded-xl border border-stitch-outline-variant p-5 flex flex-col gap-4">
      <div>
        <h2 className="text-xs font-bold text-stitch-on-surface-variant uppercase tracking-widest">
          Asistente de análisis IA
        </h2>
        <p className="text-[11px] text-stitch-on-surface-variant mt-1">
          Preguntá sobre la data histórica. La IA responde solo con estos datos — es asesor, vos decidís.
        </p>
      </div>

      <div className="flex flex-col gap-3 max-h-72 overflow-y-auto">
        {messages.length === 0 && (
          <div className="flex flex-wrap gap-2">
            {SUGGESTIONS.map((s) => (
              <button
                key={s}
                onClick={() => ask(s)}
                className="text-[11px] text-stitch-primary border border-stitch-primary/30 rounded-full px-3 py-1 hover:bg-stitch-primary/10 transition-colors"
              >
                {s}
              </button>
            ))}
          </div>
        )}

        {messages.map((m, i) => (
          <div key={i} className={m.role === "user" ? "self-end max-w-[85%]" : "self-start max-w-[90%]"}>
            <div
              className={`text-xs rounded-lg px-3 py-2 leading-relaxed ${
                m.role === "user"
                  ? "bg-stitch-primary-container text-stitch-primary"
                  : "bg-stitch-surface-container-high text-stitch-on-surface"
              }`}
            >
              {m.text}
            </div>
          </div>
        ))}

        {analyze.isPending && (
          <div className="self-start text-xs text-stitch-on-surface-variant">Analizando…</div>
        )}
      </div>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          ask(input);
        }}
        className="flex gap-2"
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Preguntá algo sobre los datos…"
          maxLength={500}
          className="flex-1 bg-stitch-surface-container-high text-sm text-white rounded-lg px-3 py-2 outline-none border border-stitch-outline-variant focus:border-stitch-primary"
        />
        <button
          type="submit"
          disabled={analyze.isPending || !input.trim()}
          className="bg-stitch-primary text-stitch-surface font-bold text-xs uppercase px-4 rounded-lg disabled:opacity-50"
        >
          Preguntar
        </button>
      </form>

      <p className="text-[10px] text-stitch-on-surface-variant">
        Base: histórico DataCrim 2017–2020 (dónde, no a qué hora). Contrasta con contexto
        actual de la web <b>(sin verificar)</b> — la fuente queda marcada en cada respuesta.
      </p>
    </section>
  );
};
