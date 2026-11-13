# Onda 1 — Data Studio

**Stato:** da implementare  
**Dipende da:** Onda 0  
**Sblocca:** Chart Studio (modello dati condiviso), Report Studio (data profile)  
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Trasformare il tab Data da “vista DT + editor rhandsontable sotto soglia” in un
ambiente di preparazione dati completo:

- più dataset gestiti e attivabili;
- griglia con ricerca, filtri, selezione e inspector;
- operazioni su righe e colonne che generano comandi R;
- data dictionary con etichette e unità;
- undo/checkpoint di sessione;
- import wizard con anteprima;
- fallback editing per dataset grandi;
- passaggio diretto dalla selezione all'analisi.

Nessuna nuova procedura statistica: tutte le trasformazioni riusano i command
builder e i dialoghi esistenti.

---

## 2. Stato attuale

| Elemento | File | Situazione |
|---|---|---|
| UI Data | `data_pane_ui()` in `R/app.R` | Radio View/Edit, Refresh, Apply, download CSV/RData |
| Vista | `output$data_table` | `DT::datatable`, server-side sopra 5.000 righe |
| Editing | `output$data_editor` | `rhandsontable`, abilitato sotto 10.000 celle |
| Applicazione | `observeEvent(input$data_apply)` | `hot_to_r()` + `update_dataset()` |
| Stato | `R/state.R` | `state$active_dataset`, `dataset()`, `editable_dataset()` |
| Command builder | `R/command-builders-data.R` | Compute, delete, recode, factor, bin, standardize, subset, sort, reshape, import/export |
| Dialoghi | `R/dialogs-data.R` | 25+ dialoghi dati |
| Import testo | `R/dialogs-import-text.R` | File, clipboard, URL |
| Import formati | `R/dialogs-data.R` | Excel, SPSS, Stata, SAS, Minitab |

Limiti attuali:

- un solo dataset attivo, senza registro o cronologia dei dataset;
- nessuna operazione strutturale dalla griglia (aggiungi/duplica/elimina
  riga o colonna);
- nessun inspector di colonna;
- nessun data dictionary;
- nessun undo;
- sopra soglia l'editing è semplicemente disabilitato;
- nessuna anteprima di import;
- nessun passaggio selezione → analisi.

---

## 3. Stato target

### Layout

```text
┌─────────────────────────────────────────────────────────────┐
│ Toolbar: dataset ▼ | View/Edit | Cerca | Filtri | Colonne ▼ | Righe ▼ | Export │
├──────────────────────────────────────────────┬──────────────┤
│ Griglia (DT o rhandsontable)                 │ Inspector    │
│                                              │              │
│  colonne con badge tipo e missing             │ Profilo      │
│  righe selezionabili                          │ Statistiche  │
│                                              │ Azioni       │
├──────────────────────────────────────────────┴──────────────┤
│ Missingness bar | selezione | stato dataset                  │
└─────────────────────────────────────────────────────────────┘
```

### Modalità

| Modalità | Comportamento |
|---|---|
| **View** | DT con filtri, ricerca, ordinamento, selezione righe; nessuna modifica |
| **Edit** | rhandsontable con context menu, resize, tipi; sotto soglia |
| **Targeted** | sopra soglia: editing mirato per colonna, filtri e operazioni via dialogo |
| **Read-only** | dataset non editabile per policy o dimensione estrema |

---

## 4. Architettura e modello dati

### 4.1 Registro dataset

In `R/state.R`:

```r
state$datasets <- list(
  Dataset = list(
    name = "Dataset",
    rows = 150L,
    cols = 5L,
    classes = c(Species = "factor", Sepal.Length = "numeric"),
    source = "csv:/path/file.csv",
    modified = Sys.time(),
    editable = TRUE
  )
)
```

API:

```r
dataset_registry(state)
dataset_register(state, name)
dataset_unregister(state, name)
dataset_activate(state, name) # wrappa active_dataset()
dataset_metadata(state, name)
```

`state$active_dataset` resta la fonte di verità per il resto del motore.

### 4.2 Data dictionary

```r
state$data_dictionary <- list(
  Dataset = list(
    Sepal.Length = list(label = "Lunghezza sepalo", units = "cm",
                        description = "Misura in centimetri"),
    Species = list(label = "Specie", units = NULL)
  )
)
```

API:

```r
variable_label(state, dataset, variable)
set_variable_label(state, dataset, variable, label, units = NULL)
dictionary_table(state, dataset)
```

