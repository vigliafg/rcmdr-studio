# Onda 7 — Piattaforma, progetto, plugin e qualità

**Stato:** da implementare  
**Dipende da:** Onde 0–6 e Onda 6.5 (menu platform)
**Sblocca:** RcmdrShiny Studio 2.0 stabile e manutenibile  
**Documento padre:** [`README.md`](README.md)

> **Punto di partenza:** l'Onda 6.5 è chiusa. Prima di iniziare, leggere
> [`diary/wave-06.5-menu-platform.md`](diary/wave-06.5-menu-platform.md)
> (sezione 0). Baseline attesa: **2932 pass, 0 fail, 16 skip**;
> `R CMD check` 1.21.0 **OK**. Il primo task è **P7.1 — Schema progetto**.

---

## 1. Obiettivo

Rendere la Studio UI una piattaforma, non solo una somma di schermate:

- progetto di sessione `.rcmdrproj`;
- autosave, recovery, checkpoint, export bundle;
- performance e memoria sotto controllo;
- Plugin SDK v2 additivo;
- health/diagnostics;
- matrice di test e release criteria.

---

## 2. Progetto di sessione

### 2.1 Formato

YAML versionato, estensione `.rcmdrproj`:

```yaml
version: 1
created: "2026-11-14T10:00:00"
modified: "2026-11-14T10:42:00"
package_version: "1.13.0"

datasets:
  - name: Dataset
    source: "data/iris.csv"
    include: false
    active: true
    dictionary:
      Sepal.Length:
        label: "Lunghezza sepalo"
        units: "cm"

models:
  - name: model.1
    class: lm
active_model: model.1

documents:
  - id: report-1
    path: "report.Rmd"
    mode: rmd
    text: "..."
    active: true

plots:
  - id: plot-0001
    file: "assets/plot-0001.png"
    title: "Istogramma"
    spec: {...}
    pinned: false

presets:
  numericalSummaries:
    "Default didattico":
      mean: true
      sd: true

favorites:
  - numericalSummaries
  - Histogram

options:
  ui_mode: studio
  theme: system
  language: it

history:
  include: false
```

### 2.2 API

```r
project_new(path, title = NULL)
project_open(path)
project_save(state, path = NULL)
project_save_as(state, path)
project_recent()
project_autosave(state)
project_recover(path)
project_export_bundle(state, file)
```

### 2.3 Regole

- i dataset possono essere referenziati o inclusi;
- i path sono relativi al progetto quando possibile;
- i plot sono copiati in `assets/`;
- la cronologia è opzionale;
- la versione dello schema è obbligatoria;
- migrazione da versioni precedenti con funzione dedicata.

### 2.4 Task

| ID | Task | File |
|---|---|---|
| P7.1 | Schema e validazione | `R/project.R` |
| P7.2 | Save/load | `R/project.R` |
| P7.3 | Recent projects | `R/project.R`, `R/app.R` |
| P7.4 | Autosave/recovery | `R/project.R` |
| P7.5 | Export bundle | `R/project.R` |
| P7.6 | Home progetti | `R/app.R` |

---

## 3. Checkpoint e recovery

### 3.1 Checkpoint

- dataset: già in Onda 1;
- sessione: elenco oggetti, dataset/modello attivo, documenti aperti;
- UI: “Crea checkpoint”, “Ripristina”, “Elimina”;
- cap: numero e dimensione.

### 3.2 Recovery

- autosave ogni 30 s;
- file `.rcmdrproj.autosave`;
- prompt all'avvio se più recente del progetto;
- confronto data/ora e dimensione;
- “Recupera” / “Ignora” / “Elimina”.

### 3.3 Task

| ID | Task | File |
|---|---|---|
| P7.7 | Checkpoint sessione | `R/checkpoints.R`, `R/state.R` |
| P7.8 | Recovery prompt | `R/project.R`, `R/app.R` |

---

## 4. Performance e memoria

### 4.1 Obiettivi

- avvio rapido anche con 15 plugin;
- griglia fluida su dataset medi;
- preview reattive;
- nessuna crescita incontrollata di log, plot, cronologia, checkpoint.

### 4.2 Interventi

| Area | Intervento |
|---|---|
| Plugin | Caricamento lazy e cache del catalogo |
| Menu | Cache dell'albero e delle attivazioni |
| Help | Indice costruito lazy e cache |
| Tabelle | DT server-side oltre soglia |
| Plot | Thumbnail lazy, limite `max_plots` |
| Cronologia | Cap e trimming |
| Checkpoint | Cap per numero e byte |
| Preview | Debounce, cache, cleanup |
| Output | Cap `max_output_lines` |
| Autosave | Scrittura atomica e debounce |

### 4.3 Benchmark

- avvio a freddo/caldo;
- import CSV 10k/100k righe;
- render griglia 10k righe;
- preview chart su 1k/10k righe;
- 100 comandi in cronologia;
- 50 plot in galleria;
- memoria dopo 1 ora di sessione simulata.

### 4.4 Task

| ID | Task | File |
|---|---|---|
| P7.9 | Lazy plugin/cataloghi | `R/plugins.R`, `R/menus.R` |
| P7.10 | Cache help/menu | `R/help.R`, `R/menus.R` |
| P7.11 | Benchmark suite | `tests/benchmarks/` |
| P7.12 | Trimming e cap | `R/commands.R`, `R/history.R`, `R/checkpoints.R` |

---

## 5. Plugin SDK v2

### 5.1 Principi

- **first-party:** i 15 plugin sono mantenuti dall'autore e versionati con
  l'app; non c'è compatibilità esterna da preservare;
