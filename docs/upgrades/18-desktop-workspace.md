# Onda 18 — Spazio di lavoro desktop

**Data:** 2026-11-18  
**Stato:** in corso — S1–S9 fatti (lotti 1–3), prossimo S10–S12  
**Baseline:** RcmdrShiny Studio 2.9.0 + T13 (hardening editor)  
**Dipende da:** Onda 17 (split pane, menu contestuali, drag-and-drop, viste
pigre) e T13 (editor legato a dataset/vista)  
**Documento padre:** [`README.md`](README.md)  
**ADR collegata:** [`DECISIONS.md`](DECISIONS.md) — ADR-018

---

## 1. Obiettivo

L'Onda 17 ha chiuso il **comportamento** desktop: split, menu contestuali,
drag-and-drop, palette, notifiche, viste pigre. L'Onda 18 chiude ciò che manca
per parlare di **spazio di lavoro** desktop:

- una sola menu bar come navigazione principale, non tre livelli che dicono
  cose simili;
- un workspace con due viste affiancabili, pannelli nascondibili e layout
  salvati;
- un **undo/redo applicativo** per i dati e la galleria, non solo per l'editor
  di codice;
- selezione a intervallo e copia negli appunti;
- finestre e pannelli che si possono ridimensionare e ricordare;
- una densità desktop vera, non solo controlli piccoli dentro una dashboard;
- geometria e ultima vista che sopravvivono al riavvio;
- una status bar che dice dove sei e cosa hai selezionato;
- una scala onesta per i dataset grandi.

Al termine:

- Studio usa **una menu bar** con `Alt` mnemonic e scorciatoie visibili;
  tema, lingua e densità stanno in **View/Options**, non nella topbar;
- due viste possono convivere (per esempio Data + Chart) senza duplicare gli
  output;
- `Ctrl+Z`/`Ctrl+Shift+Z` annullano e ripristinano le ultime modifiche a dati
  e galleria, con voce in **Edit**;
- una selezione di celle si copia come TSV e la status bar la descrive;
- i dialoghi ricordano la dimensione e Help/Console possono vivere in un
  pannello modeless;
- la chrome Studio è più piatta e compatta, senza cambiare la modalità
  Classica;
- layout, pannelli, ultima vista, larghezze e dimensioni dei dialoghi
  sopravvivono al riavvio;
- la suite completa è verde e il limite browser è documentato.

Nessun comando R, ID, valore o stringa i18n esistente cambia. La modalità
Classica resta strutturalmente identica (`tabsetPanel`, `data-value`).

---

## 2. Non-obiettivi

| Elemento | Motivo |
|---|---|
| Electron/Tauri o finestre native | l'app resta browser-native; il wrapper è un'onda separata |
| MDI completo con finestre flottanti libere | troppo rischio per focus, ARIA e persistenza |
| Più di due slot di workspace | due viste coprono il caso desktop reale |
| Duplicare la stessa vista nei due slot | gli output Shiny hanno un solo id |
| Nuovo motore di tabelle (`reactable`, `ag-grid`, `rtabulator`) | il gate T7 e T13 restano la decisione corrente |
| Undo di navigazione, tema, lingua o dialoghi | non sono mutazioni del lavoro |
| Undo del testo nei campi e in Ace | Ace ha la sua history; il menu delega |
| Nuove procedure statistiche o grafici | cambia la pelle, non il motore |
| Riscrittura della modalità Classica | è il contratto di compatibilità |

---

## 3. Stato di partenza (misurato)

