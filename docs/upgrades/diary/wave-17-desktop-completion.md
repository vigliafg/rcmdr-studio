# Diario di handoff — Onda 17 — completamento desktop

**Data:** 2026-11-18  
**Stato:** lotto 1 completato (T1–T3); prossimo lotto T4–T6  
**Ondata precedente:** `wave-16-bslib-widgets.md` (Onda 16, 2.8.0)  
**Documento di settore:** [`17-desktop-completion.md`](../17-desktop-completion.md)  
**QA dei widget:** [`QA-WIDGETS.md`](../QA-WIDGETS.md)  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo del lotto 1

L'Onda 16 ha reso omogenei i controlli; questa onda aggiunge ciò che manca
intorno ai controlli. Il primo lotto copre tre bisogni trasversali:

- un aiuto breve **dove serve**, senza rubare il focus e senza sostituire il
  testo di aiuto già presente;
- l'unica famiglia di input ancora assente, le **date**, con il primo caso
  d'uso reale nel filtro del Data Studio;
- un **feedback unico** per notifiche e operazioni lunghe, annunciato anche a
  chi usa uno screen reader.

Al termine del lotto:

- `help_tip()` è un trigger focusabile con tooltip bslib, `Esc` chiude il
  fumetto e non il dialogo;
- `date_input()` e `date_range_input()` leggono date vere, con lingua e
  cancellazione;
- il filtro del Data Studio passa dal campo testo al selettore di intervallo
  quando la colonna è `Date`/`POSIXct`, senza cambiare i dati né i comandi;
- le notifiche usano i token, si fermano a tre e vivono in una regione
  `aria-live`; le operazioni lunghe impostano `aria-busy` e annunciano il
  lavoro in corso;
- la suite completa è verde.

---

## 2. T1 — Tooltip accessibili · `0be8a6d`

**File:** `R/ui-components.R`, `R/chart-studio.R`,
`R/dialogs-import-text.R`, `R/dialogs-stats.R`,
`inst/www/css/20-components.css`, `inst/www/js/40-interactions.js`,
`inst/i18n/it.tsv`, test.

- `help_tip(text, label, placement)` avvolge `bslib::tooltip()` con un
  `<button type="button">` e l'icona `help` decorativa.
- Il trigger ha `aria-label`; Bootstrap collega il fumetto con
  `aria-describedby` quando è visibile.
- `40-interactions.js` intercetta `Esc` in fase di cattura sul trigger,
  chiude il tooltip e ferma la propagazione: il modale resta aperto e il
  focus resta sul trigger.
- Il fumetto usa `--bs-tooltip-*` mappate su superficie, testo, bordo e ombra
  piccola.
- Primi usi: *Alpha*, *Jitter* e *Facet scales* nel Chart Builder; il
  separatore decimale in *Import text data*; il test di bontà in *Frequency
  Distributions*. Il testo di aiuto permanente resta dov'era.

**Deviazione:** il piano cita anche i popover; questa onda adotta solo
`tooltip()`. Un popover richiede contenuto interattivo e un pattern di focus
che nessun parametro attuale giustifica: resta fuori, elencato nelle domande
aperte.

---

## 3. T2 — Campi data e filtro · `069f2e7`

**File:** `R/widgets.R`, `R/data-studio.R`, `R/app.R`,
`inst/i18n/it.tsv`, test.

- `date_input()` e `date_range_input()` su `airDatepickerInput()`: formato
  `yyyy-MM-dd`, `min`/`max`, pulsante di cancellazione, chiusura automatica,
  lingua da `current_language()`.
- Un campo senza etichetta visibile riceve una label `visually-hidden`
  (“Date”, “Date range”), così il controllo ha sempre un nome.
- `date_column()` riconosce `Date`, `POSIXct` e `POSIXlt`;
  `date_range_keep()` confronta date di calendario, estremi inclusi, con un
  estremo aperto o nessun filtro.
- Il filtro del Data Studio mostra `data_filter_dates` al posto di
  `data_filter_value` quando la colonna è una data. Il campo testo e il suo
  comportamento restano per tutti gli altri tipi; “Clear filter” azzera
  entrambi.
- Il filtro è di sola vista: non modifica il dataset, non genera comandi e
  non tocca la selezione delle righe (che continua a usare `.row_id`).

**Limite:** non c'è un browser per provare il calendario; la resa del popup e
il fuso orario di `POSIXct` sono verificati a livello di helper e markup, non
a occhio.

---

## 4. T3 — Notifiche e stato · `3f40a12`

**File:** `R/app.R`, `inst/www/css/50-widgets.css`,
`inst/www/js/40-interactions.js`, test.

- `.shiny-notification` usa superficie, bordo, ombra e striscia di tipo a
  token; il pannello sta sopra i modali (`z-index` 1080).
