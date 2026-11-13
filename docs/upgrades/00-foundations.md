# Onda 0 — Fondazioni

**Stato:** da implementare  
**Dipende da:** —  
**Sblocca:** tutte le ondate successive  
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Rendere possibile la Studio UI senza toccare il motore statistico:

- una shell moderna e coerente;
- componenti UI condivisi;
- command palette;
- cronologia strutturata;
- anteprima del comando nei dialoghi;
- preview isolate per grafici e Markdown;
- accessibilità e scorciatoie di base;
- feature flag per una migrazione graduale.

Al termine dell'Onda 0 l'app deve essere già più moderna, ma nessun comando
esistente deve cambiare.

---

## 2. Stato attuale

| Area | File | Situazione |
|---|---|---|
| Shell e server | `R/app.R` (1.212 righe) | UI, server, tab, menu, dialoghi, download e stato in un unico file |
| Stato | `R/state.R` | `AppState` con dataset attivo, log, output, plot, opzioni |
| Comandi | `R/commands.R` | `run_command()`, cattura output, plot PNG, rgl |
| Dialoghi | `R/dialogs.R` | `dialog_spec()`, catalogo, runtime modale |
| Widget | `R/widgets.R` | Equivalenti Shiny dei widget Rcmdr |
| Menu | `R/menus.R` | Parser e renderer `details/summary` |
| Help | `R/help*.R` | Ricerca, topic, pannello inline |
| CSS | `app_css()` in `R/app.R` | Colori fissi, dark mode via classi |
| Test | `tests/testthat/` | Unit, integration, E2E opt-in |

Problemi principali:

- `app.R` è troppo grande per aggiungere tre studi.
- Non esiste una cronologia azionabile: solo `state$log`.
- I dialoghi non mostrano il comando prima di eseguirlo.
- Non esiste una command palette.
- Non esiste un preview engine isolato.
- La UI non ha token di design né componenti condivisi.
- La modalità unica rende rischioso ogni cambio di layout.

---

## 3. Architettura target

### Nuovi moduli

| Modulo | Responsabilità |
|---|---|
| `R/ui-components.R` | Componenti HTML/Shiny condivisi e classi CSS |
| `R/command-palette.R` | Indice, ricerca fuzzy, UI e azioni della palette |
| `R/history.R` | Record, aggiunta, ricerca, rerun, insert della cronologia |
| `R/preview.R` | Valutazione isolata, rendering temporaneo, cleanup |
| `R/shortcuts.R` | Mappa delle scorciatoie e helper JS |
| `R/features.R` | Feature flag e modalità Studio/Classica |
| `R/project.R` | Schema progetto (implementazione completa in Onda 7) |

### Moduli modificati

| Modulo | Modifica |
|---|---|
| `R/app.R` | Shell, tab, server modulare, modalità, status bar |
| `R/state.R` | `history`, `checkpoints`, `datasets`, `dialog_presets`, `features`, `ui_mode` |
| `R/commands.R` | Hook cronologia senza cambiare `state$log` |
| `R/dialogs.R` | Preview, preset, validazione, breadcrumb |
| `R/widgets.R` | Widget con badge tipo/missing, preset, help inline |
| `R/menus.R` | Filtro, preferiti, recenti, stato di espansione |
| `R/options.R` | Nuove opzioni e validazione |

### Regole di dipendenza

```text
app.R
 ├─ ui-components.R
 ├─ command-palette.R
 ├─ history.R
 ├─ preview.R
 ├─ data-studio.R        (Onda 1)
 ├─ chart-studio.R       (Onda 2)
 ├─ report-studio.R      (Onda 3)
 └─ project.R            (Onda 7)
```

I nuovi moduli non devono importare `app.R`. Le funzioni pure devono poter
essere testate senza una sessione Shiny.

---

## 4. Task

### S0.1 — Identità e documentazione

**Descrizione:** applicare il nuovo posizionamento senza cambiare il package.

**File:** `DESCRIPTION`, `README.md`, `NEWS.md`, `_pkgdown.yml`, `inst/CITATION`,
vignette, nuovo topic `about`.

**Passi:**

1. `Title: A Browser-Native Statistical Workbench Inspired by the R Commander`.
2. `Description`: sostituire “Shiny Version of the R Commander” con il nuovo
   posizionamento, mantenendo l'attribuzione.
3. README: prima sezione con “not a clone” e i tre studi.
4. UI: titolo `RcmdrShiny Studio`, sottotitolo “Inspired by R Commander”.
5. Dialogo **About** con versione, citazione, licenza, upstream, link al
   repository.
6. `inst/help-topics/topics/about.md` + traduzione italiana.
7. `_pkgdown.yml`: sezione “Studio” e nuovo titolo.

**Test:** `R CMD check` documentazione; nessun link rotto.