| Area | Situazione | Conseguenza |
|---|---|---|
| Shell | topbar + menubar + sidebar menu + tab principali | tre livelli di navigazione, ~170 px di chrome prima del contenuto |
| Topbar | brand, tema, lingua, densità, dataset, modello, palette | controlli di preferenza in prima fila |
| Workspace | `main_tabs` con 9 viste; split solo dentro una vista | Data e Chart non possono convivere |
| Split | `split_pane()` a due pannelli, dimensioni persistite | ottimo mattone, ma non è un layout di workspace |
| Undo | Ace per il testo, checkpoint per i dati | nessun `Ctrl+Z` applicativo, nessun redo |
| Selezione | DT a righe; editor a celle | niente intervallo né copia TSV |
| Dialoghi | modali, dimensione fissa | niente geometria ricordata |
| Help/Console | tab principali | non sono pannelli modeless |
| Geometria | split e ordine colonne persistiti | mancano pannelli, ultima vista, larghezze, dialoghi |
| Status bar | dataset, modello, comandi, plot | non dice riga/colonna/selezione |
| Dati grandi | DT server-side oltre 5.000 righe; editor 10.000 celle | soglie non misurate insieme, nessuna virtualizzazione |
| Accessibilità | focus, ARIA, tastiera, contrasto | menu bar non ancora `role="menubar"` completa |

---

## 4. Principi e vincoli

1. **Una sola navigazione principale.** La menu bar è la fonte; la sidebar
   diventa un pannello opzionale, non una seconda menu bar.
2. **Classica non si tocca.** Ogni modifica di shell, densità e workspace è
   confinata alla modalità Studio.
3. **Due slot, viste uniche.** Primario e secondario non possono mostrare la
   stessa vista; niente output duplicati.
4. **Layout versionati.** Ogni preferenza di workspace ha un `version`; un file
   vecchio o corrotto ricade sul default, non rompe l'avvio.
5. **Undo onesto.** Si annullano dati e galleria, non la navigazione; il testo
   resta ad Ace. La status bar dice cosa è stato annullato.
6. **Keyboard-first.** Ogni gesto nuovo ha una via da tastiera: `F6` per i
   pannelli, `Alt` per i menu, frecce per i separatori, `Ctrl+C` per la
   selezione.
7. **Nessuna dipendenza nuova senza gate.** Il workspace si costruisce con
   `split_pane`, CSS e JS nostro; non si adotta un framework di docking.
8. **Offline.** Nessun CDN, nessun font remoto.
9. **Un lotto = tre commit verdi.** Dopo S3, S6, S9 e S12 ci si ferma, si
   scrive il diario e si consegna.
10. **La densità non è un tema.** È una regola di chrome, non un colore: deve
    valere per tutte le 8 palette.

---

## 5. Architettura target

### 5.1 Shell menu-first

- Un solo `<nav role="menubar">` con gruppi `role="menuitem"`,
  `aria-haspopup`, `aria-expanded`, `Alt` mnemonic e `F10` per entrare.
- La sidebar dei menu diventa un **drawer opzionale** (“Commands”), chiuso di
  default in Studio; si apre da View o dal pulsante della topbar.
- La topbar scende a ~40 px: brand, dataset/modello attivo, palette, Help.
  Tema, lingua e densità passano in **View** e **Options**.
- Le tab principali diventano un **view switcher** compatto. In Studio non
  c'è più un `tabsetPanel` con tutte le viste: il primario è un
  `workspace_slot_ui("primary")` che rende una sola vista.
- `input$main_tabs` resta il **contratto di navigazione**: il view switcher fa
  `Shiny.setInputValue('main_tabs', id)`, così `view_ready()`, `state$show_tab()`
  e i test continuano a leggere lo stesso id. Non è più il DOM delle tab.
- In Classica `main_tabs_ui("classic")` resta il `tabsetPanel` di oggi, con i
  suoi `data-value` e il suo comportamento.

### 5.2 Workspace a due slot

Schema persistito in `state$options$workspace`:

```r
list(
  version = 1L,
  slots = list(primary = "data", secondary = NULL),
  split = 0.62,
  hidden = list(data = c("inspector")),
  sidebar = FALSE,
  last = "data"
)
```

- `workspace_views()` registra le viste disponibili con id stabile:
  `home`, `workflows`, `data`, `charts`, `report`, `script`, `console`,
  `environment`, `help`.
