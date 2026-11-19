# Onda 20 — Esempi dal R Graph Gallery

**Data:** 2026-11-19  
**Stato:** implementata (3.2.0)  
**Baseline:** RcmdrShiny Studio 3.1.0 (Onda 19)  
**ADR:** ADR-020  
**Diario:** [`diary/wave-20-chart-examples.md`](diary/wave-20-chart-examples.md)

---

## 1. Obiettivo

Aggiungere al Chart Studio una **galleria visuale offline di esempi curati**,
ispirata all'R Graph Gallery, e i **tipi di grafico mancanti** che possono
essere riprodotti con ggplot2 senza un secondo motore.

La galleria non è un browser del sito: è un catalogo locale di ricette. Ogni
scheda mostra un'anteprima, una descrizione e il codice; **Apri nel builder**
porta tipo, opzioni e tema nel builder senza caricare dati nella sessione e
senza eseguire comandi.

---

## 2. Non obiettivi

- Nessun engine base e nessuna nuova dipendenza obbligatoria.
- Nessuna immagine o codice scaricato a runtime.
- Nessun comando eseguito dall'apertura di un esempio.
- Nessun tipo che richieda mappe, grafi, 3D o animazioni: restano plugin o
  onde future.
- Nessuna modifica ai comandi, ai dialoghi o alle stringhe esistenti.

---

## 3. Cosa è stato consegnato

### 3.1 Galleria Examples

- Quarta modalità del Chart Studio: **Build | Models | Examples | Gallery**.
- 26 esempi, con anteprima locale 640×400.
- Filtri per famiglia e livello, ricerca testuale, conteggio.
- Card come `<button>`, `aria-pressed`, nome accessibile, immagine con `alt`.
- Dettaglio con descrizione, fonte, **Apri nel builder**, **Copia codice** e
  codice collassabile.
- Link esterni con `rel="noopener noreferrer"`.
- Stato vuoto con **Pulisci filtri**.
- Loader condiviso con Models: una sola strada per caricare una ricetta.

### 3.2 Tipi aggiunti

| Tipo | Mapping | Note |
|---|---|---|
| Lollipop | categoria, valore | `geom_segment()` + `geom_point()` |
| Dumbbell | categoria, inizio, fine | due punti + segmento |
| Doughnut | categoria, valore | `coord_polar(theta = "y")` + foro |
| Stacked area | x, valore, serie | `geom_area(position = "stack")` |
| Ridgeline | numerico, gruppo | richiede `ggridges` |
| Beeswarm | gruppo, numerico | richiede `ggbeeswarm` |

I tipi con package opzionale compaiono solo se il package è installato e sono
dichiarati in `Suggests`. Nessun package nuovo obbligatorio.

### 3.3 Dati e anteprime

- Dati da `datasets` (`iris`, `mtcars`, `ToothGrowth`, `faithful`,
  `airquality`, `USArrests`, `EuStockMarkets`) e piccoli data frame preparati.
- `tools/build_chart_examples.R` genera le anteprime con lo stesso renderer
  della preview; `--check` verifica manifest e file mancanti.
- `inst/www/chart-examples/NOTICE` attribuisce l'ispirazione all'R Graph
  Gallery (repository MIT) e dichiara che nessuna immagine del sito viene
  ridistribuita.
- Budget: 26 PNG, circa 720 KB.

---

## 4. Esperienza utente

```text
[ Famiglia ▾ ] [ Livello ▾ ] [ Cerca esempi... ]        [ 26 esempio/i ]
┌──────────────────────────────┬─────────────────────────────────────────┐
│ card  card  card             │ anteprima grande                        │
│ card  card  card             │ titolo, famiglia, livello               │
│                              │ Apri nel builder · Copia codice         │
│                              │ Fonte: R Graph Gallery                  │
└──────────────────────────────┴─────────────────────────────────────────┘
```

- 3 colonne su desktop, 1 sotto 992 px.
- Il dettaglio è affiancato con il `split_pane` esistente.
- Aprire un esempio non cambia dati, log, history o galleria personale.
- Se le colonne del dataset attivo hanno nomi e tipi compatibili, il mapping
  viene riportato; altrimenti resta vuoto e il builder chiede le variabili.