- Il pannello riceve `role="status"`, `aria-live="polite"` e
  `aria-atomic="false"`; un osservatore tiene solo le tre notifiche più
  recenti, chiudendo le più vecchie.
- `set_busy(value, message)` è l'unico punto che cambia `state$busy` e invia
  `rcmdr-busy`; il client aggiorna `aria-busy` su `#main-content` e la
  regione `#rcmdr-live-status`.
- I tre punti che eseguono codice (applicare un dialogo, console, script)
  passano da `set_busy()` con un messaggio tradotto.
- La barra di stato continua a mostrare il badge “busy”: è la metà visiva
  dello stesso stato.

---

## 5. Verifica

| Controllo | Esito |
|---|---|
| Suite completa del lotto 1 | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti (`tests-w17-lotto1.log`) |
| Test mirati T1 | markup del trigger, `aria-label`, icona decorativa, uso nel builder, `Esc` |
| Test mirati T2 | valore JSON, intervallo, label nascosta, `date_range_keep`, `date_column` |
| Test mirati T3 | live region, `aria-busy`, limite a tre, token delle notifiche |
| `node --check` | verde su `app_js()` composto |
| App | riavviata su `http://127.0.0.1:3841`, HTTP 200 |
| ID e comandi | invariati; il filtro data non genera comandi |

Log: `/tmp/opencode/tests-w17-lotto1.log`.

---

## 6. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task |
|---|---|---|---|
| Il tooltip non è stato visto in un browser | apertura su focus, `Esc` e posizione non confermati a occhio | test JS/CSS; galleria pronta | T11 |
| Il calendario air-datepicker non è stato visto in un browser | resa del popup e lingua non confermate | test di markup e helper | T11 |
| `POSIXct` viene filtrato per giorno | un orario nella stessa giornata è incluso | è il comportamento dichiarato del filtro di vista | T2 |
| Le notifiche oltre tre vengono chiuse | un avviso molto vecchio sparisce | è la coda richiesta dal piano | T3 |
| `help_tip` non sostituisce l'help permanente | due livelli di aiuto convivono | scelta esplicita: il testo resta per i parametri che lo meritano | T1 |
| 26 e2e ancora saltati | copertura browser non esercitata | `RCMDRSHINY_E2E=1` | T11 |

Nessun blocco di codice: il lotto è chiuso.

---

## 7. Prossimo lotto

**Lotto 2 — interazioni desktop (T4–T6):**

1. **T4** — `split_pane()` con separatore `role="separator"`, frecce,
   `Home`/`End`, doppio clic/doppio Invio, persistenza e collasso a una
   colonna.
2. **T5** — `context_menu()` con tasto destro, tasto Menu, `Shift`+`F10`,
   `Esc` e ritorno del focus; le voci chiamano gli handler esistenti.
3. **T6** — drag-and-drop per colonne, grafici fissati e file, con “Sposta
   su/giù” nel menu contestuale e la stessa persistenza.

Gate del lotto: le tre interazioni convivono nelle viste, a zoom 200% e con
`prefers-reduced-motion`.

---

## 8. Domande aperte

- [ ] Il tooltip su focus è utile o è rumore per chi tabula? Oggi si apre su
      focus e su hover, come chiede il piano.
- [ ] `Esc` sul trigger deve chiudere solo il tooltip o anche il dialogo se il
      tooltip non è aperto? Oggi chiude il dialogo solo quando non c'è un
      fumetto aperto.
- [ ] Il filtro data deve includere l'intera giornata di un `POSIXct` o
      lavorare a istanti? Oggi lavora a giorni.
- [ ] Le notifiche più vecchie vanno chiuse o solo nascoste? Oggi vengono
      chiuse, così la coda resta a tre.
- [ ] Popover: servono davvero? Nessun parametro attuale ha contenuto
      interattivo nell'aiuto.

---

## 9. Checklist di handoff

- [x] T1 committato (`0be8a6d`).
- [x] T2 committato (`069f2e7`).
- [x] T3 committato (`3f40a12`).
- [x] Suite completa verde: `EXIT=0`.
- [x] `node --check` verde.
- [x] App riavviata (HTTP 200).
- [x] `it.tsv` aggiornato per tutte le stringhe nuove.
- [x] Nessun ID, valore o comando cambiato.
- [x] `CHECKLIST.md` aggiornata (T1–T3).
- [x] Diario creato.
- [x] Utente informato: “lotto 1 pronto, puoi compattare il contesto”.

---

## 10. Artefatti

- `/tmp/opencode/tests-w17-lotto1.log` — suite finale del lotto 1.
- `/tmp/opencode/tests-w17-t1t3-a.log` — test mirati dopo T1–T3.
- `/tmp/opencode/app-w17-t1t3.js` — JS composto, verificato con
  `node --check`.
- `/tmp/opencode/app-w17.log` — avvio dell'app.
