# Diario di handoff — Onda 9 — ggplot2 di prima classe

**Data:** 2026-11-15
**Stato:** completata (2.2.0)
**Documento di settore:** [`../09-ggplot-integration.md`](../09-ggplot-integration.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa

**Stato:** branch `main`, HEAD corrente (vedi `git log -1`), Onda 9 chiusa.

**Baseline:** `testthat::test_local()` → **3576 pass, 0 fail, 22 skip**;
`R CMD check --no-manual` su `RcmdrShiny_2.2.0.tar.gz` → **Status: OK**.

**Prossimo task:** nessuno obbligatorio. Estensioni possibili in sezione 8.

**Da leggere:** questo diario; `../09-ggplot-integration.md`; sezione Onda 9 di
`../CHECKLIST.md`; `../chart-studio` help topic e `vignettes/chart-studio.Rmd`.

---

## 1. Obiettivo e risultato

Portare ggplot2 da copertura parziale (6 tipi, comandi ibridi/malformati) a
motore completo per gli 11 tipi del Chart Studio.

**Risultato:**

- Builder ggplot dedicato (`R/chart-ggplot.R`) per istogramma, densità,
  boxplot, dispersione, linee, barre, dot, strip, QQ, medie, xyplot.
- Mapping estesi solo ggplot: facet (tutti), size e label (scatter).
- Opzioni comuni: alpha, position, binwidth, smooth method/se, jitter, shape,
  flip, facet scales/columns, tema ggplot.
- Etichette: title, subtitle, tag, x, y, caption.
- Scale: log x/y, palette fill/colour, facet free scales, linee multi-serie
  con colori nominati.
- Comando unico `print(ggplot(...))`; rimossi prefisso base e `title()`.
- Interattività `plotly::ggplotly()` con gate di compatibilità.
- Validazione engine-aware; preview/apply/export/round-trip verificati.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| _(questo commit)_ | feat: make ggplot2 a first-class chart engine | Onda 9 (2.2.0) |

---

## 3. File

**Creati**

- `R/chart-ggplot.R` — builder ggplot (11 tipi, mapping, opzioni, temi).
- `tests/testthat/test-chart-ggplot.R` — 11 comandi, facet, temi, preview,
  apply/export, interattività.
- `docs/upgrades/09-ggplot-integration.md` — piano e stato.

**Modificati**

- `R/chart-spec.R` — comando unico per engine, validazione engine-aware,
  interattività, default tema/etichette.
- `R/chart-types.R` — mapping UI dipendente dall'engine.
- `R/chart-studio.R` — controlli ggplot, mapping estesi, reset/reopen.
- `tests/testthat/test-chart-spec.R` — 11/11 tipi invece del limite a 6.
- `DESCRIPTION` (2.2.0), `NEWS.md`, help topic, vignetta, README/CHECKLIST/
  TEST-MATRIX.

---

## 4. Test ed evidenze

| Verifica | Esito |
|---|---|
| Comandi ggplot 11/11 | verdi |
| Validazione 11/11 | verdi |
| Preview 11/11 (ggplot2 installato) | `type = image`, nessun errore |
| Apply + export PNG | file non vuoto |
| Base engine invariato | test Chart Studio verdi |
| Suite completa | **3576 pass, 0 fail, 22 skip** |
| `R CMD check` 2.2.0 | **Status: OK** |

---

## 5. Decisioni

- Gli slot `facet` sono disponibili per tutti i tipi; `size` e `label` solo per
  lo scatter, dove hanno una semantica chiara.
- `facet`/`size`/`label` non entrano mai nei comandi base.
- La palette agisce come `scale_fill_manual`/`scale_colour_manual`; senza
  gruppo non viene emesso alcuno scale.
- Le linee multi-serie usano un layer per serie con colori nominati, senza
  dipendere da `tidyr`.
- `ggplotly` è attivo solo se un probe minimo riesce: plotly 4.10.4 e ggplot2
  4.0.2 su questa macchina sono incompatibili, quindi l'interattivo è
  disattivato e l'HTML non viene offerto.

---

## 6. Limiti noti

| Limite | Impatto | Nota |
|---|---|---|
| `ggplotly` dipende dalle versioni plotly/ggplot2 | nessun interattivo in questo ambiente | gate automatico |
| Un solo slot facet | niente facet a due variabili | fuori perimetro |
| `size`/`label` solo scatter | niente label su bar/means | scelta di semantica |
| `scale`/`breaks` restano opzioni base | ignorati da ggplot | documentato |
| `boxplots` marginali e `log` base restano nel motore base | parità non totale sulle opzioni base | usare ggplot per log |
| Ogni geom/scale/coord non è esposto | API builder, non ggplot completo | estendibile via plugin |

---

## 7. Prossimi passi possibili

- Facet grid a due variabili (`rows`/`cols`).
- Label e size per bar/means/dot con `after_stat`.
- Scale continue personalizzate (colore, size, alpha) oltre le palette.
- Coordinata `coord_polar`, `coord_fixed`.
- Export SVG/PDF con temi ggplot verificati visivamente.
- Quando plotly supporta ggplot2 4.x, test E2E del dettaglio interattivo.

---

## 8. Comandi per riprendere

```bash
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-chart-ggplot.R")'
Rscript -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_dir("tests/testthat", reporter="silent"); d <- as.data.frame(res); cat(nrow(d), sum(d$passed), sum(d$failed), sum(d$skipped), "\n")'
R CMD build . && _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```
