# Skill Registry — AlertaYa

> Infraestructura para SDD. Regenerar con `/skill-registry` o `sdd-init`.

## User Skills (triggers)

| Skill | Trigger |
|-------|---------|
| go-testing | Tests en Go, Bubbletea TUI |
| skill-creator | Crear nuevas skills |
| caveman | Modo de comunicación comprimida |

## Project Conventions

- `CLAUDE.md` (raíz) — fuente de verdad del proyecto. Clean Architecture, gestores por servicio (mobile=flutter, web/api=bun, ml=uv).
- `docs/rules/CODING_STANDARDS.md` — convenciones de código.
- `docs/rules/SECURITY_RULES.md` — reglas de seguridad (críticas: nunca exponer reportante, cifrar AES-256, no loguear PII).
- `docs/rules/UI_RULES.md` — reglas UI.
- `docs/architecture/CONSTRAINTS.md` — restricciones MVP no negociables.

## Compact Rules — Python / ML (ml/)

- Stack: Python 3.11, FastAPI, uv, pytest. Modelos: scikit-learn, xgboost, pyod, prophet.
- Gestor: **uv** (nunca pip directo). `uv add` / `uv sync`.
- Clean Architecture: domain → application → infrastructure → presentation. Domain nunca importa infra.
- Tipado estricto, sin `dynamic`. Nombres en inglés, strings UI/comentarios en español.
- Tests: `uv run pytest --tb=short`. Lint CI: `flake8 src --max-line-length=100 --exclude=src/models/`.
- Modelos `.joblib` en `src/models/` (excluidos del lint; evaluar `.gitignore`).
- DataCrim solo tiene AÑO (sin hora) → modelos espaciales con datos reales; dimensión horaria = datos propios post-launch.