- Senza dataset la ricetta si carica lo stesso e l'avviso spiega di importare
  i dati.

---

## 5. Architettura

### File nuovi

```text
R/chart-examples.R          registro, dati, spec, codice, filtri
R/chart-examples-ui.R       UI e server della modalità Examples
R/chart-types-extra.R       lollipop, dumbbell, doughnut, area, ridgeline, beeswarm
tools/build_chart_examples.R generazione e verifica delle anteprime
inst/www/chart-examples/    26 PNG + manifest.tsv + NOTICE
tests/testthat/test-chart-examples.R
tests/testthat/test-chart-types-extra.R
```

### File modificati

- `R/chart-studio.R`: quarta modalità, loader condiviso, chiamata al server
  Examples.
- `R/chart-types.R`: `chart_type_ids()` e registrazione dei tipi extra.
- `R/chart-ggplot.R`: layer dei nuovi tipi e fix di `chart_option_input_id()`
  per le opzioni fuori dalla mappa comune.
- `R/chart-spec.R`: titoli dei nuovi tipi.
- `inst/www/css/60-views.css`: griglia, card, dettaglio, responsive.
- `inst/i18n/it.tsv`: solo nuove stringhe.
- `inst/help-topics/topics/chart-studio.md` e `it/`: motore unico, Examples,
  tipi estesi.

---

## 6. Registro esempi

| Famiglia | Esempi |
|---|---|
| Descrittiva | istogramma, istogramma a bin fissi, densità per gruppo, ECDF, ridgeline, beeswarm |
| Confronto | violin, boxplot, strip |
| Correlazione | scatter con smooth, scatter con ellisse, densità 2D, QQ, correlazione |
| Categorie | barre, barre raggruppate, dot plot, heatmap |
| Composizione | pie con test, doughnut |
| Evoluzione | linea, area, serie multiple, area impilata |
| Ranking | lollipop, dumbbell |

Le sorgenti sono pagine tematiche di `https://r-graph-gallery.com/`; le
descrizioni sono originali.

---

## 7. Test

### Nuovi

- `test-chart-examples.R`: registro, spec, codice, filtri, mapping, markup,
  apertura nel builder senza side effect.
- `test-chart-types-extra.R`: layer e validazione dei sei tipi; gating dei
  package opzionali.
- `test-chart-ggplot.R`: mapping di default dei nuovi tipi.
- `test-chart-spec.R` / `test-chart-types.R`: copertura automatica dei tipi
  registrati.

### Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 29 e2e saltati; 3 warning noti |
| `node --check` | verde |
| App HTTP | 200 su `http://127.0.0.1:3841/` |
| Anteprime | 26/26, manifest coerente, 720 KB |
| Classic | invariata |

---

## 8. Rischi e limiti

| Rischio | Mitigazione |
|---|---|
| Duplicare Models | loader condiviso, un solo percorso |
| Aspettativa delle 400 pagine | catalogo curato, link esterni, NOTICE |
| Peso immagini | 26 PNG, lazy loading, budget |
| Licenza | anteprime generate localmente, nessuna immagine del sito |
| Mapping sbagliato | solo nomi/tipi compatibili |
| Package opzionale mancante | `requires` + gating, esempio e tipo nascosti |

Restano fuori dall'onda, come concordato: radar, parallel coordinates,
treemap, waffle, dendrogramma, mappe, network/flow, 3D e animazione. Sono
tipi da plugin o da onda successiva; l'architettura della galleria li accoglie
senza cambiamenti.

---

## 9. Criteri di chiusura

- [x] Modalità Examples con griglia, filtri, dettaglio e stato vuoto.
- [x] 26 esempi con anteprima locale, fonte e codice.
- [x] Apri nel builder senza side effect.
- [x] Sei nuovi tipi, con gating per i package opzionali.
- [x] Nessuna richiesta di rete nella vista Examples.
- [x] 3 colonne a 1280 px, 1 a 640 px, token e focus.
- [x] Suite completa, app HTTP 200, help aggiornato.
- [x] NEWS, README, ADR-020, checklist, diario.
