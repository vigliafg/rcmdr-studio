# Diario di handoff — Onda 5 — Navigazione, dialoghi e workflow

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** `wave-04-workbench.md`  
**Ondata successiva:** Onda 6 — Help, i18n, onboarding  
**Documento di settore:** [`../05-navigation-dialogs-workflows.md`](../05-navigation-dialogs-workflows.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo:** rendere il catalogo di 863 voci utilizzabile senza conoscerlo a
memoria, completando palette, preferiti, ricerca menu, breadcrumb, scorciatoie,
dialog platform 2.0, workflow guidati e suggerimenti sulle variabili, senza
aggiungere procedure statistiche.

**Risultato effettivo:** la navigazione è ora un livello completo sopra il
catalogo:

- **Palette**: ricerca fuzzy su menu, dialoghi, help, dataset, variabili,
  cronologia e workflow; filtro per tipo; preferiti; recenti; motivi di
  disabilitazione; azioni per riga; indice in cache.
- **Preferiti e recenti**: stella su ogni voce del menu, sezioni in cima alla
  sidebar, persistenza in `preferences.rds`.
- **Menu search**: filtro live su label, path e comando, evidenziazione,
  espandi/comprimi tutto, stato di espansione persistito.
- **Breadcrumb**: i dialoghi e la palette mostrano il percorso nel menu.
- **Scorciatoie**: `Ctrl+K`, `Ctrl+Shift+P`, `Ctrl+/`, `F1`, `Alt+1..9`,
  `Ctrl+Enter`, `Ctrl+Shift+Enter`, `Ctrl+S`, `Ctrl+Shift+S`, modal elenco.
- **Dialog platform 2.0**: preview completa, preset nominati con export/import,
  validazione inline con focus e `aria-invalid`, selector con tipo/missing/unique,
  layout modale responsive.
- **Workflow guidati**: cinque workflow, stato per passo, apri/salta/indietro/
  annulla, comandi registrati e bozza di sezione report.
- **Suggerimenti variabile**: pulsanti contestuali nell'inspector del Data
  Studio, basati su tipo e disponibilità, che aprono i dialoghi esistenti con
  memoria.

**Cosa è pronto:** N5.1–N5.17.

**Cosa non è pronto:** Onda 6 (help full-text, “Try it”, glossario, tour,
italiano completo), Onda 7 (progetto, bundle, plugin SDK v2, QA).

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `53d3a39` | feat: Wave 5 navigation, dialogs and guided workflows | Commit principale dell'Onda 5 |
| `316d07d` | docs: record the console input fix in the Wave 4 diary | Ultimo commit Onda 4 |

Il diario viene committato subito dopo il commit principale.

---

## 3. File creati e modificati

### Creati

- `R/preferences.R` — preferenze di sessione (preferiti, recenti, espansione,
  preset, lingua, tema), file RDS, override `RcmdrShiny.preferences` e
  `RCMDRSHINY_PREFERENCES`.
- `R/dialog-presets.R` — preset nominati, export/import versionato.
- `R/dialog-validation.R` — normalizzazione `field_errors`, riepilogo e payload
  browser.
- `R/shortcuts.R` — tabella e modal delle scorciatoie.
- `R/workflows.R` — modello, registry, stato, UI, azioni e sezione report.
- `R/suggestions.R` — metadati variabile, suggerimenti e memoria dialoghi.
- `inst/help-topics/topics/navigation-workflows.md` — topic dedicato.
- `vignettes/navigation-workflows.Rmd` — vignetta dedicata.
- `tests/testthat/test-command-palette-advanced.R`
- `tests/testthat/test-menu-search.R`
- `tests/testthat/test-dialog-presets.R`
- `tests/testthat/test-dialog-validation.R`
- `tests/testthat/test-workflows.R`
- `tests/testthat/test-variable-suggestions.R`
- `tests/testthat/test-shortcuts.R`
- `tests/testthat/test-enhanced-selectors.R`
- `tests/testthat/test-navigation-e2e.R`

### Modificati

- `R/state.R` — `dialog_errors`, preferiti/recenti/espansione, workflow,
  cache palette, opzioni `menu_recent_length`, `persist_preferences`,
  `preferences_file`, `workflow_step_limit`.
- `R/features.R` — flag `dialog_validation`, `menu_search`, `workflows`,
  `suggestions`.
- `R/command-palette.R` — tipi `dialog`/`workflow`, filtri, cache, azioni,
  preferiti/recenti, stato disabilitato.
- `R/menus.R` — `menu_command_path`, preferiti, recenti, espansione,
  evidenziazione, sezioni sidebar, stelle.
- `R/dialogs.R` — `dialog_ids()`, breadcrumb nel modal.
- `R/plugins.R` — invalidazione della cache `dialog_ids` al cambio plugin.
- `R/widgets.R` — `descriptions` in `var_input()`, `groups_input()`,
  `model_formula_input()`.
- `R/dialogs-summaries.R`, `R/dialogs-graphs.R`, `R/dialogs-models.R` —
  selector descrittivi nei dialoghi principali.
- `R/app.R` — integrazione palette, menu, preferiti, preset, validazione,
  workflow, suggerimenti, scorciatoie, CSS e JS.
- `tests/testthat/test-wave0-e2e.R` — la voce “Numerical summaries” è ora di
  tipo `dialog`, non `menu`.
- `DESCRIPTION`, `NEWS.md`, `README.md` — versione 1.19.0 e stato Wave 5.
- `_pkgdown.yml`, `inst/help-topics/index.yml`,
  `inst/help-topics/topics/keyboard-shortcuts.md` — topic, vignetta e
  scorciatoie.
- `man/widgets.Rd` — documentazione del nuovo argomento `descriptions`.
- `docs/upgrades/05-navigation-dialogs-workflows.md`, `CHECKLIST.md`.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **2747 pass, 0 fail, 14 skip** |
| E2E core | `test-shinytest2.R` | **15 pass** |
| E2E Wave 0 | `test-wave0-e2e.R` | **3 pass** |
| E2E documenti | `test-documents-e2e.R` | **8 pass** |
| E2E Data Studio | `test-data-studio-e2e.R` | **6 pass** |
| E2E Chart Studio | `test-chart-studio-e2e.R` | **7 pass** |
| E2E Report Studio | `test-report-studio-e2e.R` | **5 pass** |
| E2E Workbench | `test-workbench-e2e.R` | **10 pass** |
| E2E Navigation/Workflows | `test-navigation-e2e.R` | **4 pass** |
| E2E plugin | `test-plugins-e2e.R` | **19 pass** |
| `R CMD check` | `R CMD build .` + `_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_1.19.0.tar.gz` | **Status: OK** |
| Help inventory | `Rscript tools/inventory_help.R --plugins all` | 644 documented, 55 extra, 0 fallback |
| Link checker | `Rscript tools/check_help_links.R --strict` | 449 topic, nessun link rotto |

Gli skip sono i test E2E/visual opt-in. Resta il warning cosmetico di
`shinytest2` “Failed to locate globals in server function” per `renderPlot`.

---

## 5. Decisioni e ADR

- **La palette è un indice, non un motore.** Ogni riga conserva il comando
  originale; aprire un dialogo non esegue nulla; eseguire un comando passa da
  `launch()` e quindi da `run_command()`.
- **Preferenze fuori dallo stato statistico.** Preferiti, recenti, espansione,
  preset, lingua e tema stanno in un RDS separato. Il file è piccolo e
  indipendente dal progetto (Onda 7 potrà spostarlo nel progetto).
- **`dialog_ids()` è cache per revisione plugin.** Evita di ricostruire il
  catalogo a ogni ricerca e si invalida in `RcmdrPlugin`/`unload_plugins()`.
- **La cache della palette usa `state$revision` + versione plugin.** Un comando
  eseguito o un plugin caricato ricostruisce l'indice; digitare no.
- **Preferiti e recenti sono gli stessi dati di menu e palette.** Una sola
  funzione (`menu_favorite_*`, `menu_recent_*`) alimenta sidebar e palette.
- **La ricerca menu evidenzia con `\Q...\E`.** Evita di trattare caratteri
  speciali come regex e mantiene case-insensitive.
- **Le sezioni Preferiti/Recenti usano link semplici, non `actionLink()`.** Gli
  id duplicati dei `actionLink` con l'albero venivano rilevati da Shiny; il link
  invia `menu_command` e il server chiama `launch()`.
- **Validazione: `field_errors` è il contratto nuovo, `error` resta.** I dialoghi
  vecchi continuano a mostrare un toast; quelli nuovi mantengono il modal
  aperto, mostrano il riepilogo e marcano i campi.
- **Workflow = orchestrazione.** Nessuna validazione propria, nessun comando
  nuovo. I comandi dei passi sono esattamente quelli prodotti dai dialoghi o dal
  comando diretto.
- **I passi diretti registrano il log.** `workflow_run_command()` cattura le
  righe aggiunte a `state$log`, così la sezione report non perde i comandi.
- **La sezione report è una bozza modificabile.** Un chunk per passo completato;
  nessun test o modello nuovo.
- **Suggerimenti a regole semplici.** Tipo, missing, livelli e dataset attivo;
  nessuna inferenza e nessuna raccomandazione di modello.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| N5.1 | Palette con più azioni | Azioni per riga: esegui/apri/attiva/suggerisci/rerun/insert/copia/start | Stessa palette, nessun motore parallelo |
| N5.2 | Preferiti in `R/menus.R` e `R/state.R` | Aggiunto `R/preferences.R` per la persistenza | Un solo servizio per tutte le preferenze |
| N5.5 | Scorciatoie JS | `Alt+1..9` e modal, non `Alt+1..8` | La tab Workflows è la nona tab Studio |
| N5.7 | Export/Import preset | Export via `downloadButton` nel modal, import via `fileInput` | Nessun nuovo servizio di download |
| N5.9 | Drag & drop multi-selezione | Selectize con ricerca e descrizioni | Meno JS custom, stessa usabilità |
| N5.10 | Responsive e accessibilità | CSS modale, breadcrumb, `aria-invalid`, focus | Audit completo in Onda 7 |
| N5.13 | Integrazione cronologia | `history_ids` dei comandi del passo | Tracciabilità senza duplicare la cronologia |
| N5.14 | Workflow “Sopravvivenza” | Passi bloccati con motivo se il plugin manca | Nessun comando parziale |
| N5.15 | Sezione report | Testo + chunk con i comandi registrati | Bozza modificabile |
| — | — | Corretto `var_input(descriptions)` | I value erano le descrizioni, non i nomi: bug intercettato dall'E2E |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| Warning `shinytest2` sui globals di `renderPlot` | Rumore nei log E2E | Ignorabile; i test passano | N5.1 |
| Preferenze non sopravvivono a un riavvio se la directory non è scrivibile | Nessun errore, si riparte vuoti | Usare `RCMDRSHINY_PREFERENCES` | N5.2 |
| I preset non sono validati contro la versione futura del dialogo | Possibili campi ignorati | Versione preset rifiutata se diversa | N5.7 |
| Un workflow senza dataset mostra passi dialogo disponibili ma vuoti | Errore del dialogo | I passi diretto sono bloccati con motivo | N5.11 |
| Suggerimenti non coprono classi esotiche | Nessun pulsante | Usare il menu | N5.16 |
| Il report del workflow non include output, solo comandi | Bozza da completare | Eseguire il chunk nel Report Studio | N5.15 |
| `dialog_preset_select` non usa selectize | Nessuna ricerca nei preset | I preset sono pochi | N5.7 |
| `Ctrl+/` dipende dal layout della tastiera | Scorciatoia non sempre disponibile | Usare il pulsante nella Home/Help | N5.5 |

---

## 8. Domande aperte

- [ ] I preferiti devono diventare parte del progetto in Onda 7?
- [ ] La palette deve indicizzare anche gli output e i modelli attivi?
- [ ] I workflow devono poter essere definiti dai plugin?
- [ ] La sezione report deve includere anche gli output catturati?
- [ ] I preset devono essere validati campo per campo contro lo spec del
      dialogo?
- [ ] I suggerimenti devono usare anche i modelli già fittati?
- [ ] La tab Workflows deve stare in Classic o restare solo Studio?
- [ ] `Alt+1..9` deve essere personalizzabile?

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../06-help-i18n-onboarding.md` e
   `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: **2747 pass, 0 fail, 14 skip**).
