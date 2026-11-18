# Diario di handoff — Onda 18 — spazio di lavoro desktop

**Data:** 2026-11-18  
**Stato:** onda chiusa — 12 step (S1–S12), versione 3.0.0  
**Baseline:** RcmdrShiny Studio 2.9.0 + T13  
**Documento di settore:** [`18-desktop-workspace.md`](../18-desktop-workspace.md)  
**ADR:** [`DECISIONS.md`](../DECISIONS.md) — ADR-018  
**Onda precedente:** [`wave-17-desktop-completion.md`](wave-17-desktop-completion.md)

---

## 1. Lotti 1–2 — shell, workspace, undo, selezione, dialoghi

Restano invariati:

- Studio non renderizza più un `tabsetPanel` con tutte le viste: una sola
  vista primaria, un secondo slot facoltativo, nessuna vista duplicata.
- `input$main_tabs` resta il contratto stabile; il view switcher lo aggiorna e
  `state$show_tab()` continua a funzionare.
- Menubar `role="menubar"` con F10, `Alt`+lettera, frecce, `Down`, `Esc`.
- Data Studio ha l'**Inspector**, Chart Studio il **Preview**; entrambi sono
  nascondibili e persistiti.
- Undo/redo applicativo per dati e galleria (`R/undo.R`), con limiti 20 voci e
  50 MB, menu Edit e `Ctrl+Z` fuori dai campi.
- Selezione **Rows / Cells** con TSV, `Ctrl+C` e status bar.
- Dialoghi ridimensionabili con geometria per `dialog_id` e pannelli modeless
  Help/Console/Output.

Dettagli e deviazioni dei lotti 1–2 sono nella storia Git; il diario
registra i lotti 3–4 e la chiusura.

---

## 2. S7 — Densità e chrome desktop · `6da52af`

**File:** `inst/www/css/00-tokens.css`, `10-shell.css`, `60-views.css`,
`70-refine.css`, `inst/www/js/00-boot.js`, `R/app.R`, `R/dialogs-tools.R`,
menu, i18n, test.

- Il body riceve `rcmdr-mode-studio` / `rcmdr-mode-classic`
  (`rcmdr-ui-mode`): tutte le regole desktop sono confinate alla modalità
  Studio, quindi Classica mantiene spaziatura e `tabsetPanel`.
- Token di chrome: topbar 40 px, menubar 28 px, toolbar/view bar 40 px.
- Raggi 4/6/8 px (`--rcmdr-radius-lg` scende da 12 a 8 px).
- Card piatte: bordo 1 px, nessuna ombra; ombre solo su menu, dialoghi e
  drop-down. Rimossi i gradienti: la hero di Home non esiste più.
- Home è una **start page a due colonne**: azioni + tastiera a sinistra,
  Continue/Recent/Projects a destra, checklist e salute sotto.
- Tema, lingua e densità escono dalla topbar: **View > Preferences...** apre
  il dialogo Options, che ora contiene anche la lingua. La topbar tiene brand,
  dataset/modello, palette, Help, Classic/Studio e About.
- Due input nascosti (`theme`, `language`) ricevono `updateSelectInput()` dal
  dialogo: gli observer esistenti continuano a governare Ace, menù e help
  senza duplicare la logica.
- La matrice 8 temi × 2 densità resta invariata; nessun colore nuovo.

---

## 3. S8 — Geometria persistente · `d566b85`

**File:** `R/preferences.R`, `R/state.R`, `R/data-studio.R`, `R/app.R`,
`R/dialogs.R`, menu, `inst/www/js/00-boot.js`, `65-data-selection.js`, CSS,
test.

- `state$options$geometry` versionato:
  `list(version, dialogs, widths, last_view, sidebar)`.
- `geometry_normalize()` valida tutto; un file vecchio, corrotto o con
  versione futura ricade sui default senza errori.
- Ultima vista: la vista salvata inizializza il `main_tabs` nascosto, quindi il
  riavvio riapre il workspace lasciato.
- Sidebar: il toggle invia `sidebar_collapsed`; al riavvio `rcmdr-sidebar`
  riapplica lo stato senza toccare il resto.
- Larghezze DT per dataset: grip da 7 px sull'intestazione, trascinamento,
  `data_column_widths`, clamp 40–1200 px; applicate al render successivo.
