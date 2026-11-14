# Diario di handoff — Onda 6.5 — Piattaforma menu e ID stabili

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** `wave-06-help-i18n-onboarding.md`  
**Ondata successiva:** Onda 7 — Piattaforma, plugin, qualità  
**Documento di settore:** [`../06.5-menu-platform.md`](../06.5-menu-platform.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Direttiva:** i 15 plugin sono first-party; il menu diventa una barra
orizzontale gerarchica in stile SPSS/Minitab; i command ID del motore restano
invariati; servono ID stabili per menu e voci.

**Risultato effettivo:**

- **Menubar orizzontale** con nove gruppi: File, Edit, Data, Transform,
  Analyze, Graphs, Reports, Utilities, Help. Sottomenu annidati con
  `<details>`, chiusura su click esterno, apertura di un solo gruppo per volta,
  scorrimento orizzontale su schermi piccoli.
- **Registry stabile** (`R/menu-registry.R`): separazione tra `module_id`,
  `menu_id`, `item_id` e `command_id`; ID DOM derivati da `item_id`
  (`menu_item_file_save_script`), non da un contatore posizionale.
- **Sorgente curata**: `inst/menus/core.yml` con 9 gruppi top-level e
  `plugins/*/inst/menus/module.yml` per i 15 moduli first-party.
- **File > Save unico** con sotto-voci Data set, Script, Report (R Markdown),
  Report (knitr), Workspace e un sottogruppo “Save as”. I comandi restano
  `saveDataSet`, `saveLog`, `saveRmd`, `saveRnw`, `saveWorkspace`.
- **Reports** e **Transform** sono gruppi di primo livello; Models e
  Distributions sono annidati sotto Analyze.
- **Nessuna perdita di routine**: un test golden verifica che tutti i 280
  comandi del core e tutti i 782 comandi dell'insieme core+15 moduli siano
  ancora raggiungibili. Le rimozioni dei moduli sono limitate ai singoli
  comandi che il modulo sostituisce; un modulo non cancella più un intero menu
  del core.
- **Migrazione**: i vecchi ID di espansione (`fileMenu`, `statisticsMenu`, ...)
  sono mappati ai nuovi `menu_id` al caricamento delle preferenze. Preferiti e
  recenti restano keyed by `command_id`, che è già stabile.
- **Validazione**: ID duplicati, parent inesistenti, cicli e comandi mancanti
  vengono segnalati; il caricamento dei moduli non ridichiara i gruppi core.
- **UI**: il vecchio albero in sidebar è sostituito dal menubar; la sidebar
  conserva ricerca menu, preferiti e recenti.
- Topic `menu-structure`, aggiornamenti a `navigation-workflows`,
  `keyboard-shortcuts`, `writing-plugins`, vignetta `menu-platform`.

Tutti i task M6.5.1–M6.5.7 sono chiusi.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `4952414` | feat: Wave 6.5 menu platform and stable ids | Commit principale |
| `4173539` | docs: add Wave 6.5 menu platform plan | Piano approvato |

---

## 3. File creati e modificati

### Creati

- `R/menu-registry.R` — schema, costruttori, parser, merge, validazione,
  conversione legacy, curatela, migrazione ID.
- `inst/menus/core.yml` — layout core curato.
- `plugins/*/inst/menus/module.yml` — 15 frammenti first-party.
- `tools/build_menu_registry.R` — generatore e audit del registry.
- `inst/help-topics/topics/menu-structure.md` e traduzione italiana.
- `vignettes/menu-platform.Rmd`.
- Test: `test-menu-registry.R`, `test-menu-migration.R`,
  `test-menu-platform-e2e.R`.

### Modificati

- `R/menus.R` — `menu_tree()` usa il registry; `menubar_ui()` e
  `menubar_top_ui()`; leaves con `item_id`, `menu_id`, `module_id`.
- `R/app.R` — `uiOutput("menubar")`, CSS menubar/dark/mobile, observer e JS di
  apertura/chiusura; sidebar senza albero.
- `R/preferences.R` — migrazione degli ID di espansione.
- `R/plugins.R` — nessuna modifica strutturale; i moduli usano il registry.
- Test aggiornati: top-level, breadcrumb, sidebar → menubar, plugin Wave 0.
- `DESCRIPTION`, `NEWS.md`, `README.md`, `_pkgdown.yml`.
- Topic: `navigation-workflows`, `keyboard-shortcuts`, `writing-plugins`.
- `docs/upgrades/06.5-menu-platform.md`, `CHECKLIST.md`.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **2932 pass, 0 fail, 16 skip** |
| E2E menu platform | `RCMDRSHINY_E2E=1 testthat::test_file("tests/testthat/test-menu-platform-e2e.R")` | **16 pass** |
| E2E navigation | `RCMDRSHINY_E2E=1 testthat::test_file("tests/testthat/test-navigation-e2e.R")` | **4 pass** |
| E2E core | `RCMDRSHINY_E2E=1 testthat::test_file("tests/testthat/test-shinytest2.R")` | **15 pass** |
| `R CMD check` | `R CMD build .` + `R CMD check --no-manual` | **Status: OK** su 1.21.0 |
| Help inventory | `tools/inventory_help.R --plugins all` | 644 documented, 58 extra |
| Link checker | `tools/check_help_links.R --strict` | 451 topic, nessun link rotto |
| Copertura comandi | audit registry | 782/782 comandi raggiungibili, 0 persi |

Resta il warning cosmetico di `shinytest2` sui globals di `renderPlot`.

---

## 5. Decisioni e ADR

- **I command ID non si toccano.** `saveLog`, `saveRmd`, `saveWorkspace`, ecc.
  restano il contratto con cronologia, script, report e test golden.
- **Il layout è un registry, non un file di menu.** `Rcmdr-menus.txt` resta
  sorgente di attivazione e migrazione; il layout vive in `core.yml` e nei
  frammenti dei moduli.
- **I moduli si agganciano, non ridichiarano.** Se un frammento dichiara un
  gruppo già presente nel core, il gruppo core vince e gli item del modulo
  vengono aggiunti.
- **Un modulo non cancella un menu core.** Le rimozioni a livello di menu sono
  state disattivate in generazione; restano le rimozioni di singoli comandi,
  limitate al modulo `core` di origine.
- **ID generati dalla gerarchia, non dalla posizione.** `menu_dom_id()` deriva
  da `item_id`; riordinare non cambia né ID né test.
- **Preferiti e recenti restano per command ID.** È una deviazione dal piano
  iniziale: i command ID sono già stabili e la migrazione sarebbe stata
  inutile. Gli `item_id` servono per DOM, palette e futura telemetria dei
  layout.
- **Il menubar è nativo.** `<details>`/`<summary>` dà tastiera, focus e apertura
  senza un menu JavaScript custom; il CSS gestisce dropdown e mobile.
- **La sidebar non duplica il menu.** Conserva ricerca, preferiti e recenti;
  il catalogo completo vive nel menubar.

---

## 6. Deviazioni dal piano

| Task | Piano | Fatto | Motivo |
|---|---|---|---|
| M6.5.2 | Curare tutte le 351 voci | Generazione + curatela dei gruppi top-level e di File > Save; il resto conserva la gerarchia legacy sotto i nuovi root | 351 voci richiedono più sessioni; la copertura comandi è garantita |
| M6.5.4 | Preferiti migrati a item_id | Preferiti/recenti restano command ID; migrata l'espansione | Command ID già stabili; meno rischio |
| M6.5.5 | Offcanvas mobile | Menubar orizzontale scrollabile e dropdown fixed su mobile | Meno JS, stessa raggiungibilità |
| M6.5.6 | Palette con item_id | Palette usa ancora command ID come chiave azione; path e DOM usano item_id | Non rompe le azioni esistenti |
| M6.5.3 | Rimozioni menu dei plugin | Disattivate; restano solo remove di comandi | EZR cancellava Help/Data/Analyze e perdeva comandi |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task |
|---|---|---|---|
| Curazione manuale delle 351 voci non completata | Alcuni sottomenu hanno ancora nomi legacy (`Import data`, `Data in packages`) | Il layout è stabile e modificabile in `core.yml` | M6.5.2 |
| EZR aggiunge i propri menu accanto ai core invece di sostituirli | Possibili voci duplicate in File/Data/Analyze | Copertura comandi preservata; curare il frammento EZR | M6.5.3 |
| I frammenti dei plugin installati vanno rigenerati/reinstallati | Un plugin vecchio usa il fallback legacy | `tools/build_menu_registry.R` + reinstall | M6.5.3 |
| Solo il gruppo Save ha ID semantici leggibili | Altri item hanno ID generati (`item.core...`) | Sono stabili; rinominare solo se serve | M6.5.2 |
| Menubar mobile con dropdown a posizione fissa | Può sovrapporsi al contenuto su viewport molto piccole | Scorrimento orizzontale; test manuale | M6.5.5 |

---

## 8. Domande aperte

- [ ] Curare tutti i sottomenu in `core.yml` in una sessione dedicata?
- [ ] Convertire i preferiti da command ID a item ID in Onda 7?
- [ ] EZR deve sostituire o affiancare i menu core?
- [ ] Il menubar deve avere una modalità “compact” per Classic?
- [ ] La sidebar deve ospitare i workflow o restare solo preferiti/ricerche?
- [ ] Gli ID generati vanno rinominati in modo semantico per tutti i gruppi?
- [ ] I frammenti dei plugin devono essere versionati anche nel bundle Onda 7?

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../07-platform-plugins-quality.md` e
   `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: **2932 pass, 0 fail, 16 skip**).
