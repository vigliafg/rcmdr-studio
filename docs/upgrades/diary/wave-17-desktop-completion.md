# Diario di handoff — Onda 17 — completamento desktop

**Data:** 2026-11-18  
**Stato:** lotto 3 completato (T1–T9); prossimo lotto T10–T12  
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

**Lotto 4 — prestazioni, QA, chiusura (T10–T12):**

1. **T10** — rendering pigro delle viste pesanti, con misure prima/dopo,
   cache e invalidazione; nessun dato stantio.
2. **T11** — e2e, screenshot e regressione visiva dove il browser funziona;
   riesame delle checklist manuali.
3. **T12** — chiusura: NEWS, topic, diario, checklist e push.

Gate del lotto: primo render e invalidazione verdi; nessuna vista pesante
costruita prima della prima apertura.

Il dettaglio del lotto 3 chiuso è nel §12.

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

---

## 11. Lotto 2 in dettaglio (T4–T6)

### T4 — Pannelli ridimensionabili · `08d63d9`

**File:** `R/ui-components.R`, `R/preferences.R`, `R/state.R`,
`R/chart-studio.R`, `R/data-studio.R`, `R/report-studio.R`, `R/app.R`,
`inst/www/css/60-views.css`, `inst/www/js/40-interactions.js`, test.

- `split_pane(id, first, second, orientation, initial, min, min_second)` è un
  grid a tre tracce: primo pannello, separatore, secondo pannello.
- Il separatore è `role="separator"`, `tabindex="0"`,
  `aria-orientation` coerente (verticale per i pannelli affiancati),
  `aria-valuemin/max/now` e `aria-valuetext`; `aria-controls` punta ai due
  pannelli.
- Tastiera: frecce (2%, con `Shift` 8%), `Home`/`End` agli estremi,
  `Enter`/`Spazio` o doppio clic per il default. I limiti in pixel sono
  calcolati dal client e riportati in `aria-valuemin/max`.
- Il trascinamento aggiorna la vista a ogni movimento e invia il rapporto a
  Shiny solo al rilascio; le frecce inviano al `keyup`, così una freccia
  tenuta premuta non riscrive il file a ogni ripetizione.
- `state$options$layouts[[id]] = list(version, first)` è versionato;
  `preferences_peek()` lo legge già alla costruzione della UI, quindi la
  misura sopravvive al riavvio. La scrittura passa da `persist_preferences()`
  e non rende sporco il progetto.
- Applicazione: Data Studio (griglia/inspector), Chart Builder
  (parametri/anteprima), Report Studio (outline/editor/anteprima con due
  split annidati).
- Sotto i breakpoint esistenti i pannelli tornano a una colonna e il
  separatore esce dal layout: a zoom 200% non c'è nulla da trascinare.

**Deviazione:** il piano chiede il doppio `Invio` per il default; qui basta
un `Invio`/`Spazio` (e il doppio clic resta per il mouse). Una sequenza di due
pressioni è invisibile a chi non la conosce e il pattern ARIA dello splitter
prevede il tasto singolo.

### T5 — Menu contestuali · `10ee7fe`

**File:** `R/ui-components.R`, `R/data-studio.R`, `R/chart-studio.R`,
`R/script-studio.R`, `inst/www/css/20-components.css`,
`inst/www/js/40-interactions.js`, test.

- `context_menu()` produce un pannello `role="menu"` nascosto;
  `context_menu_item()` è un vero `<button role="menuitem">`;
  `context_menu_separator()` chiude i gruppi.
- Un item può cliccare un controllo esistente (`data-rcmdr-menu-click`) o
  inviare `{payload del target, action}` a un input Shiny già gestito. Non
  esiste una seconda implementazione delle azioni.
- `context_menu_target()` rende focusabile la regione, la annuncia con
  `aria-haspopup="menu"` e trasporta il payload JSON.
- Apertura: tasto destro, tasto Menu, `Shift`+`F10`. Un solo menu aperto;
  posizione fissata dentro il viewport; `Esc` chiude e riporta il focus al
  target; frecce, `Home`/`End` e `Tab` sono gestiti.