- Dimensioni dialoghi già in `geometry$dialogs` (S6).
- **View > Reset layout**: geometry, split, ordine colonne, pannelli, vista
  secondaria e sidebar tornano ai default; dati, history, log e undo restano.
- Le preferenze `layouts` e `column_order` restano ai nomi storici per
  compatibilità; la geometria nuova copre solo ciò che S8 aggiunge.

---

## 4. S9 — Status bar e navigazione da tastiera · `47bbe56`

**File:** `R/app.R`, `R/data-studio.R`, `R/chart-studio.R`,
`inst/www/js/40-interactions.js`, `70-keyboard.js`, CSS, test.

- Status bar: versione, modalità, dimensioni, **Data: …**, comandi, history,
  **Model: …**, grafici, selezione, ultima azione/undo, busy, ultimo errore.
- `aria-live="polite"` e `aria-atomic="false"` sulla barra; selezione e
  undo/redo passano anche da `rcmdr-announce` verso `#rcmdr-live-status`.
- `F6` / `Shift+F6` ciclano il focus tra primario, secondario, pannello
  interno (Inspector/Preview), pannello modeless e status bar. Le regioni
  hanno `role="region"`, nome e lo stesso token di focus dei controlli.
- Il pannello modeless ha titolo (`modeless-title`) e pulsante **Back to
  workspace**; il focus torna al trigger alla chiusura.
- Menu: F10/Alt/frecce/Esc restano quelli di S1, nessuna regressione.

---

## 5. S10 — Dati grandi · `ca2f1bc`

**File:** `R/data-studio.R`, `R/app.R`, `R/benchmark.R`, `DESCRIPTION`,
`tests/testthat/test-data-studio-grid.R`, `tests/testthat/test-performance.R`,
`tests/benchmarks/README.md`, `docs/upgrades/QA-DATA.md`, i18n.

- `data_grid_plan()` è l'unico punto che applica le due soglie: righe per il
  paging server-side (5.000) e celle per l'editor (10.000). Render, proxy di
  ricerca e `data_info` leggono lo stesso piano.
- Avviso unico sopra la griglia: dice quale limite vale e cosa continua a
  funzionare; in Edit è un warning, in View una nota. Il limite dell'editor
  non nasconde più la griglia.
- `benchmark_data_scale()` misura prima vista, payload client/server, filtro,
  copia TSV e memoria; le righe `data grid …` entrano nella suite completa,
  non nella quick (che resta il fumo a 7 righe).
- Misure (5 colonne, un run di sviluppo): prima vista 198 / 207 / 552 ms a
  10k / 50k / 100k; payload client 474 KB / 2.4 MB / 4.9 MB; pagina server
  1.3 KB; frame di vista circa il doppio del data set.
- Decisione: 5.000 righe per il server-side, 10.000 celle per l'editor,
  nessun motore nuovo. Metodo e tabella in `QA-DATA.md`.
- `jsonlite` entra nei `Suggests`: serve solo alla misura del payload, che è
  una dipendenza già presente via htmlwidgets.

---

## 6. S11 — Accessibilità desktop ed e2e · `52475a1`

**File:** `inst/www/js/65-data-selection.js`, `R/data-studio.R`,
`inst/www/css/10-shell.css`, `60-views.css`, `inst/i18n/it.tsv`,
`tests/testthat/test-accessibility.R`, `test-data-studio-grid.R`,
`test-desktop-workspace-e2e.R`, `ACCESSIBILITY.md`, `QA-WIDGETS.md`.

- **Griglia da tastiera**: la tabella è un tab stop, le frecce muovono un
  cursore di riga, `Invio`/`Spazio` selezionano (Ctrl/Cmd per aggiungere),
  `Shift`+frecce estendono la selezione a celle, `Esc` pulisce. La selezione
  parte senza mouse e il server la annuncia come prima.
- **Grip delle colonne**: da decorazione a `role="separator"` focalizzabile,
  con `aria-valuenow`, frecce ±16 px, `Home` al default e pubblicazione della
  larghezza su `keyup`.
- **Zoom 200%**: il guscio collassa a una colonna sotto 991.98 px CSS; la
  sidebar impilata resta entro 40vh e il main riduce il padding. Regola
  Studio-scoped, dopo il blocco desktop, per non lasciare vincere il
  `max-height` pieno.
- **Reduced motion**: la regola globale esistente copre anche le nuove
  transizioni; nessun `!important` nuovo.