3. Avviare l'Onda 7 dal task **P7.1 — Schema progetto**.

### Task dell'ondata successiva

| ID | Task | Priorità |
|---|---|---|
| P7.1 | Schema progetto | Alta |
| P7.2 | Save/load progetto | Alta |
| P7.3 | Recent projects | Media |
| P7.4 | Autosave/recovery | Alta |
| P7.5 | Export bundle | Alta |
| P7.6 | Home progetti | Media |
| P7.7 | Checkpoint sessione | Media |
| P7.8 | Recovery prompt | Media |
| P7.9 | Lazy plugin/cataloghi | Media |
| P7.10 | Cache help/menu | Media |
| P7.11 | Benchmark suite | Media |
| P7.12 | Trimming e cap | Media |
| P7.13 | API plugin v2 | Alta |
| P7.14 | Nuovi hook | Media |
| P7.15 | Documentazione plugin | Media |
| P7.16 | Test 15 plugin | Alta |
| P7.17 | Health panel | Media |
| P7.18 | Diagnostics esteso | Media |
| P7.19 | Matrice test | Media |
| P7.20 | Visual regression | Bassa |
| P7.21 | Accessibility checklist | Media |
| P7.22 | Release checklist Studio | Alta |

---

## 10. Comandi per riprendere

```bash
cd /home/vigliafg/Documenti/GitHub/rcmdr-studio
git status
git log --oneline -5
Rscript -e 'testthat::test_local()'
Rscript tools/build_menu_registry.R
Rscript tools/check_help_links.R --strict
```

