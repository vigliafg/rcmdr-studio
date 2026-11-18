# Rendering pigro delle viste pesanti (Onda 17, T10)

**Data:** 2026-11-18  
**Ambito:** `R/app.R`, `R/chart-studio.R`, `R/help-server.R`,
`R/report-studio.R`  
**Test:** [`../tests/testthat/test-lazy-views.R`](../../tests/testthat/test-lazy-views.R)

---

## 1. Metodo

Le viste pesanti non vengono più costruite al primo flush: ogni `renderUI`
controlla `view_ready(input, "id")` (o `subview_ready()` per le schede interne)
e restituisce subito se la vista non è quella visibile. Un input assente —
chiamata diretta nei test o primo flush senza tab — mantiene il comportamento
storico e costruisce l'output: nessun test o script rimane senza dati.

Misure con `Rscript --vanilla`, `pkgload::load_all()` e `shiny::testServer()`,
dataset di 200 righe, `main_tabs = "home"`. Il tempo è quello del primo accesso
all'output dopo un warm-up; non include il costo del browser.

## 2. Prima

| Output nascosto | Tempo | Contenuto |
|---|---|---|
| `chart_gallery_grid` | 41 ms | griglia costruita |
| `models_dashboard` | 4 ms | tabella costruita |
| `help_results` | 3 ms | risultati costruiti |
| `report_preview` | 3 ms | anteprima costruita |
| `app_ui()` | 1135 ms | invariato: dipende dagli asset inline |

`app_ui()` resta dominato dalla lettura e dall'inlining di 165 KB di CSS+JS:
T10 non tocca quel percorso, che serve al primo paint.

## 3. Dopo

| Output nascosto | Tempo | Contenuto |
|---|---|---|
| `chart_gallery_grid` | 3 ms | vuoto (`req` soddisfatto? no) |
| `models_dashboard` | 4 ms | vuoto |
| `help_results` | 3 ms | vuoto |
| `report_preview` | 3 ms | vuoto |
| `gallery_open` | 7 ms | griglia costruita alla prima apertura |

La Gallery passa da 41 ms di costruzione a 3 ms di rifiuto; il costo si paga
solo quando la scheda si apre. Le altre viste erano già piccole nel dataset di
prova, ma il percorso è lo stesso: nessun markup finché la vista non è
visibile.

## 4. Output differiti

| Vista | Output |
|---|---|
| Chart Studio | `chart_gallery_grid`, `chart_models_grid`, `chart_detail`, `chart_detail_plotly_ui`, `chart_detail_plotly` |
| Help | `help_context`, `help_categories`, `help_recent`, `help_results`, `help_topic` |
| Report Studio | `report_editor_ui`, `report_outline`, `report_chunks`, `report_preview`, `report_status_ui` |
| Environment | `environment_pane`, `environment_objects`, `environment_preview`, `environment_datasets`, `models_dashboard` |
| Workflows | `workflow_panel` |

## 5. Invalidazione

Il gate dipende da `input$main_tabs` (e da `input$chart_mode` per le schede
interne): quando la vista torna visibile l'output è invalidato e viene
ricostruito dalle reactive correnti (`chart_revision()`, `tick()`,
`report_revision()`, `text_debounced()`). Il test
`a lazy view is rebuilt from the current data, never from a stale copy`
aggiunge un grafico mentre la Gallery è nascosta e verifica che alla riapertura
compaiano entrambi.

## 6. Limiti

- Le misure sono di `testServer`, non di un browser: non includono layout,
  paint né il tempo di rete del websocket.
- `app_ui()` non è stato ridotto: gli asset inline sono una scelta deliberata
  per l'uso offline.
- Gli output della Console e della Home restano sempre attivi: sono la vista
  iniziale e devono essere pronti.