- `workspace_slot_ui(slot)` rende la vista scelta. Primario e secondario sono
  due output indipendenti, non un tabset con contenuti nascosti: una vista
  esiste una volta sola nel DOM.
- Una vista non può stare in entrambi gli slot. Se l'utente assegna al
  secondario la vista già nel primario, le due si scambiano.
- `state$show_tab()` e il view switcher passano da un messaggio
  `rcmdr-view` che aggiorna slot e `input$main_tabs`; nessuna navigazione
  clicca più una `.nav-link` inesistente.
- Il separatore tra gli slot è `split_pane()` con dimensione persistita.
- Le viste pigre leggono **entrambi** gli slot: `view_ready()` e
  `subview_ready()` diventano `workspace_visible(view)` e consultano primario,
  secondario e pannelli aperti, non solo `input$main_tabs`.
- Layout salvati: “Analisi” (Data + Chart), “Report” (Report + Help),
  “Sviluppo” (Script + Console), “Singolo”. Ogni layout ricorda slot e pannelli.
- Il workspace non è un docking libero: è una griglia a due slot con viste
  uniche. È il compromesso che tiene ARIA, focus e output Shiny sotto
  controllo.

### 5.3 Pannelli interni

- Ogni vista dichiara i pannelli nascondibili:
  - Data: `grid`, `inspector`;
  - Chart: `builder`, `preview`;
  - Report: `outline`, `editor`, `preview`;
  - Script: `editor`, `outline`, `diagnostics`;
  - Console: `console`, `output`, `messages`.
- “View > Panels” mostra le caselle; lo stato va in `workspace$hidden`.
- Un pannello nascosto non costruisce il suo output finché non torna visibile
  (si riusa `view_ready()`/`subview_ready()`).
- Il separatore interno resta `split_pane()`; se un pannello è nascosto, il
  separatore sparisce e l'altro occupa lo spazio.

### 5.4 Undo/redo applicativo

- Nuovo `R/undo.R` con uno stack limitato:
  `list(kind, label, before, after, bytes, time)`.
- Copertura:
  - **dati**: prima/dopo del dataset attivo per i comandi che lo mutano,
    dentro `run_data_commands()` e per i comandi console che cambiano il
    dataset attivo;
  - **galleria**: `state$plots` (metadati, non i file) per pin, rinomina,
    eliminazione, riordino e registrazione.
- Non copre: navigazione, tema, lingua, dialoghi, testo di Ace e dei campi,
  né gli altri oggetti creati dalla console. Per la console si annulla solo il
  dataset attivo, non l'intero ambiente R.
- Limiti: massimo 20 voci e 50 MB di snapshot; oltre, si scarta la più vecchia.
  Il progetto caricato svuota lo stack.
- Menu **Edit**: Undo/Redo con etichetta (“Undo: Rename column”), abilitati
  solo se c'è una voce; `Ctrl+Z`/`Ctrl+Shift+Z` solo quando il focus non è in
  un input o in Ace. La status bar annuncia l'esito in `aria-live`.
- Il ripristino non riesegue comandi: rimette lo snapshot e invalida le viste.

### 5.5 Selezione e appunti

- Un selettore **Rows / Cells** nella toolbar del Data Studio. In `Rows`
  resta il comportamento attuale; in `Cells` si attiva la selezione a
  intervallo.
- Selezione con trascinamento, `Shift`+frecce, `Shift`+clic; `Esc` pulisce.
- `Ctrl+C` copia il blocco come TSV; `Edit > Copy selection` fa lo stesso.
  Fallback con `<textarea>` se `navigator.clipboard` non è disponibile.
- La status bar mostra `R1C1:R4C3`, righe/colonne selezionate, celle non vuote.
- L'editor a celle conserva il copia/incolla nativo di `rhandsontable`; il
  Data Studio in sola lettura non incolla.
- La selezione si azzera a ogni draw, cambio dataset o filtro.

### 5.6 Finestre e dialoghi

