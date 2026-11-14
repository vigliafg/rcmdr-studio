# Diario di handoff — Onda 2 — Chart Studio

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** Onda 1 — Data Studio  
**Ondata successiva:** Onda 3 — Report Studio  
**Documento di settore:** [`../02-chart-studio.md`](../02-chart-studio.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo:** trasformare il tab Charts in un ambiente di creazione e gestione
grafici — builder visuale, anteprima isolata, comando R equivalente, galleria
con metadati, export PNG/PDF/SVG/HTML, temi, round-trip, selezione — senza
aggiungere procedure statistiche e senza cambiare i comandi dei dialoghi.

**Risultato effettivo:** la modalità Studio ha un **Chart Studio** operativo:

- builder con tipo, dataset, mapping dinamici, opzioni, tema, etichette e
  dimensioni;
- anteprima PNG isolata con debounce e cache;
- comando generato visibile in tempo reale;
- **Apply** che esegue il comando del dialogo equivalente, lo registra nella
  cronologia con sorgente `chart` e allega la specifica al plot;
- galleria con ricerca, filtro per tipo, pin, rinomina, dettaglio, confronto
  via API, copia codice, elimina, export e riapertura nel builder;
- export PNG/PDF/SVG/HTML;
- palette e temi, incluso il motore ggplot2 opt-in;
- selezione plotly e subset dagli punti selezionati;
- pulsante **Advanced** verso il dialogo Rcmdr esistente con memoria
  precompilata.

La modalità **Classica** mantiene il vecchio pannello Plots con la galleria a
filmstrip e gli export PNG/PDF.

**Cosa è pronto:** C2.1–C2.10, con le deviazioni annotate in §6.

**Cosa non è pronto:** Report Studio (Onda 3); UI di confronto affiancato;
builder 3D; anteprima plotly interattiva dentro il builder (l'interattività è
nel pannello di dettaglio della galleria); highlight della selezione senza
subset.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `4e77187` | feat: Wave 2 Chart Studio | Commit principale dell'Onda 2 |
| `f95324a` | docs: record Wave 1 fixes in the diary | Ultimo commit Onda 1 |

Il diario è committato subito dopo il commit principale.

---

## 3. File creati e modificati

### Creati

- `R/chart-spec.R` — `chart_spec()`, validazione, palette, tema, etichette,
  `chart_spec_command()`, `chart_spec_interactive()`, chiave di cache,
  titolo automatico e comando ggplot2.
- `R/chart-types.R` — registry degli undici tipi con mapping, controlli,
  comando, espressione plotly, dialogo avanzato e memoria.
- `R/chart-studio.R` — API galleria (`plot_register`, `plot_list`,
  `plot_update`, `plot_delete`, `plot_export`, `plot_reopen`,
  `plot_compare`), cache preview, `chart_preview()`, `chart_apply()`, UI
  Build/Gallery, dialogs `chartRename`, `chartDelete`, `chartExport` e
  `chart_studio_server()`.
- `inst/help-topics/topics/chart-studio.md` — topic Chart Studio.
- `vignettes/chart-studio.Rmd` — spec → preview → apply → gallery → export.
- `tests/testthat/helper-chart.R` — stato e dataset condivisi.
- `tests/testthat/test-chart-spec.R`
- `tests/testthat/test-chart-types.R`
- `tests/testthat/test-chart-preview.R`
- `tests/testthat/test-chart-apply.R`
- `tests/testthat/test-chart-gallery.R`
- `tests/testthat/test-chart-theme.R`
- `tests/testthat/test-chart-export.R`
- `tests/testthat/test-chart-roundtrip.R`
- `tests/testthat/test-chart-studio.R`
- `tests/testthat/test-chart-studio-e2e.R`

### Modificati

- `R/state.R` — `plot_counter`, `chart_last_spec`, `chart_selection`,
  opzioni `chart_preview_width`, `chart_preview_height`,
  `chart_preview_cache`.
- `R/commands.R` — `run_plot_command()` registra id, spec, titolo, tag e pin
  tramite `plot_register()`.
- `R/plotly.R` — gli builder plotly includono `source = "rcmdr-chart"`;
  lo scatter registra `plotly_selected`.
- `R/app.R` — `classic_plots_pane_ui()` separato, `plots_pane_ui(mode)`,
  Charts in Studio usa Chart Studio, wiring del server, CSS della galleria e
  dei dettagli, `chart_revision`.
- `R/dialogs.R` — registrati `chart_studio_dialogs()`.
- `R/history-ui.R` — sorgente `chart` nella cronologia.
- `R/features.R` — `chart_studio = TRUE`.
- `DESCRIPTION` — versione 1.16.0, descrizione, URL/BugReports del repo
  `rcmdr-studio`, `htmlwidgets` e `svglite` in Suggests.
- `README.md`, `NEWS.md` — stato e funzioni Wave 2.
- `_pkgdown.yml` — vignetta `chart-studio`.
- `inst/help-topics/index.yml` — topic `chart-studio`.
- `inst/etc/help-inventory.csv` — rigenerato.
- `tests/testthat/test-shinytest2.R` — il tab Charts verifica le card della
  nuova galleria.
- `tests/testthat/test-wave0.R` — sorgenti cronologia aggiornate con `chart`.
- `docs/upgrades/02-chart-studio.md`, `CHECKLIST.md`, `README.md` — stato
  Onda 2.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **2004 pass, 0 fail, 11 skip** |
| E2E core | `... test-shinytest2.R` | **15 pass** |
| E2E Wave 0 | `... test-wave0-e2e.R` | **3 pass** |
| E2E documenti | `... test-documents-e2e.R` | **8 pass** |
| E2E Data Studio | `... test-data-studio-e2e.R` | **6 pass** |
| E2E Chart Studio | `... test-chart-studio-e2e.R` | **7 pass** |
| E2E plugin | `... test-plugins-e2e.R` | **19 pass** |
| `R CMD check` | `_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual` | **Status: OK** |
| Help inventory | `Rscript tools/inventory_help.R --plugins all` | 637 documented, 55 extra, 3 fallback |
| Link checker | `Rscript tools/check_help_links.R --strict` | 446 topic, nessun link rotto |

Gli skip sono i test E2E/visual opt-in. Resta il warning cosmetico di
`shinytest2` “Failed to locate globals in server function” per `renderPlot`.

---

## 5. Decisioni e ADR

- **La specifica è l'unica fonte di verità.** Builder, anteprima, comando,
  galleria e round-trip derivano tutti da `chart_spec`. La spec viene allegata
  al plot applicato.
- **Comando del dialogo, non un secondo dialetto.** Con tema default ed
  etichette vuote, `chart_spec_command()` coincide con il builder del dialogo.
  Palette, `par()` ed etichette sono prefissi/suffissi emessi solo quando
  l'utente li cambia.
- **Preview isolata.** `chart_preview()` usa `preview_plot()` e non chiama
  `run_command()`; non logga e non aggiunge plot. Debounce 350 ms e cache
  limitata a 12 voci, invalidata da `state$revision`.
- **Apply atomico.** `chart_apply()` valida, esegue il comando e allega la
  spec solo se il comando ha avuto successo. Un errore non registra il plot.
- **Dialoghi invece di modali ad hoc.** Rinomina, eliminazione ed export usano
  `dialog_spec()` e il runtime standard, come in Onda 1.
- **Galleria con link inline.** Le azioni delle card usano
  `Shiny.setInputValue('chart_action', ...)` invece di actionButton dinamici,
  per evitare i problemi di ri-rendering già visti nel Data Studio.
- **Motore ggplot2 opt-in.** Il motore base resta il default. ggplot2 è
  disponibile solo se installato e solo per i tipi supportati.
- **Selezione plotly con observer lazy.** L'observer `plotly_selected` viene
  creato solo dopo che un widget interattivo ha registrato la source, per
  evitare il warning di plotly su source non registrata.
- **Export tramite downloadButton nascosti.** Il dialogo di export imposta
  `state$chart_export_request` e usa `request_download()` verso gli handler
  statici; le azioni inline della galleria fanno lo stesso.
- **Nessuna nuova dipendenza obbligatoria.** `plotly` era già Suggests;
  `htmlwidgets` e `svglite` sono aggiunti a Suggests.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| C2.2 | Modalità Build / Gallery / Detail | Build e Gallery; il dettaglio è un pannello della galleria | Meno navigazione, stesso contenuto |
| C2.3 | Preview live anche plotly | Immagine PNG nel builder, plotly nel dettaglio della galleria | Evita widget instabili dentro un `uiOutput` che si ri-renderizza |
| C2.5 | Confronto affiancato in UI | API `plot_compare()` e dettaglio singolo | Il confronto visuale richiede un layout dedicato; rinviato |
| C2.6 | SVG sempre | SVG solo se `svglite` è installato, altrimenti device cairo | Coerente con il principio “disabilitato con spiegazione” |
| C2.9 | Brush + highlight | Selezione plotly e subset per scatter senza gruppi | Il mapping dei punti con gruppi richiede una logica per curva; rinviato |
| C2.10 | E2E istogramma, scatter, boxplot | E2E istogramma completo (build, apply, pin, rename, reopen, export) | Lo scatter/boxplot sono coperti dagli unit test dei comandi e della preview |
| — | 3D nel builder | Resta il dialogo rgl esistente | Fuori perimetro: nessun nuovo tipo |
| — | Anteprima interattiva nel builder | Solo PNG | Affidabilità in Shiny/Bootstrap 5 |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| Warning `shinytest2` sui globals di `renderPlot` | Rumore nei log E2E | Ignorabile; i test passano | C2.10 |
| Il dettaglio plotly può emettere un errore client `GLOBAL is not defined` in shinytest2 | Cosmetico; il widget e i test funzionano | Nessuna azione | C2.5 |
| Le thumbnail richiedono `state$plot_dir` | In embedding senza directory la card mostra “No preview” | L'app normale imposta `plot_dir` | C2.5 |
| `chart_preview()` allega `RcmdrMisc`/`car` quando il comando li usa | Side effect sul search path, come il motore comandi | Documentato | C2.3 |
| Un env personalizzato con catena che non raggiunge il search path non vede i package appena allegati | Comandi `Hist`/`scatterplot` possono fallire in test embedded | Usare un env con parent `globalenv()` o l'env di default | — |
| “Add to report” è solo una notifica | Il report include già tutti i plot | Esportare dal tab Report | C2.5 |
| Nessuna UI di confronto affiancato | Solo API | Dettaglio singolo | C2.5 |

---

## 8. Domande aperte

- [ ] Il confronto affiancato deve stare nella galleria o in una tab dedicata?
- [ ] L'anteprima plotly interattiva va spostata anche nel builder?
- [ ] Il builder 3D deve esistere o resta solo il dialogo rgl?
- [ ] Il subset da selezione deve supportare anche scatter con gruppi?
- [ ] L'export deve ricordare l'ultimo formato e le ultime dimensioni?
- [ ] “Add to report” deve selezionare i plot da includere invece di includerli
  tutti?
- [ ] Il titolo rinominato nella galleria deve diventare un'etichetta della
  spec al prossimo apply?

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../03-report-studio.md` e `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: **2004 pass, 0 fail, 11 skip**).
3. Avviare l'Onda 3 dal task **R3.1 — Registro documenti**.

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| R3.1 | Registro documenti | Alta | Riusa `state$document` |
| R3.2 | Report Studio UI | Alta | Home/Report |
| R3.3 | Outline e chunk list | Alta | Documento Rmd |
| R3.4 | Preview Markdown/HTML | Alta | `preview_markdown()` |
| R3.5 | Celle eseguibili | Alta | `run_command()` |
| R3.6 | Template gallery | Media | Template Rmd |
| R3.7 | Inserimento contestuale | Alta | Grafici e output |
| R3.8 | YAML form e bibliografia | Media | Header Rmd |
| R3.9 | Knit manager | Alta | `rmarkdown` |
| R3.10 | Autosave e recovery | Media | Sessione |
| R3.11 | Test, help, vignetta | Alta | E2E Report |

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
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-chart-studio-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
```

**Baseline attesa:** 2004 pass, 0 fail, 11 skip; `R CMD check` OK.

---

## 11. Note di contesto

- Il package installato è stato aggiornato a 1.16.0 durante gli E2E; dopo
  modifiche al codice serve `R CMD INSTALL .` prima degli E2E.
- `state$plots` è la galleria: ogni voce ha `id`, `spec`, `title`, `tags`,
  `pinned`, `url`, `file`, `recorded`, `code`, `time`.
- `plot_register()` assegna un id stabile e incrementa `plot_counter`; i plot
  creati da dialoghi e script passano da `run_plot_command()` e quindi entrano
  nella galleria.
- `chart_apply()` chiama `run_command()` con `source = "chart"` e
  `dialog_id = "chartStudio"`.
- `chart_spec_command()` è la funzione da testare per la parità con i builder
  dei dialoghi.
- La cache preview è in `.chart_preview_cache` e si svuota con
  `chart_preview_cache_clear()`.
- Il server Chart Studio è `chart_studio_server(input, output, session, state,
  chart_revision, refresh, tick)`; gli output hanno id `chart_*`.
- `output$chart_detail_plotly_ui` e `output$chart_detail_plotly` sono
  disponibili solo con plotly installato.
- Le azioni della galleria usano l'input `chart_action` con
  `list(index, action)`.
- I download usano `state$chart_export_request` e gli handler
  `chart_download_png/pdf/svg/html` (bottoni nascosti in `chart_studio_ui()`).
- In Classic mode `plots_pane_ui("classic")` mantiene la galleria storica e i
  suoi output; in Studio mode il tab Charts usa `chart_studio_ui()`.
- I test Chart usano `helper-chart.R` con `new.env(parent = globalenv())`.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “diario pronto, puoi compattare il contesto”.
