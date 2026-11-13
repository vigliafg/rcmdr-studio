# Onda 3 — Report Studio

**Stato:** da implementare  
**Dipende da:** Onda 0, Onda 2 (galleria grafici)  
**Sblocca:** report riproducibili e presentabili senza lasciare l'app  
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Trasformare il Report tab da iframe sul knit a un ambiente di authoring:

- split editor/anteprima;
- outline e navigazione;
- celle eseguibili e output inline;
- template di report;
- inserimento di output, plot, tabelle e passi di cronologia;
- form YAML;
- knit manager con formati e storico;
- autosave e recovery.

Lo **Script** resta l'editor di codice a basso livello. Il **Report Studio** è
l'ambiente per documenti R Markdown e knitr.

---

## 2. Stato attuale

| Elemento | File | Situazione |
|---|---|---|
| Document model | `R/document.R` (587 righe) | Modi `r`, `rmd`, `rnw`; template; chunk; sezioni; knit |
| Dialoghi documento | `R/document-dialogs.R` (421 righe) | New/Open/Save/Save as, section, chunk, bibliography, knit |
| Report sessione | `R/report.R` (172 righe) | `report_rmd()`, HTML, export dialog |
| UI Script | `R/app.R` | Mode selector, New/Open/Save, Section, Chunk, Knit, Run |
| UI Report | `R/app.R` | iframe, download, refresh |
| Stato | `R/state.R` | `state$document`, `state$knit_result` |

Limiti attuali:

- un solo buffer documento, senza tab;
- nessuna anteprima Markdown live;
- nessun outline cliccabile;
- nessuna cella eseguibile con output inline;
- nessun template gallery;
- YAML modificabile solo a mano o con un dialogo limitato;
- knit sincrono senza progresso strutturato né storico;
- nessun autosave/recovery;
- Report tab passivo.

---

## 3. Stato target

### Layout

```text
┌──────────────────────────────────────────────────────────────┐
│ Toolbar: New | Open | Save | Template | Insert ▼ | Knit ▼   │
├──────────────┬──────────────────────────┬────────────────────┤
│ Outline      │ Editor                   │ Preview            │
│              │                          │                    │
│ # Sezione 1  │  ---                     │  [Markdown/HTML]   │
│ # Sezione 2  │  title: ...              │                    │
│  ## ...      │  ---                     │  Tabs: Preview |   │
│              │                          │  HTML | PDF | Word │
│ Chunk list   │  ```{r}                  │                    │
│  - setup     │  summary(Dataset)        │                    │
│  - plot      │  ```                     │                    │
├──────────────┴──────────────────────────┴────────────────────┤
│ Stato: modificato · autosave 12:31 · knit: HTML 12:30        │
└──────────────────────────────────────────────────────────────┘
```

### Modalità

| Modalità | Uso |
|---|---|
| **Report Studio** | Authoring Rmd/Rnw con preview, outline, insert, knit |
| **Script** | Codice R puro, notebook/celle, esecuzione |
| **Classica** | Comportamento 1.13.0: mode selector nello Script, Report iframe |

---

## 4. Architettura

### 4.1 Document model

Mantenere `state$document` come buffer attivo per compatibilità, ma aggiungere
un registro documenti:

```r
state$documents <- list(
  "report-1" = list(
    id = "report-1",
    path = "/path/report.Rmd",
    mode = "rmd",
    text = "...",
    dirty = FALSE,
    last_saved = Sys.time(),
    autosave_path = "..."
  )
)
state$active_document <- "report-1"
```

`document_text(state)`, `document_set_text()`, `document_mode()` leggono e
scrivono il documento attivo; il resto del motore continua a funzionare.

### 4.2 Parser e outline

Riusare:

- `document_chunk_bounds(text, mode)`;
- `document_section_lines(text, mode)`;
- `document_chunk_at(text, row, mode)`.

Nuove funzioni:

```r
document_outline(text, mode) -> data.frame(level, title, line)
document_chunks(text, mode) -> data.frame(id, label, start, end, code)
document_front_matter(text) -> list(values, lines, bounds)
document_set_front_matter(state, values)
```

### 4.3 Preview

| Preview | Tecnologia | Esecuzione codice |
|---|---|---|
| Markdown | `commonmark` (Imports) | No |
| HTML | `rmarkdown::render` | Sì, su richiesta |
| PDF | `rmarkdown::pdf_document` / `knitr` | Sì, su richiesta |
| Word | `rmarkdown::word_document` | Download |

La preview veloce non esegue i chunk: mostra il testo e segnaposto per i
blocchi di codice. Il knit esegue tutto nel `state$env`.

### 4.4 Celle

```r
state$cell_outputs <- list(
  "chunk-1" = list(
    status = "ok",
    output = character(),
    plots = list(),
    time = Sys.time()
  )
)
```

Regole:

- “Esegui cella” usa `run_command(state, code)`;
- l'output è inline e collassabile;
- l'output inline è una preview di sessione, non viene scritto nel documento;
- “Inserisci output” o “Inserisci plot” aggiunge esplicitamente il contenuto
  al documento;
