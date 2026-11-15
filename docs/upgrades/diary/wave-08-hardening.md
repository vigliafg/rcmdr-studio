# Diario di handoff — Onda 8 — Hardening menu e ciclo di vita plugin

**Data:** 2026-11-15
**Stato:** Fase 1 completata (2.0.2); Fase 2 pianificata (2.1.0)
**Baseline:** RcmdrShiny 2.0.2
**Documento di settore:** [`../08-hardening-menus-plugins.md`](../08-hardening-menus-plugins.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa per la prossima sessione

**Stato al momento della compattazione:** branch `main`, HEAD corrente (vedi
`git log -1`), working tree pulito, Fase 1 pushata su `origin/main`.

**Baseline verificata:**
`testthat::test_local()` → **3379 pass, 0 fail, 20 skip**;
`R CMD check --no-manual` su `RcmdrShiny_2.0.2.tar.gz` → **Status: OK**.

**Prossimo task:** **H8.8 — Persistenza plugin e Plugin Manager**, poi H8.9,
H8.10, H8.11, H8.12 (vedi sezione 8).

**Da leggere, in quest'ordine:**

1. questo diario (sezioni 0, 5, 7, 8);
2. [`../08-hardening-menus-plugins.md`](../08-hardening-menus-plugins.md),
   sezioni 4 (decisioni), 6 (Fase 2) e 10 (test);
3. [`../CHECKLIST.md`](../CHECKLIST.md), sezione Onda 8;
4. solo se serve: `R/plugins.R`, `R/preferences.R`, `R/health.R`.

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
| _(questo commit)_ | feat: unify command availability and harden plugins | Fase 1 completa (2.0.2) |

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
- `DESCRIPTION` (2.0.2), `NEWS.md` (2.0.2).
- `inst/help-topics/topics/writing-plugins.md`, `vignettes/plugins.Rmd`.
- `docs/upgrades/08-hardening-menus-plugins.md`, `CHECKLIST.md`,
  `TEST-MATRIX.md`, `ACCESSIBILITY.md`, `DECISIONS.md` (ADR-011…013).

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Suite completa | `testthat::test_local()` | **3379 pass, 0 fail, 20 skip** |
| Menu e disponibilità | `test_file("tests/testthat/test-menus.R")` | verde |
| Attivazione | `test_file("tests/testthat/test-activation.R")` | verde |
| Guardie | `test_file("tests/testthat/test-menu-availability.R")` | verde |
| Plugin | `test_file("tests/testthat/test-plugins.R")` | verde |
| `R CMD check` | build + check `--no-manual` su 2.0.2 | **Status: OK** |
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
| Lazy differito al primo catalogo | Non riduce il lavoro, lo sposta all'avvio sessione | Documentato; da misurare | H8.10, H8.11 |
| Conflitti tra plugin solo warning | Override silenziosi fuori dalla console | Nessuno | H8.9 |
| E2E non rieseguiti | Nessuna copertura browser del click su voce disabilitata | Eseguire `RCMDRSHINY_E2E=1` | H8.12 |

---

## 8. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario e la sezione 6 del documento di settore.
2. Eseguire la baseline (sezione 9) e confermare **3379 pass, 0 fail**.
3. Partire da **H8.8**.

### H8.8 — Persistenza plugin e Plugin Manager (2.1.0)

- `R/preferences.R`: campo `plugins` nello snapshot e nel load, validazione,
  fallimenti registrati con `plugin_record_failure()`.
- `R/app.R`: semantica `NULL` → salvati, `character()` → nessuno, vettore →
  quelli indicati (l'argomento esplicito vince).
- Nuovo dialogo in Utilities: elenco `RcmdrShinyPlugin.*` installati con
  versione/stato, checkbox, path per script, "Apply" scrive le preferenze,
  messaggio "Reload to apply".
- Test: roundtrip preferenze, tre semantiche, plugin salvato mancante,
  rendering del dialogo.
- Accettazione: la selezione sopravvive al riavvio; un plugin mancante non
  blocca l'avvio.

### H8.9 — Conflitti visibili

- `.plugin_registry$conflicts` alimentato da `check_conflicts()`; health,
  diagnostics e notifica una tantum; i clash col core restano errori.

### H8.10 — Lazy documentato e misurato

- Health/diagnostics espongono il numero di plugin accodati e il tempo di
  materializzazione; help/vignetta aggiornati (già aggiornati in Fase 1, da
  completare con la parte di misura).

### H8.11 — Benchmark plugin

- Scenari: load 1 plugin, load 15, primo catalogo dopo lazy, `menu_tree()`
  caldo, conteggio fallimenti; budget in `R/benchmark.R` e `TEST-MATRIX.md`.
- Baseline 2.0.1 misurata: 5,69 s per 16 plugin; tree 0,7–1,5 s.

### H8.12 — Chiusura Fase 2

- `NEWS.md` 2.1.0, `DESCRIPTION` 2.1.0, E2E gated, diario aggiornato,
  checklist `[x]`.

### Dopo la Fase 2

- **H8.13** solo ADR/spike: lazy reale per gruppo e registry per-sessione.
  Nessuna implementazione senza decisione esplicita.

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
