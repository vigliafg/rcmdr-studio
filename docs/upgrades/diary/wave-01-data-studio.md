# Diario di handoff — Onda 1 — Data Studio

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** Onda 0 — Studio foundations  
**Ondata successiva:** Onda 2 — Chart Studio  
**Documento di settore:** [`../01-data-studio.md`](../01-data-studio.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo:** trasformare il tab Data in un ambiente di preparazione dati
completo (registro dataset, griglia, inspector, operazioni strutturali,
checkpoint, dizionario, import wizard, fallback per dataset grandi,
selezione → analisi) senza aggiungere procedure statistiche e senza cambiare
i comandi esistenti.

**Risultato effettivo:** la modalità Studio ha un **Data Studio** operativo:
registro e selettore dei dataset, griglia con ricerca e filtro di vista,
inspector di colonna, operazioni su righe e colonne come comandi R,
checkpoint di sessione, dizionario dati con export CSV/YAML e import CSV,
import wizard con anteprima e modalità targeted sopra la soglia di editing.
La modalità Classica mantiene il vecchio pannello Data.

**Cosa è pronto:** D1.1–D1.11, con le deviazioni annotate in §6.

**Cosa non è pronto:** Chart Studio e Report Studio (Onde 2–3); handoff
selezione → grafico (Onda 2); workflow e palette evoluta (Onda 5); progetto
`.rcmdrproj` (Onda 7).

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `ec733cd` | feat: Wave 1 Data Studio | Commit principale dell'Onda 1 |
| `2b4153d` | docs: add Wave 1 Data Studio handoff diary | Diario |
| `9800602` | docs: mark Wave 1 diary as handed off | Handoff |
| `7e3e817` | fix: keep the delete-rows selection in the dialog | Selezione righe nel dialogo |
| `011b405` | docs: mark Wave 0 diary as handed off | Ultimo commit Onda 0 |

Il commit principale include anche il logging delle modifiche cella come
comandi (`cmd_edit_cells()`), aggiunto dopo la prima stesura dei test.

---

## 3. File creati e modificati

### Creati

- `R/data-studio.R` — registro dataset, dizionario, checkpoint, selezione,
  profilo di colonna, missingness, anteprima import, helper griglia, UI
  Data Studio, sette dialoghi (`dataAddColumn`, `dataDuplicateColumn`,
  `dataColumnType`, `dataCreateSubset`, `dataDeleteRows`, `dataCheckpoints`,
  `dataDictionary`).
- `inst/help-topics/topics/data-studio.md` — topic Data Studio.
- `vignettes/data-studio.Rmd` — ciclo import → ispeziona → pulisci → deriva →
  esporta.
- `tests/testthat/test-data-registry.R`
- `tests/testthat/test-data-studio-grid.R`
- `tests/testthat/test-column-profile.R`
- `tests/testthat/test-data-rows.R`
- `tests/testthat/test-checkpoints.R`
- `tests/testthat/test-data-dictionary.R`
- `tests/testthat/test-import-wizard.R`
- `tests/testthat/test-selection-handoff.R`
- `tests/testthat/test-data-studio-dialogs.R`
- `tests/testthat/test-data-studio-e2e.R`

### Modificati

- `R/state.R` — `datasets`, `data_dictionary`, `checkpoints`,
  `checkpoint_counter`, `data_selection`, `last_checkpoint_skip`, opzioni
  `checkpoint_max`, `checkpoint_max_bytes`, `import_preview_rows`;
  `active_dataset()` e `update_dataset()` registrano il dataset.
- `R/commands.R` — `remember_assignment()` registra i data frame creati da
  comandi.
- `R/command-builders-data.R` — nuovi builder per colonne, righe, tipi,
  etichette e modifiche cella (`cmd_edit_cells()`).
- `R/dialogs.R` — registrati `dataImportWizard` e i dialoghi Data Studio.
- `R/history-ui.R` — sorgenti `data` e `checkpoint` nella cronologia.
- `R/app.R` — Data Studio UI e server: selettore dataset, griglia, filtro,
  inspector, selezione, azioni, dialoghi, checkpoint, dizionario, import;
  pulsanti statici fuori dall'inspector per evitare re-trigger; aggiornamento
  del test E2E del tab Data.
- `DESCRIPTION` — versione 1.15.0, descrizione, `graphics` in Imports.
- `README.md`, `NEWS.md` — funzioni e stato Wave 1.
- `_pkgdown.yml` — vignetta `data-studio`.
- `inst/help-topics/index.yml` — topic `data-studio`.
- `inst/etc/help-inventory.csv` — rigenerato.
- `tests/testthat/test-command-builders-data.R` — test dei nuovi builder.
- `tests/testthat/test-shinytest2.R` — attende `data_studio_editor` nel tab
  Data in modalità Studio.
- `docs/upgrades/01-data-studio.md`, `CHECKLIST.md`, `README.md` — stato
  Onda 1.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **1640 pass, 0 fail, 10 skip** |
| E2E core | `NOT_CRAN=true RCMDRSHINY_E2E=1 ... test-shinytest2.R` | **15 pass** |
| E2E Wave 0 | `... test-wave0-e2e.R` | **3 pass** |
| E2E documenti | `... test-documents-e2e.R` | **8 pass** |
| E2E Data Studio | `... test-data-studio-e2e.R` | **6 pass** |
| E2E plugin | `... test-plugins-e2e.R` | **19 pass** |
| `R CMD check` | `_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual` | **Status: OK** |
| Help inventory | `Rscript tools/inventory_help.R --plugins all` | 629 documented, 55 extra, 8 fallback |
| Link checker | `Rscript tools/check_help_links.R --strict` | 445 topic, nessun link rotto |

Gli skip sono i test E2E/visual opt-in e non indicano fallimenti. Il warning
di `shinytest2` “Failed to locate globals in server function” è dovuto
all'analisi statica di `renderPlot` e non impedisce l'avvio né i test.

---

## 5. Decisioni e ADR

- **Dialoghi invece di modali ad hoc.** Le prime operazioni strutturali
  usavano `showModal()` direttamente. Con Bootstrap 5/Shiny 1.10 il modale
  veniva ri-mostrato dopo la chiusura. Tutte le operazioni sono quindi
  dialoghi del runtime standard (`dialog_spec()`), che offre già anteprima,
  preset, validazione e chiusura affidabile.
- **Selezione righe con callback dedicato.** La selezione DT non era
  affidabile in questa combinazione di versioni. Il callback
  `grid_selection_callback()` registra `.row_id` e invia
  `data_grid_selection`; la selezione resta corretta anche con filtri e
  ordinamento.
- **Filtro di vista lato server.** Il filtro di colonna è un reactive che
  filtra la griglia, non un filtro DT `filter = "top"` (che in questo
  ambiente richiedeva `noUiSlider` e falliva). Il filtro non modifica il
  dataset e non produce comandi.
- **Checkpoint prima della mutazione.** Le operazioni distruttive e le
  modifiche cella creano un checkpoint prima del comando. Il ripristino è
  una nota di cronologia (`source = "checkpoint"`), non un comando.
- **Logging delle modifiche cella.** `cmd_edit_cells()` confronta vecchio e
  nuovo data frame e genera un'assegnazione per ogni cella cambiata, così
  anche l'editing `rhandsontable` rispetta il contratto “ogni mutazione è un
  comando”.
- **Pulsanti azione statici.** I pulsanti del Data Studio vivono fuori
  dall'`uiOutput` dell'inspector: il refresh del profilo non li ricrea e non
  ri-triggera gli observer.
- **Nessuna nuova dipendenza.** `DT`, `rhandsontable`, `utils`, `graphics`
  erano già disponibili. `yaml` e `readxl` restano Suggests opzionali.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| D1.2 | DT `filter = "top"` | Ricerca globale DT + filtro di colonna reactive | `noUiSlider` non funzionante con DT 0.34/Bootstrap 5 in questo ambiente; il filtro reactive è più prevedibile |
| D1.4 | Reorder colonne con UI | Builder `cmd_reorder_columns()` disponibile, nessun pulsante dedicato | Il riordino visuale richiede drag-and-drop o una UI dedicata; rinviato a Onda 5 |
| D1.6 | Cap 20 checkpoint / 50 MB | Implementato, con `checkpoint_max` e `checkpoint_max_bytes` configurabili | — |
| D1.8 | CSV/TXT/XLSX/XLS/SAV/DTA/SAS7BDAT/MTW | Wizard CSV/TXT/XLSX/XLS; gli altri formati restano nei dialoghi esistenti | Anteprima generica per SPSS/Stata/SAS non disponibile senza dipendenze aggiuntive |
| D1.7 | Import/export dizionario CSV/YAML | Export CSV/YAML e import CSV nel dialogo Dictionary | L'import YAML è rinviato; il CSV copre il caso d'uso |
| D1.10 | Analizza/grafica/invia/esporta selezione | Subset comandato e attivazione; export selezione non dedicato | Chart handoff e export selezione sono più naturali in Onda 2 |
| D1.2 | Selezione DT nativa | Callback dedicato `.row_id` | Selezione DT inaffidabile nella combinazione di versioni corrente |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| `renderPlot` genera un warning di analisi statica in `shinytest2` | Rumore nei log E2E | Ignorabile; i test passano | D1.3 |
| Il select “Columns for subset” viene ricreato a ogni tick | Possibile perdita della selezione colonne in casi limite | Il valore è ricalcolato da `data_selection()` | D1.10 |
| Il riordino colonne non ha UI | Operazione disponibile solo via builder | Dialogo dedicato in Onda 5 | N5.9 |
| Import SPSS/Stata/SAS/Minitab non usa il wizard | Restano i dialoghi storici | Usare i dialoghi esistenti | D1.8 |
| Il filtro di colonna è “contains” per character e “equals” per numerico | Filtri complessi non supportati | Usare i dialoghi subset/filter esistenti | D1.2 |
| Checkpoint non persistiti tra sessioni | Undo solo di sessione | Sarà nel progetto `.rcmdrproj` | P7.7 |

---

## 8. Domande aperte

- [ ] Il riordino colonne deve usare drag-and-drop o un dialogo con ordine
  testuale?
- [ ] Il filtro di colonna deve supportare operatori (`>`, `<`, `!=`) o
  restare un filtro “contains/equals”?
- [ ] Il dataset registry deve persistere la fonte (`csv:...`) anche quando
  il dataset è creato da uno script?
- [ ] L'import wizard deve supportare SPSS/Stata/SAS con anteprima parziale?
- [ ] Il limite dei checkpoint deve essere configurabile da Options?
- [ ] La selezione deve includere un'espressione di filtro persistente tra
  sessioni?

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../02-chart-studio.md` e `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: **1640 pass, 0 fail, 10 skip**).
3. Avviare l'Onda 2 dal task **C2.1 — Chart spec e registry**.

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| C2.1 | Chart spec e registry | Alta | Riutilizza `column_profile()` e il dataset registry |
| C2.2 | Builder UI | Alta | Variabili, geometrie, estetica |
| C2.3 | Preview live | Alta | Usa il preview engine esistente |
| C2.4 | Apply e registrazione | Alta | Comando + galleria |
| C2.5 | Galleria evoluta | Alta | Filtri, metadati, reopen |
| C2.6 | Export | Alta | PNG/PDF/SVG/HTML |
| C2.7 | Temi e palette | Media | Token esistenti |
| C2.8 | Round-trip e reopen | Media | Chart spec ↔ dialogo |
| C2.9 | Selezione e brush | Media | Usa `data_selection()` |
| C2.10 | Test, help, vignetta | Alta | E2E Chart Studio |

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
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-data-studio-e2e.R")'
```

**Baseline attesa:** 1640 pass, 0 fail, 10 skip; `R CMD check` OK.

---

## 11. Note di contesto

- Il package installato in `~/R/.../RcmdrShiny` è stato aggiornato a 1.15.0
  durante i test E2E; se si modifica il codice e si eseguono gli E2E, serve
  `R CMD INSTALL .` prima.
- `dataset_registry()` riconcilia il registro con `list_data_sets(state)` a
  ogni chiamata: non va memorizzato il risultato.
- `active_dataset()` registra automaticamente il dataset; `update_dataset()`
  resta per compatibilità ma le modifiche cella passano ora da
  `cmd_edit_cells()` e `run_command()`.
- La selezione righe usa `grid_selection_callback()` e l'input
  `data_grid_selection`; `.row_id` è l'ultima colonna della griglia ed è
  nascosta.
- Il filtro di colonna è in `data_view_frame()`: usa
  `data_filter_value_d()` (debounce 300 ms).
- I dialoghi Data Studio sono in `data_studio_dialogs()` e registrati in
  `base_dialog_catalog()`.
- I pulsanti azione del Data Studio sono statici in `data_studio_ui()`; non
  spostarli dentro `output$data_inspector`.
- `close_modal()` è stato rimosso: le operazioni usano il runtime dialoghi.
- La modalità Classica conserva `classic_data_pane_ui()` e
  `output$data_pane` con `data_editor`.
- Il warning `shinytest2` sui globals di `renderPlot` è cosmetico.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “diario pronto, puoi compattare il contesto”.
