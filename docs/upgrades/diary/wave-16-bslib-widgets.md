# Diario di handoff — Onda 16 — bslib, shinyWidgets e sistema dei widget

**Data:** 2026-11-18  
**Stato:** lotto 1 completato (S1–S3); prossimo lotto S4–S6  
**Ondata precedente:** `wave-15-ui-refresh.md` (Onda 15, 2.8.0)  
**Documento di settore:** [`16-bslib-widgets.md`](../16-bslib-widgets.md)  
**Contratto dei token:** [`UI-TOKENS.md`](../UI-TOKENS.md)  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo del lotto

Il primo lotto non tocca ancora l'accordion: prepara il terreno. Serve una
specifica desktop scritta, una galleria che mostri ogni famiglia di widget in
ogni stato e le due famiglie che oggi si vedono di più — campi/binari e
elenchi. Senza questa base, l'accordion e i dialoghi del lotto 2 sarebbero
costruiti su controlli ancora disomogenei.

Al termine del lotto:

- `shinyWidgets` è una dipendenza con un proprietario esplicito;
- i due fogli di bridge caricano nell'ordine giusto e non contengono colori
  letterali;
- checkbox, radio, campi e select hanno una sola mano;
- il Chart Builder usa un elenco ricercabile per il mapping;
- la galleria `tools/widget_gallery.R` mostra tutto in 8 temi × 2 densità.

---

## 2. Cosa è stato fatto

### S1 — Dipendenze, specifica, bridge, galleria

- `shinyWidgets (>= 0.9.1)` in `Imports`; installata la 0.9.1. `start.sh`
  elenca la dipendenza nel messaggio di errore.
- `widget_library()` in `R/widgets.R` nomina le famiglie adottate:
  `virtualSelectInput`, `noUiSliderInput`, `spectrumInput`. È il punto in cui
  la dipendenza ha un proprietario.
- `inst/www/css/15-bootstrap.css`: variabili `--bs-accordion-*` mappate sui
  token, header senza il display size di bslib, chevron disegnato con
  `currentColor` (il data URI di Bootstrap non segue la palette), focus.
- `inst/www/css/55-shinywidgets.css`: variabili e classi di virtual select,
  noUiSlider e spectrum; nessun colore letterale.
- `--rcmdr-shadow-sm` in tutte le palette: menu e dropdown hanno un'ombra
  propria, i modali tengono quella grande.
- `tools/widget_gallery.R`: applicazione di sviluppo (esclusa dal pacchetto)
  con campi, select, listbox, checkbox, radio, switch, segmented, picker,
  slider, colore, data, accordion e tabella; selettore di tema e densità;
  modalità `RCMDRSHINY_GALLERY_CHECK=1` per la verifica senza browser.
- `tests/testthat/test-widget-library.R`: floor della dipendenza, ordine dei
  fogli, token, ID dei widget, assenza di asset remoti, copertura della
  galleria e check mode.

**Commit:** `3b58384` — `build(ui): add shinyWidgets and the token bridge`

### S2 — Campi, checkbox, radio, switch

- Campi (`form-control`, `form-select`, input-group): raggio da token, hover
  che cambia solo il bordo, placeholder attenuato, disabled, read-only,
  invalid con `--rcmdr-danger`.
- Select nativa: freccia disegnata con due gradienti in `currentColor` invece
  del data URI fisso; una `<select multiple>` diventa un listbox a sei righe,
  senza freccia, con righe selezionabili.
- Checkbox e radio: 16 px, `--rcmdr-radius-xs` o pill, hover, disabled,
  invalid; il segno è quello bianco di Bootstrap, quindi il riempimento resta
  `primary` in ogni palette.
- Lo switch esistente è già sulla stessa griglia (36 × 20) e non è stato
  riscritto.
- Test: regole CSS, stati, nessun `50%` grezzo (sostituito dal token pill).

**Commit:** `54ada44` — `feat(ui): refine the field, checkbox and radio families`

### S3 — Dropdown, listbox, picker