- Nuovo `test-desktop-workspace-e2e.R`: F6 sul focus reale, reflow a 640 px,
  classi `rcmdr-dark`/`rcmdr-contrast` sul body. Saltato come gli altri.
- `Rscript tools/check_browser.R` rieseguito: `about:blank` e `data:` ok,
  `local http` in timeout; 29 e2e saltati (26 + 3 desktop), screenshot non
  rigenerati. Il limite è scritto in `QA-WIDGETS.md` § 10 e in
  `ACCESSIBILITY.md`.

---

## 7. S12 — Chiusura

**File:** `NEWS.md`, `DESCRIPTION` (3.0.0), `inst/help-topics/topics/about.md`,
`README.md`, `docs/upgrades/CHECKLIST.md`, `18-desktop-workspace.md`,
`README.md` delle onde, questo diario.

- NEWS 3.0.0 racconta workspace, chrome, geometria, dati grandi e
  accessibilità; nessun comando, ID o stringa esistente è cambiato.
- Il topic About descrive la navigazione menu-first, i due slot, l'undo, la
  geometria, la tastiera e le soglie dei dati grandi.
- README passa dallo status 2.0 al 3.0 e aggiunge le righe del workspace.
- Checklist e piano segnano S1–S12 chiusi; i criteri di chiusura sono
  spuntati.

---

## 8. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 29 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w18-lotto4.log`) |
| `node --check` | verde sul JS composto (`/tmp/opencode/app-s12.js`) |
| Dati grandi | 5.000 righe server, 10.000 celle editor; misure in `QA-DATA.md` |
| Benchmark | `data grid 10k/50k/100k` entro 1000/1500/2500 ms |
| Chrome | token 40/28/40, raggi 4/6/8, regole solo `body.rcmdr-mode-studio` |
| Home | due colonne, nessuna hero, nessun gradiente |
| Geometria | ultima vista, sidebar, larghezze DT, dialoghi, reset senza dati |
| Status/tastiera | dataset, modello, ultima azione, F6, annunci, modeless |
| Griglia | tab stop, cursore di riga, selezione da tastiera, grip con frecce |
| Zoom | collasso a una colonna sotto 991.98 px; sidebar ≤ 40vh |
| Classic | `tabsetPanel` e `data-value` invariati |
| App | riavviata su `http://127.0.0.1:3841`, HTTP 200 |

---

## 9. Problemi noti e rinvii

| Problema | Impatto | Rinvio |
|---|---|---|
| Chrome non naviga `http(s)` | 29 e2e saltati, screenshot non rigenerati | verifica su desktop |
| Modalità Classica client-side | con dati grandi va usata Studio | documentato in `QA-DATA.md` |
| Selezione Cells limitata alla pagina DT | nessun range tra pagine | onda futura |
| Undo di delete non ripristina il PNG | metadati sì, file no | onda futura |
| Reset layout non chiude il pannello modeless | resta aperto | onda futura |
| Sidebar ripristinata dopo il flush | breve flash al primo paint | onda futura |
| `layouts`/`column_order` fuori da `geometry` | compatibilità con file vecchi | onda futura |
| Larghezze DT applicate al render successivo | il drag è immediato, il ridisegno usa i `columnDefs` | accettato |
| Ace con tema `system` resta chiaro | il server non conosce la preferenza del client | accettato |

Nessun rinvio blocca l'onda: sono limiti dichiarati, non promesse.

---

## 10. Prossimo passo

Nessun lotto è pianificato. Candidati emersi dalle domande aperte del piano:
un terzo slot per la Console, undo dei modelli, selezione a intervallo tra
pagine, chiusura del pannello modeless nel reset e un wrapper desktop
(Tauri/Electron) come onda separata. Il gate `rtabulator`/`toastui` resta
chiuso finché le misure di `QA-DATA.md` bastano.

---

## 11. Checklist di handoff

- [x] S10 committato (`ca2f1bc`).
- [x] S11 committato (`52475a1`).
- [x] S12 committato.
- [x] Suite completa verde.
- [x] JS controllato con `node --check`.
- [x] App riavviata (HTTP 200).
- [x] `it.tsv` aggiornato per le stringhe nuove.
- [x] Nessun comando o ID esistente cambiato.
- [x] NEWS, topic, README, checklist e diario aggiornati.
- [x] Push su `main`.
- [x] Utente informato: “Onda 18 chiusa, puoi compattare”.
