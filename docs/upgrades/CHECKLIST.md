# Checklist di implementazione — RcmdrShiny Studio

**Baseline:** RcmdrShiny 1.13.0 (`rstats-commander`, congelato)  
**Repository:** `rcmdr-studio`  
**Legenda:** `[ ]` da fare · `[~]` in corso · `[x]` fatto · `[!]` bloccato · `[-]` rinviato

Aggiornare questa checklist a ogni task chiuso, citando commit o PR nella
colonna Note.

---

## Onda 0 — Fondazioni

| ID | Task | Stato | Note |
|---|---|---|---|
| S0.1 | Identità e documentazione | [x] | DESCRIPTION/README/NEWS/About/help topic |
| S0.2 | Design system e token | [x] | `R/ui-components.R`, CSS tokens, themes |
| S0.3 | Shell e IA Studio/Classica | [x] | Home, Console grouping, sidebar search |
| S0.4 | Command palette | [x] | Menus, help, data, variables, history |
| S0.5 | Cronologia strutturata | [x] | `R/history.R`, cards, rerun, insert |
| S0.6 | Dialog platform 2.0 | [x] | Preview, presets, To script; field-level validation deferred |
| S0.7 | Preview engine | [x] | `R/preview.R`, isolated, no side effects |
| S0.8 | Accessibilità e tastiera | [x] | Shortcuts, focus, ARIA baseline; full audit in Onda 7 |
| S0.9 | Feature flag e harness | [x] | `R/features.R`, flags, tests |

### Chiusura Onda 0

- [x] Identità aggiornata in DESCRIPTION/README/NEWS/UI.
- [x] Dialogo About.
- [x] Shell Studio/Classica.
- [x] Home.
- [x] Sidebar ricerca/preferiti/recenti.
- [x] Palette copre tutte le voci implementate.
- [x] Cronologia con rerun/edit/insert.
- [x] Anteprima comando senza side effect.
- [x] Preset e validazione dialoghi.
- [x] Preview engine isolato.
- [x] Scorciatoie e accessibilità.
- [x] Feature flag.
- [x] Test e E2E verdi.
- [x] Help topic e vignetta.

---

## Onda 1 — Data Studio

| ID | Task | Stato | Note |
|---|---|---|---|
| D1.1 | Registro dataset | [x] | `R/data-studio.R`, selettore attivo |
| D1.2 | Griglia, ricerca, filtri, selezione | [x] | DT, filtro vista, selezione originale |
| D1.3 | Inspector di colonna | [x] | `column_profile()`, grafico compatto |
| D1.4 | Operazioni su colonne | [x] | Builder + dialoghi |
| D1.5 | Operazioni su righe | [x] | Builder + selezione |
| D1.6 | Undo e checkpoint | [x] | `R/data-studio.R`, ripristino di sessione |
| D1.7 | Data dictionary | [x] | Attributi, tabella, CSV/YAML |
| D1.8 | Import wizard | [x] | `dataImportWizard`, anteprima |
| D1.9 | Fallback big data | [x] | Modalità targeted |
| D1.10 | Selezione → analisi | [x] | Subset comandato |
| D1.11 | Test, help, vignetta | [x] | Unit, E2E, topic, vignetta |

### Chiusura Onda 1

- [x] Ciclo import → ispeziona → pulisci → deriva → esporta.
- [x] Dataset grandi non disabilitati.
- [x] Ogni mutazione genera un comando.
- [x] Filtro vista vs subset distinto.
- [x] Undo/checkpoint documentato come sessione.
- [x] E2E verde.
- [x] Help topic e vignetta.

---

## Onda 2 — Chart Studio