- Prototipo nella galleria di `virtualSelectInput`, `pickerInput` e listbox
  nativa.
- **Decisione:** si usa `virtualSelectInput`, non `pickerInput`. Il primo è
  indipendente da Bootstrap, ha ricerca, gruppi, chip e “seleziona tutto” e
  non carica la vecchia `bootstrap-select`. `pickerInput` resta fuori anche
  da `widget_library()`.
- `picker_input()`: stesso ID e stessi valori (stringa per singola, vettore
  per multipla); ricerca attiva, prima opzione non auto-selezionata,
  `hideClearButton` solo per la multipla.
- `listbox_input()`: `<select multiple>` nativa, `size = 8`, Ctrl/Shift,
  nessun JavaScript. È il controllo per gli elenchi che restano visibili.
- Mapping del Chart Builder migrato a `picker_input()`; `chart_reset` usa
  `shinyWidgets::updateVirtualSelect()` per riallineare le scelte al dataset.
- L'helper e2e di `test-chart-extensions-e2e.R` legge il JSON del widget,
  accettando anche la vecchia forma selectize.
- CSS: variabili `--vs-*`, chip, dropdown con ombra piccola, opzione attiva e
  selezionata; regole globali `.vs__*` nel caso il menu sia portato fuori dal
  widget.
- Test: ID, config JSON (search, multiple, selectedValue), listbox nativa,
  messaggio per elenco vuoto, mapping senza selectize.

**Commit:** `5599c74` — `feat(ui): choose the virtual select and give the mapping a searchable list`

---

## 3. Deviazioni dal piano

| Punto | Piano | Fatto | Motivo |
|---|---|---|---|
| Scelta dell'elenco | `virtualSelectInput` oppure `pickerInput` | `virtualSelectInput` | indipendente da Bootstrap, niente `bootstrap-select` 1.13.8 |
| Listbox sempre visibile | widget shinyWidgets | `<select multiple>` nativa | Ctrl/Shift e righe sono il comportamento desktop; nessun JS |
| Ombra dei menu | `--rcmdr-shadow` | nuovo `--rcmdr-shadow-sm` per palette | l'ombra grande era pensata per i modali |
| `slider_input()` | noUiSlider in S9 | resta Shiny fino a S9 | il lotto 1 non tocca i parametri numerici |
| `var_input()` | famiglia nuova in S3 | resta `selectizeInput` fino a S10 | la migrazione dei 106 punti è un passo isolato e reversibile |
| Icona del chevron | token | `::after` con due bordi | il data URI di Bootstrap non può usare `currentColor` |
| Galleria | forse in `inst` | `tools/`, esclusa da `.Rbuildignore` | è un banco di sviluppo, non una funzione dell'app |

Nessuna modifica a ID, valori, comandi R o stringhe i18n.

---

## 4. File creati e modificati

### Creati

- `inst/www/css/15-bootstrap.css`
- `inst/www/css/55-shinywidgets.css`
- `tools/widget_gallery.R`
- `tests/testthat/test-widget-library.R`
- `docs/upgrades/diary/wave-16-bslib-widgets.md` (questo file)

### Modificati

- `DESCRIPTION`: `shinyWidgets (>= 0.9.1)`.
- `start.sh`: elenco delle dipendenze nel messaggio di errore.
- `R/app.R`: `app_css_files()` con i due fogli di bridge.
- `R/widgets.R`: `widget_library()`, `picker_input()`, `listbox_input()`.
- `R/chart-types.R`: mapping del Chart Builder su `picker_input()`.
- `R/chart-studio.R`: reset del mapping con `updateVirtualSelect()`.
- `inst/www/css/00-tokens.css`: `--rcmdr-shadow-sm` in tutte le palette.
- `inst/www/css/50-widgets.css`: campi, checkbox, radio, select, listbox.
- `docs/upgrades/UI-TOKENS.md`: specifica desktop, proprietà, famiglie,
  bridge, decisione S3.
