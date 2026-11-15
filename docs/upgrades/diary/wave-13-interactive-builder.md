# Diario di handoff — Onda 13 — Anteprima interattiva nel builder

**Data:** 2026-11-15
**Stato:** completata (2.6.0)
**Documento di settore:** [`../13-interactive-builder.md`](../13-interactive-builder.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa

**Stato:** branch `main`, HEAD corrente, Onda 13 chiusa.

**Baseline:** `testthat::test_local()` → **3767 pass, 0 fail, 22 skip**;
`R CMD check --no-manual` → **Status: OK**.

**Prossimo task:** nessuno obbligatorio. Estensioni: selezione anche per
ggplotly quando compatibile, editing diretto degli elementi, argomenti R
aggiuntivi.

---

## 1. Risultato

- Il pannello Build mostra `plotlyOutput` quando `chart_preview()` produce un
  widget; altrimenti l’immagine PNG.
- Sorgente `rcmdr-build`, separata da `rcmdr-chart` della galleria.
- Conteggio punti selezionati e pulsante “Create data set from selection” per
  scatter non raggruppato.
- `chart_subset_selected()` condiviso da builder e galleria.
- Selezione azzerata su Refresh, Reset e Apply.

## 2. File

- `R/chart-studio.R` — media UI, renderPlotly, selezione builder, helper
  subset, refactor galleria.
- Test: `test-chart-preview.R` (sorgente widget), `test-chart-gallery.R`
  (helper subset), `test-chart-studio.R` (UI media).
- Documentazione: piano 13, NEWS 2.6.0, help, vignetta.

## 3. Verifiche

| Verifica | Esito |
|---|---|
| Widget nel builder e sorgente separata | verdi |
| Fallback immagine | verdi |
| Subset da selezione e rifiuti | verdi |
| Galleria invariata | verdi |
| Suite | **3767 pass, 0 fail, 22 skip** |
| `R CMD check` 2.6.0 | **Status: OK** |

## 4. Limiti

- Selezione solo scatter non raggruppato.
- ggplot interattivo dipende da plotly/ggplot2 compatibili.
- Il widget non modifica la spec.
- Nessun editing diretto di punti/assi/layer.

## 5. Comandi

```bash
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-chart-preview.R")'
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-chart-gallery.R")'
R CMD build . && _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```
