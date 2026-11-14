# Diario di handoff — Onda 6 — Help, i18n e onboarding

**Data:** 2026-11-14  
**Stato:** completata  
**Ondata precedente:** `wave-05-navigation-dialogs-workflows.md`  
**Ondata successiva:** Onda 7 — Piattaforma, plugin, qualità  
**Documento di settore:** [`../06-help-i18n-onboarding.md`](../06-help-i18n-onboarding.md)  
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo:** trasformare l'help in un centro di documentazione e
apprendimento offline: indice full-text, filtri, esempi eseguibili e tracciati,
mappa errore → topic, glossario, tour, italiano e cambio lingua senza
riavvio.

**Risultato effettivo:**

- **Indice full-text** (`R/help-index.R`) costruito per revisione del registry
  e lingua, con cache invalidata al caricamento/scaricamento dei plugin.
  Pesi: titolo 5, keyword/alias 4, heading 3, corpo 1; boost per titolo esatto.
  Il completamento delle parole è limitato a pochi caratteri per non far
  combaciare `logistic` con `logisticQuantiles`.
- **Ricerca e filtri** per tipo, origine (core/plugin) e categoria, con
  snippet evidenziati (`<mark>`), tipo, origine e categoria nel risultato.
- **Topic più ricchi**: TOC con ancore, dialoghi correlati apribili, comandi
  citati, argomenti correlati, copia link, segnalazione problema e R reference.
- **Esempi runnable**: parser dal front matter (`examples`, `runnable`), UI con
  Esegui/Copia/Inserisci nello script, conferma, scelta del dataset quando
  serve, sostituzione di `{dataset}`/`Dataset`, esecuzione via
  `run_command(source = "help")` e quindi registrazione nella cronologia.
- **Mappa errore → topic** (`R/help-errors.R`) per oggetti mancanti, pacchetti
  e funzioni mancanti, fattori/contrasti, valori mancanti, pandoc/knit, file,
  memoria, fit singolari e sintassi. Link nella card di errore, nei messaggi e
  nel modal di errore del dialogo. Il campo `error` è ora conservato anche
  nella history.
- **Glossario** (`glossary`) e `keyboard-shortcuts` aggiornato con ricerca,
  filtri, esempi, tour e lingua.
- **Onboarding** (`R/onboarding.R`): tour in quattro passi con evidenziazione,
  Skip, “Non mostrare più” in `localStorage`, riavvio da **Help > Guided
  tour**; checklist Home derivata dalla sessione.
- **Italiano**: 27 topic core tradotti (glossario, Data/Chart/Report Studio,
  Workbench, navigazione/workflow e aggiornamenti a help center e scorciatoie)
  più un overlay TSV (`inst/i18n/it.tsv`) per le stringhe Studio non presenti
  nei PO ereditati da Rcmdr.
- **Lingua live**: `tr()` consulta prima il catalogo in-process (PO + TSV),
  poi gettext. Topbar, menu, tab, help e messaggi server si ridisegnano senza
  riavvio; lingua e tema sono salvati in `preferences.rds` e applicati al
  primo render.
- **Audit i18n**: `tools/audit_i18n.R`, con step in CI.

Tutti i task H6.1–H6.19 sono chiusi. La checklist Home mostra “Salva un
progetto” come non disponibile finché il feature flag `project` non viene
attivato in Onda 7.

---

## 2. File creati e modificati

### Creati

- `R/help-index.R` — indice, stemming controllato, snippet, TOC, parser esempi,
  scelte dei filtri.
- `R/help-errors.R` — pattern errore → topic, suggerimento e link UI.
- `R/onboarding.R` — passi del tour, modal, checklist e progresso.
- `inst/i18n/it.tsv` — overlay di traduzioni per la UI Studio.
- `inst/help-topics/topics/glossary.md` — glossario.
- `inst/help-topics/topics/it/{glossary,chart-studio,data-studio,report-studio,workbench,navigation-workflows}.md`.
- `vignettes/help-and-onboarding.Rmd`.
- `tools/audit_i18n.R`.
- `man/{i18n,help_errors,onboarding}.Rd`.
- Test: `test-help-index.R`, `test-help-ranking.R`, `test-help-filters.R`,
  `test-help-examples.R`, `test-help-errors.R`, `test-onboarding.R`,
  `test-i18n.R`, `test-help-wave6-server.R`, `test-help-onboarding-e2e.R`.