- il knit riesegue i chunk, come da semantica R Markdown.

### 4.5 Template

```r
report_templates() -> list(
  analysis = list(
    id = "analysis",
    title = "Report di analisi",
    description = "...",
    mode = "rmd",
    text = c(...)
  ),
  ...
)
```

Template iniziali:

1. **Report di analisi** — contesto, dati, statistiche, grafici, conclusioni.
2. **Data profile** — struttura, missing, distribuzioni, qualità.
3. **Model diagnostics** — formula, summary, diagnostica, influenza, effect
   plot.
4. **Teaching handout** — obiettivi, dati, comandi, risultati, esercizi.
5. **Survival report** — KM, Cox, diagnostica, interpretazione.

Tutti usano comandi esistenti e placeholder `{{dataset}}`.

### 4.6 Inserimento contestuale

```r
report_insert_text(state, text, level = NULL)
report_insert_chunk(state, code, label = NULL, options = character())
report_insert_output(state, history_id)
report_insert_plot(state, plot_id)
report_insert_table(state, object, caption = NULL)
report_insert_history_step(state, history_id)
report_insert_data_profile(state, dataset)
report_insert_model_summary(state, model)
```

### 4.7 YAML front matter

Campi supportati:

```yaml
title: "..."
author: "..."
date: "2026-11-13"
output: html_document
toc: true
bibliography: references.bib
link-citations: true
theme: cosmo
```

Form con validazione; editor raw opzionale. Usare `yaml` (Imports) con
fallback al parser interno esistente.

### 4.8 Knit manager

```r
state$knit_history <- list(
  list(id = "knit-1", format = "html", file = "...", url = "...",
       status = "ok", time = Sys.time(), duration_ms = 4200)
)
```

UI:

- formato disponibile/non disponibile con motivo;
- progresso;
- errori con contesto (chunk, riga, messaggio);
- storico knit;
- apri nel browser;
- download;
- “Knit e apri”.

### 4.9 Autosave e recovery

- autosave ogni 30 s se `dirty`;
- path in `state$project$autosave` o temp;
- recovery prompt all'avvio;
- dirty indicator nella toolbar;
- “Salva” e “Salva come” usano `document_save()`;
- backup `.bak` prima del salvataggio.

---

## 5. Task

### R3.1 — Registro documenti

**File:** `R/document.R`, `R/state.R`, `R/report-studio.R`.

**Passi:**

1. Aggiungere `state$documents` e `state$active_document`.
2. Funzioni `document_list()`, `document_create()`, `document_activate()`,
   `document_close()`.
3. Migrare `document_text()` e amici al documento attivo.
4. Mantenere `state$document` sincronizzato.
5. Test di retrocompatibilità con i test documento esistenti.

**Accettazione:** più documenti convivono; i test esistenti restano verdi.

---

### R3.2 — Report Studio UI

**File:** nuovo `R/report-studio.R`, `R/app.R`.

**Passi:**

1. `reportStudioUI()` e `reportStudioServer()`.
2. Toolbar con New/Open/Save/Save as/Template/Insert/Knit.
3. Outline, editor, preview.
4. Tabs preview.
5. Status bar con dirty/autosave/knit.
6. In modalità Classica, mantenere il layout attuale.

**Test:** `test-report-studio-ui.R`; E2E.

**Accettazione:** il Report Studio sostituisce l'iframe nel modo Studio senza
rimuovere la modalità Classica.

---

### R3.3 — Outline e chunk list

**File:** `R/document.R`, `R/report-studio.R`.

**Passi:**

1. `document_outline()` e `document_chunks()`.
2. UI outline cliccabile che posiziona il cursore in Ace.
3. Chunk list con label, stato e pulsante Esegui.
4. Aggiornamento con debounce sul testo.
5. Test parser.

**Accettazione:** outline e chunk list restano sincronizzati con l'editor.

---

### R3.4 — Preview Markdown e HTML

**File:** `R/report-studio.R`, `R/preview.R`.

**Passi:**

1. Preview Markdown con `commonmark`.
2. Placeholder per chunk e YAML.
3. Render HTML on demand.
4. Cache per testo identico.
5. Errori di render in un pannello.

**Test:** `test-report-preview.R`.

**Accettazione:** la preview veloce non esegue codice; il render HTML sì.

---

### R3.5 — Celle eseguibili

**File:** `R/report-studio.R`, `R/commands.R`.

**Passi:**

1. Mappare chunk → id stabile.
2. “Esegui cella” chiama `run_command()` e salva l'output in
   `state$cell_outputs`.
3. Render inline collassabile.
4. “Esegui tutte” e “Esegui fino a qui”.
5. “Inserisci output” e “Inserisci plot” nel documento.
6. Test: esecuzione, output, inserimento.

**Accettazione:** l'utente può esplorare i risultati senza perdere il
documento; il knit resta la fonte finale.

---

### R3.6 — Template gallery

**File:** nuovo `R/report-templates.R`, `R/report-studio.R`.

**Passi:**