Quando l'utente modifica un'etichetta, il comando generato è:

```r
attr(Dataset$Sepal.Length, "label") <- "Lunghezza sepalo"
attr(Dataset$Sepal.Length, "units") <- "cm"
```

Nessuna dipendenza da `Hmisc`.

### 4.3 Checkpoint e undo

```r
state$checkpoints <- list(
  list(
    id = "ckpt-0001",
    dataset = "Dataset",
    time = Sys.time(),
    label = "Prima di deleteVariable",
    data = <data.frame>,
    cells = 750L
  )
)
```

Regole:

- snapshot prima di ogni mutazione del dataset attivo;
- cap: 20 checkpoint e 50 MB complessivi (configurabile);
- se il dataset supera il cap, si conserva solo l'ultimo checkpoint o nessuno;
- il ripristino è un'operazione di sessione, non un comando del log;
- la UI lo dice esplicitamente: “Ripristino di sessione, non comando R”.

### 4.4 Selezione

```r
state$data_selection <- list(
  dataset = "Dataset",
  rows = c(1L, 4L, 7L),
  columns = c("Sepal.Length", "Species"),
  expression = "Species == 'setosa'" # opzionale
)
```

API:

```r
data_selection(state)
set_data_selection(state, rows = NULL, columns = NULL, expression = NULL)
clear_data_selection(state)
selection_subset_command(state, new_name)
```

---

## 5. Task

### D1.1 — Registro dataset e selettore

**File:** `R/state.R`, `R/data-studio.R`, `R/app.R`.

**Passi:**

1. Aggiungere `state$datasets`, `state$data_dictionary`,
   `state$checkpoints`, `state$data_selection`.
2. Registrare il dataset quando `active_dataset()` viene impostato o quando
   `remember_assignment()` rileva un data frame.
3. Costruire `dataset_registry()` e `dataset_activate()`.
4. UI: select dataset nella toolbar con dimensione, fonte e badge “attivo”.
5. Azioni rapide: View, Summary, Export, Remove from registry, Set active.

**Test:** `test-data-registry.R`.

**Accettazione:** più dataset convivono; l'attivazione aggiorna badge, menu e
inspector.

---

### D1.2 — Griglia, ricerca, filtri, selezione

**File:** `R/data-studio.R`, `R/app.R`.

**Passi:**

1. Estrarre `data_pane_ui()` in `dataStudioUI()`.
2. View: `DT::datatable` con:
   - `filter = "top"`;
   - `options = list(pageLength = 25, scrollX = TRUE, searchHighlight = TRUE)`;
   - `selection = "multiple"`;
   - classi per tipo e missing.
3. Edit: `rhandsontable` con `contextMenu`, `dropdownMenu`, `manualColumnResize`,
   `manualRowResize`, `stretchH = "all"`, `useTypes = TRUE`.
4. Toolbar: ricerca globale, filtro attivo, reset filtri, selettore colonne.
5. Selection handler: `input$data_table_rows_selected` e
   `input$data_table_columns_selected`.
6. Barra missingness: percentuale per colonna, click → filtra o apre dialogo
   missing.

**Test:** `test-data-studio-grid.R`; E2E filtro/selezione.

**Accettazione:** filtro e selezione non modificano il dataset; sono
chiaramente “vista”.

---

### D1.3 — Inspector di colonna

**File:** `R/data-studio.R`.

**Contenuto:**

- nome, tipo, classe, etichetta, unità;
- n, missing, unici;
- per numeriche: min, max, media, mediana, sd, quartili;
- per fattori: livelli e conteggi;
- mini-distribuzione: istogramma o bar chart;
- azioni: Rename, Type, Recode, Bin, Standardize, Delete, Label, Filter,
  Sort, Summary, Plot.

**Passi:**

1. `selected_column` reactive; click su header o scelta da lista.
2. `column_profile(state, dataset, variable)` pura e testabile.
3. `renderPlot` compatto per numeriche/fattori.
4. Azioni: `set_dialog_memory()` + `state$open_dialog(id)`.

**Test:** `test-column-profile.R`; E2E inspector.

**Accettazione:** il profilo è corretto su numeriche, fattori, character e
logical; le azioni aprono il dialogo giusto con la variabile preselezionata.

---

### D1.4 — Operazioni su colonne

**File:** `R/command-builders-data.R`, `R/data-studio.R`, `R/dialogs-data.R`.

**Nuovi command builder puri:**