### Modificati

- `R/help.R` — `examples` nel topic, filtri in `help_catalog()`, nuova
  `help_search()`, snippet HTML, ancore di rendering, invalidazione indice.
- `R/help-ui.R` — filtri, risultati arricchiti, TOC, esempi, dialoghi, comandi,
  footer con copy/report.
- `R/help-server.R` — filtri, esempi con conferma, apertura dialoghi,
  segnalazione problema, dipendenza dalla revisione lingua.
- `R/i18n.R` — catalogo PO live, overlay TSV, `i18n_set_language()`,
  `i18n_parse_po()`, normalizzazione codici.
- `R/preferences.R` — `preferences_peek()`, ripristino lingua e tema.
- `R/state.R` — nessuna modifica strutturale; la revisione lingua è un
  reactive della shell.
- `R/history.R`, `R/commands.R` — campo `error` nella history.
- `R/history-ui.R` — link contestuale e testo dell'errore nella card.
- `R/app.R` — topbar reattiva, lingua live, tour, checklist, JS/CSS, link
  errore, `app()` applica la lingua salvata.
- `R/dialogs.R` — comandi `helpTour` e `helpGlossary`, tab tradotte.
- `inst/etc/Rcmdr-menus.txt` — voci “Guided tour” e “Glossary”.
- `inst/help-topics/index.yml` — topic `glossary`.
- Topic aggiornati: `getting-started`, `help-center`, `keyboard-shortcuts`,
  `linear-model`, `numerical-summaries`, `writing-help-topics`, e relative
  traduzioni italiane.
- `tools/check_help_links.R` — non tratta i link `topic:` come file relativi.
- `.github/workflows/help.yaml` — audit i18n.
- `DESCRIPTION`, `NEWS.md`, `README.md`, `_pkgdown.yml`, `NAMESPACE`, `man/`.
- `docs/upgrades/06-help-i18n-onboarding.md`, `CHECKLIST.md`.

---

## 3. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit/integration | `testthat::test_local()` | **2888 pass, 0 fail, 15 skip** |
| E2E help/onboarding | `RCMDRSHINY_E2E=1 testthat::test_file("tests/testthat/test-help-onboarding-e2e.R")` | **4 pass** |
| E2E navigation | `RCMDRSHINY_E2E=1 testthat::test_file("tests/testthat/test-navigation-e2e.R")` | **4 pass** |
| E2E core | `RCMDRSHINY_E2E=1 testthat::test_file("tests/testthat/test-shinytest2.R")` | **15 pass** |
| `R CMD check` | `R CMD build .` + `_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_1.20.0.tar.gz` | **Status: OK** |
| Help inventory | `Rscript tools/inventory_help.R --plugins all` | 644 documented, 57 extra, 0 fallback |
| Link checker | `Rscript tools/check_help_links.R --strict` | 450 topic, nessun link rotto |
| i18n audit | `Rscript tools/audit_i18n.R` | 1368 msgid, 386 tradotti (28.2%), 982 mancanti |

Resta il warning cosmetico di `shinytest2` “Failed to locate globals in server
function” per `renderPlot`, già noto dall'Onda 0.

---

## 4. Decisioni e ADR

- **L'indice è una cache, non una seconda fonte.** La fonte resta il Markdown
  registrato; l'indice si invalida con `revision` e lingua.
- **Il completamento delle parole è conservativo.** Un termine esatto vince;
  il prefisso si aggiunge solo entro tre caratteri. Senza questo limite i nomi
  dei dialoghi (`logisticQuantiles`) dominavano le ricerche.
