# Diario di handoff — Onda 4 — Workbench

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** Onda 3 — Report Studio  
**Ondata successiva:** Onda 5 — Navigazione, dialoghi, workflow  
**Documento di settore:** [`../04-workbench.md`](../04-workbench.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo:** colmare il divario tra GUI a dialoghi e workbench statistico con
Script multi-documento, console R, output strutturato, environment esplorabile
e dashboard dei modelli, senza aggiungere procedure statistiche.

**Risultato effettivo:** Studio offre ora tre livelli di lavoro sullo stesso
motore:

- **dialoghi** (invariati);
- **console** con input diretto, recall, storico e guardia interattiva;
- **script** con tab, celle eseguibili, outline, diagnostica, find/replace,
  formattazione e autosave.

Tutti condividono `run_command()`, `state$log`, `state$history`,
`state$output`, `state$messages`, `state$env` e la galleria plot.

**Cosa è pronto:** W4.1–W4.21, con le deviazioni annotate in §6.

**Cosa non è pronto:** Onda 5 (navigazione, dialoghi, workflow), cancellazione
reale dei comandi, debugger R, esecuzione in background.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `165a70c` | feat: Wave 4 Workbench | Commit principale dell'Onda 4 |
| `22ce9e2` | fix: allow multi-line console input with Shift+Enter | Correzione finale della console |
| `8f1458c` | docs: add Wave 3 Report Studio handoff diary | Ultimo commit Onda 3 |

Il diario viene committato subito dopo il commit principale.

---

## 3. File creati e modificati

### Creati

- `R/script-studio.R` — registro script, celle, run above/below, outline,
  diagnostica, formattazione, completamenti, UI e server.
- `R/console-studio.R` — storico console, recall, esecuzione, filtri, UI.
- `R/environment-studio.R` — object explorer, anteprima, azioni, viste
  dataset, dialogo `environmentSave`.
- `R/models-studio.R` — registry modelli, dashboard, azioni, dialogo
  `modelExport`.
- `inst/help-topics/topics/workbench.md` — topic Workbench.
- `vignettes/workbench.Rmd` — celle, console, output, environment e modelli.
- `tests/testthat/helper-workbench.R`
- `tests/testthat/test-script-registry.R`
- `tests/testthat/test-script-cells.R`
- `tests/testthat/test-console.R`
- `tests/testthat/test-output-cards.R`
- `tests/testthat/test-environment.R`
- `tests/testthat/test-model-registry.R`
- `tests/testthat/test-models-dashboard.R`
- `tests/testthat/test-workbench-ui.R`
- `tests/testthat/test-workbench-e2e.R`

### Modificati

- `R/state.R` — `history_pinned`, `console_index`, `console_last`,
  `message_entries`, `message_counter`, `execution_id`, `script_outputs`,
  `model_selection`, `environment_selection`, `environment_preview`; opzioni
  `console_history_length`, `script_cells`, `script_format`.
- `R/features.R` — flag `script_studio`, `environment_studio`,
  `models_studio`.
- `R/commands.R` — l'id di cronologia è allocato prima dell'esecuzione e
  `eval_code()` registra i messaggi strutturati con severità.
- `R/history.R` — `message_add()`, `messages_as_data_frame()`,
  `messages_filter()`, `messages_clear()`, pin della cronologia.
- `R/history-ui.R` — filtri per stato, card con pin, tab Output e Messages
  Studio, sorgenti `report`, `environment`, `model`.
- `R/app.R` — Script Studio, Console Studio, Output/Messages Studio,
  Environment workspace, observer environment/models, JS per cursore,
  find/replace, completamenti e frecce della console, CSS.
- `R/dialogs.R` — registrati `environmentSave` e `modelExport`.
- `R/script-studio.R` — `document_new` in modalità R crea uno script.
- `R/console.R` — resta la guardia `console_is_interactive()`.
- `DESCRIPTION` — versione 1.18.0, descrizione e `styler` nei Suggests.
- `README.md`, `NEWS.md` — stato e funzioni Wave 4.
- `_pkgdown.yml` — vignetta `workbench`.
- `inst/help-topics/index.yml` — categoria e topic `workbench`.
- `tests/testthat/test-wave0.R` — sorgenti di cronologia aggiornate.
- `docs/upgrades/04-workbench.md`, `CHECKLIST.md`, `README.md`.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **2569 pass, 0 fail, 13 skip** |
| E2E core | `test-shinytest2.R` | **15 pass** |
| E2E Wave 0 | `test-wave0-e2e.R` | **3 pass** |
| E2E documenti | `test-documents-e2e.R` | **8 pass** |
| E2E Data Studio | `test-data-studio-e2e.R` | **6 pass** |
| E2E Chart Studio | `test-chart-studio-e2e.R` | **7 pass** |
| E2E Report Studio | `test-report-studio-e2e.R` | **5 pass** |
| E2E Workbench | `test-workbench-e2e.R` | **10 pass** |
| E2E plugin | `test-plugins-e2e.R` | **19 pass** |
| `R CMD check` | `_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual` | **Status: OK** |
| Help inventory | `Rscript tools/inventory_help.R --plugins all` | 644 documented, 55 extra, 0 fallback |
| Link checker | `Rscript tools/check_help_links.R --strict` | 448 topic, nessun link rotto |

Gli skip sono i test E2E/visual opt-in. Resta il warning cosmetico di
`shinytest2` “Failed to locate globals in server function” per `renderPlot`.

---

## 5. Decisioni e ADR

- **Un solo registro documenti.** Non è stato introdotto `state$scripts`: i tab
  dello Script sono `state$documents`, gli stessi del Report Studio. Il buffer
  attivo resta `state$document`, quindi ogni chiamante storico continua a
  funzionare.
- **Celle dal parse R.** In modalità R le celle seguono le espressioni di
  primo livello trovate da `parse(keep.source = TRUE)`. Un fallback a blocchi
  separati da righe vuote mantiene l'editor usabile quando il testo non parsa.
- **Output celle separato.** `state$script_outputs` è distinto da
  `state$cell_outputs` del Report Studio. Le chiavi sono posizionali, quindi
  vengono azzerate quando il testo cambia.
- **Esecuzione senza log.** `script_execute()` usa `run_command(log = FALSE)`
  per non duplicare il codice tramite auto-append; la storia strutturata
  registra comunque la sorgente `script`.
- **Console con guardia, non cancellazione.** R è single-thread: i comandi
  interattivi vengono rilevati e rifiutati prima dell'esecuzione. Non si
  promette un'interruzione reale.
- **Output cards = history cards.** Le card dell'Output sono le stesse della
  cronologia, con pin, rerun, dialogo, script e report. Il testo grezzo resta
  disponibile per compatibilità.
- **Messaggi strutturati accanto al testo.** `state$messages` resta il buffer
  storico; `state$message_entries` aggiunge severità, comando e history id.
- **Environment read-only in anteprima.** `object_preview()` usa `str()` e
  `summary()` fuori dal motore; le azioni che stampano o modificano passano da
  `run_command()`.
- **Models dashboard senza nuove procedure.** Il registry legge solo metadati;
  le azioni richiamano i comandi esistenti (`summary`, `Anova`, `AIC`,
  `BIC`, `vif`, `outlierTest`, `stepwise`, `plot`).
- **Reopen con memoria.** Si cerca la voce di cronologia che ha creato il
  modello con `dialog_id`/`dialog_memory`; in assenza si apre il dialogo della
  classe con `model`/`model_name` precompilati.
- **Formattazione opzionale.** `styler` è un Suggests; senza il pacchetto il
  pulsante spiega perché non formatta.
- **Autosave condiviso.** Lo Script usa lo stesso `document_autosave()` e la
  stessa directory del Report; il timer dello Script salva solo quando il tab
  è visibile, quello del Report resta attivo.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| W4.1 | `state$scripts` separato | Registro documenti condiviso | Evita due buffer divergenti tra Script e Report |
| W4.2 | Celle per sezione | Celle da `parse()` + fallback | Più preciso per chiamate multi-riga |
| W4.4 | Folding/multi-cursor espliciti | Ace li offre; aggiunti find/replace e completamenti | Meno JS custom, stesse capacità |
| W4.5 | Autosave separato | Stesso autosave del Report | Un solo servizio, come da rischio §10 |
| W4.8 | Output card nuove | Riuso delle history card con pin | Una sola rappresentazione della cronologia |
| W4.9 | Cancellazione reale | Solo rilevamento e blocco | R è single-thread; niente finte cancellazioni |
| W4.13 | Azioni View/Summary/Plot/str/Save/Remove | Tutte presenti; Save usa un dialogo | Salvataggio riproducibile con comando |
| W4.14 | Anteprima nel pannello | `str`/`summary` read-only | Nessun comando, nessun log |
| W4.17 | Registry con molte classi | Classi del menu + wrapper misti | Coerenza con l'attivazione dei menu |
| W4.19 | Confronto AIC/BIC | Delta AIC rispetto al migliore | Tabella leggibile, nessun test nuovo |
| W4.21 | Reopen sempre possibile | Memoria o fallback per classe | Non tutti i modelli nascono da un dialogo |
| — | E2E con click diretto | `Shiny.setInputValue` inline per le azioni | Evita problemi Bootstrap 5/Shiny con pulsanti dinamici |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| Warning `shinytest2` sui globals di `renderPlot` | Rumore nei log E2E | Ignorabile; i test passano | W4.19 |
| `Run cell` senza riga valida esegue tutte le celle | Comportamento di fallback | Tenere il cursore nell'editor | W4.2 |
| Le celle non parsabili usano i blocchi vuoti | Meno precise | Correggere il parse | W4.2 |
| L'output inline sparisce a ogni modifica | Voluto: gli id sono posizionali | Rieseguire la cella | W4.2 |
| La console non può cancellare un comando | R è single-thread | La guardia blocca i prompt | W4.9 |
| `styler` non installato | Format disabilitato con messaggio | Installare `styler` | W4.5 |
| Reopen di modelli non fittati da dialogo | Apre il dialogo della classe | Compilare i campi | W4.21 |
| `Anova`/`vif` richiedono `car` | Errore come card se manca | Installare `car` | W4.20 |
| Il registry modelli ignora classi non elencate | Modello assente dalla dashboard | Aggiungere la classe o usare il comando | W4.17 |
| L'autosave non sopravvive a un riavvio di R | Recovery nella stessa sessione | Salvare su file | W4.5 |

---

## 8. Domande aperte

- [ ] Serve un vero job in background per i comandi lunghi in Onda 7?
- [ ] Il registry script deve poter salvare un layout di tab per progetto?
- [ ] `Run cell` deve seguire il cursore anche quando l'editor non ha il focus?
- [ ] Le output card devono sostituire del tutto il testo grezzo?
- [ ] Il dashboard modelli deve poter esportare una tabella di confronto?
- [ ] L'autosave deve usare la directory del progetto quando esisterà?
- [ ] La console deve supportare comandi multi-riga con `Shift+Enter` e un
      pulsante "Run" separato?

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../05-navigation-dialogs-workflows.md` e
   `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: **2569 pass, 0 fail, 13 skip**).
