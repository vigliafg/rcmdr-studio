# Diario di handoff — Onda 14 — Dipendenze obbligatorie

**Data:** 2026-11-15
**Stato:** completata (2.7.0)
**Decisione:** ADR-015
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa

**Stato:** branch `main`, HEAD corrente, modifica chiusa.

**Baseline:** suite invariata; `R CMD check --no-manual` su
`RcmdrShiny_2.7.0.tar.gz` → **Status: OK**.

**Prossimo task:** nessuno. Se serve un'installazione più leggera, valutare un
meta-pacchetto (ADR-015, alternativa scartata).

---

## 1. Risultato

- `ggplot2` e `plotly` spostati da `Suggests` a `Imports`.
- `install.packages("RcmdrShiny")` li installa automaticamente.
- Engine ggplot2 sempre offerto; plotly/HTML sempre disponibili per i tipi con
  espressione interattiva.
- `ggplotly_available()` resta come gate di compatibilità versioni.
- Documentazione aggiornata: README requirements, help chart-studio, vignetta.
- ADR-015 registra decisione e alternative.

## 2. File

- `DESCRIPTION` (2.7.0, Imports).
- `NEWS.md`, `README.md`, help topic, vignetta.
- `docs/upgrades/DECISIONS.md` (ADR-015).

## 3. Verifiche

| Verifica | Esito |
|---|---|
| `R CMD check --no-manual` 2.7.0 | **Status: OK** |
| `ggplot2`/`plotly` in Imports | verificato |
| Assenza dai Suggests | verificato |
| Documentazione coerente | aggiornata |

## 4. Limiti

- Installazione più pesante (dipendenze transitive di plotly/ggplot2).
- La compatibilità `ggplotly` non è garantita dall'installazione: il probe
  resta necessario.
- `htmlwidgets` resta in Suggests anche se arriva con plotly; è usato solo
  nell'export HTML.
