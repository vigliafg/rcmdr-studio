# Diario di handoff — Onda 3 — Report Studio

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** Onda 2 — Chart Studio  
**Ondata successiva:** Onda 4 — Workbench  
**Documento di settore:** [`../03-report-studio.md`](../03-report-studio.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo:** trasformare il tab Report da iframe sul knit a un ambiente di
authoring R Markdown — registro documenti, outline, celle eseguibili, template,
inserimento contestuale, YAML, knit manager, autosave — senza aggiungere
procedure statistiche e senza rimuovere la modalità Classica.

**Risultato effettivo:** la modalità Studio ha un **Report Studio** operativo:

- registro multi-documento con attivazione, chiusura e dirty tracking;
- toolbar con documenti, New, Template, Open, Save, Save as, YAML e Knit;
- outline cliccabile e chunk list con stato e pulsante Run;
- editor Ace dedicato, anteprima Markdown/HTML/Source e barra di stato;
- anteprima Markdown veloce con `commonmark` che non esegue codice;
- celle eseguibili con output inline, plot e storia strutturata;
- cinque template con sostituzione del dataset;
- inserimento esplicito di output, plot, storia, tabelle, profilo dati,
  summary di modello, sezioni e chunk;
- form YAML conservativo con bibliografia e citation linking;
- knit manager con formati, motivazioni, storico, errori, anteprima e
  download;
- autosave periodico, banner di recovery e backup `.bak`.

La modalità **Classica** mantiene il vecchio pannello Report con iframe e
download.

**Cosa è pronto:** R3.1–R3.11, con le deviazioni annotate in §6.

**Cosa non è pronto:** Onda 4 (Workbench), inserimento alla posizione del
cursore, knit asincrono, recovery dopo un riavvio completo di R.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `28810b2` | feat: Wave 3 Report Studio | Commit principale dell'Onda 3 |
| `9af134b` | docs: add Wave 2 Chart Studio handoff diary | Ultimo commit Onda 2 |

Il diario viene committato subito dopo il commit principale.

---

## 3. File creati e modificati

### Creati

- `R/report-studio.R` — anteprima, celle, inserimento, UI, dialoghi
  `reportYaml`/`reportTemplate`, server e knit manager UI.
- `R/report-templates.R` — cinque template, scelta, applicazione e gallery.
- `inst/help-topics/topics/report-studio.md` — topic Report Studio.
- `vignettes/report-studio.Rmd` — template → documento -> preview → celle →
  YAML → knit → autosave.
- `tests/testthat/helper-report.R`
- `tests/testthat/test-document-registry.R`
- `tests/testthat/test-document-outline.R`
- `tests/testthat/test-report-preview.R`
- `tests/testthat/test-report-cells.R`
- `tests/testthat/test-report-templates.R`
- `tests/testthat/test-report-insert.R`
- `tests/testthat/test-report-yaml.R`
- `tests/testthat/test-report-knit-manager.R`
- `tests/testthat/test-report-autosave.R`
- `tests/testthat/test-report-studio.R`
- `tests/testthat/test-report-studio-e2e.R`

### Modificati

- `R/state.R` — `documents`, `active_document`, `document_counter`,
  `document_dirty`, `autosave_dir`, `autosave_time`, `recoveries`,
  `cell_outputs`, `cell_counter`, `knit_history`, `knit_counter`; opzioni
  `report_preview_cache`, `autosave_interval`, `document_backup`.
- `R/document.R` — registro, outline/chunk parser, front matter, autosave,
  recovery, knit history e `document_format_reason()`; `document_new()` e
  `document_open()` usano il registro; `document_save()` crea il backup.
- `R/app.R` — `report_pane_ui(mode)`, Report Studio in modalità Studio,
  inizializzazione del registro, directory report/autosave, chiamata a
  `report_studio_server()`, CSS del workspace, `rcmdrReportGoto()` e
  `rcmdrRunChunk()` limitato a `#script_editor_ui`.
- `R/dialogs.R` — registrati `report_studio_dialogs()`.
- `R/features.R` — `report_studio = TRUE`.
- `R/chart-studio.R` — guardia su `chart_preview_image` per sorgenti non
  valide.
- `DESCRIPTION` — versione 1.17.0, descrizione.
- `README.md`, `NEWS.md` — stato e funzioni Wave 3.
- `_pkgdown.yml` — vignetta `report-studio`.
- `inst/help-topics/index.yml` — categoria `report` e topic `report-studio`.
- `inst/etc/help-inventory.csv` — rigenerato.
- `tests/testthat/test-shinytest2.R`, `test-documents-e2e.R`,
  `test-plugins-e2e.R`, `test-wave0-e2e.R` — selettore Ace limitato a
  `#script_editor_ui`.
- `docs/upgrades/03-report-studio.md`, `CHECKLIST.md`, `README.md` — stato
  Onda 3.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **2277 pass, 0 fail, 12 skip** |
| E2E core | `test-shinytest2.R` | **15 pass** |
| E2E Wave 0 | `test-wave0-e2e.R` | **3 pass** |
| E2E documenti | `test-documents-e2e.R` | **8 pass** |
| E2E Data Studio | `test-data-studio-e2e.R` | **6 pass** |
| E2E Chart Studio | `test-chart-studio-e2e.R` | **7 pass** |
| E2E Report Studio | `test-report-studio-e2e.R` | **5 pass** |
| E2E plugin | `test-plugins-e2e.R` | **19 pass** |
| `R CMD check` | `_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual` | **Status: OK** |
| Help inventory | `Rscript tools/inventory_help.R --plugins all` | 642 documented, 55 extra, 0 fallback |
| Link checker | `Rscript tools/check_help_links.R --strict` | 447 topic, nessun link rotto |

Gli skip sono i test E2E/visual opt-in. Resta il warning cosmetico di
`shinytest2` “Failed to locate globals in server function” per `renderPlot`.

---

## 5. Decisioni e ADR

- **Un solo buffer condiviso.** `state$document` resta la fonte per Script e
  Report; il registro aggiunge `state$documents` e `state$active_document`
  senza rompere i chiamanti storici.
- **Documenti vuoti riusati.** `document_new()` riusa un buffer vuoto e pulito
  invece di creare tab vuote.
- **Preview ≠ knit.** `report_preview_markdown()` non esegue codice e sostituisce
  i chunk con placeholder. Il knit usa `document_knit()` e riesegue tutto.
- **Celle senza doppioni.** `report_run_cell()` usa `run_command(log = FALSE)`
  per non attivare l'auto-append del documento; la storia strutturata registra
  comunque la sorgente `report`.
- **Inserimento esplicito.** `report_insert_*` modificano il documento solo
  quando l'utente preme il pulsante; nessuna anteprima o esecuzione scrive nel
  documento.
- **YAML conservativo.** `document_set_front_matter()` parte dai valori correnti
  e sostituisce solo i campi passati; i campi sconosciuti restano.
- **Knit con storico.** `document_knit()` registra successi e fallimenti,
  durata, errore e link; `document_format_reason()` spiega i formati mancanti.
- **Autosave separato dall'utente.** Le copie vanno nella directory di autosave
  e il salvataggio crea un `.bak` prima di sovrascrivere.
- **Editor Ace dedicato.** Il Report Studio ha `report_editor`; la E2E e
  `rcmdrRunChunk()` sono state limitate a `#script_editor_ui` per non
  confondere i due editor.
- **Nessuna nuova dipendenza obbligatoria.** `commonmark`, `yaml`, `rmarkdown`
  e `knitr` erano già Suggests e hanno fallback o messaggi espliciti.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| R3.2 | Toolbar con Insert/Knit dropdown | Pulsanti piatti e pannello Insert in `<details>` | Meno complessità Bootstrap 5, stesso contenuto |
| R3.3 | Cursore in Ace dall'outline | `gotoLine()` in Ace | Fatto; l'inserimento invece resta in coda |
| R3.4 | Render HTML on demand separato | Tab HTML mostra l'ultimo knit; Knit è il render | Evita due pipeline di render e cache divergenti |
| R3.5 | Esegui cella con `run_command()` | `run_command(log = FALSE, source = "report")` | Evita che l'auto-append duplichi il chunk |
| R3.7 | Inserimento nella sezione corrente | In coda al documento o prima di `\end{document}` | Il cursore richiede un round-trip JS/server; rinviato |
| R3.9 | Progresso strutturato | Notifica + busy state, knit sincrono | Shiny single-thread; niente finta cancellazione |
| R3.10 | Recovery dopo crash | Recovery nella stessa sessione/processo | La directory autosave è in `tempdir()`; rinviato a Onda 7 (progetto) |
| R3.11 | E2E template → plot → output → knit | Fatto, con inserimento output da cella | Il selettore storia non è affidabile nel browser; la cella sì |
| — | Markdown preview con placeholder HTML | Placeholder come blocchi HTML | `commonmark` preserva l'HTML raw |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| Warning `shinytest2` sui globals di `renderPlot` | Rumore nei log E2E | Ignorabile; i test passano | R3.11 |
| `selectInput` della storia può mostrare solo l'opzione più recente nel browser | L'E2E evita il selettore e usa la cella | Usare il pulsante Run della cella | R3.7 |
| L'auto-append dei comandi può aggiungere chunk al documento Rmd | Comportamento storico, non nuovo | Disattivare “Append generated commands” nello Script | R3.7 |
| Il knit è sincrono | La UI attende la fine | Notifica di busy; nessuna cancellazione | R3.9 |
| L'autosave non sopravvive a un riavvio di R | Recovery limitata al processo | Salvare su file; Onda 7 potrà usare il progetto | R3.10 |
| YAML annidato complesso è conservato solo se `yaml` è installato | Round-trip non garantito per strutture esotiche | Usare il campo raw o `yaml` | R3.8 |
| Il preview Rnw non è renderizzato | Mostra il sorgente con una nota | Knit per il PDF | R3.4 |
| L'inserimento è in coda, non al cursore | Meno preciso in documenti lunghi | Riordinare a mano o usare Section | R3.7 |

---

## 8. Domande aperte

- [ ] L'inserimento deve usare davvero la posizione del cursore in Ace?
- [ ] Il knit deve diventare asincrono con `callr`/`future` in Onda 7?
- [ ] L'autosave deve vivere nella directory del progetto quando esisterà?
- [ ] Il preview HTML deve essere un render separato dal knit?
- [ ] Il selettore della storia va sostituito con una lista di card?
- [ ] L'auto-append va disattivato per i documenti creati da template?
- [ ] I template devono poter usare il modello attivo, non solo il dataset?

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../04-workbench.md` e `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: **2277 pass, 0 fail, 12 skip**).
3. Avviare l'Onda 4 dal task **W4.1 — Registro script e tab**.

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| W4.1 | Registro script e tab | Alta | Riusa il registro documenti |
| W4.2 | Celle e run above/below | Alta | `run_command()` |
| W4.3 | Outline e diagnostica | Media | Parser R |
| W4.4 | Find/replace e autocomplete | Media | Ace |
| W4.5 | Format e autosave | Media | `document_autosave()` |
| W4.6 | Console UI e input | Alta | `R/console.R` |
| W4.7 | Storico comandi | Alta | `state$history` |
| W4.8 | Output card e rerun | Alta | Output strutturato |
| W4.9 | Rilevamento comandi interattivi | Media | Console guard |
| W4.10 | Output cards | Alta | UI |
| W4.11 | Ricerca/filtri output | Media | UI |
| W4.12 | Messages per severità | Media | `state$messages` |
| W4.13 | Object explorer | Alta | `ls(state$env)` |
| W4.14 | Anteprima oggetto | Media | `str`/`summary` |
| W4.15 | Azioni rapide | Media | Menu |
| W4.16 | Dataset registry view | Alta | `dataset_registry()` |
| W4.17 | Model registry | Alta | `state$active_model` |
| W4.18 | Model registry UI | Alta | UI |
| W4.19 | Dashboard tabella/confronto | Media | UI |
| W4.20 | Azioni modello | Media | Dialoghi |
| W4.21 | Reopen dialog con memoria | Alta | `open_dialog_memory()` |