```r
cmd_add_column(dataset, name, value = NA)
cmd_duplicate_column(dataset, variable, name)
cmd_delete_columns(dataset, variables)
cmd_rename_column(dataset, variable, new_name)
cmd_reorder_columns(dataset, order)
cmd_set_column_type(dataset, variable, type)
cmd_add_row(dataset, values = NULL)
cmd_delete_rows(dataset, rows)
cmd_duplicate_rows(dataset, rows)
```

Per i tipi:

- numeric → factor: riusa `cmd_numeric_to_factor()`;
- character → factor: riusa `cmd_character_to_factor()`;
- factor → numeric: nuovo builder con validazione dei livelli;
- logical → numeric/factor: builder dedicato.

**Test:** golden test per ogni builder; `test-command-builders-data.R` esteso.

**Accettazione:** ogni operazione produce un comando eseguibile e il dataset
resta coerente.

---

### D1.5 — Operazioni su righe

**File:** `R/command-builders-data.R`, `R/data-studio.R`.

**Azioni:**

- aggiungi riga vuota o con valori;
- duplica righe selezionate;
- elimina righe selezionate;
- filtra righe (vista) o crea subset (comando);
- ordina per colonne;
- apri “Remove rows” / “Select rows” con la selezione precompilata.

**Regole:**

- eliminazione righe: conferma + checkpoint;
- duplicazione: nuovo `cmd_duplicate_rows()`;
- filtro vista: nessun comando;
- “Crea subset”: `cmd_subset_dataset()` con espressione o indici.

**Test:** `test-data-rows.R`.

**Accettazione:** selezione → elimina/duplica/subset funziona e lascia il log
coerente.

---

### D1.6 — Undo e checkpoint

**File:** nuovo `R/checkpoints.R` (o dentro `R/state.R`),
`R/data-studio.R`.

**API:**

```r
checkpoint_create(state, label)
checkpoint_list(state, dataset = active_dataset(state))
checkpoint_restore(state, id)
checkpoint_clear(state, id = NULL)
```

**UI:** pulsante Undo nella toolbar; menu “Checkpoint” con elenco, età e
dimensione; conferma al ripristino.

**Regole:**

- creare il checkpoint prima dell'esecuzione del comando, non dopo;
- non creare checkpoint per comandi che non cambiano il dataset;
- il ripristino aggiorna dataset, dizionario e inspector;
- il ripristino non aggiunge un comando al log, ma aggiunge una nota nella
  cronologia.

**Test:** `test-checkpoints.R`.

**Accettazione:** dopo un'operazione distruttiva, il ripristino recupera il
dataset precedente; la memoria resta sotto il cap.

---

### D1.7 — Data dictionary

**File:** `R/state.R`, `R/data-studio.R`, `R/command-builders-data.R`.

**Azioni:**

- modifica etichetta/unità/descrizione;
- import/export del dizionario in CSV/YAML;
- visualizzazione nelle intestazioni o nel tooltip;
- inclusione nel report “Data profile”.

**Comandi:** `attr()` come in §4.2.

**Test:** `test-data-dictionary.R`.

**Accettazione:** le etichette sopravvivono a salvataggio/riavvio del
progetto e compaiono nei report.

---

### D1.8 — Import wizard

**File:** `R/dialogs-import-text.R`, `R/dialogs-data.R`, `R/data-studio.R`.

**Passi:**

1. `fileInput` con `accept` per CSV, TXT, XLSX, XLS, SAV, DTA, SAS7BDAT, MTW.
2. Drag & drop: JS che assegna il file a `fileInput` o usa `input$file`.
3. Anteprima: prime 20 righe, delimiter, header, decimal, missing, encoding.
4. Rilevamento tipo per colonna e proposta di conversione.
5. Nome dataset + “Importa come nuovo” o “Sostituisci attivo”.
6. Comando generato: `read.csv`, `readxl::read_excel`, `foreign::read.spss`,
   ecc.
7. Salvataggio nella lista file recenti.

**Test:** `test-import-wizard.R`; E2E CSV.

**Accettazione:** import CSV/XLSX con anteprima e comando riproducibile.

---

### D1.9 — Fallback big data

**File:** `R/data-studio.R`, `R/state.R`.

**Regole:**

- `editable_dataset()` resta la soglia per l'editing cellulare;
- sopra soglia, la modalità Edit diventa “Targeted”:
  - niente griglia editabile;
  - inspector e filtri restano;
  - “Modifica colonna” apre i dialoghi mirati;
  - “Aggiungi colonna calcolata” usa `cmd_compute()`;
  - “Elimina righe” chiede espressione o campione;
  - “Esporta” resta disponibile.