1. Definire i 5 template.
2. UI con card, descrizione, anteprima.
3. Creazione con nome e dataset.
4. Test: ogni template è Rmd/Rnw valido e knittabile (dove le dipendenze sono
   disponibili).

**Accettazione:** un template produce un documento valido con il dataset
attivo.

---

### R3.7 — Inserimento contestuale

**File:** `R/report.R`, `R/report-studio.R`, `R/document.R`.

**Passi:**

1. Implementare le funzioni `report_insert_*`.
2. Menu Insert con:
   - Output dell'ultimo comando;
   - Plot selezionato;
   - Tabella;
   - Passo di cronologia;
   - Data profile;
   - Model summary;
   - Sezione;
   - Chunk.
3. Test: insert non corrompe il documento.

**Accettazione:** ogni inserimento è riproducibile e collocato nella sezione
corrente.

---

### R3.8 — YAML form e bibliografia

**File:** `R/document.R`, `R/report-studio.R`, `R/document-dialogs.R`.

**Passi:**

1. Parse/update front matter.
2. Form con titolo, autore, data, output, TOC, bibliography, tema.
3. Validazione YAML.
4. Integrazione con il dialogo bibliografia esistente.
5. Test: round-trip YAML.

**Accettazione:** il form non perde campi non gestiti; il documento resta
valido.

---

### R3.9 — Knit manager

**File:** `R/document.R`, `R/report-studio.R`, `R/app.R`.

**Passi:**

1. `document_knit()` con progresso e cattura errori.
2. `state$knit_history`.
3. UI formati con disponibilità.
4. Preview HTML/PDF e download Word.
5. “Knit e apri”.
6. Test: HTML se disponibile; errore gestito se pandoc manca.

**Accettazione:** knit non blocca la UI senza feedback; gli errori sono
leggibili e contestualizzati.

---

### R3.10 — Autosave e recovery

**File:** `R/document.R`, `R/report-studio.R`, `R/project.R`.

**Passi:**

1. Dirty tracking su modifica.
2. Autosave periodico.
3. Recovery prompt.
4. Backup `.bak`.
5. Test con file temporanei.

**Accettazione:** un crash simulato non perde più di 30 secondi di lavoro.

---

### R3.11 — Test, help, vignetta

**File:** `tests/testthat/*`,
`inst/help-topics/topics/report-studio.md`,
`vignettes/report-studio.Rmd`.

**Contenuto help:**

- Report Studio vs Script;
- preview vs knit;
- celle;
- template;
- insert;
- YAML;
- formati;
- autosave;
- troubleshooting.

**Test E2E:** template → insert plot → preview → knit HTML → download.

---

## 6. Regole di riproducibilità

| Azione | Comando? | Note |
|---|---|---|
| Modifica testo | No | È authoring |
| Anteprima Markdown | No | Non esegue codice |
| Esegui cella | Sì | `run_command()` |
| Inserisci output | No | Contenuto del documento |
| Inserisci plot | No | Path/figura nel documento |
| Knit | Sì | Riesegue i chunk |
| YAML form | No | Metadati |
| Template | No | Testo iniziale |
| Autosave | No | File di recovery |

---

## 7. Test e accettazione dell'Onda 3

### Unit

- `test-document-registry.R`
- `test-document-outline.R`
- `test-report-preview.R`
- `test-report-cells.R`
- `test-report-templates.R`
- `test-report-insert.R`
- `test-report-yaml.R`
- `test-report-knit-manager.R`
- `test-report-autosave.R`

### E2E

1. Apri Report Studio.
2. Crea da template “Report di analisi”.
3. Inserisci ultimo plot e ultimo output.
4. Esegui una cella.
5. Visualizza preview Markdown.
6. Knit HTML.
7. Scarica il report.
8. Verifica che il documento sia valido.

### Criterio finale

> Il Report Studio permette di scrivere, esplorare e produrre un report
> riproducibile senza ambiguità tra anteprima, esecuzione e knit.

---

## 8. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| Preview veloce confusa con knit | Etichette chiare: “Anteprima” vs “Knit” |
| Output inline diverso dal knit | Nota esplicita; il knit riesegue |
| Multi-documento rompe i test | `state$document` sincronizzato; test retrocompatibili |
| YAML parser perde campi | Round-trip conservativo |
| Knit lungo blocca la UI | Progresso, busy state, messaggi; niente finta cancellazione |
| Autosave sovrascrive file utente | Path separato + backup |

---

## 9. Fuori perimetro

- WYSIWYG completo.
- Editing collaborativo.
- Pubblicazione automatica su server.
- Nuove procedure statistiche.

---

## 10. Checklist di chiusura

- [ ] Registro documenti.
- [ ] Report Studio UI.
- [ ] Outline.
- [ ] Chunk list.
- [ ] Preview Markdown.
- [ ] Preview/render HTML.
- [ ] Celle eseguibili.
- [ ] Template gallery.
- [ ] Insert contestuale.
- [ ] YAML form.
- [ ] Bibliografia.
- [ ] Knit manager.
- [ ] Autosave/recovery.
- [ ] Help topic e vignetta.
- [ ] Test unit e E2E verdi.
