# Diario di handoff — Onda 18 — spazio di lavoro desktop

**Data:** 2026-11-18  
**Stato:** lotto 3 completato (S1–S9); prossimo lotto S10–S12  
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

Dettagli e deviazioni dei lotti 1–2 sono nella storia Git; questo diario
copre il lotto 3.

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

## 5. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w18-lotto3.log`) |
| Chrome | token 40/28/40, raggi 4/6/8, regole solo `body.rcmdr-mode-studio` |
| Home | due colonne, nessuna hero, nessun gradiente |
| Geometria | ultima vista, sidebar, larghezze DT, dialoghi, reset senza dati |
| Status/tastiera | dataset, modello, ultima azione, F6, annunci, modeless |
| `node --check` | verde sul JS composto (`/tmp/opencode/app-s9.js`) |
| App | riavviata su `http://127.0.0.1:3841`, HTTP 200 |
| Classic | `tabsetPanel` e `data-value` invariati |

---

## 6. Problemi noti e blocchi

| Problema | Impatto | Task |
|---|---|---|
| Nessun browser | chrome, F6, resize e start page non visti a schermo | S11 |
| Resize DT custom | niente estensione ColResize; larghezze solo colonne visibili | S10/S11 |
| Larghezze al render successivo | il drag è immediato, la persistenza si vede al ridisegno | S10 |
| Undo di delete non ripristina il PNG | metadati sì, file no | S11 |
| Selezione Cells limitata alla pagina DT | nessun range tra pagine | S5bis |
| `layouts`/`column_order` fuori da `geometry` | compatibilità con file vecchi | S12 |
| Sidebar ripristinata dopo il flush | breve flash al primo paint | S11 |
| Reset layout non chiude il pannello modeless | resta aperto | S12 |

---

## 7. Prossimo lotto

**S10–S12 — chiusura dell'onda:**

1. **S10** — dati grandi: misure a 10.000/50.000/100.000 righe, soglia DT
   server-side misurata, nessun motore nuovo.
2. **S11** — accessibilità desktop ed e2e: tastiera, zoom 200%, screenshot,
   contrasto sulle nuove superfici.
3. **S12** — chiusura: NEWS 3.0.0, topic, diario, push.

Gate: nessuna regressione nei comandi, Classic invariata, nessuna nuova
stringa non tradotta.

---

## 8. Checklist di handoff

- [x] S7 committato (`6da52af`).
- [x] S8 committato (`d566b85`).
- [x] S9 committato (`47bbe56`).
- [x] Suite completa verde.
- [x] JS controllato con `node --check`.
- [x] App riavviata (HTTP 200).
- [x] `it.tsv` aggiornato per le stringhe nuove.
- [x] Nessun comando o ID esistente cambiato.
- [x] Diario aggiornato.
- [x] Utente informato: “lotto 3 pronto, puoi compattare”.