**Test:** dataset sintetico sopra soglia; nessun crash.

**Accettazione:** nessun vicolo cieco: l'utente può comunque preparare i dati.

---

### D1.10 — Selezione → analisi

**File:** `R/data-studio.R`, `R/dialogs.R`.

**Azioni:**

- “Analizza selezione” → crea subset con nome generato e lo attiva;
- “Grafica selezione” → apre Chart Studio con il subset;
- “Invia a dialogo” → passa l'espressione di filtro a un dialogo che la
  supporta (`subset`, modelli con `subset`);
- “Esporta selezione” → CSV del subset.

**Test:** `test-selection-handoff.R`.

**Accettazione:** la selezione produce un comando riproducibile o un filtro
esplicito, mai un'azione magica non tracciata.

---

### D1.11 — Test, help, vignetta

**File:** `tests/testthat/*`, `inst/help-topics/topics/data-studio.md`,
`vignettes/data-studio.Rmd`, `_pkgdown.yml`.

**Contenuto help:**

- panoramica Data Studio;
- view vs edit vs targeted;
- inspector;
- operazioni;
- undo;
- import;
- selezione;
- data dictionary.

**Test E2E:** import CSV → filtro → edit cella → nuova colonna → undo → export.

---

## 6. Regole di riproducibilità

| Azione | Comando? | Note |
|---|---|---|
| Filtro di vista | No | È una vista effimera; indicato in UI |
| Crea subset | Sì | `cmd_subset_dataset()` |
| Modifica cella | Sì | Assegnazione sulla colonna/riga |
| Aggiungi/duplica/elimina riga | Sì | Nuovi builder |
| Aggiungi/duplica/elimina colonna | Sì | Nuovi builder |
| Rinomina colonna | Sì | `names()` o `colnames()` |
| Cambia tipo | Sì | Builder dedicato |
| Etichetta/unità | Sì | `attr()` |
| Undo/checkpoint | No | Operazione di sessione, nota in cronologia |
| Import | Sì | `read.*()` |
| Export | Sì | `write.csv()` / `save()` |

---

## 7. Test e accettazione dell'Onda 1

### Unit

- `test-data-registry.R`
- `test-data-studio-grid.R`
- `test-column-profile.R`
- `test-command-builders-data.R` (esteso)
- `test-data-rows.R`
- `test-checkpoints.R`
- `test-data-dictionary.R`
- `test-import-wizard.R`
- `test-selection-handoff.R`

### E2E

1. Importa un CSV.
2. Filtra per una colonna.
3. Modifica una cella.
4. Aggiungi una colonna calcolata.
5. Duplica ed elimina una riga.
6. Esegui undo.
7. Esporta il dataset.
8. Verifica comandi nel log e nel report.

### Criterio finale

> Il Data Studio copre il ciclo “import → ispeziona → pulisci → deriva →
> esporta” senza mai nascondere il codice R e senza disabilitare i dataset
> grandi.

---

## 8. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| rhandsontable lento o instabile su dataset medi | Soglia + modalità targeted; test di performance |
| Undo crea aspettative di undo globale | Etichettare “Ripristino dataset”, non “Undo comando” |
| Filtri e subset confusi | Distinzione visiva e testuale; “Crea subset” esplicito |
| Data dictionary non portabile | Salvarlo nel progetto e in CSV/YAML |
| Nuovi builder rompono i golden test | Test dedicati e comandi esistenti intatti |
| Selezione DT instabile con filtri | Test con filtri attivi; usare indici originali |

---

## 9. Fuori perimetro

- Pivot table / reshape visuale avanzato (i dialoghi esistenti restano).
- Editing collaborativo.
- Pulizia dati automatica o suggerimenti AI.
- Nuove procedure statistiche.

---

## 10. Checklist di chiusura

- [ ] Registro dataset.
- [ ] Selettore dataset e badge.
- [ ] Griglia view/edit/targeted.
- [ ] Ricerca, filtri, selezione.
- [ ] Inspector di colonna.
- [ ] Operazioni colonne con comandi.
- [ ] Operazioni righe con comandi.
- [ ] Checkpoint e ripristino.
- [ ] Data dictionary.
- [ ] Import wizard.
- [ ] Fallback big data.
- [ ] Selezione → analisi.
- [ ] Help topic e vignetta.
- [ ] Test unit e E2E verdi.
