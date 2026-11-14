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
| C2.1 | Chart spec e registry | [ ] | |
| C2.2 | Builder UI | [ ] | |
| C2.3 | Preview live | [ ] | |
| C2.4 | Apply e registrazione | [ ] | |
| C2.5 | Galleria evoluta | [ ] | |
| C2.6 | Export | [ ] | |
| C2.7 | Temi e palette | [ ] | |
| C2.8 | Round-trip e reopen | [ ] | |
| C2.9 | Selezione e brush | [ ] | |
| C2.10 | Test, help, vignetta | [ ] | |

### Chiusura Onda 2

- [ ] Build → preview → apply → gallery → export.
- [ ] Comando applicato identico al dialogo.
- [ ] Round-trip fedele.
- [ ] Export PNG/PDF/SVG/HTML.
- [ ] Temi e palette.
- [ ] Advanced verso dialogo esistente.
- [ ] E2E verde.
- [ ] Help topic e vignetta.

---

## Onda 3 — Report Studio

| ID | Task | Stato | Note |
|---|---|---|---|
| R3.1 | Registro documenti | [ ] | |
| R3.2 | Report Studio UI | [ ] | |
| R3.3 | Outline e chunk list | [ ] | |
| R3.4 | Preview Markdown/HTML | [ ] | |
| R3.5 | Celle eseguibili | [ ] | |
| R3.6 | Template gallery | [ ] | |
| R3.7 | Inserimento contestuale | [ ] | |
| R3.8 | YAML form e bibliografia | [ ] | |
| R3.9 | Knit manager | [ ] | |
| R3.10 | Autosave e recovery | [ ] | |
| R3.11 | Test, help, vignetta | [ ] | |

### Chiusura Onda 3

- [ ] Template → insert → preview → knit → download.
- [ ] Preview veloce non esegue codice.
- [ ] Celle con output inline.
- [ ] YAML round-trip conservativo.
- [ ] Knit history e errori contestualizzati.
- [ ] Autosave/recovery.
- [ ] E2E verde.
- [ ] Help topic e vignetta.

---

## Onda 4 — Workbench

| ID | Task | Stato | Note |
|---|---|---|---|
| W4.1 | Registro script e tab | [ ] | |
| W4.2 | Celle e run above/below | [ ] | |
| W4.3 | Outline e diagnostica | [ ] | |
| W4.4 | Find/replace e autocomplete | [ ] | |
| W4.5 | Format e autosave | [ ] | |
| W4.6 | Console UI e input | [ ] | |
| W4.7 | Storico comandi | [ ] | |
| W4.8 | Output card e rerun | [ ] | |
| W4.9 | Rilevamento comandi interattivi | [ ] | |
| W4.10 | Output cards | [ ] | |
| W4.11 | Ricerca/filtri output | [ ] | |
| W4.12 | Messages per severità | [ ] | |
| W4.13 | Object explorer | [ ] | |
| W4.14 | Anteprima oggetto | [ ] | |
| W4.15 | Azioni rapide | [ ] | |
| W4.16 | Dataset registry view | [ ] | |
| W4.17 | Model registry | [ ] | |
| W4.18 | Model registry UI | [ ] | |
| W4.19 | Dashboard tabella/confronto | [ ] | |
| W4.20 | Azioni modello | [ ] | |
| W4.21 | Reopen dialog con memoria | [ ] | |

### Chiusura Onda 4

- [ ] Console, Script e dialoghi condividono log/cronologia.
- [ ] Output cards con rerun.
- [ ] Environment con anteprima e azioni.
- [ ] Models dashboard.
- [ ] Limiti console documentati.
- [ ] E2E verde.
- [ ] Help topic e vignetta.

---

## Onda 5 — Navigazione, dialoghi, workflow

| ID | Task | Stato | Note |
|---|---|---|---|
| N5.1 | Palette evoluta | [ ] | |
| N5.2 | Preferiti/recenti | [ ] | |
| N5.3 | Menu search | [ ] | |
| N5.4 | Breadcrumb | [ ] | |
| N5.5 | Scorciatoie complete | [ ] | |
| N5.6 | Preview completa | [ ] | |
| N5.7 | Preset UI e persistenza | [ ] | |
| N5.8 | Validazione inline | [ ] | |
| N5.9 | Selector arricchiti | [ ] | |
| N5.10 | Responsive e accessibilità dialogo | [ ] | |
| N5.11 | Workflow model e registry | [ ] | |
| N5.12 | Workflow UI | [ ] | |
| N5.13 | Integrazione dialoghi/cronologia | [ ] | |
| N5.14 | Cinque workflow iniziali | [ ] | |
| N5.15 | Generazione sezione report | [ ] | |
| N5.16 | Suggerimenti per variabile | [ ] | |
| N5.17 | UI inspector/menu | [ ] | |

### Chiusura Onda 5

- [ ] Palette, preferiti, recenti, menu search.
- [ ] Preset e validazione.
- [ ] Cinque workflow.
- [ ] Suggerimenti contestuali.
- [ ] E2E verde.
- [ ] Help topic e vignetta.

---

## Onda 6 — Help, i18n, onboarding

| ID | Task | Stato | Note |
|---|---|---|---|
| H6.1 | Indice full-text | [ ] | |
| H6.2 | Ranking e filtri | [ ] | |
| H6.3 | Snippet e correlati | [ ] | |
| H6.4 | Topic TOC e link | [ ] | |
| H6.5 | “Try it” | [ ] | |
| H6.6 | Parser esempi | [ ] | |
| H6.7 | UI esempi e conferma | [ ] | |
| H6.8 | Esecuzione loggata | [ ] | |
| H6.9 | Mappa errori | [ ] | |
| H6.10 | UI errore contestuale | [ ] | |
| H6.11 | Glossario | [ ] | |
| H6.12 | Scorciatoie aggiornate | [ ] | |
| H6.13 | Tour engine | [ ] | |
| H6.14 | Tour UI e persistenza | [ ] | |
| H6.15 | Checklist Home | [ ] | |
| H6.16 | Audit stringhe | [ ] | |
| H6.17 | Topic italiani | [ ] | |
| H6.18 | Lingua reattiva | [ ] | |
| H6.19 | Persistenza lingua | [ ] | |

### Chiusura Onda 6

- [ ] Ricerca full-text e filtri.
- [ ] “Try it” tracciato.
- [ ] Mappa errori.
- [ ] Glossario e scorciatoie.
- [ ] Tour e checklist.
- [ ] Italiano completo.
- [ ] Cambio lingua live o fallback documentato.
- [ ] E2E verde.

---

## Onda 7 — Piattaforma, plugin, qualità

| ID | Task | Stato | Note |
|---|---|---|---|
| P7.1 | Schema progetto | [ ] | |
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
```