- `docs/upgrades/CHECKLIST.md`: S1–S3 chiusi.
- `tests/testthat/test-widgets.R`, `test-chart-types.R`,
  `test-widget-library.R`, `test-chart-extensions-e2e.R`.

---

## 5. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti |
| `test-widget-library.R` | bridge, ordine dei file, ID, nessun asset remoto, galleria |
| Galleria in check mode | `gallery ok`, 14.661 byte di HTML |
| Ordine CSS nel `<head>` | Bootstrap prima, `app_css()` dopo; il bridge vince |
| Colori letterali nei bridge | nessun hex, nessun `rgb()` |
| Contrasto | tabelle di `test-contrast.R` invariate e verdi |
| 8 temi × 2 densità | token e bridge verificati a livello R |

Log: `/tmp/opencode/tests-w16-batch1.log`.

---

## 6. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task |
|---|---|---|---|
| Il dropdown di virtual select non è stato visto in un browser | forma e ombra non confermate visivamente | galleria pronta; screenshot/e2e su una macchina con browser | S3, QA |
| `shinyWidgets` porta Font Awesome e i suoi asset | peso aggiunto, tutto locale | misurato; nessun CDN | S1 |
| La `<select multiple>` è stilata dal browser per alcune parti | resa diversa tra Chrome e Firefox | righe e colori coperti; verifica visiva nella galleria | S3 |
| `pickerInput` non è stato adottato | resta una dipendenza non usata | non è in `widget_library()`; nessun codice la carica | — |
| 26 e2e ancora saltati | copertura browser non esercitata | `RCMDRSHINY_E2E=1` su browser funzionante | QA |
| Screenshot non generabili qui | confronto visivo assente | checklist della galleria | QA |

Nessun blocco di codice: il lotto è chiuso.

---

## 7. Prossimo passo

**Lotto 2 — Accordion e prima migrazione (S4–S6):**

1. **S4** — `settings_accordion()`, `settings_panel()`, `settings_group()` con
   heading semantics, densità e test.
2. **S5** — *Options* in cinque pannelli; apertura di tutti i pannelli e focus
   sul primo campo quando la validazione fallisce.
3. **S6** — Chart Builder: “Chart and data” resta fisso, il resto va in
   accordion; stessi ID e stesso comando.

Gate del lotto: *Options* e Chart Builder nelle 8 palette × 2 densità, senza
regressioni nel contract.

---

## 8. Domande aperte

- [ ] Conferma visiva del dropdown virtual select (posizione, ombra, chip) su
      Chrome e Firefox reali.
- [ ] La `<select multiple>` nativa è sufficiente per i 106 `var_input()`, o
      serve il picker anche nei dialoghi? La decisione è in S10, con il
      contract come gate.
- [ ] Il peso di Font Awesome è accettabile? Oggi sì, perché è locale e già
      usato da altre dipendenze; va rimisurato se cresce.
- [ ] Il `--rcmdr-shadow-sm` è abbastanza distinto dall'ombra grande nei temi
      scuri? Verifica visiva nella galleria.

---

## 9. Checklist di handoff

- [x] S1 committato (`3b58384`).
- [x] S2 committato (`54ada44`).
- [x] S3 committato (`5599c74`).
- [x] Suite completa verde: `EXIT=0`.
- [x] Galleria in check mode verde.
- [x] `UI-TOKENS.md` aggiornato con specifica e proprietà.
- [x] `CHECKLIST.md` aggiornata (S1–S3).
- [x] Diario scritto.
- [x] Nessun ID, valore o comando cambiato.
- [x] Utente informato: “lotto 1 pronto, puoi compattare il contesto”.

---

## 10. Artefatti

- `/tmp/opencode/tests-w16-batch1.log` — suite del lotto 1.
- `/tmp/opencode/t-s1.log`, `t-s1b.log`, `t-s2.log`, `t-s2b.log`,
  `t-s3.log`, `t-s3b.log`, `t-s3c.log` — test mirati.
- `/tmp/opencode/install-shinywidgets.log` — installazione 0.9.1.
- `/tmp/opencode/gallery.log` — avvio della galleria su `3850`.
