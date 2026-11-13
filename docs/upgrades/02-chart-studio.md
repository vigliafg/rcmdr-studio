# Onda 2 — Chart Studio

**Stato:** da implementare  
**Dipende da:** Onda 0 (preview engine, cronologia, design system)  
**Sblocca:** Report Studio (galleria grafici, inserimento plot)  
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Trasformare il tab Plots in un ambiente di creazione e gestione grafici:

- builder visuale con mappature;
- anteprima live isolata;
- generazione del comando R equivalente;
- galleria con metadati, ricerca, pin, rinomina e confronto;
- export PNG/PDF/SVG/HTML;
- round-trip: riaprire un grafico nel builder;
- temi, palette e opzioni di presentazione;
- nessuna nuova procedura statistica.

Il Chart Studio non sostituisce i dialoghi esistenti: li rende accessibili da
una UI più moderna. Il pulsante **Advanced** apre sempre il dialogo completo.

---

## 2. Stato attuale

| Elemento | File | Situazione |
|---|---|---|
| Dialoghi grafici | `R/dialogs-graphs.R` (842 righe) | 20+ dialoghi, alcuni con `interactive` |
| Command builder | `R/command-builders-graphs.R` | Comandi base R, palette, 3D |
| Plotly | `R/plotly.R` | 4 builder interattivi: histogram, boxplot, scatter, line |
| Cattura plot | `R/commands.R` | `run_plot_command()` salva PNG e `recordPlot()` |
| Stato plot | `R/state.R` | `state$plots`: `file`, `url`, `code`, `recorded`, `time` |
| UI | `R/app.R` | Galleria thumbnail, immagine corrente, header, export PNG/PDF, rgl |
| Report | `R/report.R` | Include i plot per path |

Limiti attuali:

- i grafici nascono solo da un dialogo, non da un builder;
- nessuna anteprima prima di eseguire;
- plotly copre solo quattro tipi;
- la galleria non ha metadati, ricerca, pin o rinomina;
- non si può riaprire un grafico con gli stessi parametri;
- export limitato a PNG/PDF;
- temi e palette non sono centralizzati;
- non c'è round-trip tra plot e parametri.

---

## 3. Stato target

### Layout

```text
┌──────────────────────────────────────────────────────────────┐
│ Toolbar: Build | Gallery | Export | Copy code | Advanced     │
├───────────────────────┬──────────────────────────────────────┤
│ Builder               │ Preview                              │
│                       │                                      │
│ Tipo ▼                │  [grafico live]                      │
│ Dati ▼                │                                      │
│ X ▼  Y ▼  Gruppo ▼    │  Comando generato:                   │
│ Facet ▼               │  hist(Dataset$y, ...)                │
│ Opzioni               │                                      │
│ Tema/Palette          │                                      │
│ [Anteprima] [Applica] │                                      │
├───────────────────────┴──────────────────────────────────────┤
│ Filmstrip: plot recenti, pin, ricerca, metadati              │
└──────────────────────────────────────────────────────────────┘
```

### Modalità

| Modalità | Uso |
|---|---|
| **Build** | Creare un grafico con il builder |
| **Gallery** | Esplorare, cercare, confrontare, esportare i grafici |
| **Detail** | Grande anteprima, metadati, codice, azioni |

---

## 4. Architettura

### 4.1 Chart spec

```r
chart_spec <- list(
  id = "chart-0001",
  dataset = "Dataset",
  type = "histogram",
  mapping = list(
    x = "Sepal.Length",
    y = NULL,
    group = NULL,
    facet = NULL,
    size = NULL,
    label = NULL
  ),
  options = list(
    bins = "Sturges",
    scale = "frequency",
    smooth = FALSE,
    log = "",
    position = "stack",
    alpha = 0.7
  ),
  theme = list(
    engine = "base",          # "base" | "ggplot2" (opzionale)
    palette = "default",
    base_size = 12,
    grid = TRUE,
    legend = "right",
    background = "white"
  ),
  labels = list(
    title = "",
    x = "",
    y = "",
    caption = ""
  ),
  size = list(width = 800, height = 600),
  command = "hist(...)",
  interactive = "plotly::plot_ly(...)"
)
```

### 4.2 Registry dei tipi

```r
chart_types() -> list(
  histogram = list(
    label = "Istogramma",
    requires = c("x"),
    optional = c("group", "facet"),
    controls = function(spec) { ... },
    command = function(spec) { ... },
    preview = function(spec) { ... }
  ),
  ...
)
```

Tipi iniziali, tutti già coperti dai dialoghi esistenti:

- histogram;
- density;
- boxplot;
- scatter;
- line;
- bar;
- dot;
- strip;
- QQ;
- means;
- conditioning/xyplot;
- 3D (rimanda al dialogo rgl).

### 4.3 Motori

