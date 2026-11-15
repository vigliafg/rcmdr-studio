# Onda 9 — ggplot2 come motore di prima classe

**Data:** 2026-11-15
**Stato:** implementata (2.2.0)
**Baseline:** RcmdrShiny 2.1.0
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Portare l'engine ggplot2 dalla copertura parziale (6 tipi, opzioni ignorate,
comandi malformati) a **motore completo per tutti gli 11 tipi del Chart
Studio**, con mapping estesi, opzioni, temi, scale, coordinate, facet, etichette,
preview, apply, export, round-trip e interattività.

“Totalità delle features” in questo contesto significa: **tutte le funzionalità
esposte dal modello del Chart Studio** (tipi, mapping, opzioni, tema, etichette,
dimensione, export). Non significa esporre ogni geom/scale/coord di ggplot2:
l'API resta quella del builder, estendibile dai plugin.

## 2. Stato di partenza (audit)

| Problema | Evidenza |
|---|---|
| Solo 6 tipi su 11 | `chart_ggplot_types()` |
| Scatter + smooth genera `ggplot(D, aes(...), geom_smooth(...) + ...)` | comando malformato |
| Doppia etichettatura: `labs()` + `title()` base | comando ibrido |
| `scale`, `breaks`, `log`, `boxplots` ignorati | opzioni UI senza effetto |
| Nessun facet/size/label mapping | registry senza slot |
| Palette senza gruppo inattiva | `scale_*_manual` solo con gruppo |
| Nessuna interattività ggplot | `chart_spec_interactive` usa solo i builder base |

## 3. Task

| ID | Task | File | Accettazione |
|---|---|---|---|
| G9.1 | Mapping esteso (facet, size, label) solo per ggplot | `chart-types.R`, `chart-studio.R` | [x] Campi solo con engine ggplot |
| G9.2 | Builder ggplot per 11 tipi | `chart-ggplot.R` | [x] Comando valido e preview per 11/11 |
| G9.3 | Opzioni comuni: alpha, position, binwidth, smooth/se, jitter, flip, shape | UI + spec | [x] Tutte nel comando |
| G9.4 | Temi, scale log, palette, labs (title/subtitle/tag) | `chart-ggplot.R` | [x] `theme_*`, `scale_*`, `labs` corretti |
| G9.5 | Facet wrap con scales e ncol | `chart-ggplot.R` | [x] `facet_wrap(vars(...))` |
| G9.6 | Comando unico: niente prefisso base né `title()` per ggplot | `chart-spec.R` | [x] Nessun comando ibrido |
| G9.7 | Interattività `plotly::ggplotly()` per tutti i tipi | `chart-spec.R` | [x] Gated sulla compatibilità plotly/ggplot2 |
| G9.8 | Validazione engine-aware e test | `chart-spec.R`, `test-chart-ggplot.R` | [x] 11/11 validi, apply/export verdi |

## 4. Fuori perimetro

- Ogni singolo geom/scale/coord di ggplot2 (estensibile via plugin).
- `ggplotly` con selezione punti ↔ subset dataset (resta base/plotly).
- Facet a due variabili (grid): il builder espone un solo slot facet.
- Editing libero del codice ggplot: resta il builder; `Advanced` apre il dialogo Rcmdr base.

## 5. Criteri di chiusura

- 11/11 tipi con comando ggplot valido e preview senza errori.
- Base engine invariato (test esistenti verdi).
- Apply registra in galleria con spec e round-trip.
- Export PNG/PDF/SVG dal comando ggplot.
- `NEWS.md`, help topic, vignetta, `TEST-MATRIX.md` aggiornati.
- Suite e `R CMD check` verdi.