| ID | Task | Stato | Note |
|---|---|---|---|
| C2.1 | Chart spec e registry | [x] | `R/chart-spec.R`, `R/chart-types.R` |
| C2.2 | Builder UI | [x] | `R/chart-studio.R`, layout Build/Gallery |
| C2.3 | Preview live | [x] | Preview isolata, debounce, cache |
| C2.4 | Apply e registrazione | [x] | Comando loggato, spec allegata |
| C2.5 | Galleria evoluta | [x] | Ricerca, pin, rinomina, dettaglio, confronto |
| C2.6 | Export | [x] | PNG/PDF/SVG/HTML |
| C2.7 | Temi e palette | [x] | Palette, sfondo, base size, ggplot2 |
| C2.8 | Round-trip e reopen | [x] | Spec conservata e riaperta |
| C2.9 | Selezione e brush | [x] | Plotly + subset dagli punti |
| C2.10 | Test, help, vignetta | [x] | Unit, E2E, topic, vignetta |

### Chiusura Onda 2

- [x] Build → preview → apply → gallery → export.
- [x] Comando applicato identico al dialogo.
- [x] Round-trip fedele.
- [x] Export PNG/PDF/SVG/HTML.
- [x] Temi e palette.
- [x] Advanced verso dialogo esistente.
- [x] E2E verde.
- [x] Help topic e vignetta.

---

## Onda 3 — Report Studio

| ID | Task | Stato | Note |
|---|---|---|---|
| R3.1 | Registro documenti | [x] | `R/document.R`, multi-documento |
| R3.2 | Report Studio UI | [x] | `R/report-studio.R`, toolbar/outline/editor/preview |
| R3.3 | Outline e chunk list | [x] | `document_outline()`, `document_chunks()` |
| R3.4 | Preview Markdown/HTML | [x] | commonmark, placeholder, HTML da knit |
| R3.5 | Celle eseguibili | [x] | `report_run_cell()`, output inline |
| R3.6 | Template gallery | [x] | Cinque template e card |
| R3.7 | Inserimento contestuale | [x] | Output, plot, storia, tabella, profilo, modello |
| R3.8 | YAML form e bibliografia | [x] | Round-trip conservativo |
| R3.9 | Knit manager | [x] | Formati, storico, errori, download |
| R3.10 | Autosave e recovery | [x] | Autosave, banner, `.bak` |
| R3.11 | Test, help, vignetta | [x] | Unit, E2E, topic, vignetta |

### Chiusura Onda 3

- [x] Template → insert → preview → knit → download.
- [x] Preview veloce non esegue codice.
- [x] Celle con output inline.
- [x] YAML round-trip conservativo.
- [x] Knit history e errori contestualizzati.
- [x] Autosave/recovery.
- [x] E2E verde.
- [x] Help topic e vignetta.

---

## Onda 4 — Workbench

| ID | Task | Stato | Note |
|---|---|---|---|
| W4.1 | Registro script e tab | [x] | `R/script-studio.R`, documenti condivisi |
| W4.2 | Celle e run above/below | [x] | `script_cells()`, run cell/above/below |
| W4.3 | Outline e diagnostica | [x] | `script_outline()`, `script_diagnostics()` |
| W4.4 | Find/replace e autocomplete | [x] | Barra find + completamento Ace |
| W4.5 | Format e autosave | [x] | `styler` opzionale, autosave condiviso |
| W4.6 | Console UI e input | [x] | `R/console-studio.R` |
| W4.7 | Storico comandi | [x] | Recall con frecce, limite opzione |
| W4.8 | Output card e rerun | [x] | Card con rerun/dialogo/script |
| W4.9 | Rilevamento comandi interattivi | [x] | Guardia console documentata |
| W4.10 | Output cards | [x] | Card filtrabili con pin |
| W4.11 | Ricerca/filtri output | [x] | Testo, stato, fonte |
| W4.12 | Messages per severità | [x] | `message_add()`, filtro |
| W4.13 | Object explorer | [x] | `object_list()` |
| W4.14 | Anteprima oggetto | [x] | `object_preview()` read-only |
| W4.15 | Azioni rapide | [x] | Summary/str/Plot/Save/Remove |
| W4.16 | Dataset registry view | [x] | Vista Data sets |
| W4.17 | Model registry | [x] | `model_registry()` |
| W4.18 | Model registry UI | [x] | Tab Models |
| W4.19 | Dashboard tabella/confronto | [x] | AIC/BIC e delta |
| W4.20 | Azioni modello | [x] | Comandi esistenti |
| W4.21 | Reopen dialog con memoria | [x] | Memoria da history |