Per gli E2E:

```bash
R CMD INSTALL .
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-menu-platform-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-navigation-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
```

**Baseline attesa:** 2932 pass, 0 fail, 16 skip; `R CMD check` OK.

---

## 11. Note di contesto

- `menu_registry_cached()` restituisce il registry core + moduli registrati;
  la chiave include revisione plugin e mtime dei frammenti.
- `menu_registry_default_file()` cerca `inst/menus/core.yml` nel pacchetto e
  nel source tree.
- `menu_registry_merge()` ignora i gruppi già presenti nel core: i moduli
  aggiungono solo item e sottogruppi nuovi.
- `menu_registry_apply_removes()` supporta remove di comando per modulo di
  origine; le remove di menu sono supportate dal codice ma non generate dai
  moduli first-party.
- `menu_dom_id(item_id)` sostituisce i caratteri non alfanumerici con `_`.
- `menu_leaves()` restituisce `item_id`, `menu_id`, `module_id`, `command`,
  `path`, `key`; la palette usa ancora `command` come chiave azione.
- `menu_migrate_ids()` mappa gli ID legacy usando `legacy_ids` dei gruppi.
- `menubar_ui()` rende i top-level con `<details>`; i sottomenu usano
  `menu_node_ui()` e mantengono `data-menu-id` per l'espansione persistita.
- `tools/build_menu_registry.R` è idempotente; `--check` non scrive.
- I frammenti dei plugin sono esclusi dal pacchetto core da `.Rbuildignore`;
  viaggiano con i rispettivi pacchetti plugin.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “Onda 6.5 completata, pronta per l'Onda 7”.