- I dialoghi restano modali, ma il `.modal-content` è ridimensionabile con un
  grip `role="separator"` e frecce; la dimensione è ricordata per `dialog_id`
  in `state$options$geometry$dialogs`.
- Help, Console e Output possono vivere nel secondario o in un pannello
  modeless; non sono più solo tab.
- Nessuna finestra flottante libera: il workspace a due slot è il modello.
- Un dialogo che si apre dopo un cambio vista non ruba il focus a un pannello
  modeless; il focus torna al trigger.

### 5.7 Densità desktop

- Nuova chrome Studio, non una terza densità:
  - topbar 40 px, menubar 28 px, toolbar 40 px con il view switcher nella
    stessa riga;
  - raggi 4/6/8 px, ombra solo su menu, dialoghi e drop-down;
  - card senza ombra, bordo 1 px, niente gradienti;
  - Home senza hero: una start page a due colonne (recenti + azioni).
- Tutto è confinato a `body.rcmdr-mode-studio`; Classica mantiene il suo
  aspetto.
- La matrice 8 temi × 2 densità resta la verifica; nessun colore nuovo senza
  token.

### 5.8 Geometria persistente

`state$options$geometry` versionato:

```r
list(
  version = 1L,
  workspace = list(...),          # 5.2
  layouts = list(...),            # split esistenti
  columns = list(...),            # ordine colonne esistente
  widths = list(D = c(a = 120)),  # larghezze DT per dataset
  dialogs = list(histogram = list(width = 720, height = 560)),
  last_view = "data",
  sidebar = FALSE
)
```

- Letta con `preferences_peek()` prima della UI, come i layout di Onda 17.
- Reset in **View > Reset layout**; nessun reset dei dati.
- Un file vecchio o corrotto ricade sul default.

### 5.9 Status bar e tastiera

- Status bar: dataset, righe × colonne, selezione, modello attivo, ultima
  azione/undo, busy. La selezione e l'undo sono annunciati in `aria-live`.
- `F6`/`Shift+F6` spostano il focus tra primario, secondario, pannello interno
  e status bar; il focus visibile è lo stesso token.
- Menu: `Alt` mnemonics, `F10`, frecce, `Esc` chiude e restituisce il focus.
- Un pannello modeless ha un titolo e un pulsante “Torna al workspace”.

### 5.10 Dati grandi

- Misurare 10.000 / 50.000 / 100.000 righe: tempo di prima vista, memoria,
  cambio filtro, copia di un intervallo.
- Soglia DT server-side misurata, non scelta a occhio; l'editor resta limitato
  e dice perché.
- Nessun nuovo motore di tabelle in questa onda: se i numeri non bastano, il
  gate `rtabulator`/`toastui` resta il passo successivo.

---

## 6. Sequenza degli step

### Lotto 1 — Shell e workspace

#### S1 — Menu-first shell

**Obiettivo:** una sola navigazione principale, chrome più bassa.

**File:** `R/app.R`, `R/menus.R`, `R/ui-components.R`, `R/workspace.R`
(prima versione, solo render del primario), `inst/www/css/10-shell.css`,
`inst/www/css/20-components.css`, `inst/www/js/50-menubar.js`, test.

**Cosa cambia:** menubar `role="menubar"` con `Alt`/`F10`; sidebar opzionale;
topbar a 40 px; tema/lingua/densità in View/Options; view switcher compatto in
Studio. `input$main_tabs` resta l'id di contratto, ma non è più un tabset:
`workspace_slot_ui("primary")` rende una sola vista. Classica intatta.

**Accettazione:** una sola menu bar; `Alt` e `F10` funzionano; nessun id o
comando cambia; la vista si raggiunge anche senza sidebar; 8 × 2 coerenti.

**Commit:** `feat(shell): make the menu bar the primary navigation`

#### S2 — Workspace a due slot

**Obiettivo:** due viste affiancate, con layout salvati.