### Chiusura Onda 4

- [x] Console, Script e dialoghi condividono log/cronologia.
- [x] Output cards con rerun.
- [x] Environment con anteprima e azioni.
- [x] Models dashboard.
- [x] Limiti console documentati.
- [x] E2E verde.
- [x] Help topic e vignetta.

---

## Onda 5 — Navigazione, dialoghi, workflow

| ID | Task | Stato | Note |
|---|---|---|---|
| N5.1 | Palette evoluta | [x] | completato |
| N5.2 | Preferiti/recenti | [x] | completato |
| N5.3 | Menu search | [x] | completato |
| N5.4 | Breadcrumb | [x] | completato |
| N5.5 | Scorciatoie complete | [x] | completato |
| N5.6 | Preview completa | [x] | completato |
| N5.7 | Preset UI e persistenza | [x] | completato |
| N5.8 | Validazione inline | [x] | completato |
| N5.9 | Selector arricchiti | [x] | completato |
| N5.10 | Responsive e accessibilità dialogo | [x] | completato |
| N5.11 | Workflow model e registry | [x] | completato |
| N5.12 | Workflow UI | [x] | completato |
| N5.13 | Integrazione dialoghi/cronologia | [x] | completato |
| N5.14 | Cinque workflow iniziali | [x] | completato |
| N5.15 | Generazione sezione report | [x] | completato |
| N5.16 | Suggerimenti per variabile | [x] | completato |
| N5.17 | UI inspector/menu | [x] | completato |

### Chiusura Onda 5

- [x] Palette, preferiti, recenti, menu search.
- [x] Preset e validazione.
- [x] Cinque workflow.
- [x] Suggerimenti contestuali.
- [x] E2E verde.
- [x] Help topic e vignetta.

---

## Onda 6 — Help, i18n, onboarding

| ID | Task | Stato | Note |
|---|---|---|---|
| H6.1 | Indice full-text | [x] | `R/help-index.R`; indice per revisione/lingua |
| H6.2 | Ranking e filtri | [x] | pesi 5/4/3/1, boost titolo, filtri tipo/origine/categoria |
| H6.3 | Snippet e correlati | [x] | snippet con `<mark>`, correlati, comandi e dialoghi |
| H6.4 | Topic TOC e link | [x] | TOC con ancore, link topic/dialoghi/comandi |
| H6.5 | “Try it” | [x] | conferma, dataset, `run_command(source="help")` |
| H6.6 | Parser esempi | [x] | `help_parse_examples()`, solo `runnable: true` |
| H6.7 | UI esempi e conferma | [x] | Esegui/Copia/Inserisci nello script |
| H6.8 | Esecuzione loggata | [x] | history con `source = "help"` e output |
| H6.9 | Mappa errori | [x] | `R/help-errors.R`, pattern conservativi |
| H6.10 | UI errore contestuale | [x] | link nella card errore, messages e modal dialogo |
| H6.11 | Glossario | [x] | `glossary` + traduzione italiana |
| H6.12 | Scorciatoie aggiornate | [x] | `keyboard-shortcuts` aggiornato (help, tour, lingua) |
| H6.13 | Tour engine | [x] | `R/onboarding.R`, quattro passi |
| H6.14 | Tour UI e persistenza | [x] | modal, highlight, localStorage, Help > Tour guidato |
| H6.15 | Checklist Home | [x] | checklist Home; progetto gated su feature flag |
| H6.16 | Audit stringhe | [x] | `tools/audit_i18n.R`, step CI |
| H6.17 | Topic italiani | [x] | 27 topic core italiani + overlay TSV Studio |
| H6.18 | Lingua reattiva | [x] | catalogo PO/TSV live; topbar, menu, tab, help, messaggi |
| H6.19 | Persistenza lingua | [x] | lingua e tema in `preferences.rds` |

