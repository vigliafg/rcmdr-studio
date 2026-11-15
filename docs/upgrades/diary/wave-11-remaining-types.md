# Diario di handoff — Onda 11 — Completamento degli altri tipi

**Data:** 2026-11-15
**Stato:** completata (2.4.0)
**Documento di settore:** [`../11-remaining-types.md`](../11-remaining-types.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa

**Stato:** branch `main`, HEAD corrente, Onda 11 chiusa.

**Baseline:** `testthat::test_local()` → **3631 pass, 0 fail, 22 skip**;
`R CMD check --no-manual` → **Status: OK**.

**Prossimo task:** nessuno obbligatorio. Estensioni possibili: tipi ggplot-only
(violin, ECDF), campo “argomenti R aggiuntivi”.

---

## 1. Risultato

Completati gli otto tipi rimasti:

- **Densità**: kernel, adjust, rug, grid (base); adjust (ggplot).
- **Linee**: line/step/area, linetype, linewidth, gruppo colore (ggplot);
  gruppo ignorato nel base.
- **Barre**: width, statistica count/percent (ggplot).
- **Dot**: bin (base), binaxis/stackdir/dotsize/binwidth (ggplot).
- **Strip**: method (base), jitter width/height/shape (ggplot).
- **QQ**: distribuzione norm/unif/exp, linea, envelope, grid (base);
  distribuzione e linea (ggplot).
- **Medie**: connect, error width, point size (base connect; ggplot tutti).
- **XYplot**: type p/l/b, layout, smooth (base e ggplot).

Default invariati; test dedicati per ogni argomento.

## 2. File

- `R/command-builders-graphs.R` — density, qq, dot, means, xyplot.
- `R/chart-types.R` — default e controlli degli otto tipi.
- `R/chart-ggplot.R` — density adjust, line/step/area, bar percent, dot,
  strip, qq distribution, means summary, xyplot smooth.
- Test: `test-command-builders-graphs.R`, `test-chart-ggplot.R`.
- Documentazione: piano 11, NEWS 2.4.0, help topic, vignetta.

## 3. Verifiche

| Verifica | Esito |
|---|---|
| Default builder invariati | verdi |
| Nuovi argomenti base | verdi |
| Nuovi argomenti ggplot | verdi |
| Preview/apply tipi toccati | `image` |
| Suite | **3631 pass, 0 fail, 22 skip** |
| `R CMD check` 2.4.0 | **Status: OK** |

## 4. Limiti

- Kernel/rug/grid non hanno equivalente ggplot2: restano base-only.
- Envelope QQ solo base.
- Linee con gruppo e più serie: il gruppo colore si applica alla serie
  singola; con più serie restano i colori per serie.
- Bar percent solo ggplot.
- Nessun nuovo tipo ggplot-only.

## 5. Comandi

```bash
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-chart-ggplot.R")'
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-command-builders-graphs.R")'
R CMD build . && _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```