**File:** `R/workspace.R` (estensione), `R/state.R`, `R/preferences.R`,
`R/app.R`, `R/chart-studio.R`, `R/help-server.R`, `R/report-studio.R`,
`inst/www/css/60-views.css`, `inst/www/js/40-interactions.js`, test.

**Cosa cambia:** `workspace_views()`, `workspace_slot_ui()`, schema versionato,
layout “Analisi/Report/Sviluppo/Singolo”, scambio di vista, separatore
persistito; primario e secondario sono due render distinti, nessuna vista
duplicata. `main_tabs` diventa un input nascosto aggiornato dal view switcher e
da `state$show_tab()`.

**Accettazione:** Data + Chart convivono; cambiare slot non perde stato; il
layout sopravvive al riavvio; Classica resta a tab.

**Commit:** `feat(workspace): add two-slot saved layouts`

#### S3 — Pannelli nascondibili e split tra viste

**Obiettivo:** adattare lo spazio senza toccare i dati.

**File:** `R/workspace.R`, `R/app.R`, `R/data-studio.R`, `R/chart-studio.R`,
`R/report-studio.R`, `R/script-studio.R`, CSS/JS, test.

**Cosa cambia:** View > Panels, pannelli per vista, separatore interno che
sparisce, output non costruito se il pannello è nascosto; drag della linguetta
di vista verso l'altro slot con alternativa “Apri a destra”.

**Accettazione:** nascondere/mostrare un pannello non perde dati; il focus
torna; il layout è persistito; nessun output duplicato.

**Commit:** `feat(workspace): hide panels and split views`

**Gate lotto 1:** una menu bar, due slot, pannelli e layout salvati; Classica
identica; suite verde.

---

### Lotto 2 — Azioni reversibili

#### S4 — Undo/redo applicativo

**Obiettivo:** `Ctrl+Z` anche fuori dall'editor di codice.

**File:** `R/undo.R` (nuovo), `R/state.R`, `R/app.R`, `R/menus.R`,
`R/chart-studio.R`, `R/checkpoints.R`, test.

**Cosa cambia:** stack dati/galleria, limiti, menu Edit, scorciatoie, status
bar; esclusi navigazione, tema, dialoghi e testo.

**Accettazione:** undo/redo di una modifica dati e di un pin; il redo si
svuota dopo una nuova azione; il progetto caricato pulisce lo stack; nessun
comando rieseguito.

**Commit:** `feat(undo): add application undo and redo`

#### S5 — Selezione a intervallo e appunti

**Obiettivo:** copiare un blocco come in un foglio.

**File:** `R/data-studio.R`, `R/app.R`, `inst/www/js/40-interactions.js`,
`inst/www/js/70-keyboard.js`, CSS, test.

**Cosa cambia:** modo Rows/Cells, selezione con trascinamento e `Shift`,
`Ctrl+C`, TSV, status bar, fallback senza clipboard.

**Accettazione:** la selezione riga esistente resta; in Cells la copia è TSV;
`Esc` pulisce; nessuna modifica ai dati; tastiera completa.

**Commit:** `feat(data): select and copy cell ranges`

#### S6 — Dialoghi ridimensionabili e pannelli modeless

**Obiettivo:** finestre che si adattano e Help/Console fuori dai tab.

**File:** `R/dialogs.R`, `R/help-server.R`, `R/console-studio.R`,
`R/app.R`, CSS/JS, test.

**Cosa cambia:** grip di ridimensionamento con `role="separator"` e frecce;
dimensione per `dialog_id`; Help/Console/Output nel secondario o modeless;
focus di ritorno.

**Accettazione:** il dialogo ricorda la dimensione; il grip è da tastiera; Help
modeless non ruba il focus; Classica invariata.

**Commit:** `feat(ui): add resizable dialogs and modeless panels`

**Gate lotto 2:** undo/redo, copia intervallo e pannelli modeless; nessuna
regressione nei comandi.

---

### Lotto 3 — Superficie desktop

#### S7 — Densità e chrome desktop

**Obiettivo:** togliere l'aria da dashboard.