### Chiusura Onda 6

- [x] Ricerca full-text e filtri. — indice, ranking, filtri e snippet
- [x] “Try it” tracciato. — esempi runnable, conferma, log
- [x] Mappa errori. — errori → topic in card e dialoghi
- [x] Glossario e scorciatoie. — glossary e keyboard-shortcuts
- [x] Tour e checklist. — tour + checklist Home
- [x] Italiano completo. — 27 topic core + overlay UI; fallback inglese
- [x] Cambio lingua live o fallback documentato. — live per menu/tab/help/messaggi; chrome statico al reload
- [x] E2E verde. — help/onboarding E2E e navigation E2E verdi

---

## Onda 6.5 — Piattaforma menu e ID stabili

Direttiva: plugin first-party, menubar orizzontale in stile SPSS/Minitab, ID
stabili per menu e voci. I command ID del motore restano invariati.

| ID | Task | Stato | Note |
|---|---|---|---|
| M6.5.1 | Schema, costruttori e validatore ID | [x] | `R/menu-registry.R`: schema, costruttori, validazione, migrazione |
| M6.5.2 | Registry core e mappatura voci | [x] | `inst/menus/core.yml`: 9 gruppi top-level, File > Save curato |
| M6.5.3 | Frammenti menu dei 15 moduli | [x] | `plugins/*/inst/menus/module.yml`: 15 moduli, nessuna perdita comandi |
| M6.5.4 | Loader, merge e migrazione preferiti | [x] | loader, merge, remove per comando, migrazione espansione |
| M6.5.5 | Menubar UI, tastiera, ARIA, responsive | [x] | menubar `<details>` multilivello, tastiera, responsive, CSS dark |
| M6.5.6 | Palette, breadcrumb, help e ricerca | [x] | palette/breadcrumb/help su path e ID nuovi |
| M6.5.7 | Test golden, E2E, documentazione e vignetta | [x] | test registry/migrazione/E2E, topic e vignetta |

### Chiusura Onda 6.5

- [x] Nessun ID posizionale (`menu_item_N`) nel DOM.
- [x] `menu_id` e `item_id` unici, stabili e validati.
- [x] Tutti i `command_id` esistenti ancora raggiungibili.
- [x] Preferiti, recenti ed espansione migrati.
- [x] Menubar accessibile e responsive.
- [x] 15 moduli first-party caricati dal nuovo registry.
- [x] Palette, breadcrumb e help allineati.
- [x] E2E e test golden verdi.

---

## Onda 7 — Piattaforma, plugin, qualità

| ID | Task | Stato | Note |
|---|---|---|---|
| P7.1 | Schema progetto | [x] | Schema, validazione, migrazione e path helper in `R/project.R`; 88 test |
| P7.2 | Save/load progetto | [ ] | |
| P7.3 | Recent projects | [ ] | |
| P7.4 | Autosave/recovery | [ ] | |
| P7.5 | Export bundle | [ ] | |
| P7.6 | Home progetti | [ ] | |
| P7.7 | Checkpoint sessione | [ ] | |
| P7.8 | Recovery prompt | [ ] | |
| P7.9 | Lazy plugin/cataloghi | [ ] | |
| P7.10 | Cache help/menu | [ ] | |
| P7.11 | Benchmark suite | [ ] | |
| P7.12 | Trimming e cap | [ ] | |
| P7.13 | API plugin v2 | [ ] | |
| P7.14 | Nuovi hook | [ ] | |
| P7.15 | Documentazione plugin | [ ] | |
| P7.16 | Test 15 plugin | [ ] | |
| P7.17 | Health panel | [ ] | |
| P7.18 | Diagnostics esteso | [ ] | |
| P7.19 | Matrice test | [ ] | |
| P7.20 | Visual regression | [ ] | |
| P7.21 | Accessibility checklist | [ ] | |
| P7.22 | Release checklist Studio | [ ] | |

### Chiusura Onda 7

