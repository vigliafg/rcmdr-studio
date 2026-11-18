# Diario di handoff — Onda 18 — spazio di lavoro desktop

**Data:** 2026-11-18  
**Stato:** lotto 1 completato (S1–S3); prossimo lotto S4–S6  
**Baseline:** RcmdrShiny Studio 2.9.0 + T13  
**Documento di settore:** [`18-desktop-workspace.md`](../18-desktop-workspace.md)  
**ADR:** [`DECISIONS.md`](../DECISIONS.md) — ADR-018  
**Onda precedente:** [`wave-17-desktop-completion.md`](wave-17-desktop-completion.md)

---

## 1. Obiettivo del lotto 1

Aprire il workspace desktop:

- una sola navigazione principale, senza il `tabsetPanel` con tutte le viste;
- due slot con viste uniche e layout salvati;
- pannelli nascondibili e modalità focus;
- `input$main_tabs` come contratto stabile per la logica esistente.

Il lotto non tocca i comandi, gli ID dei dialoghi, i valori o le stringhe i18n
esistenti.

---

## 2. S1 — Shell menu-first · `03f908b`

**File:** `R/workspace.R`, `R/app.R`, `R/menus.R`, `R/ui-components.R`,
`inst/www/js/00-boot.js`, `inst/www/js/50-menubar.js`,
`inst/www/css/10-shell.css`, test.

- In Studio non c'è più un `tabsetPanel` con tutte le viste: il primario è un
  `workspace_slot_ui` che rende **una sola vista**. Gli output delle altre viste
  non esistono nel DOM.
- `input$main_tabs` resta il contratto: un `textInput` nascosto lo inizializza,
  il view switcher lo aggiorna con `Shiny.setInputValue`, `state$show_tab()`
  continua a funzionare.
- Il view switcher è una `role="tablist"` di pulsanti `role="tab"`, con
  `aria-selected` e `data-value`.
- La menubar ha `role="menubar"`; i gruppi sono `menuitem` con
  `aria-haspopup`/`aria-expanded`. F10 e `Alt`+lettera aprono un gruppo, le
  frecce si muovono, `Down` entra nel menu, `Esc` chiude e torna al summary.
- La sidebar ha un pulsante nella topbar; il toggle aggiunge
  `rcmdr-sidebar-collapsed` al corpo. Non è ancora persistito: S8.
- `workspace_layout` è l'output che renderà lo split nel lotto S2.

**Deviazione:** tema, lingua e densità restano nella topbar in questo step;
la loro migrazione a View/Options è prevista in S7. La sidebar resta aperta di
default per non perdere la scopribilità; il default chiuso arriverà con la
densità desktop.

**Test:** `main_tabs_ui("studio")` ora è lo shell del workspace; i test che
cercavano le vecchie tab Studio sono stati aggiornati. Classic conserva il
`tabsetPanel` e i suoi `data-value`.

---

## 3. S2 — Workspace a due slot · `44496bd`

**File:** `R/workspace.R`, `R/app.R`, `R/state.R`, `R/preferences.R`,
`inst/www/css/10-shell.css`, `tests/testthat/test-workspace.R`.

- Nuovo schema `state$options$workspace_secondary` versionato di fatto dal
  file preferenze; il secondo slot si sceglie da un select “Second view”.
- Primario e secondario sono due render distinti: nessuna vista è duplicata
  nel DOM. Se il secondario coincide con il primario, si chiude.
- `workspace_view_ui()` rende la vista scelta; `workspace_layout` costruisce
  `split_pane("workspace_split", ...)` con dimensione persistita.
- `view_ready()` consulta **entrambi** gli slot: una vista nel secondario
  costruisce i suoi output pesanti come se fosse primaria.
- La selezione del secondario è persistita e ripristinata al riavvio.
- Lo scambio avviene da “Swap sides”: `updateTextInput` sul contratto
  `main_tabs` e aggiornamento del select.

**Test:** layout con due slot, render separati, persistenza, `view_ready` con
secondario.

---

## 4. S3 — Pannelli e focus · `26d11db`

**File:** `R/workspace.R`, `R/app.R`, `R/data-studio.R`, `R/chart-studio.R`,
`R/ui-components.R`, `R/state.R`, `R/preferences.R`, CSS, test.

- `split_pane(second = NULL)` restituisce un blocco singolo: niente binario
  vuoto quando un pannello è nascosto.
- Data Studio: checkbox **Inspector**; Chart Studio: checkbox **Preview**.
  Lo stato va in `state$options$workspace_panels[[view]]` ed è persistito.
- `workspace_view_ui(show_inspector=, show_preview=)` decide al momento del
  render, quindi il pannello nascosto non costruisce il proprio output.
- Modalità **Split / Primary / Secondary** e pulsante **Swap sides** quando il
  secondario è attivo. La modalità è persistita.
- Il focus selector non compare se non c'è un secondario.

**Deviazione:** Report e Script non hanno ancora i toggle dei pannelli interni;
sono previsti in S8. Il drag della vista verso l'altro slot non è stato
implementato: l'assegnazione avviene dal select “Second view”, che è anche
l'alternativa da tastiera. Il drag potrà arrivare in S3bis o S8.

---

## 5. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti (`tests-w18-lotto1.log`) |
| `node --check` | verde su `app_js()` composto |
| App | riavviata su `http://127.0.0.1:3841`, HTTP 200 |
| Classic | `tabsetPanel` e `data-value` invariati |
| Workspace | due slot, vista unica, persistenza, focus |
| Pannelli | Data inspector e Chart preview nascondibili |
| Menu | `role="menubar"`, `menuitem`, F10/Alt/frecce/Esc |

---

## 6. Problemi noti e blocchi

| Problema | Impatto | Task |
|---|---|---|
| Nessun browser | menu, split e pannelli non visti a schermo | S11 |
| Tema/lingua/densità ancora in topbar | topbar non ancora desktop | S7 |
| Sidebar non persistita | si riapre al riavvio | S8 |
| Report/Script senza toggle pannelli | copertura parziale | S8 |
| Drag della vista non implementato | si usa il select | S3bis/S8 |
| Preferenze reali possono avere `workspace_focus` vecchio | test isolati con input esplicito | S8 |

---

## 7. Prossimo lotto

**S4–S6 — Azioni reversibili:**

1. **S4** — undo/redo applicativo per dati e galleria, menu Edit, limiti.
2. **S5** — selezione a intervallo, copia TSV, status bar.
3. **S6** — dialoghi ridimensionabili e Help/Console modeless.

Gate: nessun comando rieseguito dall'undo; la selezione riga resta il default;
Classic non cambia.

---

## 8. Checklist di handoff

- [x] S1 committato (`03f908b`).
- [x] S2 committato (`44496bd`).
- [x] S3 committato (`26d11db`).
- [x] Suite completa verde.
- [x] `node --check` verde.
- [x] App riavviata (HTTP 200).
- [x] `it.tsv` aggiornato per le stringhe nuove.
- [x] Nessun comando o ID esistente cambiato.
- [x] Diario creato.
- [x] Utente informato: “lotto 1 pronto, puoi compattare”.