**File:** `inst/www/css/00-tokens.css`, `10-shell.css`, `20-components.css`,
`60-views.css`, `R/app.R`, test della matrice.

**Cosa cambia:** topbar/menubar/view switcher/toolbar più bassi; raggi 4/6/8;
card piatte; Home come start page; nessun gradiente in Studio.

**Accettazione:** 8 × 2 contrasto; 200% zoom; nessun overflow; Classica
intatta; nessuna nuova stringa non tradotta.

**Commit:** `feat(ui): add desktop density and chrome`

#### S8 — Geometria persistente

**Obiettivo:** ritrovare il workspace dopo il riavvio.

**File:** `R/preferences.R`, `R/workspace.R`, `R/app.R`,
`R/data-studio.R`, `R/dialogs.R`, test.

**Cosa cambia:** `geometry` versionato; ultima vista, pannelli, larghezze DT,
dimensioni dialoghi, sidebar; reset in View.

**Accettazione:** il riavvio ripristina il layout; un file vecchio ricade sul
default; il reset non tocca i dati.

**Commit:** `feat(workspace): remember geometry and the last view`

#### S9 — Status bar e navigazione da tastiera

**Obiettivo:** sapere sempre dove sei.

**File:** `R/app.R`, `R/menus.R`, `inst/www/js/70-keyboard.js`, CSS, test.

**Cosa cambia:** status bar con selezione, undo, dataset, modello; `F6`/
`Shift+F6`; `Alt`/`F10` completi; scorciatoie visibili nei menu.

**Accettazione:** focus ciclico senza trappole; la status bar annuncia; i menu
sono raggiungibili da tastiera; nessun conflitto con Ace/input.

**Commit:** `feat(ui): add contextual status and pane keys`

**Gate lotto 3:** chrome desktop, geometria e tastiera; 8 × 2 e zoom 200%.

---

### Lotto 4 — Scala, QA, chiusura

#### S10 — Dati grandi

**Obiettivo:** numeri onesti, non promesse.

**File:** `R/app.R`, `R/data-studio.R`, `R/benchmark.R`,
`tests/testthat/test-data-studio-grid.R`, docs.

**Cosa cambia:** misura 10k/50k/100k; soglia server-side; stato “editing
disabled”; nessun nuovo motore.

**Accettazione:** prima vista e filtro entro budget; memoria misurata; nessuna
regressione per i dataset piccoli; il limite è documentato.

**Commit:** `perf(data): scale the grid beyond the editor threshold`

#### S11 — Accessibilità desktop ed e2e

**Obiettivo:** verificare, non assumere.

**File:** `tests/testthat/*-e2e.R`, `tools/help_screenshots.R`,
`docs/upgrades/QA-WIDGETS.md`, `ACCESSIBILITY.md`.

**Cosa cambia:** percorso solo tastiera, screen reader, zoom 200%, reduced
motion, matrice 8 × 2; e2e e screenshot dove il browser funziona.

**Accettazione:** i 26 e2e verdi o limite Chrome documentato; screenshot
rigenerati; differenze accettate scritte.

**Commit:** `test(ui): audit the desktop keyboard and zoom`

#### S12 — Chiusura

**Obiettivo:** consegnare.

**File:** `NEWS.md`, `inst/help-topics/topics/about.md`,
`docs/upgrades/CHECKLIST.md`, `README.md`,
`docs/upgrades/diary/wave-18-desktop-workspace.md`.

**Cosa cambia:** NEWS 3.0.0, topic, checklist, diario, README; suite completa;
app riavviata; push.

**Accettazione:** `EXIT=0`; working tree pulito; limiti e rinvii scritti.

**Commit:** `docs: close wave 18`

---