3. Avviare l'Onda 6 dal task **H6.1 — Indice full-text**.

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| H6.1 | Indice full-text | Alta | Help |
| H6.2 | Ranking e filtri | Alta | Help |
| H6.3 | Snippet e correlati | Media | Help |
| H6.4 | Topic TOC e link | Media | Help |
| H6.5 | “Try it” | Alta | Help |
| H6.6 | Parser esempi | Alta | Help |
| H6.7 | UI esempi e conferma | Alta | Help |
| H6.8 | Esecuzione loggata | Alta | Commands |
| H6.9 | Mappa errori | Alta | Help |
| H6.10 | UI errore contestuale | Media | Help |
| H6.11 | Glossario | Media | Help |
| H6.12 | Scorciatoie aggiornate | Bassa | Help |
| H6.13 | Tour engine | Media | Nuovo modulo |
| H6.14 | Tour UI e persistenza | Media | UI |
| H6.15 | Checklist Home | Media | Home |
| H6.16 | Audit stringhe | Alta | i18n |
| H6.17 | Topic italiani | Alta | `inst/help-topics` |
| H6.18 | Lingua reattiva | Alta | i18n |
| H6.19 | Persistenza lingua | Media | `preferences.R` |

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
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-navigation-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
```

**Baseline attesa:** 2747 pass, 0 fail, 14 skip; `R CMD check` OK.

---

## 11. Note di contesto

- `preferences_default_file()` rispetta prima `RCMDRSHINY_PREFERENCES`, poi
  `getOption("RcmdrShiny.preferences")`, poi `XDG_CONFIG_HOME`/`APPDATA`.
- `state$options$persist_preferences` può disattivare la persistenza.
- `palette_index_cached()` è la funzione da usare nel server; `palette_index()`
  resta pura per i test.
- `palette_type_choices()` restituisce i valori `all`, `menu`, `dialog`,
  `help`, `data`, `history`, `workflow`, `favorite`.
- `menu_command_path("numericalSummaries")` restituisce
  `c("Statistics", "Summaries", "Numerical summaries...")`.
- `menu_shortcut_link()` usa un link semplice e invia `menu_command`; non è un
  `actionLink()` per evitare id duplicati con l'albero.
- `dialog_field_errors()` accetta vettori nominati o liste; i nomi senza prefisso
  vengono prefissati con l'id del dialogo in `submit_dialog()`.
- `dialog_validation_ui()` è renderizzato in `dialog_validation_ui` output;
  `rcmdr-field-errors` marca i campi e sposta il focus.
- `workflow_start()`, `workflow_step_open()`, `workflow_mark_step()`,
  `workflow_skip_step()`, `workflow_back()`, `workflow_cancel()`,
  `workflow_progress()`, `workflow_report_section()`,
  `workflow_insert_report()`.
- `workflow_step_open()` restituisce `dialog` + `memory` senza eseguire; il
  server usa `open_dialog_memory()`.
- `workflow_mark_step()` viene chiamata in `submit_dialog()` dopo
  `apply_dialog_result()`, con gli id di cronologia nuovi.
- `variable_suggestions()` restituisce `id`, `title`, `description`, `dialog`,
  `available`; `suggestion_memory()` produce la memoria per il dialogo.
- `var_input(descriptions = ...)` usa la descrizione come **label** e il nome
  della variabile come **value**; non invertire i due.
- La tab `Workflows` è solo Studio; in Classic resta il menu.
- Il test `test-navigation-e2e.R` isola le preferenze con
  `RCMDRSHINY_PREFERENCES = tempfile()`.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “diario pronto, puoi compattare il contesto”.