- **Gli esempi sono opt-in.** Solo `runnable: true` esegue; il comando è sempre
  mostrato e confermato, passa da `run_command()` e finisce nella cronologia.
- **La mappa errori è conservativa.** Pattern noti, nessun link generico quando
  il messaggio non è riconosciuto.
- **Il tour non esegue comandi.** Cambia tab e illumina un selettore; la
  checklist deriva dalla sessione reale (dataset, history, plot, documenti).
- **La lingua live usa un catalogo in-process.** I PO ereditati da Rcmdr non
  coprono le stringhe Studio; l'overlay TSV evita di riscrivere i PO e permette
  al cambio lingua di funzionare senza riavvio. La cornice statica non
  reattiva viene aggiornata al reload, come fallback previsto dal piano.
- **La lingua è una preferenza, non uno stato statistico.** Sta in
  `preferences.rds` insieme a tema, preferiti, recenti, espansione e preset.
- **`help_topic_panel_ui()` accetta lo stato ma non lo usa.** È pronto per
  future azioni dipendenti dal dataset senza cambiare la firma.

---

## 5. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| H6.1 | `terms = list(term = list(doc = weight))` | `terms` named list di vettori nominati + `docs` data frame | Lookup più rapido e semplice da testare |
| H6.2 | Ranking con alias 4 e match esatto | Aggiunto boost +6 per token in titolo e +25 per titolo esatto | Evita che il corpo superi il titolo |
| H6.5 | “Try it” con scelta dataset | Placeholder `{dataset}` e sostituzione di `Dataset` | Gli esempi restano leggibili e funzionano con il dataset attivo |
| H6.7 | Conferma prima di eseguire | Modal con anteprima, dataset e nota sul log | Trasparenza e riproducibilità |
| H6.10 | `console-studio.R` | Card di history, messaggi e modal dialogo | L'errore vive in più punti; un solo helper |
| H6.15 | Include “salva progetto” | Voce presente ma gated sul flag `project` | Il progetto arriva in Onda 7 |
| H6.17 | “Completare i topic core” | 27 topic core + overlay UI TSV | I topic core sono completi; la UI resta parzialmente in inglese con fallback |
| H6.18 | Shell `uiOutput("app_shell")` | Topbar + tab + menu reattivi, resto al reload | Meno invasivo, stesso risultato per menu/help/pannelli |
| H6.19 | `R/state.R`, `R/project.R` | `preferences.rds` + `preferences_peek()` | Il progetto non esiste ancora |

---

## 6. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| UI Studio non tradotta al 100% | Italiano parziale fuori dai topic core | Fallback inglese; audit in CI | H6.16/H6.17 |
| La cornice statica usa la lingua del primo render | Topbar/brand al reload | Menu, tab, help e messaggi sono live | H6.18 |
| “Salva un progetto” non disponibile | Checklist non completabile al 100% | pinned sul feature flag | H6.15 |
| Esempi con variabili non presenti nel dataset attivo | Errore del comando | L'utente vede l'errore e il log; sceglie un dataset adatto | H6.5 |
| `run_command()` non conservava `error` nella history | Nessun link nella card | Corretto aggiungendo `error` | H6.10 |
| Handler JS con zero argomenti interrompeva lo script | Link help/esempi non funzionavano | Handler con parametro `message` | H6.7 |

---

## 7. Domande aperte

- [ ] La checklist deve includere il progetto prima dell'Onda 7?
- [ ] Gli esempi runnable devono poter usare un dataset scelto senza dataset
      attivo, impostandolo come attivo?
- [ ] La mappa errori deve coprire anche errori dei plugin?
- [ ] L'overlay TSV deve diventare un file PO completo per l'italiano?
- [ ] Il tour deve mostrare i passi anche in Classic?
- [ ] Il glossario deve avere un indice alfabetico laterale?
- [ ] La lingua deve essere parte del progetto in Onda 7?
- [ ] Gli esempi devono essere tradotti insieme al topic o restare inglesi?

---

