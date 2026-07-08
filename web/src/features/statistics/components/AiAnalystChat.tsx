import { FC, useEffect, useRef, useState } from "react";
import { Bot, CircleStop, Send, Sparkles, Trash2 } from "lucide-react";
import ReactMarkdown, { type Components } from "react-markdown";
import remarkGfm from "remark-gfm";

import {
  streamAnalyze,
  type AnalyzeContext,
} from "../infrastructure/ai.api";

interface Message {
  id: string;
  role: "user" | "ai";
  text: string;
  status?: "streaming" | "complete" | "error";
}

const SUGGESTIONS = [
  "¿Qué distritos priorizar para patrullaje?",
  "¿Qué tipo de delito predomina?",
  "¿Dónde se concentran los robos?",
];

const markdownComponents: Components = {
  h1: ({ children }) => (
    <h3 className="mb-2 mt-3 text-sm font-bold text-stitch-on-surface first:mt-0">
      {children}
    </h3>
  ),
  h2: ({ children }) => (
    <h3 className="mb-2 mt-3 text-sm font-bold text-stitch-on-surface first:mt-0">
      {children}
    </h3>
  ),
  h3: ({ children }) => (
    <h3 className="mb-2 mt-3 text-sm font-bold text-stitch-on-surface first:mt-0">
      {children}
    </h3>
  ),
  p: ({ children }) => <p className="mb-2 last:mb-0">{children}</p>,
  strong: ({ children }) => (
    <strong className="font-bold text-stitch-on-surface">{children}</strong>
  ),
  ul: ({ children }) => (
    <ul className="mb-2 list-disc space-y-1 pl-5 last:mb-0">{children}</ul>
  ),
  ol: ({ children }) => (
    <ol className="mb-2 list-decimal space-y-1 pl-5 last:mb-0">{children}</ol>
  ),
  blockquote: ({ children }) => (
    <blockquote className="my-2 border-l-2 border-stitch-primary pl-3 text-stitch-on-surface-variant">
      {children}
    </blockquote>
  ),
  a: ({ href, children }) => (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className="font-semibold text-stitch-primary underline underline-offset-2"
    >
      {children}
    </a>
  ),
};

function createMessageId(): string {
  return crypto.randomUUID();
}

