# Diario di handoff — Onda 0 — Studio foundations

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** nessuna (baseline 1.13.0)  
**Ondata successiva:** Onda 1 — Data Studio  
**Documento di settore:** [`../01-data-studio.md`](../01-data-studio.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo:** introdurre l'identità RcmdrShiny Studio e le fondazioni
trasversali (shell, design system, palette, cronologia, anteprima comando,
preview isolate, accessibilità, feature flag) senza cambiare la semantica dei
comandi esistenti.

**Risultato effettivo:** l'app parte in modalità **Studio** con Home, Data,
Charts, Report, Script, Console, Environment e Help; la modalità **Classica**
mantiene le tab 1.13. Sono operativi command palette, cronologia strutturata,
anteprima del comando nei dialoghi, preset, “To script”, preview isolate, temi
chiaro/scuro/alto contrasto e una console minima.

**Cosa è pronto:** tutte le task S0.1–S0.9, con le eccezioni annotate in §6.

**Cosa non è pronto:** Data Studio, Chart Studio e Report Studio (Onde 1–3);
favorites/recenti evoluti della palette e validazione field-level (Onda 5);
progetto `.rcmdrproj` (Onda 7); cambio lingua live (Onda 6).

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `5ce0293` | feat: Wave 0 Studio foundations | Commit principale dell'Onda 0 |
| `8fa760b` | docs: define wave handoff protocol and diary template | Regola di handoff |
| `7578795` | docs: add sector-by-sector upgrade plan | Piano iniziale |
| `0992823` | chore: import RcmdrShiny functional clone as baseline | Baseline |

---

## 3. File creati e modificati

### Creati

- `R/features.R` — feature flag, modalità Studio/Classica, tema.
- `R/history.R` — record, aggiunta, ricerca, rerun, dialog, insert.
- `R/history-ui.R` — card e filtri della cronologia.
- `R/preview.R` — preview isolate e clone dello stato per dry-run.
- `R/command-palette.R` — indice e ricerca fuzzy, modale, risultati.
- `R/console.R` — console minima e guardia sui comandi interattivi.
- `R/ui-components.R` — componenti condivisi e token di markup.
- `inst/help-topics/topics/about.md` — topic “About RcmdrShiny Studio”.
- `tests/testthat/test-wave0.R` — unit/integration test dell'Onda 0.
- `tests/testthat/test-wave0-e2e.R` — flusso browser Studio.

### Modificati

- `R/app.R` — shell Studio/Classica, CSS token, JS, Home, Console workspace,
  palette, cronologia, status bar, temi, scorciatoie, dialog preview wiring.
- `R/state.R` — `history`, `history_counter`, `dialog_presets`,
  `execution_source`, opzioni `ui_mode`, `theme`, `history_length`, `features`.
- `R/commands.R` — `run_command()` alimenta la cronologia senza cambiare
  `state$log`; nuovi argomenti `source`, `dialog_id`, `dialog_memory`,
  `history`.
- `R/dialogs.R` — nuovi campi `dialog_spec()`, preview panel, preset bar,
  “To script”, About aggiornato.
- `R/dialogs-tools.R` — Options con modalità interfaccia e tema; preview
  disabilitata.
- `R/document-dialogs.R` — preview disabilitata sui dialoghi con side effect.
- `R/plugins.R` — preview disabilitata sul caricamento plugin.
- `DESCRIPTION` — versione 1.14.0, nuovo titolo e descrizione.
- `README.md`, `NEWS.md` — identità e funzioni Onda 0.
- `man/run_command.Rd` — nuovi argomenti documentati.
- `inst/help-topics/index.yml`, `getting-started.md`,
  `keyboard-shortcuts.md` — Studio e nuove scorciatoie.
- `inst/etc/help-inventory.csv` — rigenerato con `--plugins all`.
- `docs/upgrades/00-foundations.md`, `CHECKLIST.md` — stato Onda 0.
- Test E2E esistenti — switch tab espliciti per Studio e label `Charts`.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **1403 pass, 0 fail, 9 skip** |
| E2E core | `NOT_CRAN=true RCMDRSHINY_E2E=1 ... test-shinytest2.R` | **15 pass** |
| E2E documenti | `... test-documents-e2e.R` | **8 pass** |
| E2E plugin | `... test-plugins-e2e.R` | **19 pass** |
| E2E Wave 0 | `... test-wave0-e2e.R` | **3 pass** |
| `R CMD check` | `_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual` | **Status: OK** |
| Help inventory | `Rscript tools/inventory_help.R --plugins all` | 629 documented, 55 extra |
| Link checker | `Rscript tools/check_help_links.R --strict` | 444 topic, nessun link rotto |

Gli skip sono i test E2E/visual opt-in e non indicano fallimenti.

---

## 5. Decisioni e ADR

- Nessun nuovo ADR: l'Onda 0 implementa ADR-002, ADR-003, ADR-004, ADR-007,
  ADR-008 e ADR-009.
- **Nessuna nuova dipendenza** è stata aggiunta in questa ondata. La shortlist
  (`commonmark`, `yaml`, `bsicons`, `shinyjs`, `sortable`, `later`) resta una
  decisione della prossima ondata, da rivalutare quando servirà davvero.
- La console minima è stata anticipata dall'Onda 4 per rendere la tab Console
  significativa; l'Onda 4 completerà storico, output cards e limiti.
- `main_tabs_ui` non deve dipendere da `tick()`, altrimenti l'intera UI
  (incluso l'editor Ace) viene ricreata a ogni comando. Usa
  `main_tabs_mode()`.
- La cronologia ha un proprio `history_revision` per invalidare le card dentro
  tab annidate e nascoste.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| S0.6 | Validazione inline field-level | Messaggio d'errore nel pannello anteprima + toast; `dialog_validation_ui` predisposto | I 118 `on_ok` restituiscono oggi un errore unico; la mappatura campo→errore richiede una revisione in Onda 5 |
| S0.4 | Palette con preferiti/recenti | Palette con recenti nella cronologia e indice; preferiti rinviati | I preferiti sono parte dell'Onda 5 |
| S0.2 | Nuove dipendenze UI | Nessuna dipendenza aggiunta; componenti e JS nativi | Ridurre il rischio in una ondata fondativa |
| Onda 4 | Console completa | Console minima con input, output cards e guardia interattivi | Dare senso alla tab Console subito |
| Onda 1 | Data Studio | Tab Data invariata | Fuori perimetro Onda 0 |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| La preset bar è inline e presente in ogni dialogo | UI un po' densa | Verrà compattata in Onda 5 | N5.7 |
| `on_ok` con side effect esterni non è adatto alla preview | Falso comando o effetti | `preview = FALSE` su Options, loadPlugins e dialoghi documento; clone dello stato per gli altri | S0.6 |
| Output in tab annidate nascoste può non aggiornarsi | Card cronologia vuote finché non si forza il refresh | `history_revision` + observer su `console_tabs` | S0.5 |
| Il select tema non riflette il valore salvato in `localStorage` | Solo estetica del controllo | Il tema viene applicato dal JS; il select mostra “System” | S0.8 |
| Cambio lingua ancora a restart | UX i18n | Documentato; Onda 6 | H6.18 |
| `outputOptions(suspendWhenHidden = FALSE)` va chiamato dopo la creazione dell'output | Errore di avvio se spostato | Le chiamate sono dopo le definizioni di history/console/home | S0.3 |

---

## 8. Domande aperte

- [ ] I preset dei dialoghi devono essere persistiti nel progetto `.rcmdrproj`
  (Onda 7) o restare di sessione?
- [ ] La cronologia deve avere un cap configurabile in Options oltre a
  `history_length = 200`?
- [ ] La preview del comando deve restare aperta di default in tutti i dialoghi
  o solo nei dialoghi principali?
- [ ] Il motore di ricerca della palette deve passare a un indice precalcolato
  quando il catalogo help crescerà?

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../01-data-studio.md` e `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: 1403 pass, 0 fail).
3. Avviare l'Onda 1 dal task **D1.1 — Registro dataset**.

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| D1.1 | Registro dataset | Alta | `state$datasets`, `dataset_registry()` |
| D1.2 | Griglia, ricerca, filtri, selezione | Alta | Estrarre `data_pane_ui` |
| D1.3 | Inspector di colonna | Alta | `column_profile()` pura |
| D1.4 | Operazioni su colonne | Alta | Nuovi command builder |
| D1.5 | Operazioni su righe | Alta | Nuovi command builder |
| D1.6 | Undo e checkpoint | Media | `state$checkpoints` |
| D1.7 | Data dictionary | Media | Attributi label/units |
| D1.8 | Import wizard | Media | Anteprima e tipi |
| D1.9 | Fallback big data | Media | Modalità targeted |
| D1.10 | Selezione → analisi | Media | Subset/filtro |
| D1.11 | Test, help, vignetta | Alta | E2E Data Studio |

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
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-wave0-e2e.R")'
```

**Baseline attesa:** 1403 pass, 0 fail, 9 skip; `R CMD check` OK.

---

## 11. Note di contesto

- `main_tabs_ui` viene renderizzato da `uiOutput("main_tabs_ui")`; deve
  dipendere solo da `main_tabs_mode()`, non da `tick()`.
- `history_revision` è il segnale dedicato per le card della cronologia.
- I click dentro i modali non arrivano al listener `document` in bubbling:
  usare `onclick` inline (`rcmdrPaletteClick`, `rcmdrHistoryClick`,
  `rcmdrCopy`) o capture phase.
- Le scelte `selectInput` seguono la convenzione nomi = label, valori = codici.
  `history_source_labels()` è stato corretto dopo un bug “All sources”.
- `preview_state_clone()` è un clone shallow: isola assegnazioni e callback,
  ma non gli effetti esterni. Per i dialoghi con I/O usare `preview = FALSE`.
- La modalità Classica non mostra la History tab: la cronologia resta
  accessibile via palette e, in futuro, dalla Console unificata.
- Il package installato in `~/R/.../RcmdrShiny` è stato aggiornato a 1.14.0
  durante i test E2E; se si modifica il codice e si eseguono gli E2E, serve
  `R CMD INSTALL .` prima.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “diario pronto, puoi compattare il contesto”.