## 8. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. Leggere questo diario, `../07-platform-plugins-quality.md` e
   `../CHECKLIST.md`.
2. Eseguire `Rscript -e 'testthat::test_local()'` per confermare la baseline
   (atteso: **2888 pass, 0 fail, 15 skip**).
3. Avviare l'Onda 7 dal task **P7.1 — Schema progetto**.

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| P7.1 | Schema progetto | Alta | `R/project.R` |
| P7.2 | Save/load progetto | Alta | |
| P7.3 | Recent projects | Media | |
| P7.4 | Autosave/recovery | Alta | |
| P7.5 | Export bundle | Alta | |
| P7.6 | Home progetti | Media | Chiude la voce “Salva un progetto” della checklist |
| P7.7 | Checkpoint sessione | Media | |
| P7.8 | Recovery prompt | Media | |
| P7.9 | Lazy plugin/cataloghi | Media | |
| P7.10 | Cache help/menu | Media | L'indice Wave 6 è già cached |
| P7.11 | Benchmark suite | Media | |
| P7.12 | Trimming e cap | Media | |
| P7.13 | API plugin v2 | Alta | |
| P7.14 | Nuovi hook | Media | |
| P7.15 | Documentazione plugin | Media | |
| P7.16 | Test 15 plugin | Alta | |
| P7.17 | Health panel | Media | |
| P7.18 | Diagnostics esteso | Media | |
| P7.19 | Matrice test | Media | |
| P7.20 | Visual regression | Bassa | |
| P7.21 | Accessibility checklist | Media | |
| P7.22 | Release checklist Studio | Alta | |

---

## 9. Comandi per riprendere

```bash
cd /home/vigliafg/Documenti/GitHub/rcmdr-studio
git status
git log --oneline -5
Rscript -e 'testthat::test_local()'
Rscript tools/check_help_links.R --strict
Rscript tools/audit_i18n.R
```

Per gli E2E:

```bash
R CMD INSTALL .
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-help-onboarding-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-navigation-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
```

**Baseline attesa:** 2888 pass, 0 fail, 15 skip; `R CMD check` OK.

---

## 10. Note di contesto

- `help_index_cached(language)` è la funzione da usare nel server;
  `help_index_build()` resta pura per i test e la vignetta.
- `help_index_terms()` limita il completamento a `nchar(token) + 3`; non
  rimuovere il limite senza rivedere il ranking.
- `help_search()` accetta `category`, `type` e `package`; `package = "core"`
  significa nessun package (topic del nucleo).
- `help_parse_examples()` accetta sia stringhe sia mapping; solo
  `runnable: true` è eseguibile.
- `help_example_prepare_code()` sostituisce `{dataset}` sempre e `Dataset` solo
  se l'oggetto non esiste già.
- `run_command(..., source = "help")` registra la history con la nuova etichetta
  “Help examples”.
- `error_help_topic()` restituisce `NULL` per messaggi non riconosciuti; i
  chiamanti devono gestire `NULL`.
- `i18n_set_language()` aggiorna opzione e `LANGUAGE`; `tr()` usa il catalogo
  in-process (PO + TSV) prima di gettext.
- `preferences_peek()` serve a `app()` per applicare lingua e tema prima del
  primo render.
- Il tour autostart usa `shiny:connected` + fallback su `load`; gli handler
  custom **devono avere un parametro** (`function(message)`), altrimenti Shiny
  interrompe la registrazione e tutti i listener successivi non vengono
  creati.
- `inst/i18n/it.tsv` è l'overlay delle stringhe Studio; aggiungere qui le nuove
  stringhe italiane e rilanciare `tools/audit_i18n.R`.
- Il topic `glossary` è nel manifest `inst/help-topics/index.yml`; le
  traduzioni sono scoperte dalla sottodirectory `it/`.

---

## 11. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata.
- [x] Documento di settore aggiornato.
- [x] Diario committato e pushato.
- [x] Utente informato: “Onda 6 completata, pronto per l'Onda 7”.
