# Diario di handoff — Onda 18 — spazio di lavoro desktop

**Data:** 2026-11-18  
**Stato:** lotto 2 completato (S1–S6); prossimo lotto S7–S9  
**Baseline:** RcmdrShiny Studio 2.9.0 + T13  
**Documento di settore:** [`18-desktop-workspace.md`](../18-desktop-workspace.md)  
**ADR:** [`DECISIONS.md`](../DECISIONS.md) — ADR-018  
**Onda precedente:** [`wave-17-desktop-completion.md`](wave-17-desktop-completion.md)

---

## 1. Lotto 1 — shell e workspace · `03f908b`, `44496bd`, `26d11db`

Il lotto 1 ha aperto il workspace desktop e resta invariato:

- Studio non renderizza più un `tabsetPanel` con tutte le viste: una sola
  vista primaria, un secondo slot facoltativo, nessuna vista duplicata.
- `input$main_tabs` resta il contratto stabile; il view switcher lo aggiorna e
  `state$show_tab()` continua a funzionare.
- Menubar `role="menubar"` con F10, `Alt`+lettera, frecce, `Down`, `Esc`.
- Data Studio ha il pannello **Inspector**, Chart Studio il pannello
  **Preview**; entrambi sono nascondibili e persistiti.
- Modalità **Split / Primary / Secondary** e **Swap sides** per il secondario.
- Classic conserva `tabsetPanel` e i suoi `data-value`.

Dettagli e deviazioni del lotto 1 sono nella storia Git; il presente diario
copre il lotto 2.

---

## 2. S4 — Undo/redo applicativo · `074f9e9`

**File:** `R/undo.R` (nuovo), `R/state.R`, `R/commands.R`, `R/data-studio.R`,
`R/chart-studio.R`, `R/dialogs.R`, `R/project.R`, `R/activation.R`, menu,
`inst/www/js/70-keyboard.js`, test.

- Nuovo stack limitato `list(kind, label, before, after, bytes, time)` per
  **dati** e **galleria**; 20 voci e 50 MB, con scarto della voce più vecchia.
- I comandi console sono tracciati solo se nominano il dataset attivo in
  un'assegnazione (`<-`); `summary(D)` non paga uno snapshot.
- I comandi di Data Studio sono sospesi dal tracciamento automatico e
  registrano **una sola** voce per l'intera azione (`Adding a row`,
  `Cell editing`).
- Galleria: aggiunta, pin/unpin, rinomina, eliminazione e riordino.
- Il ripristino rimette lo snapshot e non esegue alcun comando; history, log e
  script non crescono durante undo/redo.
- Menu **Edit**: `Undo: <azione>` / `Redo: <azione>`, disabilitati quando lo
  stack è vuoto; `Ctrl+Z` / `Ctrl+Shift+Z` solo fuori da input, textarea e Ace.
- La status bar annuncia `Undone: …` / `Redone: …` nella regione `aria-live`.
- Il caricamento di un progetto svuota undo e redo.

**Limite noto:** l'undo di un'eliminazione ripristina i metadati della
galleria, non il file PNG già cancellato.

---

## 3. S5 — Selezione a intervallo e appunti · `5b17dd9`

**File:** `R/data-studio.R`, `R/app.R`, `R/activation.R`, `R/dialogs.R`,
`R/state.R`, menu, `inst/www/js/65-data-selection.js`, CSS, test.

- Nuovo selettore **Rows / Cells** nella toolbar del Data Studio. Rows resta
  il default e conserva il comportamento Wave 17.
- In Cells: clic singolo, `Shift`+clic, trascinamento e `Shift`+frecce
  selezionano un rettangolo; `Esc` pulisce. La selezione si azzera a ogni
  ridisegno, cambio dataset o filtro.
- La selezione vive in `state$data_selection$cells` con l'intervallo
  `R1C1:R4C3`; righe e colonne restano valorizzate per le azioni esistenti.
- `Ctrl+C`, **Edit > Copy selection** e il pulsante nella barra copiano il
  blocco come TSV nell'ordine visibile, senza `.row_id`; i valori con tab o
  newline vengono appiattiti. Fallback con `<textarea>` se
  `navigator.clipboard` non è disponibile.