- Applicazione: griglia del Data Studio (azioni di colonna e di riga),
  schede della galleria grafici (con voce Pin/Unpin coerente), linguette dei
  documenti (Attiva/Chiudi con lo stesso payload di `script_tab_action`).

**Deviazione:** il menu della griglia agisce sulla colonna selezionata, non
sulla colonna sotto il puntatore: il data frame di DT non espone in modo
stabile l'indice della colonna cliccata senza duplicare la selezione. Le voci
sono le stesse dei bottoni dell'inspector e cliccano quei bottoni.

### T6 — Drag-and-drop con alternativa da tastiera · `7e9230b`

**File:** `R/app.R`, `R/chart-studio.R`, `R/data-studio.R`,
`R/preferences.R`, `R/project.R`, `R/state.R`, `R/ui-components.R`,
`inst/www/css/60-views.css`, `inst/www/js/40-interactions.js`, test.

- **Colonne del Data Studio:** l'intestazione di DT diventa trascinabile;
  il rilascio invia l'ordine completo a `data_column_order`. Il server lo
  normalizza (colonne ignote scartate, nuove in coda) e lo salva in
  `state$options$column_order`, versionato e persistito. I bottoni “Move
  left”/“Move right”, presenti nella scheda Colonne e nel menu contestuale,
  producono lo stesso ordine da tastiera.
- L'ordine è di **vista**: `data_view_frame()` riordina il frame solo per DT,
  `.row_id` resta l'ultimo, i dati e i comandi non cambiano.
- **Grafici fissati:** le schede fissate sono `draggable`; il rilascio invia
  `{from, to}` a `chart_order`. Il server riordina solo il blocco fissato e
  salva `order` in ogni voce; `project_plot_entry()` e il caricamento del
  progetto conservano il campo. Il menu contestuale offre “Move earlier” e
  “Move later”, che chiamano lo stesso `plot_move()`.
- **File drop:** l'area della griglia è una dropzone per file di testo (CSV,
  TSV, TXT, DAT, PSV) fino a 2 MB. Il client legge il testo, il server lo
  salva con `store_import_file()` e apre `readDataSet` già compilato (nome,
  percorso, separatore). Il dialogo è la conferma: nessun comando parte
  senza OK.

**Deviazione:** l'ordine delle colonne è di sola vista, quindi non consuma un
checkpoint dati; il piano lo immaginava annullabile con i checkpoint. Il
checkpoint resta per le modifiche reali, che qui non avvengono. Il drop è
testo-only: un `.xlsx` trascinato viene rifiutato con un avviso e resta il
percorso “Import...” esistente.

### Verifica del lotto 2

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w17-lotto2.log`) |
| `node --check` sul JS composto | verde |
| App | riavviata su `http://127.0.0.1:3841`, HTTP 200 |
| Split | markup ARIA, frecce, `Home`/`End`, reset, persistenza, collasso |
| Menu | un solo menu, viewport, focus di ritorno, stessi handler |
| Drag | ordine colonne persistito, ordine pin nel progetto, drop nel dialogo |
| Test aggiornato | l'asserzione globale “nessun Escape nel JS” ora è “lo gestiscono tooltip e menu”, perché il vecchio test assumeva un solo consumatore |

### Limiti del lotto 2

| Limite | Impatto | Task |
|---|---|---|
| Nessun browser disponibile | drag, drop, menu e separatore non sono stati visti a schermo | T11 |
| Menu della griglia sulla selezione | un clic destro su un'altra colonna non la seleziona | T5/T11 |
| Ordine colonne di vista | non è nei checkpoint dati | T6 |
| Drop solo testo | Excel e file binari passano da “Import...” | T6/T11 |
| Il separatore non ha un test e2e | la tastiera è coperta dal JS, non da un browser | T11 |

---

## 12. Lotto 3 in dettaglio (T7–T9)

### T7 — Tabelle di sola lettura · `e05a8d5`

**Esito del gate: `reactable` non entra.**

- Prototipo `reactable 0.4.5` in una libreria temporanea; tabella di confronto
  modelli con tema dai token, `compact`, `striped`.