3. Avviare l'Onda 5 dal task **N5.1 — Palette evoluta**.

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| N5.1 | Palette evoluta | Alta | `R/command-palette.R` |
| N5.2 | Preferiti/recenti | Alta | Stato sessione |
| N5.3 | Menu search | Media | Già presente, estendere |
| N5.4 | Breadcrumb | Bassa | Shell |
| N5.5 | Scorciatoie complete | Media | JS |
| N5.6 | Preview completa | Media | Dialoghi |
| N5.7 | Preset UI e persistenza | Media | `dialog_presets` |
| N5.8 | Validazione inline | Alta | `dialog_spec$validate` |
| N5.9 | Selector arricchiti | Media | UI |
| N5.10 | Responsive e accessibilità dialogo | Media | Bootstrap/A11y |
| N5.11 | Workflow model e registry | Alta | Nuovo modulo |
| N5.12 | Workflow UI | Alta | UI |
| N5.13 | Integrazione dialoghi/cronologia | Media | History |
| N5.14 | Cinque workflow iniziali | Alta | Nessuna nuova statistica |
| N5.15 | Generazione sezione report | Media | Report Studio |
| N5.16 | Suggerimenti per variabile | Media | Data Studio |
| N5.17 | UI inspector/menu | Media | Shell |

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
R CMD INSTALL .
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-workbench-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
```

**Baseline attesa:** 2569 pass, 0 fail, 13 skip; `R CMD check` OK.

---

## 11. Note di contesto

- Il package installato va aggiornato con `R CMD INSTALL .` dopo modifiche al
  codice, prima degli E2E: `RcmdrShiny::app()` usa il namespace installato.
- `script_registry()` restituisce `id`, `title`, `path`, `mode`, `dirty`,
  `active`, `label`; è lo stesso registro di `document_list()`.
- `script_cells(text, mode)` restituisce `id`, `label`, `start`, `end`, `code`;
  in R gli id sono `cell-NN`, in Rmd/Rnw sono gli id dei chunk.
- `script_cell_at(cells, row)` usa righe 0-based come Ace.
- `script_run_cell()` e `script_run_cells()` salvano in `state$script_outputs`.
- `console_execute()` restituisce `status = "blocked"` per i comandi
  interattivi e `state$console_last` per lo stato dell'ultimo comando.
- `console_history_recall(state, -1)` va indietro, `1` avanti.
- `history_pinned_ids()` e `history_toggle_pin()` gestiscono i pin.
- `message_add()` alimenta `state$message_entries`; `state$messages` resta il
  testo storico.
- `object_list()`, `object_preview()`, `object_action()` gestiscono
  l'Environment; `model_registry()`, `model_action()`,
  `model_reopen_dialog()` gestiscono i modelli.
- `model_classes` è un vettore in `R/activation.R`: non ridefinirlo come
  funzione. Il registry usa `model_registry_classes()`.
- In modalità Classica restano `script_pane_ui()`, `output_pane_ui()`,
  `messages_pane_ui()` e `uiOutput("environment_pane")`.
- `script_studio_server()` registra gli output `script_*` e gli input
  `script_*`, `run_cell_request`, `run_above_request`, `run_below_request`.
- `console_studio_ui()` mantiene gli id `console_input`, `console_run`,
  `console_log` usati dai test esistenti.
- L'E2E Workbench usa `Shiny.setInputValue` per le azioni e limita i selettori
  Ace a `#script_editor_ui`.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “diario pronto, puoi compattare il contesto”.