/** Chat grounded en datos históricos, con respuesta incremental y Markdown seguro. */
export const AiAnalystChat: FC<AnalyzeContext> = ({ districts, types }) => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [isStreaming, setIsStreaming] = useState(false);
  const abortControllerRef = useRef<AbortController | null>(null);
  const conversationRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = conversationRef.current;
    if (container) container.scrollTop = container.scrollHeight;
  }, [messages]);

  useEffect(
    () => () => {
      abortControllerRef.current?.abort();
    },
    [],
  );

  async function ask(raw: string) {
    const question = raw.trim();
    if (!question || isStreaming) return;

    const userMessage: Message = {
      id: createMessageId(),
      role: "user",
      text: question,
      status: "complete",
    };
    const assistantMessageId = createMessageId();
    const assistantMessage: Message = {
      id: assistantMessageId,
      role: "ai",
      text: "",
      status: "streaming",
    };
    const controller = new AbortController();
    abortControllerRef.current = controller;

    setMessages((current) => [
      ...current,
      userMessage,
      assistantMessage,
    ]);
    setInput("");
    setIsStreaming(true);

    try {
      await streamAnalyze({
        question,
        context: { districts, types },
        signal: controller.signal,
        onDelta: (content) =>
          setMessages((current) =>
            current.map((message) =>
              message.id === assistantMessageId
                ? { ...message, text: message.text + content }
                : message,
            ),
          ),
      });
      setMessages((current) =>
        current.map((message) =>
          message.id === assistantMessageId
            ? { ...message, status: "complete" }
            : message,
        ),
      );
    } catch (error) {
      const errorMessage =
        error instanceof Error
          ? error.message
          : "No se pudo conectar con el asistente IA.";
      setMessages((current) =>
        current.map((message) => {
          if (message.id !== assistantMessageId) return message;
          const separator = message.text ? "\n\n" : "";
          return {
            ...message,
            text: `${message.text}${separator}> ${errorMessage}`,
            status: controller.signal.aborted ? "complete" : "error",
          };
        }),
      );
    } finally {
      abortControllerRef.current = null;
      setIsStreaming(false);
    }
  }

  return (
    <section className="flex flex-col gap-4 rounded-xl border border-stitch-outline-variant bg-stitch-surface-container p-5">
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-stitch-primary/30 bg-stitch-primary-container text-stitch-primary">
            <Sparkles size={18} aria-hidden="true" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-xs font-bold uppercase tracking-widest text-stitch-on-surface-variant">
                Asistente de análisis IA
              </h2>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-stitch-primary/30 px-2 py-0.5 text-[10px] font-bold text-stitch-primary">
                <span className="h-1.5 w-1.5 rounded-full bg-stitch-primary" />
                En vivo
              </span>
            </div>
            <p className="mt-1 text-xs text-stitch-on-surface-variant">
              Analiza el histórico DataCrim y separa claramente las fuentes.
            </p>
          </div>
        </div>

        {messages.length > 0 && !isStreaming && (
          <button
            type="button"
            onClick={() => setMessages([])}
            className="inline-flex min-h-11 items-center gap-2 rounded-lg px-3 text-xs font-semibold text-stitch-on-surface-variant hover:bg-stitch-surface-container-high hover:text-stitch-on-surface"
            aria-label="Limpiar conversación"
          >
            <Trash2 size={15} aria-hidden="true" />
            Limpiar
          </button>
        )}
      </div>

      <div
        ref={conversationRef}
        className="flex min-h-48 max-h-[30rem] flex-col gap-4 overflow-y-auto rounded-xl border border-stitch-outline-variant bg-stitch-surface-container-low p-4"
        aria-live="polite"
      >
        {messages.length === 0 && (
          <div className="flex flex-1 flex-col justify-center gap-4 py-4">
            <div className="flex items-center gap-2 text-sm font-semibold text-stitch-on-surface">
              <Bot size={18} className="text-stitch-primary" aria-hidden="true" />
              ¿Qué necesitas analizar?
            </div>
            <div className="flex flex-wrap gap-2">
              {SUGGESTIONS.map((suggestion) => (
                <button
                  key={suggestion}
                  type="button"
                  onClick={() => ask(suggestion)}
                  className="min-h-11 rounded-full border border-stitch-primary/30 px-4 py-2 text-left text-xs font-semibold text-stitch-primary hover:bg-stitch-primary/10"
                >
                  {suggestion}
                </button>
              ))}
            </div>
          </div>
        )}

        {messages.map((message) => (
          <article
            key={message.id}
            className={
              message.role === "user"
                ? "ml-auto max-w-[80%]"
                : "mr-auto w-full max-w-[92%]"
            }
          >
            <div className="mb-1 flex items-center gap-2 px-1 text-[10px] font-bold uppercase tracking-wider text-stitch-on-surface-variant">
              {message.role === "user" ? "Tú" : "Análisis IA"}
              {message.status === "streaming" && (
                <span className="normal-case tracking-normal text-stitch-primary">
                  Respondiendo en vivo…
                </span>
              )}
            </div>
            <div
              className={`rounded-xl px-4 py-3 text-sm leading-6 ${
                message.role === "user"
                  ? "bg-stitch-primary-container text-stitch-primary"
                  : message.status === "error"
                    ? "border border-stitch-error/40 bg-stitch-surface-container-high text-stitch-on-surface"
                    : "border border-stitch-outline-variant bg-stitch-surface-container-high text-stitch-on-surface"
              }`}
            >
              {message.role === "ai" ? (
                message.text ? (
                  <ReactMarkdown
                    remarkPlugins={[remarkGfm]}
                    components={markdownComponents}
                  >
                    {message.text}
                  </ReactMarkdown>
                ) : (
                  <span className="text-stitch-on-surface-variant">
                    Preparando análisis…
                  </span>
                )
              ) : (
                message.text
              )}
            </div>
          </article>
        ))}
      </div>

      <form
        onSubmit={(event) => {
          event.preventDefault();
          ask(input);
        }}
        className="flex gap-2"
      >
        <input
          value={input}
          onChange={(event) => setInput(event.target.value)}
          placeholder="Pregunta algo sobre los datos históricos…"
          maxLength={500}
          disabled={isStreaming}
          className="min-h-12 flex-1 rounded-xl border border-stitch-outline-variant bg-stitch-surface-container-high px-4 text-sm text-stitch-on-surface outline-none placeholder:text-stitch-outline focus:border-2 focus:border-stitch-primary disabled:opacity-60"
        />
        {isStreaming ? (
          <button
            type="button"
            onClick={() => abortControllerRef.current?.abort()}
            className="inline-flex min-h-12 min-w-32 items-center justify-center gap-2 rounded-full border border-stitch-outline px-5 text-xs font-bold uppercase text-stitch-on-surface hover:bg-stitch-surface-container-high"
          >
            <CircleStop size={16} aria-hidden="true" />
            Detener
          </button>
        ) : (
          <button
            type="submit"
            disabled={!input.trim()}
            className="inline-flex min-h-12 min-w-32 items-center justify-center gap-2 rounded-full bg-stitch-primary px-5 text-xs font-bold uppercase text-stitch-surface disabled:opacity-40"
          >
            <Send size={16} aria-hidden="true" />
            Preguntar
          </button>
        )}
      </form>

      <p className="text-[11px] text-stitch-on-surface-variant">
        Base: histórico DataCrim 2017–2020. El contexto web se muestra separado
        y con fuente. La IA asesora; la autoridad decide.
      </p>
    </section>
  );
};