- Peso: 3,5 MB installati per `reactable`, 1,9 MB per `reactR`; circa 3,6 MB
  di asset front-end (React 18, core-js, htmlwidgets, bundle reactable) contro
  165 KB di CSS+JS dell'app.
- La tabella nasce lato client dentro un `div`: senza JavaScript non c'è
  `<table>`, e la navigazione da tastiera non è nel widget.
- La misura completa e la decisione sono in
  [`QA-WIDGETS.md`](../QA-WIDGETS.md) § 8.

**Rifiniture al posto del widget:**

- `table_scroll()`: regione `role="region"`, `tabindex="0"` e nome, attorno a
  una tabella nativa.
- Header sticky e ritmo di riga DT (`--rcmdr-table-row-h`, 32/40 px) per
  `.rcmdr-table`, `.rcmdr-models-table` e i topic Help.
- Overflow orizzontale nel corpo Help.
- Il dashboard modelli usa la regione con nome “Model comparison”.

Test: `test-readonly-tables.R` verifica la regione, lo sticky, il ritmo e che
`reactable`/`reactR` non rientrino in DESCRIPTION o nel codice.

### T8 — Dialoghi dei plugin · `cbd2060`

**API:** esportati `settings_accordion()` e `settings_panel()`; nessun comando,
ID o `dialog_spec()` cambiato.

**Migrati (5):**

- ROC: sei pannelli — Data options, AUC, Confidence interval, Plot,
  Smoothing, Test.
- UCA: Phase I, Phase II, Parameters, Options, costruiti in base alla fase.
- Export: Content, Typesetting/Layout, File per xtable, latex e format.df.
- PcaRobust: Variables, Output, Plots.
- sos: Search, Filter.

**Non migrati (10):** DoE, TeachingDemos, NMBU, EZR, survival, TeachStat, HH,
KMggplot2, aRnova, FactoMineR. Sono dialoghi brevi o fabbriche di 3–6 campi;
un accordion nasconderebbe l'intero modulo. L'inventario è in
[`PLUGIN-DIALOGS.md`](../PLUGIN-DIALOGS.md).

Test: `test-plugin-dialogs.R` rende i cinque dialoghi, controlla i pannelli e
gli ID letti da `on_ok`; le suite plugin restano verdi.

### T9 — Help e palette · `2970e71`

- Il filtro “Source” dell'Help è un `picker_input()` ricercabile, con label
  visibile e `ariaLabelledby`; “Clear filters” usa `updateVirtualSelect()`.
  Il filtro “Type” resta un select nativo perché la lista è corta.
- I risultati hanno una riga di conteggio `role="status"` con `aria-live`:
  ricerca, filtri e categorie annunciano quanti argomenti hanno trovato.
- La palette mantiene il listbox e aggiunge:
  - `id` per ogni opzione e `aria-selected`;
  - `aria-activedescendant` sulla query, così il focus resta nella casella;
  - `Home`/`End` oltre alle frecce e a `Enter`;
  - una riga di conteggio annunciata;
  - la pulizia dell'`activedescendant` quando la query ricostruisce la lista.
- La ricerca full-text e il contratto della palette non cambiano.

Test: `test-help-ui.R` per picker, label e conteggio;
`test-accessibility.R` per `aria-activedescendant`, `Home`/`End` e opzioni.

### Verifica del lotto 3

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w17-lotto3.log`) |
| Gate `reactable` | chiuso, misure in `QA-WIDGETS.md` § 8 |
| Plugin | 5 migrati, 10 elencati; contract e suite plugin verdi |
| Help e palette | picker, conteggi, `aria-activedescendant`, Home/End |
| App | riavviata su `http://127.0.0.1:3841`, HTTP 200 |

### Limiti del lotto 3

| Limite | Impatto | Task |
|---|---|---|
| `reactable` non adottato | niente tabelle client-side | decisione registrata |
| 10 plugin piatti | nessun accordion dove non serve | T8 |
| Nessun browser | picker, palette e pannelli non visti a schermo | T11 |
| 26 e2e saltati | copertura browser non esercitata | T11 |