| Motore | Disponibilità | Uso |
|---|---|---|
| **base** | sempre | Comandi Rcmdr esistenti, PNG, PDF, replay |
| **plotly** | `plotly` installato | Anteprima interattiva per i tipi supportati |
| **ggplot2** | `ggplot2` installato e flag attiva | Motore moderno opzionale, comando ggplot riproducibile |

Regola: il motore base resta il default per compatibilità. Il motore ggplot2
è opt-in e non sostituisce i comandi esistenti. Se non è installato, la UI lo
disabilita con una spiegazione.

### 4.4 Preview

```r
chart_preview(state, spec) -> list(
  type = "image" | "plotly" | "html" | "error",
  file = NULL,
  widget = NULL,
  message = NULL
)
```

- base: `preview_plot()` su device temporaneo;
- plotly: `preview_plotly()`;
- ggplot2: `renderPlot` o PNG temporaneo;
- errori: messaggio leggibile, nessun crash.

### 4.5 Galleria

Estendere `state$plots`:

```r
list(
  file = "...png",
  url = "...",
  code = "hist(...)",
  recorded = <recordedplot>,
  time = Sys.time(),
  spec = <chart_spec>,
  title = "Istogramma di Sepal.Length",
  tags = c("histogram", "Dataset"),
  pinned = FALSE
)
```

API:

```r
plot_register(state, plot)
plot_list(state, query = NULL, type = NULL)
plot_update(state, id, title = NULL, tags = NULL, pinned = NULL)
plot_delete(state, id)
plot_export(state, id, format, file)
plot_reopen(state, id)
plot_compare(state, ids)
```

---

## 5. Task

### C2.1 — Chart spec e registry

**File:** nuovo `R/chart-spec.R`, nuovo `R/chart-types.R`.

**Passi:**

1. Definire `chart_spec()` e la validazione.
2. Definire `chart_types()` con label, mapping richiesti, controlli, command
   builder, preview builder.
3. Implementare i tipi iniziali.
4. Test: spec valida/invalida, mapping mancanti, default.

**Accettazione:** ogni tipo produce un comando e una preview.

---

### C2.2 — Builder UI

**File:** nuovo `R/chart-studio.R`, `R/app.R`.

**Passi:**

1. `chartStudioUI()` e `chartStudioServer()`.
2. Type gallery con icone.
3. Mapping dinamici in base al tipo.
4. Opzioni dinamiche.
5. Pannello tema/palette.
6. Pulsanti `Anteprima`, `Applica`, `Reset`, `Advanced`.
7. Layout responsive.

**Test:** `test-chart-studio-ui.R`; E2E build.

**Accettazione:** cambiare un mapping aggiorna l'anteprima e il comando.

---

### C2.3 — Preview live

**File:** `R/preview.R`, `R/chart-studio.R`.

**Passi:**

1. `chart_preview_expression(spec)`.
2. `chart_preview(state, spec)`.
3. Debounce 300–500 ms.
4. Cache per spec identica.
5. Gestione errori e timeout.
6. Cleanup dei file temporanei.

**Test:** `test-chart-preview.R`: nessun side effect, nessun plot aggiunto.

**Accettazione:** l'anteprima è fluida su dataset piccoli/medi e non inquina
la sessione.

---

### C2.4 — Applica e registra

**File:** `R/chart-studio.R`, `R/commands.R`.

**Passi:**

1. `Applica` esegue `run_command(state, spec$command)`.
2. Il comando viene loggato come oggi.
3. Dopo l'esecuzione, associare `spec` all'ultimo plot.
4. Se il comando fallisce, mostrare errore e non registrare il plot.
5. `Advanced` apre il dialogo esistente con la memoria precompilata.

**Test:** `test-chart-apply.R`; golden command.

**Accettazione:** il comando applicato è esattamente quello del dialogo
equivalente; il plot è in galleria e nel report.

---

### C2.5 — Galleria evoluta

**File:** `R/chart-studio.R`, `R/app.R`.

**Funzioni:**

- griglia/filmstrip con thumbnail;
- ricerca per titolo, tag, tipo, dataset;
- pin;
- rinomina;
- elimina con conferma;
- dettaglio con metadati;
- confronto affiancato di due plot;
- “Riapri nel builder”;
- “Copia codice”;
- “Inserisci nel report”;
- “Esporta”.

**Test:** `test-chart-gallery.R`; E2E gallery.

**Accettazione:** ogni plot ha metadati e azioni coerenti.

---

### C2.6 — Export

**File:** `R/chart-studio.R`, `R/app.R`.

**Formati:**

| Formato | Dipendenza | Note |
|---|---|---|
| PNG | sempre | Già disponibile |
| PDF | sempre | `replayPlot()` |
| SVG | `svglite` | Se assente, disabilitato con messaggio |
| HTML | `plotly`/`htmlwidgets` | Solo per plotly |
| Copia codice | sempre | Negli appunti o in un modale |

**Passi:**