**Accettazione:** il package si chiama ancora `RcmdrShiny`, ma README,
DESCRIPTION e UI parlano di RcmdrShiny Studio.

---

### S0.2 — Design system

**Descrizione:** token e componenti condivisi per evitare CSS e HTML duplicati.

**File:** nuovo `R/ui-components.R`, `R/app.R`.

**Componenti minimi:**

```r
studio_page(title, subtitle, toolbar = NULL, content)
studio_toolbar(..., left = NULL, right = NULL)
studio_tabs(id, tabs, selected = NULL)
inspector_panel(title, body, actions = NULL)
empty_state(title, message, action = NULL)
metric_card(label, value, help = NULL)
section_card(title, body, collapsed = FALSE)
split_view(left, right, proportions = c(2, 3))
code_preview(code, language = "r", copy = TRUE)
status_pill(label, status = c("ok", "warning", "error", "muted"))
command_button(id, label, command, icon = NULL)
```

**Token CSS:** definire in `app_css()`:

```css
:root {
  --rcmdr-bg: #f6f7f9;
  --rcmdr-surface: #ffffff;
  --rcmdr-surface-muted: #eef1f5;
  --rcmdr-text: #1f2933;
  --rcmdr-muted: #52606d;
  --rcmdr-border: #dde2e8;
  --rcmdr-primary: #1f3a5f;
  --rcmdr-accent: #0d6efd;
  --rcmdr-danger: #b42318;
  --rcmdr-warning: #b54708;
  --rcmdr-success: #067647;
  --rcmdr-radius: .5rem;
  --rcmdr-space: .75rem;
  --rcmdr-font-size: 1rem;
}
```

Temi: `rcmdr-theme-light`, `rcmdr-theme-dark`, `rcmdr-theme-contrast`;
densità: `rcmdr-density-compact`, `rcmdr-density-comfortable`.

**Test:** `tests/testthat/test-ui-components.R` verifica classi, label e
struttura; nessun colore hardcoded nei nuovi componenti.

**Accettazione:** la shell e almeno un pannello usano i componenti; il tema
scuro non richiede override per ogni elemento.

---

### S0.3 — Shell e information architecture

**Descrizione:** nuova shell con modalità Studio e Classica.

**File:** `R/app.R`, `R/menus.R`, `R/options.R`, nuovo `R/features.R`.

**Modalità Studio:**

```text
Home | Data | Charts | Report | Script | Console | Environment | Help
```

`Console` contiene le sotto-tab `Console`, `Output`, `Messages`.

**Modalità Classica:**

```text
Script | Output | Messages | Plots | Report | Data | Environment | Help
```

**Home (solo Studio):**

- progetti recenti;
- dataset recenti;
- “Continua dove eri rimasto”;
- import rapido;
- template di report;
- stato di salute (R, pandoc, LaTeX, plugin);
- what's new.

**Sidebar:**

- campo di ricerca che filtra l'albero dei menu;
- preferiti con stella;
- recenti;
- collapse/expand all;
- stato di espansione persistito.

**Topbar:**

- nome prodotto;
- trigger command palette (`Ctrl+K`);
- badge dataset/modello;
- lingua;
- tema;
- About.

**Status bar:**

- busy/progress;
- durata sessione;
- dimensione dataset;
- numero comandi e plot;
- ultimo errore con link.

**Test:** `test-app-integration.R` esteso; E2E per entrambe le modalità.

**Accettazione:** nessuna voce di menu persa; Classica invariata; Studio
raggiungibile e persistito.

---

### S0.4 — Command palette

**Descrizione:** ricerca globale e lancio rapido.

**File:** nuovo `R/command-palette.R`, `R/app.R`, `R/app_js()`.

**Indice:**

```r
palette_index(state) -> data.frame(
  id, type, label, path, keywords, enabled, reason, action
)
```

Tipi: `menu`, `dialog`, `help`, `dataset`, `variable`, `history`, `project`.

**Ricerca:** fuzzy match su label, path e keywords; boost per match iniziale e
per i preferiti; limite 20 risultati.

**UI:** modale con input, lista risultati, icona tipo, percorso, stato
abilitato/disabilitato e motivo.

**Azioni:**

- esegue un comando di menu;
- apre un dialogo;
- apre un topic di help;
- attiva un dataset;
- porta alla variabile nel Data Studio;
- rilancia una voce di cronologia;
- apre un progetto recente.

**Tastiera:** `Ctrl+K` apre; `ArrowUp/Down` naviga; `Enter` esegue; `Esc`
chiude.

**Test:** ranking, copertura di tutte le voci implementate, disabled con
motivo, E2E.

**Accettazione:** tutte le voci implementate sono raggiungibili; le voci
disabilitate sono visibili con motivazione.

---

### S0.5 — Cronologia strutturata

