# Onda 13 — Anteprima interattiva nel builder

**Data:** 2026-11-15
**Stato:** implementata (2.6.0)
**Baseline:** RcmdrShiny 2.5.0
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Rendere il pannello **Build** interattivo quando la spec ha una versione
plotly: hover, zoom e selezione punti disponibili mentre si modificano i
controlli, senza aspettare Apply o la galleria.

## 2. Comportamento

- Se `chart_preview()` produce un widget plotly, il pannello mostra
  `plotlyOutput` al posto dell’immagine PNG.
- Altrimenti resta l’immagine statica (ggplot senza `ggplotly`, tipi non
  supportati, plotly assente).
- La sorgente plotly del builder è **`rcmdr-build`**, separata da
  `rcmdr-chart` della galleria: le selezioni non si mescolano.
- Su scatter non raggruppato la selezione mostra il conteggio e il pulsante
  **Create data set from selection**; il comando è riproducibile e il nuovo
  dataset diventa attivo.
- La selezione viene azzerata su Refresh, Reset e Apply.

## 3. Implementazione

| Elemento | File |
|---|---|
| `uiOutput("chart_preview_media")` sceglie widget o immagine | `R/chart-studio.R` |
| `renderPlotly("chart_preview_plotly")` e flag di ready | `R/chart-studio.R` |
| Sorgente `rcmdr-build` nel codice interattivo della preview | `R/chart-studio.R` (`chart_preview`) |
| `chart_subset_selected()` condiviso da builder e galleria | `R/chart-studio.R` |
| UI e handler della selezione nel builder | `R/chart-studio.R` |

## 4. Limiti

- La selezione resta disponibile solo per scatter non raggruppato.
- Con ggplot2 l’interattivo dipende dalla compatibilità plotly/ggplot2.
- Il widget non modifica la spec: hover/zoom/selezione non cambiano il
  grafico; il subset crea un dataset.
- Nessun editing diretto degli elementi del grafico.

## 5. Criteri di chiusura

- Widget nel builder quando disponibile, immagine altrimenti.
- Sorgente separata e nessuna interferenza con la galleria.
- Subset dal builder e dalla galleria con la stessa helper.
- Test, documentazione, suite e check verdi.
