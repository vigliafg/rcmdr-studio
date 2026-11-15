# Diario di handoff — Onda 8 — Hardening menu e ciclo di vita plugin

**Data:** 2026-11-15
**Stato:** Fase 1 (2.0.2) e Fase 2 (2.1.0) completate; Fase 3 da valutare
**Baseline:** RcmdrShiny 2.1.0
**Documento di settore:** [`../08-hardening-menus-plugins.md`](../08-hardening-menus-plugins.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa per la prossima sessione

**Stato al momento della compattazione:** branch `main`, HEAD corrente (vedi
`git log -1`), working tree pulito. Onda 8 chiusa: Fasi 1–2 implementate,
Fase 3 decisa con ADR-014 (no-go).

**Baseline verificata:**
`testthat::test_local()` → **3401 pass, 0 fail, 22 skip**;
`R CMD check --no-manual` su `RcmdrShiny_2.1.0.tar.gz` → **Status: OK**.

**Prossimo task:** nessuno. Onda 8 chiusa. Eventuali riaperture sono elencate
nei trigger di ADR-014 e nella sezione 8.

**Da leggere, in quest'ordine:**

1. questo diario (sezioni 0, 5, 7, 8);
2. [`../08-hardening-menus-plugins.md`](../08-hardening-menus-plugins.md),
   sezioni 4 (decisioni), 6 (Fase 2) e 10 (test);
3. [`../audit-menu-plugin.md`](../audit-menu-plugin.md) per le evidenze
   complete dei due audit;
4. [`../CHECKLIST.md`](../CHECKLIST.md), sezione Onda 8;
5. solo se serve: `R/plugins.R`, `R/preferences.R`, `R/health.R`.

**Regola:** non assumere che il contesto precedente sia disponibile. Questo
diario è la fonte di verità.

---

## 1. Obiettivo e risultato

**Obiettivo della fase:** chiudere il debito del menu (stati non rispettati
fuori dal rendering) e rendere robusto il caricamento dei plugin, senza
cambiare ID, formati o motore.

**Risultato effettivo:**

- `command_availability()` è la fonte unica di stato; `command_enabled()` è un
  wrapper deprecato.
- `launch()` e `history_open_dialog()` usano la disponibilità e mostrano
  messaggi distinti per `porting`, `inactive`, `hidden`.
- Preferiti e recenti rispecchiano il menubar: voci non disponibili rese
  disabilitate con motivo, `hidden` omesse, preferenze mai cancellate.
- Le voci disabilitate hanno `aria-disabled`, `tabindex="0"`, motivo
  `visually-hidden` + `title`; il click non chiude più il menu.
- Errori plugin isolati in `plugin_failures()`, visibili in health,
  diagnostics e Home; l'avvio non si blocca.
- Il caricamento a runtime chiede il reload della pagina e chiarisce che
  riavviare R rimuove il plugin.
- Test nuovi su disponibilità, markup, preferiti/recenti, guardie, fallimenti
  plugin e messaggio di reload.

**Cosa non è pronto (Fase 2):** persistenza e selezione dei plugin, conflitti
visibili, benchmark del ciclo plugin.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `6222d6f` | docs: add Wave 8 hardening plan | Piano e checklist Onda 8 |
| `0735a2f` | feat: unify command availability and harden plugins | Fase 1 (2.0.2) |
| `4538bd8` | feat: persist plugin selection and surface conflicts | Fase 2 (2.1.0) |
| _(questo commit)_ | docs: close Wave 8 phase 3 and add browser coverage | Audit, E2E, ADR-014 |

---

## 3. File creati e modificati

### Creati

- `tests/testthat/test-menu-availability.R` — guardie `launch` e cronologia.

### Modificati — codice

- `R/activation.R` — `command_availability()`, indice comandi in cache,
  `command_status_reason()`, `command_status_message()`.
- `R/dialogs.R` — `command_enabled()` delega alla disponibilità.
- `R/app.R` — guardia `launch()`, notifica fallimenti plugin all'avvio, click
  su voce disabilitata non chiude il menu.
- `R/history.R` — riapertura dialogo solo se disponibile.
- `R/menus.R` — `menu_disabled_item()`, sezioni preferiti/recenti con stato.
- `R/plugins.R` — `plugin_failures()`, `plugin_record_failure()`,
  `plugin_clear_failures()`, caricamento per-plugin in `tryCatch`, messaggio
  di reload.
- `R/health.R` — `plugin_failures` e riga "Plugin failures".
- `R/diagnostics.R` — fallimenti nel report testuale.

### Modificati — test e documentazione

- `tests/testthat/test-activation.R`, `test-menus.R`, `test-plugins.R`.
- `DESCRIPTION` (2.1.0), `NEWS.md` (2.1.0).
- `inst/help-topics/topics/writing-plugins.md`, `vignettes/plugins.Rmd`.
- `docs/upgrades/08-hardening-menus-plugins.md`, `CHECKLIST.md`,
  `TEST-MATRIX.md`, `ACCESSIBILITY.md`, `DECISIONS.md` (ADR-011…013).

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Suite completa | `testthat::test_local()` | **3401 pass, 0 fail, 22 skip** |
| Menu e disponibilità | `test_file("tests/testthat/test-menus.R")` | verde |
| Attivazione | `test_file("tests/testthat/test-activation.R")` | verde |
| Guardie | `test_file("tests/testthat/test-menu-availability.R")` | verde |
| Plugin | `test_file("tests/testthat/test-plugins.R")` | verde |
| `R CMD check` | build + check `--no-manual` su 2.1.0 | **Status: OK** |
| E2E browser | `RCMDRSHINY_E2E=1 ...` | **non rieseguiti** (debito dichiarato) |

Warning ambientali noti: `rgl`/X11 (2 warning) e snapshot visual opzionale.

---

## 5. Decisioni e ADR

- **ADR-011** — disponibilità come fonte unica, fallback per comandi senza
  voce, `open_dialog()` non bloccato globalmente.
- **ADR-012** — caricamento plugin isolato; reload pagina per il runtime;
  retry solo esplicito.
- **ADR-013** — registro plugin globale di processo; assunzione single-user;
  registry per-sessione fuori perimetro.

Decisioni minori prese durante l'implementazione:

- I tooltip delle voci disabilitate usano le stesse stringhe della palette
  ("Not ported yet", "Not available for the current data set").
- I preferiti `hidden` sono omessi dalla sezione ma conservati nelle
  preferenze.
- La notifica dei fallimenti plugin è una sola per sessione, non un banner
  persistente.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| H8.6 | Azione "Reload now" opzionale | Solo messaggio, nessun pulsante | Evitare reload accidentale e perdita di stato; messaggio sufficiente |
| H8.5 | Coda non svuotata prima del successo | Coda processata voce per voce, ogni esito registrato | Implementazione più semplice e con lo stesso effetto pratico |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task |
|---|---|---|---|
| I menu sono catturati per sessione | Un plugin caricato a runtime non compare nel menubar fino al reload, ma la palette lo vede subito | Ricaricare la pagina | H8.6 (documentato) |
| Registro plugin globale | Un load/unload influenza le altre sessioni; i loro menubar restano vecchi | Assunzione single-user; reload | ADR-013 / H8.13 |
| Lazy differito al primo catalogo | Non riduce il lavoro, lo sposta all'avvio sessione | Documentato e misurato in health | H8.10, chiuso |
| Conflitti tra plugin silenziosi | Override visibili solo nella console | Risolto: health, diagnostics e notifica | H8.9, chiuso |
| E2E non rieseguiti | Nessuna copertura browser del click su voce disabilitata o del Plugin Manager | Eseguire `RCMDRSHINY_E2E=1` | Lavoro ordinario |

---

## 8. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario (sezioni 0, 7, 11, 12) e la sezione 7 del documento
   di settore.
2. Eseguire la baseline (sezione 9) e confermare **3401 pass, 0 fail**.
3. Onda 8 è chiusa. Riaprire solo se scatta un trigger di ADR-014.

### H8.13 — Chiusa con ADR-014

- **No** al lazy reale per gruppo: costo e rischio alti, beneficio non
  dimostrato (la coda si materializza comunque al primo catalogo).
- **No** al registry per-sessione: il progetto è single-user e le cache sono
  globali.
- Trigger di rivalutazione: multiutente, startup sopra budget, catalogo molto
  più grande, necessità di scaricare un singolo plugin.

### Lavoro ordinario

- Rieseguire gli E2E browser quando possibile:
  `RCMDRSHINY_E2E=1` su `test-menu-platform-e2e.R` e sul nuovo flusso del
  Plugin Manager (da creare se si vuole copertura browser).
- Tenere aggiornati health/diagnostics se si aggiungono nuovi campi plugin.
- Non modificare `menu_id`, `item_id`, `command_id` o il formato preferenze
  senza migrazione.

---

## 9. Comandi per riprendere

```bash
# baseline
Rscript -e 'pkgload::load_all(quiet=TRUE); res <- testthat::test_dir("tests/testthat", reporter="silent"); d <- as.data.frame(res); cat(nrow(d), sum(d$passed), sum(d$failed), sum(d$skipped), "\n")'

# mirati
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-menu-availability.R")'
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-plugins.R")'

# check
R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```

Nota: la suite può cancellare
`tests/testthat/_snaps/visual/quadratic-line.svg`; ripristinarlo con
`git checkout -- tests/testthat/_snaps/visual/quadratic-line.svg` prima del
commit.

---

## 10. Note di contesto

- 288 voci di menu nel core; con i 15 plugin il contratto è 782 comandi.
- Con nessun dataset: 127 `inactive`, 13 `porting`, 5 `hidden`.
- `command_availability()` memorizza l'indice comando→riga con chiave
  `(.plugin_registry$version, .menu_registry_cache$key)`.
- `plugin_failures()` è un data frame `name`, `stage`, `message`, `time`.
- Il caricamento plugin ora non lancia più errori in blocco: usare
  `plugin_failures()` nei test, non `expect_error()`.
- Non modificare `menu_id`, `item_id`, `command_id` né il formato delle
  preferenze esistenti.

---

## 11. Fase 2 — risultati (2.1.0)

**Obiettivo:** rendere la selezione dei plugin persistente e gestibile da UI,
rendere visibili i conflitti, misurare il caricamento differito e coprire il
ciclo plugin con benchmark.

**Implementato:**

- `preferences_snapshot()`/`preferences_load()` includono `plugins`
  (pacchetti e script), con filtro delle stringhe vuote.
- `app(plugins = NULL)` carica la selezione salvata; `character()` non carica
  nulla; un vettore esplicito prevale. Helper: `saved_plugin_selection()`,
  `resolve_startup_plugins()`.
- Il dialogo Utilities (id `loadPlugins`) è diventato **Manage Rcmdr
  plug-ins...**: checkbox sui pacchetti installati, script aggiuntivo con
  "Remember this script", salvataggio preferenze e reload del registry.
- `plugin_conflicts()` registra override tra plugin e col core (con
  `replace = TRUE`); health, diagnostics e una notifica per sessione li
  mostrano. I clash col core senza `replace` restano errori.
- `plugins_ensure_loaded()` misura `last_materialize_ms`; health e diagnostics
  riportano "Deferred plugins".
- Benchmark: `benchmark_plugin_load()`, `benchmark_plugin_deferred()`,
  `benchmark_plugin_tree()`; budget per "load 1 plugin", "load all plugins",
  "first catalogue after deferred loading", "menu tree warm".

**File toccati:** `R/preferences.R`, `R/app.R`, `R/plugins.R`, `R/health.R`,
`R/diagnostics.R`, `R/benchmark.R`, `inst/etc/Rcmdr-menus.txt`,
`inst/menus/core.yml`, test in `test-plugins.R`, help e vignetta plugin.

**Test:** 3401 pass, 0 fail, 22 skip; `R CMD check` OK; 0 link rotti.
Benchmark quick: load 1 plugin 831 ms (budget 6000), menu tree warm 100 ms
(budget 4000), tutti gli scenari entro budget.

**Decisioni minori:**

- Il manager applica la selezione con `unload_plugins()` + `load_plugins()`:
  stato deterministico, ma richiede il reload della pagina per i menu.
- Un plugin può essere deselezionato mentre è caricato; viene scaricato al
  reload successivo insieme agli altri.
- Gli script salvati restano nella selezione anche se il file sparisce: il
  fallimento è registrato in health.
- Non è stato aggiunto un nuovo ID di menu: si riusa `loadPlugins`, così
  conteggi e golden test del registry restano invariati.

**Debito residuo:** nessun E2E browser per il Plugin Manager; H8.13 resta una
valutazione.

---

## 12. Chiusura Onda 8 — audit, E2E e ADR-014

**Audit persistito:** [`../audit-menu-plugin.md`](../audit-menu-plugin.md)
contiene evidenze, misure, prove e mappatura difetto → correzione per entrambi
gli audit. Il piano lo cita nella sezione 2.

**E2E aggiunti:**

- `test-menu-platform-e2e.R` — secondo flusso: voce `inactive` con
  `aria-disabled`, motivo, `tabindex`, click che non chiude il menu, preferiti
  con 1 link e 2 voci disabilitate.
- `test-plugin-manager-e2e.R` — apre Utilities, seleziona un plugin installato,
  Apply e verifica la selezione scritta nel file preferenze.

**Stato E2E:** i test sono gated da `RCMDRSHINY_E2E=1`. In questa macchina
l'esecuzione browser **non è possibile**: anche i flussi E2E preesistenti
falliscono con `Chromote: timed out waiting for response to command
Page.navigate`. Non è una regressione introdotta qui; il debito di evidenza
resta dichiarato. Da rieseguire in CI o su una macchina con browser
funzionante.

**Fase 3:** ADR-014 chiude H8.13 con **no-go** su lazy reale e registry
per-sessione, e fissa i trigger di rivalutazione.

**Onda 8 chiusa.** Prossimi passi possibili: release 2.1.0 (`R CMD check
--as-cran`, tag), rifiniture UX del Plugin Manager, o una nuova ondata.
