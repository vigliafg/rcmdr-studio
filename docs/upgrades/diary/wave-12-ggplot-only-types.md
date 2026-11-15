# Diario di handoff — Onda 12 — Tipi ggplot-only

**Data:** 2026-11-15
**Stato:** completata (2.5.0)
**Documento di settore:** [`../12-ggplot-only-types.md`](../12-ggplot-only-types.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa

**Stato:** branch `main`, HEAD corrente, Onda 12 chiusa.

**Baseline:** `testthat::test_local()` → **3755 pass, 0 fail, 22 skip**;
`R CMD check --no-manual` → **Status: OK**.

**Prossimo task:** nessuno obbligatorio. Estensioni: facet grid, heatmap con
annotazioni, contour filled, campo argomenti R aggiuntivi.

---

## 1. Risultato

Aggiunti quattro tipi disponibili solo con ggplot2:

- **Violino**: trim, scala area/count/width, adjust, boxplot sovrapposto.
- **ECDF**: pad, stile linea, gruppo colore.
- **Densità 2D**: bins, bandwidth, punti.
- **Heatmap**: valore numerico, gradiente low/high, etichette valori.

**Gate engine:** ogni tipo dichiara `engines`; `chart_type_choices(engine)`
filtra la select, `chart_type_available()` e la validazione rifiutano il base,
il round-trip conserva engine e tipo.

## 2. File

- `R/chart-types.R` — nuovi descrittori, `chart_type_engines()`,
  `chart_type_available()`, scelte filtrate.
- `R/chart-ggplot.R` — mapping e layer dei quattro tipi.
- `R/chart-spec.R` — validazione engine-aware, rifiuto base, titoli.
- `R/chart-studio.R` — select iniziale base, aggiornamento scelte al cambio
  engine, reopen con scelte corrette.
- Test: `test-chart-types.R`, `test-chart-ggplot.R`.
- Documentazione: piano 12, NEWS 2.5.0, help, vignetta.

## 3. Verifiche

| Verifica | Esito |
|---|---|
| Gate base/ggplot | verdi |
| Comandi 4 tipi | verdi |
| Validazione engine | verdi |
| Preview + apply 4 tipi | verdi |
| Suite | **3755 pass, 0 fail, 22 skip** |
| `R CMD check` 2.5.0 | **Status: OK** |

## 4. Limiti

- Un solo facet (no grid a due variabili).
- Heatmap senza annotazioni/raggruppamenti oltre al valore.
- Densità 2D a contorni, non filled.
- Nessun dialogo Advanced per questi tipi.

## 5. Comandi

```bash
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-chart-ggplot.R")'
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-chart-types.R")'
R CMD build . && _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```