- La status bar mostra intervallo, righe, colonne e celle non vuote.
- L'editor a celle conserva il copia/incolla nativo di `rhandsontable`.

**Limite noto:** il trascinamento è dentro la pagina corrente di DT; non
attraversa le pagine.

---

## 4. S6 — Dialoghi ridimensionabili e pannelli modeless · `29364ba`

**File:** `R/dialogs.R`, `R/preferences.R`, `R/state.R`, `R/app.R`, menu,
`inst/www/js/10-dialogs.js`, `inst/www/js/66-modeless.js`, CSS, test.

- Ogni dialogo ha un grip `.rcmdr-dialog-resize` con `role="separator"`,
  `tabindex="0"` e frecce per larghezza/altezza (`Shift` = passo grande).
- La geometria è per `dialog_id` in `state$options$geometry$dialogs`, con
  limiti 360–4000 px in larghezza e 240–3000 px in altezza; viene scritta
  anche nelle preferenze, quindi il dialogo riapre alla stessa dimensione.
- Il grip non è una finestra flottante: il dialogo resta modale e Bootstrap
  conserva backdrop, Esc e focus.
- Nuovo menu **View** con **Help panel**, **Console panel**, **Output panel**.
- I pannelli modeless sono un dock laterale (`role="complementary"`), non una
  finestra libera. Non rubano il focus all'apertura; il pulsante Close
  restituisce il focus al trigger.
- Un pannello non può duplicare una vista già visibile nel primario o nel
  secondario: Console/Output/Messages/History sono trattati come lo stesso
  gruppo. `view_ready()` conosce anche `input$modeless_view`.
- Classic non cambia.

---

## 5. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w18-lotto2.log`) |
| Undo | dati, pin, delete, reorder; redo svuotato da una nuova azione; progetto carica pulito |
| Selezione | TSV, intervallo, status bar, menu Edit, Ctrl+C |
| Dialoghi | geometria ricordata e persistita, grip da tastiera |
| Modeless | Help/Console/Output senza modale, focus al trigger alla chiusura |
| `node --check` | verde su `10-dialogs.js`, `65-data-selection.js`, `66-modeless.js`, `70-keyboard.js` |
| App | riavviata su `http://127.0.0.1:3841`, HTTP 200 |
| Classic | `tabsetPanel` e `data-value` invariati |

---

## 6. Problemi noti e blocchi

| Problema | Impatto | Task |
|---|---|---|
| Nessun browser | grip, dock e selezione non visti a schermo | S11 |
| Undo di delete non ripristina il PNG | metadati sì, file no | S8/S11 |
| Selezione Cells limitata alla pagina DT | nessun range tra pagine | S5bis |
| Geometria workspace non ancora versionata | solo i dialoghi per ora | S8 |
| Tema/lingua/densità ancora in topbar | topbar non ancora desktop | S7 |
| Sidebar non persistita | si riapre al riavvio | S8 |
| Report/Script senza toggle pannelli | copertura parziale | S8 |
| Drag della vista non implementato | si usa il select | S3bis/S8 |

---

## 7. Prossimo lotto

**S7–S9 — Superficie desktop:**

1. **S7** — densità e chrome desktop: topbar/menubar/toolbar più bassi, raggi,
   card piatte, Home come start page, matrice 8 temi × 2 densità.
2. **S8** — geometria persistente versionata: ultima vista, pannelli, larghezze
   DT, dimensioni dialoghi, sidebar, reset in View.
3. **S9** — status bar completa e navigazione da tastiera (`F6`/`Shift+F6`),
   annunci di selezione e undo.

Gate: nessuna regressione nei comandi, Classic invariata, nessuna nuova
stringa non tradotta.

---

## 8. Checklist di handoff

- [x] S4 committato (`074f9e9`).
- [x] S5 committato (`5b17dd9`).
- [x] S6 committato (`29364ba`).
- [x] Suite completa verde.
- [x] JS controllato con `node --check`.
- [x] App riavviata (HTTP 200).
- [x] `it.tsv` aggiornato per le stringhe nuove.
- [x] Nessun comando o ID esistente cambiato.
- [x] Diario aggiornato.
- [x] Utente informato: “lotto 2 pronto, puoi compattare”.
