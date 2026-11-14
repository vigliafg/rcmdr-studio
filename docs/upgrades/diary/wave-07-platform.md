# Diario di handoff — Onda 7 — Piattaforma, progetto, plugin e qualità

**Data:** 2026-11-14
**Stato:** completata
**Versione:** RcmdrShiny Studio 2.0.0
**Ondata precedente:** `wave-06.5-menu-platform.md`
**Documento di settore:** [`../07-platform-plugins-quality.md`](../07-platform-plugins-quality.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa

L'Onda 7 è chiusa. La piattaforma è alla versione **2.0.0**.

**Baseline:** `testthat::test_local()` → **3328 pass, 0 fail, 16 skip**;
`R CMD check` su `RcmdrShiny_2.0.0.tar.gz` → **Status: OK**; E2E core 15,
menu 16, navigation 4, progetto 4; benchmark entro budget.

**Prossimo passo:** release. Restano solo le voci manuali di accessibilità e
`R CMD check` dei 15 pacchetti plugin, entrambe nella
[`../../RELEASE-CHECKLIST.md`](../../RELEASE-CHECKLIST.md).

---

## 1. Obiettivo e risultato

**Direttiva:** trasformare la Studio UI in una piattaforma: progetto di
sessione, autosave/recovery, bundle, performance, SDK plugin v2,
health/diagnostics, matrice di test e release criteria.

**Risultato:** tutti i task P7.1–P7.22 sono chiusi.

| Area | Risultato |
|---|---|
| Progetto | `.rcmdrproj` YAML versionato, salvataggio atomico, apertura, save as, recenti |
| Recovery | autosave `.autosave`, prompt all'avvio, recupera/ignora/elimina |
| Bundle | `.tar.gz` con project + data + assets; `.zip` se `zip` è disponibile |
| Checkpoint | checkpoint di sessione con dataset/modello/documenti attivi |
| Performance | lazy plugin, cache menu/help/plugin, cap estesi, benchmark |
| SDK v2 | contratto versionato, hook additivi, test sui 15 moduli |
| Health | pannello Home con versioni, package, plugin, cache, progetto, ultimo errore |
| Diagnostics | report esteso e URL issue precompilato |
| Qualità | matrice test, snapshot visuale, audit accessibilità, release checklist |

---

## 2. Progetto e persistenza (P7.1–P7.8)

### Schema

`R/project.R` definisce:

- `project_new()`, costruttori di voce (`project_dataset()`,
  `project_model_entry()`, `project_document_entry()`,
  `project_plot_entry()`);
- `project_validate()` puro con `problems`/`warnings`;
- `project_normalize()`, `project_migrate()` (v0→v1);
- helper di path: `project_relative_path()`, `project_resolve_path()`,
  `project_path_inside()`, `project_path_escapes()`, `project_assets_dir()`.

Regole principali: versione obbligatoria, timestamp ISO-8601, nomi unici, un
solo dataset/documento attivo, source obbligatorio, plot relativi e contenuti
nel progetto, campi sconosciuti = warning.

### Save/load

- `project_save(state, path)`, `project_save_as()`, `project_open(path)`,
  `project_load(state, path)`, `project_apply(state, project)`.
- I dataset senza file sorgente sono scritti in `data/<nome>.csv`; i plot sono
  copiati in `assets/<id>.<ext>`.
- La scrittura è atomica con backup `.bak`.
- Formati dataset supportati in apertura: `.csv`, `.tsv`, `.txt`, `.rds`,
  `.Rda`/`.RData`.

### Recenti, autosave, bundle

- `project_recent()`, `project_recent_add()`, `project_recent_remove()` con
  file `projects.rds` (override `options(RcmdrShiny.projects=...)` o
  `RCMDRSHINY_PROJECTS`).
- `project_autosave()`, `project_recovery_info()`, `project_recover()`,
  `project_remove_autosave()`.
- `project_export_bundle(state, file)`: `.tar.gz` sempre; `.zip` richiede
  l'eseguibile `zip`.
- `project_reset()`, `project_summary()`, `project_mark_dirty()`.

### UI

`R/project-dialogs.R`:

- dialoghi `projectNew`, `projectOpen`, `projectSaveAs`, `projectBundle`,
  `sessionCheckpoint`;
- comando diretto `projectSave`;
- card Home con nuovo/apri/salva/bundle/recenti;
- modale di recovery con Recupera / Ignora / Elimina;
- timer di autosave nel server e prompt di recupero all'avvio;
- feature flag `project` attivo.

Menu: voci in `File > New/Open/Save/Save as/Export` e
`Utilities > Session checkpoints...`; registry rigenerato.

### Checkpoint di sessione (P7.7)

`R/checkpoints.R`: `session_checkpoint_create()`, `_list()`, `_get()`,
`_restore()`, `_delete()`. Non copiano i dati: registrano dataset/modello
attivi, documenti aperti, elenco oggetti e percorso progetto. Cap
`session_checkpoint_max`.

---

## 3. Performance (P7.9–P7.12)

- **Lazy plugin**: `load_plugins(..., lazy = TRUE)` /
  `options(RcmdrShiny.lazy_plugins = TRUE)`; `plugins_ensure_loaded()`,
  `plugins_pending()`. `menu_registry_cached()` forza il caricamento prima di
  costruire il menu, così un plugin in coda non sparisce.
- **Cache**: `.plugin_catalog_cache` per menu/commands/dialogs/aliases,
  cache menu e help già esistenti. `R/cache.R` espone `cache_stats()`,
  `cache_clear()`, `cache_summary()`.
- **Benchmark**: `R/benchmark.R` e `tests/benchmarks/benchmark.R`, budget in
  `benchmark_budgets()`. Scenari: startup, import 1k/5k/10k/100k, grid,
  history, plot, help index.
- **Cap**: `session_trim()` limita `script_outputs`, `cell_outputs`,
  `knit_history` e `recent_commands`; restano attivi i cap di output, messaggi,
  plot, history, console e checkpoint.

---

## 4. Plugin SDK v2 (P7.13–P7.16)

- `plugin_api_version()` = 2; `plugin_contract()` documenta i campi stabili.
- `RcmdrShiny.plugin()` accetta `api_version`, registra `module_id`, rifiuta
  versioni future.
- Hook additivi in `R/plugin-helpers.R`:
  `plugin_ui_component()`, `plugin_dialog_preview()`,
  `plugin_register_preset()`, `plugin_register_workflow()`,
  `plugin_register_chart_type()`, `plugin_register_report_template()`,
  `plugin_help_try_it()`.
- I registry built-in vincono per id: un plugin non può sostituire workflow,
  chart type o template esistenti; i preset di sessione vincono sui preset
  plugin.
- `tests/testthat/test-plugins-compat.R` verifica tutti i 15 moduli:
  DESCRIPTION, hook `rcmdrshiny_plugin`, frammento `module.yml`, validazione
  contro il core, copertura comandi, nessuna rimozione di menu core, nessuna
  chiave DOM duplicata quando i pacchetti sono installati.

Documentazione: `vignettes/plugins.Rmd`, `topic:writing-plugins`,
`topic:projects`.

---

## 5. Health, diagnostics e qualità (P7.17–P7.22)

- `R/health.R`: `health_status()`, `health_table()`, `health_panel_ui()`.
  La card Home mostra versioni, pandoc/LaTeX, plugin caricati e in coda, help
  topics, cache, progetto, ultimo errore e uptime.
- `R/diagnostics.R`: `diagnostics_report(state)` esteso con UI mode, feature
  flag, progetto, history, cache, plugin in coda; `diagnostics_report_text()`
  e `diagnostics_issue_url()`.
- `docs/upgrades/TEST-MATRIX.md` e `tests/testthat/test-quality-matrix.R`.
- `tests/testthat/test-visual.R` + snapshot `_snaps/visual/quadratic-line.svg`
  (vdiffr opzionale).
- `docs/upgrades/ACCESSIBILITY.md` con audit e `test-accessibility.R`.
- `RELEASE-CHECKLIST.md` riscritta per Studio 2.0.

---

## 6. Decisioni

- **Il progetto descrive, non esegue.** Aprire un progetto non riesegue
  comandi: carica dati, documenti, plot e metadati. I modelli devono già
  esistere nell'ambiente; solo la selezione attiva viene ripristinata.
- **Dataset non tracciati diventano CSV.** Un dataset creato in sessione viene
  esportato in `data/<nome>.csv`, così il progetto resta portabile.
- **Path mai `..`.** I plot devono essere relativi e restare nel progetto; un
  file fuori da `assets/` è un warning, un path assoluto o con `..` è errore.
- **Autosave sempre per progetti salvati.** Il timer scrive se c'è un percorso
  o se il progetto è dirty; la scrittura è atomica e il file `.bak` è separato.
- **Dirty flag in `state_touch()`.** Qualsiasi mutazione di sessione marca il
  progetto come modificato; save/load azzerano il flag dopo il touch.
- **I moduli non cancellano menu core.** Restano possibili solo le rimozioni
  di singoli comandi.
- **SDK v2 additivo.** I built-in non sono sostituibili per id; i preset di
  sessione vincono. Non c'è compatibilità esterna: i 15 plugin sono first-party.
- **Il menu resta la Wave 6.5.** Nessun redesign: solo nuove voci progetto e
  checkpoint.

---

## 7. File

### Creati

- `R/project.R` (schema, persistenza, recenti, autosave, bundle)
- `R/project-dialogs.R`
- `R/checkpoints.R`
- `R/cache.R`
- `R/benchmark.R`
- `R/health.R`
- `R/plugin-sdk.R`? No: hook in `R/plugin-helpers.R`
- `tests/testthat/test-project.R`
- `tests/testthat/test-session-checkpoints.R`
- `tests/testthat/test-performance.R`
- `tests/testthat/test-plugin-sdk.R`
- `tests/testthat/test-plugins-compat.R`
- `tests/testthat/test-health.R`
- `tests/testthat/test-quality-matrix.R`
- `tests/testthat/test-visual.R`
- `tests/testthat/test-accessibility.R`
- `tests/testthat/test-project-e2e.R`
- `tests/testthat/_snaps/visual/quadratic-line.svg`
- `tests/benchmarks/benchmark.R`, `tests/benchmarks/README.md`
- `docs/upgrades/TEST-MATRIX.md`
- `inst/help-topics/topics/projects.md` e traduzione `it/projects.md`
- questo diario

### Modificati

- `R/state.R` (campi progetto/checkpoint/sessione, opzioni, dirty)
- `R/plugins.R` (lazy, cache, api_version, module_id)
- `R/menu-registry.R` (voci progetto/checkpoint, source root moduli, lazy)
- `R/dialogs.R`, `R/dialogs-tools.R` (catalogo, comando `projectSave`,
  diagnostics con state)
- `R/app.R` (Home progetti, health, autosave, recovery, reduced motion)
- `R/preferences.R`, `R/features.R`, `R/onboarding.R`
- `R/workflows.R`, `R/chart-types.R`, `R/report-templates.R`,
  `R/dialog-presets.R` (merge hook plugin)
- `R/commands.R`, `R/script-studio.R`, `R/report-studio.R`,
  `R/document.R` (trim)
- `R/help*.R` (topic progetto, help try-it)
- `R/diagnostics.R`
- `inst/etc/Rcmdr-menus.txt`, `inst/menus/core.yml`
- `inst/help-topics/index.yml`, topic `writing-plugins`,
  `navigation-workflows`, `keyboard-shortcuts`
- `vignettes/plugins.Rmd`
- `DESCRIPTION` (2.0.0), `NEWS.md`, `README.md`
- `docs/upgrades/CHECKLIST.md`, `07-platform-plugins-quality.md`,
  `ACCESSIBILITY.md`, `RELEASE-CHECKLIST.md`

---

## 8. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **3328 pass, 0 fail, 16 skip** |
| Progetto | `testthat::test_local(filter = "project")` | **147 pass** |
| Checkpoint | `testthat::test_local(filter = "session-checkpoints")` | pass |
| Performance | `testthat::test_local(filter = "performance")` | 27 pass |
| SDK/plugin | `testthat::test_local(filter = "plugin")` | pass |
| Health | `testthat::test_local(filter = "health")` | 26 pass |
| Accessibilità | `testthat::test_local(filter = "accessibility")` | pass |
| Visual | `NOT_CRAN=true ... test-visual.R` | snapshot ok |
| `R CMD check` 2.0.0 | build + check | **Status: OK** |
| E2E core | `RCMDRSHINY_E2E=1 test-shinytest2.R` | **15 pass** |
| E2E menu | `RCMDRSHINY_E2E=1 test-menu-platform-e2e.R` | **16 pass** |
| E2E navigation | `RCMDRSHINY_E2E=1 test-navigation-e2e.R` | **4 pass** |
| E2E progetto | `RCMDRSHINY_E2E=1 test-project-e2e.R` | **4 pass** |
| Benchmark | `Rscript tests/benchmarks/benchmark.R` | tutti entro budget |
| `R CMD check` 15 plugin | build + check per pacchetto | **15/15 Status: OK** |
| Help links | `tools/check_help_links.R --strict` | 452 topic, 0 rotti |

Benchmark rilevati (macchina di sviluppo): startup 922 ms, import 10k 19 ms,
import 100k 261 ms, grid 10k 90 ms, 100 history 15 ms, 50 plot 9 ms, help
index 1888 ms.

---

## 9. Problemi noti e follow-up

| Problema | Impatto | Workaround | Task |
|---|---|---|---|
| Voci manuali di accessibilità (zoom 200%, screen reader, axe) | Audit completo | Checklist in `ACCESSIBILITY.md` | P7.21 |
| Bundle `.zip` richiede `zip` esterno | Utenti Windows senza zip | Usare `.tar.gz` | P7.5 |
| I modelli sono descritti, non serializzati | Apertura su un'altra macchina | Rifittare il modello | P7.2 |
| Dataset con formati non supportati vengono saltati con warning | Progetto parziale | Convertire in CSV/RDS | P7.2 |
| Apertura progetto sostituisce i documenti aperti | Perdita modifiche non salvate | Salvare prima; il dialogo lo ricorda | P7.6 |
| EZR continua ad affiancare i menu core | Voci duplicate | Copertura comandi garantita | Wave 6.5 |

---

## 10. Comandi per riprendere

```bash
cd /home/vigliafg/Documenti/GitHub/rcmdr-studio
git status
git log --oneline -5
Rscript -e 'testthat::test_local()'
Rscript tools/check_help_links.R --strict
Rscript tests/benchmarks/benchmark.R --quick
R CMD build . && _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_2.0.0.tar.gz
```

E2E:

```bash
R CMD INSTALL .
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-menu-platform-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-navigation-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-project-e2e.R")'
```

**Baseline attesa:** 3328 pass, 0 fail, 16 skip; `R CMD check` OK.