1. Download handler per ogni formato.
2. Nome file con titolo e data.
3. Opzioni: larghezza, altezza, DPI, sfondo trasparente.
4. Test: file prodotto e non vuoto.

**Accettazione:** export coerente per plot base e plotly.

---

### C2.7 — Temi e palette

**File:** `R/chart-spec.R`, `R/command-builders-graphs.R`,
`R/chart-studio.R`.

**Passi:**

1. Palette predefinite e colorblind-safe.
2. Tema base: sfondo, griglia, font, legend position.
3. Comandi generati: `palette()`, `par()`, argomenti dei plot.
4. Per ggplot2: `theme_minimal()`, `scale_color_*`, `labs()`.
5. Anteprima immediata.

**Test:** `test-chart-theme.R`.

**Accettazione:** il tema scelto è visibile nell'anteprima e nel comando.

---

### C2.8 — Round-trip e reopen

**File:** `R/chart-studio.R`.

**Passi:**

1. Ogni plot applicato conserva `spec`.
2. “Riapri nel builder” ripristina dataset, tipo, mapping, opzioni, tema,
   labels.
3. Se lo `spec` manca (plot vecchio), mostra il codice e offri “Apri dialogo
   avanzato”.
4. Test: apply → reopen → apply con una modifica.

**Accettazione:** il round-trip è fedele per i tipi supportati.

---

### C2.9 — Selezione e brush

**File:** `R/chart-studio.R`, `R/state.R`.

**Passi:**

1. `plotly_selected` / `plotly_click` su scatter.
2. “Crea subset dai punti selezionati” → comando `subset()` o dataset
   temporaneo.
3. “Evidenzia selezione” senza modificare i dati.
4. Test: selezione nota produce il subset atteso.

**Accettazione:** la selezione è opzionale e non rompe i grafici non plotly.

---

### C2.10 — Test, help, vignetta

**File:** `tests/testthat/*`, `inst/help-topics/topics/chart-studio.md`,
`vignettes/chart-studio.Rmd`.

**Contenuto help:**

- Build vs Gallery;
- mapping;
- preview;
- apply;
- temi;
- export;
- round-trip;
- differenza tra grafico base e plotly;
- Advanced.

**Test E2E:** istogramma, scatter, boxplot; preview; apply; gallery; export.

---

## 6. Regole di riproducibilità

| Azione | Comando? | Note |
|---|---|---|
| Cambio mapping/opzioni | No | Solo preview |
| Anteprima | No | Isolata, nessun log |
| Applica | Sì | Esegue il comando del dialogo equivalente |
| Tema/palette | Sì | Parte del comando applicato |
| Export | No | File, non log |
| Rinomina/pin plot | No | Metadati di sessione |
| Crea subset da selezione | Sì | `subset()` |
| Advanced | Sì | Dialogo esistente |

---

## 7. Test e accettazione dell'Onda 2

### Unit

- `test-chart-spec.R`
- `test-chart-types.R`
- `test-chart-preview.R`
- `test-chart-apply.R`
- `test-chart-gallery.R`
- `test-chart-theme.R`
- `test-chart-export.R`
- `test-chart-roundtrip.R`

### E2E

1. Apri Chart Studio.
2. Scegli istogramma, variabile e gruppo.
3. Verifica anteprima.
4. Applica.
5. Verifica comando nel log.
6. Apri Gallery, rinomina, pin.
7. Riapri nel builder.
8. Esporta PNG.
9. Inserisci nel report.

### Criterio finale

> Il Chart Studio permette di creare, confrontare, esportare e ricreare un
> grafico senza mai perdere il comando R che lo ha prodotto.

---

## 8. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| Preview base grafica lenta | Debounce, cache, dimensioni ridotte |
| Plotly non disponibile | Fallback PNG, messaggio chiaro |
| ggplot2 diverge dai comandi base | Motore opt-in, golden test separati |
| Troppi tipi nel builder | Registry incrementale; Advanced per i casi complessi |
| Round-trip incompleto | Spec versionata e test di riapertura |
| Export SVG richiede `svglite` | Suggests + fallback disabilitato |

---

## 9. Fuori perimetro

- Nuovi tipi di grafico non coperti dai dialoghi esistenti.
- Editor grafico drag-and-drop tipo Illustrator.
- Animazioni o dashboard interattive.
- Nuove procedure statistiche.

---

## 10. Checklist di chiusura

- [ ] Chart spec.
- [ ] Registry tipi.
- [ ] Builder UI.
- [ ] Mapping dinamici.
- [ ] Preview live.
- [ ] Apply con comando loggato.
- [ ] Advanced verso il dialogo esistente.
- [ ] Galleria con metadati.
- [ ] Ricerca, pin, rinomina, confronto.
- [ ] Export PNG/PDF/SVG/HTML.
- [ ] Temi e palette.
- [ ] Round-trip.
- [ ] Selezione/brush.
- [ ] Help topic e vignetta.
- [ ] Test unit e E2E verdi.