**Descrizione:** una cronologia azionabile parallela al log.

**File:** nuovo `R/history.R`, `R/commands.R`, `R/state.R`, `R/app.R`,
`R/dialogs.R`.

**Record:**

```r
list(
  id = "hist-0001",
  time = Sys.time(),
  source = "dialog" | "script" | "console" | "direct",
  command = "summary(Dataset)",
  dialog_id = "numericalSummaries",
  dialog_memory = list(...),
  status = "ok" | "error" | "empty",
  output = character(),
  messages = character(),
  plot_id = NULL,
  duration_ms = 42
)
```

**API:**

```r
history_add(state, entry)
history_recent(state, n = 50)
history_find(state, id)
history_rerun(state, id)
history_open_dialog(state, id)
history_insert_script(state, id)
history_insert_report(state, id)
```

**Integrazione:**

- `run_command()` crea il record e lo chiude a fine esecuzione.
- `apply_dialog_result()` passa `dialog_id` e `memory`.
- `launch()` e `run_script()` passano `source`.
- La Console e lo Script usano lo stesso meccanismo.
- `state$log` resta invariato.

**UI:** card nella Console/Output con comando, stato, durata, output
collassabile, pulsanti `Rerun`, `Apri dialogo`, `Copia`, `Inserisci`.

**Test:** `test-history.R`; `test-commands.R` esistente deve restare verde.

**Accettazione:** ogni comando ha una voce; il log è identico; rerun e insert
funzionano.

---

### S0.6 — Dialog platform 2.0

**Descrizione:** anteprima, preset, validazione e azioni contestuali.

**File:** `R/dialogs.R`, `R/widgets.R`, `R/app.R`.

**Estensioni additive di `dialog_spec()`:**

```r
dialog_spec(
  id, title, ui, on_ok,
  category = NULL,
  keywords = character(),
  preview = TRUE,
  presets = TRUE,
  validate = NULL,
  ...
)
```

Nessun dialogo esistente deve essere riscritto: i nuovi campi sono opzionali.

**Modale:**

- header con titolo, categoria/breadcrumb, help;
- body con tab/sezioni;
- pannello “Comando” collassabile con `code_preview`;
- footer: `Reset`, `Help`, `Anteprima`, `Apply`, `OK`, `Cancel`.

**Anteprima:**

- debounce 300 ms;
- chiama `spec$on_ok(input, state)` in dry-run;
- mostra `result$commands`;
- non chiama `apply_dialog_result()`;
- se `on_ok` restituisce `error`, lo mostra come validazione, non come errore
  fatale.

**Audit di purezza:** aggiungere un test che cerca `run_command(`, assegnazioni
a `state$` e chiamate a `open_dialog()` dentro gli `on_ok`. Se un dialogo
esistente viola la regola, va corretto.

**Preset:**

- `state$dialog_presets[[id]]`: lista nominata di input;
- UI: select preset, salva, elimina, esporta/importa;
- persistenza nel progetto (Onda 7).

**Validazione inline:**

- `on_ok` può restituire `field_errors = list(field = "message")`;
- il runtime mostra il messaggio sotto il campo;
- fallback: toast o banner.

**Azioni:**

- `Apri nello Script`: inserisce il comando senza eseguirlo;
- `Copia comando`;
- `Duplica dialogo`;
- `Salva preset`.

**Test:** `test-dialogs-preview.R`, `test-dialogs-presets.R`,
`test-dialogs-validation.R`.

**Accettazione:** tutti i dialoghi core renderizzano; l'anteprima non produce
side effect; i preset sopravvivono alla sessione.

---

### S0.7 — Preview engine

**Descrizione:** anteprime isolate per grafici, Markdown e output.

**File:** nuovo `R/preview.R`.

**API:**

```r
preview_env(state)
preview_plot(state, code, width = 800, height = 600)
preview_plotly(state, code)
preview_markdown(text)
preview_cleanup()
debounce_reactive(expr, millis = 300)
```

**Regole:**

- ambiente `new.env(parent = state$env)`;
- device grafico temporaneo, sempre chiuso;
- file temporanei tracciati e rimossi;
- timeout e `tryCatch`;
- nessuna scrittura in `state$log`, `state$output`, `state$plots`;
- nessuna modifica a `.GlobalEnv`.

**Test:** `test-preview.R`: stato invariato, cleanup, errore gestito, nessun
plot aggiunto.

**Accettazione:** Chart Studio e Report Studio possono usare il motore senza
inquinare la sessione.

---

### S0.8 — Accessibilità e tastiera

**Descrizione:** baseline di navigazione e scorciatoie.

**File:** `R/app.R`, `R/app_js()`, nuovo `R/shortcuts.R`,
`inst/help-topics/topics/keyboard-shortcuts.md`.

**Scorciatoie:**