- [ ] Progetto salvabile e recuperabile.
- [ ] Bundle esportabile.
- [ ] Performance entro budget.
- [ ] Plugin SDK v2 documentato e testato.
- [ ] Health e diagnostics.
- [ ] Release criteria soddisfatti.

---

## Test e verifica continua

- [ ] `testthat::test_local()` verde.
- [ ] `R CMD check` core pulito.
- [ ] `R CMD check` 15 plugin pulito.
- [ ] `tools/inventory_help.R --plugins all` senza missing/draft.
- [ ] `tools/check_help_links.R --strict` senza link rotti.
- [ ] `RCMDRSHINY_E2E=1` flussi Studio e Classica verdi.
- [ ] Benchmark registrati.
- [ ] Accessibility checklist completata.

---

## Note di avanzamento

Usare questa sezione per decisioni, blocchi e deviazioni:

```text
2026-11-14 — Creazione repository rcmdr-studio e piano di upgrade.
2026-11-14 — Onda 0 completata: Studio shell, palette, cronologia,
             anteprima comando, preset, preview isolata, temi, Console minima.
             Test unit 1401 pass; E2E core, documenti, plugin e Wave 0 verdi.
2026-11-14 — Onda 1 completata: Data Studio con registro dataset, griglia,
             inspector, operazioni strutturali, checkpoint, dizionario,
             import wizard e fallback targeted. Test unit 1632 pass; E2E
             core, Wave 0, documenti e Data Studio verdi.
2026-11-14 — Onda 2 completata: Chart Studio con chart spec, registry tipi,
             builder, preview isolata, apply loggato, galleria con metadati,
             export PNG/PDF/SVG/HTML, temi, round-trip, selezione plotly,
             topic e vignetta. Test unit 2004 pass; E2E core, Wave 0,
             documenti, Data Studio e Chart Studio verdi.
2026-11-14 — Onda 3 completata: Report Studio con registro documenti,
             outline, chunk list, preview Markdown veloce, celle eseguibili,
             template, inserimento contestuale, YAML conservativo, knit
             manager, autosave/recovery, topic e vignetta.
2026-11-14 — Onda 4 completata: Workbench con tab script, celle e run
             above/below, outline e diagnostica, find/replace, format e
             autosave, console con storico, output cards e filtri, messages
             per severità, object explorer, dataset registry e models
             dashboard con reopen dialog.
2026-11-14 — Onda 5 completata: palette evoluta con filtri e azioni,
             preferiti/recenti persistiti, menu search con evidenziazione,
             breadcrumb, scorciatoie complete, preview e preset dialoghi,
             validazione inline, selector descrittivi, cinque workflow con
             stato e sezione report, suggerimenti per variabile. Nuovo topic
             `navigation-workflows` e vignetta.
2026-11-14 — Onda 6 completata: indice full-text con ranking e filtri,
             snippet evidenziati, TOC e link a dialoghi/comandi, esempi
             runnable con conferma e log, mappa errori → topic, glossario,
             tour in quattro passi con localStorage, checklist Home, audit
             i18n, 27 topic core italiani e overlay TSV per la UI, cambio
             lingua live con persistenza di lingua e tema. Nuovo topic
             `glossary` e vignetta `help-and-onboarding`.
2026-11-14 — Onda 6.5 completata: menubar orizzontale a 9 gruppi con
             sottomenu annidati, registry `inst/menus/core.yml`, frammenti
             `plugins/*/inst/menus/module.yml`, `menu_id`/`item_id` stabili,
             `File > Save` unico con sotto-voci per formato, migrazione
             espansione, validazione e test golden di copertura comandi.
             Nuovo topic `menu-structure` e vignetta `menu-platform`.
2026-11-14 — Onda 7 avviata: P7.1 schema progetto completato in
             `R/project.R` con costruttori di voce, validazione pura,
             migrazione v0→v1, normalizzazione e helper di path relativi
             contenuti nel progetto. 88 test dedicati; suite 3020 pass.
```