- **interno e versionato:** `module_id`, frammento menu e contratto dei
  dialoghi/comandi, documentato nella vignetta;
- **ID stabili:** `menu_id` e `item_id` dell'Onda 6.5, command ID invariati;
- **testato:** tutti i 15 moduli con test di integrazione first-party, non di
  compatibilità esterna.

### 5.2 Nuove estensioni

```r
plugin_ui_component(name, ...)
plugin_dialog_preview(spec)
plugin_register_preset(dialog_id, name, values)
plugin_register_workflow(workflow)
plugin_register_chart_type(chart_type)
plugin_register_report_template(template)
plugin_help_try_it(topic_id, examples)
```

### 5.3 Compatibilità

- `RcmdrShiny.plugin()` resta il punto di registrazione interno;
- `plugin_dialog()` accetta i campi dell'Onda 6.5;
- i 15 moduli vengono aggiornati insieme al core, senza strato di
  compatibilità esterna;
- test di integrazione per ognuno dei 15 moduli;
- i comandi Tk legacy restano non eseguibili, con avviso esplicito.

### 5.4 Task

| ID | Task | File |
|---|---|---|
| P7.13 | API v2 e versione | `R/plugins.R`, `NAMESPACE` |
| P7.14 | Nuovi hook | `R/plugin-helpers.R` |
| P7.15 | Documentazione plugin | `vignettes/plugins.Rmd` |
| P7.16 | Test 15 plugin | `tests/testthat/test-plugins-compat.R` |

---

## 6. Health e diagnostics

### 6.1 Health panel

Contenuto:

- versione RcmdrShiny Studio;
- versione R;
- piattaforma;
- pandoc/LaTeX;
- pacchetti opzionali installati;
- plugin caricati e versione;
- stato help inventory;
- performance (avvio, memoria, cache);
- ultimo errore;
- link a Diagnostics.

### 6.2 Diagnostics

Estendere `R/diagnostics.R`:

- includere modalità UI, feature flag, progetto, cronologia;
- esportare report testuale;
- copia negli appunti;
- apri issue con template.

### 6.3 Task

| ID | Task | File |
|---|---|---|
| P7.17 | Health panel | `R/health.R`, `R/app.R` |
| P7.18 | Diagnostics esteso | `R/diagnostics.R` |

---

## 7. Qualità e release

### 7.1 Matrice di test

| Livello | Cosa | Comando |
|---|---|---|
| Unit | Funzioni pure, parser, builder | `testthat::test_local()` |
| Integration | Moduli Shiny, dialoghi, stato | `testthat` |
| Golden | Comandi esistenti invariati | `test-command-builders-*` |
| E2E | Flussi Studio/Classica | `RCMDRSHINY_E2E=1` |
| Visual | Grafici e layout | `vdiffr` (opzionale) |
| Accessibility | Tastiera, focus, contrasto | checklist + axe-core |
| Performance | Benchmark | `tests/benchmarks/` |
| Package | Core + 15 plugin | `R CMD check` |

### 7.2 Release criteria

- [ ] Tutti i test verdi.
- [ ] `R CMD check` core e plugin: OK.
- [ ] Help inventory: 0 missing, 0 draft.
- [ ] Link checker strict: 0 rotti.
- [ ] E2E Studio e Classica verdi.
- [ ] Benchmark entro i budget documentati.
- [ ] Nessuna regressione sui comandi golden.
- [ ] Documentazione e NEWS aggiornati.
- [ ] Migrazione progetto testata.
- [ ] Plugin SDK v2 testato sui 15 plugin.

### 7.3 Task

| ID | Task | File |
|---|---|---|
| P7.19 | Matrice test | `tests/` |
| P7.20 | Visual regression | `tests/testthat/test-visual.R` |
| P7.21 | Accessibility checklist | `docs/upgrades/ACCESSIBILITY.md` |
| P7.22 | Release checklist Studio | `RELEASE-CHECKLIST.md` |

---

## 8. Riproducibilità

| Azione | Comando? | Note |
|---|---|---|
| Salva progetto | No | File di sessione |
| Autosave | No | Recovery |
| Checkpoint | No | Sessione |
| Export bundle | No | File |
| Plugin nuovo | Dipende | I comandi del plugin passano da `run_command()` |
| Health | No | Diagnostica |

---

## 9. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| Progetto con path assoluti non portabile | Path relativi + include dati |
| Autosave corrotto | Scrittura atomica + backup |
| Plugin v2 rompe v1 | API additiva + test compatibilità |
| Performance regression | Benchmark in CI |
| Memoria | Cap e trimming |
| Migrazione schema | Versione + test di migrazione |

---

## 10. Fuori perimetro

- Cloud sync.
- Multiutente.
- Server deployment.
- Nuove procedure statistiche.

---

## 11. Checklist di chiusura

- [ ] Schema progetto.
- [ ] Save/load.
- [ ] Recent projects.
- [ ] Autosave/recovery.
- [ ] Export bundle.
- [ ] Home progetti.
- [ ] Checkpoint sessione.
- [ ] Recovery prompt.
- [ ] Lazy plugin/cataloghi.
- [ ] Cache help/menu.
- [ ] Benchmark suite.
- [ ] Trimming e cap.
- [ ] API plugin v2.
- [ ] Nuovi hook.
- [ ] Documentazione plugin.
- [ ] Test 15 plugin.
- [ ] Health panel.
- [ ] Diagnostics esteso.
- [ ] Matrice test.
- [ ] Visual regression.
- [ ] Accessibility checklist.
- [ ] Release checklist.