## 7. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| Workspace a due slot rompe gli output Shiny | viste vuote o duplicate | niente tabset nascosto: un solo render per slot, registro centrale, test di scambio |
| `main_tabs` non è più un tabset | test e `show_tab()` cercano `.nav-link` | input di contratto aggiornato dal view switcher; test aggiornati |
| Le viste pigre non conoscono il secondario | output vuoti nello slot destro | `workspace_visible()` consulta entrambi gli slot e i pannelli |
| Layout corrotto impedisce l'avvio | app inutilizzabile | `version`, validazione, fallback al default |
| Undo consuma memoria | sessione lenta | cap 20 voci/50 MB, snapshot solo dati/galleria |
| Undo e checkpoint divergono | confusione | Edit menu spiega “undo sessione”; checkpoint resta esplicito |
| Menu-first nasconde funzioni | scopribilità | palette, drawer comandi, ricerca menu, test utente |
| Densità rompe contrasto | accessibilità | token, matrice 8 × 2, test automatici |
| Selezione intervallo confligge con selezione riga | regressione | modo Rows/Cells esplicito, default Rows |
| Dialoghi ridimensionabili e focus | tastiera bloccata | grip `role="separator"`, frecce, focus return |
| Nessun browser | QA visiva assente | S11 con sonda, limiti scritti, screenshot su desktop |
| Classic si degrada | compatibilità | CSS solo `body.rcmdr-mode-studio`, test Classic |

---

## 8. Misure di successo

| Misura | Prima | Dopo |
|---|---|---|
| Altezza chrome Studio prima del contenuto | ~170 px | ≤ 110 px (40 + 28 + 40) |
| Aprire Data + Chart affiancati | impossibile | ≤ 2 azioni o un layout salvato |
| Annullare una modifica dati | checkpoint manuale | `Ctrl+Z` |
| Copiare un intervallo | impossibile | seleziona + `Ctrl+C` in TSV |
| Ripristinare il workspace dopo il riavvio | parziale (split) | layout, pannelli, ultima vista |
| Percorso solo tastiera per cambiare vista | tab + menu | `Alt`/`F10` + `F6` + view switcher |
| Zoom 200% | verificato a token | verificato sulla nuova chrome |

Queste misure non sostituiscono i test: sono il criterio con cui si dice se
l'onda ha davvero cambiato la sensazione d'uso.

---

## 9. Criteri di chiusura

- [ ] 12 step verdi, 4 handoff (S3, S6, S9, S12).
- [ ] Una menu bar, nessuna navigazione duplicata in Studio.
- [ ] Due slot, viste uniche, layout salvati e ripristinati.
- [ ] Pannelli nascondibili senza perdere dati o output.
- [ ] Undo/redo dati e galleria con menu e scorciatoie.
- [ ] Selezione intervallo e copia TSV.
- [ ] Dialoghi con geometria ricordata; Help/Console modeless.
- [ ] Densità desktop, 8 × 2, zoom 200%, reduced motion.
- [ ] Status bar con selezione, undo e dataset.
- [ ] Misure dati grandi e soglie documentate.
- [ ] Classica strutturalmente identica.
- [ ] Suite completa `EXIT=0`; app HTTP 200; push.

---

## 10. Protocollo di handoff

Come nelle onde 16 e 17:

1. tre step;
2. suite completa e `node --check`;
3. diario in `docs/upgrades/diary/wave-18-desktop-workspace.md`;
4. commit e push;
5. stop per compattare il contesto.

Ai gate S3, S6, S9, S12 il diario elenca cosa è chiuso, le deviazioni, i limiti
e il prossimo lotto.

---

## 11. Domande aperte

- [ ] Due slot sono sufficienti, o serve un terzo per Console?
- [ ] L'undo deve coprire anche i modelli o solo dati e galleria?
- [ ] La densità desktop deve essere una terza densità esplicita o solo la
      chrome di Studio?
- [ ] La selezione a intervallo deve permettere anche il taglio/incolla nel
      Data Studio, o solo la copia?
- [ ] Help modeless deve essere un pannello del workspace o una finestra
      separata?
- [ ] Il wrapper desktop (Tauri/Electron) è un'obiezione o un'onda futura?