---

## 10. Comandi per riprendere

```bash
cd /home/vigliafg/Documenti/GitHub/rcmdr-studio
git status
git log --oneline -5
Rscript -e 'testthat::test_local()'
```

Per gli E2E:

```bash
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-report-studio-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-documents-e2e.R")'
```

**Baseline attesa:** 2277 pass, 0 fail, 12 skip; `R CMD check` OK.

---

## 11. Note di contesto

- Il package installato va aggiornato con `R CMD INSTALL .` dopo modifiche al
  codice, prima degli E2E: `RcmdrShiny::app()` usa il namespace installato.
- `state$document` è il buffer attivo; `state$documents` è il registro e
  `state$active_document` l'id attivo.
- `document_list()` restituisce `id`, `title`, `path`, `mode`, `dirty`,
  `active`, `autosave`.
- `document_chunks()` restituisce `id`, `label`, `engine`, `start`, `end`,
  `code`, `header`; gli id sono `chunk-<label>` o `chunk-NN` e sono resi unici.
- `document_chunk_at()` resta disponibile per il run chunk dello Script.
- `report_preview()` è cachata in `.report_preview_cache` e limitata
  dall'opzione `report_preview_cache`.
- `report_run_cell()` e `report_run_all_cells()` salvano in
  `state$cell_outputs`; lo stato è `ok`, `error`, `empty`, `missing`.
- `report_insert_*` scrivono solo nel documento; non eseguono comandi.
- `document_knit()` registra in `state$knit_history` e imposta
  `state$knit_result`; `document_format_reason()` spiega i formati.
- `report_studio_server(input, output, session, state, refresh, tick)` gestisce
  gli output `report_*` e gli input `report_*`.
- In modalità Classica `report_pane_ui("classic")` mantiene `#report_pane`.
- Due editor Ace: `script` in `#script_editor_ui` e `report_editor` in
  `#report_editor_ui`; i test E2E devono limitare il selettore.
- `rcmdrRunChunk()` usa `#script_editor_ui`; `rcmdrReportGoto()` usa
  `#report_editor_ui`.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “diario pronto, puoi compattare il contesto”.