| Azione | Scorciatoia |
|---|---|
| Command palette | `Ctrl+K` / `Cmd+K` |
| Esegui selezione o cella | `Ctrl+Enter` |
| Esegui tutto | `Ctrl+Shift+Enter` |
| Salva | `Ctrl+S` |
| Salva come | `Ctrl+Shift+S` |
| Knit | `Ctrl+Alt+K` |
| Cerca nell'help | `Ctrl+/` |
| Chiudi modale | `Esc` |

**Accessibilità:**

- focus visibile su tutti i controlli;
- focus trap nelle modali;
- focus restituito all'elemento di origine;
- `aria-live` per notifiche e risultati;
- `aria-current` per tab e menu;
- contrasto verificato per chiaro, scuro e alto contrasto;
- skip link mantenuto;
- nessun contenuto solo colore.

**Test:** E2E keyboard-only; checklist manuale; axe-core opzionale.

**Accettazione:** un flusso import → summary → plot è completabile da tastiera.

---

### S0.9 — Feature flag e harness

**Descrizione:** attivare le novità in modo controllato.

**File:** `R/options.R`, `R/state.R`, nuovo `R/features.R`, test helper.

**Opzioni:**

```r
state$options$ui_mode <- "studio"
state$options$features <- list(
  command_palette = TRUE,
  history = TRUE,
  dialog_preview = TRUE,
  data_studio = FALSE,
  chart_studio = FALSE,
  report_studio = FALSE,
  console = FALSE,
  project = FALSE
)
```

**Regole:**

- le feature flag disattivano la UI nuova, non il motore;
- la modalità Classica ignora le feature flag non compatibili;
- i test possono attivare selettivamente una feature.

**Test:** `test-features.R`.

**Accettazione:** con tutte le flag nuove a `FALSE`, l'app si comporta come
1.13.0; con le flag a `TRUE`, la shell Studio è attiva.

---

## 5. Riproducibilità

- Le anteprime non generano comandi nel log.
- L'anteprima del dialogo mostra il comando che verrà eseguito, ma non lo
  esegue.
- “Apri nello Script” inserisce il comando senza eseguirlo.
- La cronologia non sostituisce il log: lo affianca.
- Ogni azione che modifica dati o esegue analisi passa da `run_command()`.

---

## 6. Test e accettazione dell'Onda 0

### Unit

- `test-ui-components.R`
- `test-history.R`
- `test-preview.R`
- `test-features.R`
- `test-command-palette.R`
- `test-dialogs-preview.R`
- `test-dialogs-presets.R`
- `test-dialogs-validation.R`

### Integration / E2E

- Avvio in modalità Studio e Classica.
- Palette: cerca e apre un dialogo.
- Dialogo: anteprima comando, OK, comando nel log.
- Cronologia: rerun e inserimento nello Script.
- Tastiera: `Ctrl+K`, `Ctrl+Enter`, `Esc`.
- Tema: chiaro/scuro/alto contrasto senza layout rotti.

### Comandi

- `testthat::test_local()` verde.
- `R CMD check` core pulito.
- `tools/inventory_help.R` e `tools/check_help_links.R --strict` verdi.

### Criterio finale

> Con le feature flag nuove disattivate, il comportamento è quello di
> RcmdrShiny 1.13.0. Con le flag attivate, l'app ha la shell Studio, la
> palette, la cronologia e l'anteprima comando, senza regressioni.

---

## 7. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| `on_ok` con side effect rompe l'anteprima | Audit + test di purezza + dry-run |
| `app.R` cresce ancora | Moduli separati e componenti, non nuovo codice nel monolite |
| Feature flag dimenticate | Test con matrice flag on/off |
| Palette lenta con 863 voci | Indice precalcolato e cache |
| Cronologia troppo grande | Cap configurabile e trimming |
| Tema scuro incompleto | Token CSS e test visivo sulle schermate principali |

---

## 8. Fuori perimetro

- Data/Chart/Report Studio (Onde 1–3).
- Progetto persistente completo (Onda 7).
- Plugin SDK v2 (Onda 7).
- Nuove procedure statistiche.

---

## 9. Checklist di chiusura

- [ ] Identità aggiornata in DESCRIPTION/README/NEWS/UI.
- [ ] Dialogo About.
- [ ] Design system e token.
- [ ] Shell Studio/Classica.
- [ ] Home.
- [ ] Sidebar con ricerca/preferiti/recenti.
- [ ] Command palette.
- [ ] Cronologia strutturata.
- [ ] Anteprima comando nei dialoghi.
- [ ] Preset dialoghi.
- [ ] Validazione inline.
- [ ] Preview engine.
- [ ] Scorciatoie e accessibilità.
- [ ] Feature flag.
- [ ] Test e E2E verdi.
- [ ] Help topic e vignetta aggiornati.
