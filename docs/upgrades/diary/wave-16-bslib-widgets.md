# Diario di handoff — Onda 16 — bslib, shinyWidgets e sistema dei widget

**Data:** 2026-11-18  
**Stato:** lotti 1–3 completati (S1–S9); prossimo lotto S10–S12  
**Ondata precedente:** `wave-15-ui-refresh.md` (Onda 15, 2.8.0)  
**Documento di settore:** [`16-bslib-widgets.md`](../16-bslib-widgets.md)  
**Contratto dei token:** [`UI-TOKENS.md`](../UI-TOKENS.md)  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo dei primi tre lotti

Il primo lotto ha preparato il terreno: specifica desktop, galleria di ogni
famiglia di widget, bridge dei temi, campi e selettori binari, elenchi
ricercabili. Il secondo ha costruito il componente che riduce il carico
visivo: un accordion con semantica di heading, usato prima su *Options* e poi
sul Chart Builder. Il terzo porta il builder a sei pannelli, dà una gerarchia
anche alle opzioni che cambiano con il tipo e sostituisce i controlli numerici
e di colore con quelli desktop.

Al termine del lotto 3:

- `settings_accordion()`, `settings_panel()` e `settings_group()` sono il solo
  modo di costruire un accordion nell'app;
- *Options* è cinque pannelli e un errore apre il pannello giusto e porta il
  focus sul campo;
- il Chart Builder è una scheda “Chart and data” sempre visibile più sei
  pannelli, con tutti i 29 ID statici invariati;
- le opzioni per tipo hanno gruppi, e i pannelli ancora validi restano aperti
  quando si cambia tipo;
- alpha, jitter, base size e notch width sono slider, lo sfondo è un color
  picker, e il comando di default non cambia;
- la suite completa è verde.

---

## 2. Lotto 1 — il sistema dei widget (S1–S3)

### S1 — Dipendenze, specifica, bridge, galleria · `3b58384`

- `shinyWidgets (>= 0.9.1)` in `Imports`; `widget_library()` nomina le famiglie
  adottate.
- `15-bootstrap.css` mappa `--bs-accordion-*` sui token, disegna il chevron in
  `currentColor` e fissa il focus; `55-shinywidgets.css` fa lo stesso per
  virtual select, noUiSlider e spectrum.
- `--rcmdr-shadow-sm` in tutte le palette: menu e dropdown hanno un'ombra
  propria.
- `tools/widget_gallery.R`: banco di sviluppo escluso dal pacchetto, tutte le
  famiglie e tutti gli stati, 8 temi × 2 densità, modalità check.

### S2 — Campi, checkbox, radio, switch · `54ada44`

- Un solo chrome per campi, select e input-group: raggio da token, hover sul
  bordo, placeholder attenuato, disabled, read-only, invalid.
- Freccia della select in `currentColor`; `<select multiple>` come listbox a
  sei righe.
- Checkbox e radio a 16 px con hover, disabled, invalid e riempimento
  `primary` in ogni palette.

### S3 — Virtual select e mapping · `5599c74`

- Scelto `virtualSelectInput`, non `pickerInput`: indipendente da Bootstrap,
  ricerca, gruppi, chip e “seleziona tutto”, niente `bootstrap-select`.
- `picker_input()` e `listbox_input()`; mapping del Chart Builder migrato;
  `chart_reset` usa `updateVirtualSelect()`.
- Helper e2e aggiornato per leggere il JSON del widget.

### Handoff del lotto 1 · `b3355d2`

Diario, README e verifica del primo lotto.

---

## 3. Lotto 2 — accordion e prima migrazione (S4–S6)

### S4 — Componente accordion · `43634a9`

- `settings_accordion(..., id, open, multiple, level, class)` avvolge
  `bslib::accordion()`, aggiunge `rcmdr-accordion` e trasforma ogni
  `.accordion-header` in un heading con `aria-level`. bslib emette un `div`:
  senza questo passaggio i pannelli non compaiono nell'outline del documento.
- I valori dei pannelli devono essere unici e ogni valore in `open` deve
  nominare un pannello: un refuso è un errore, non un accordion chiuso in
  silenzio.
- `settings_panel(title, ..., value, icon, badge, grid)`: icona, badge e
  titolo in una riga; il corpo nella griglia condivisa, con `grid = FALSE` per
  i contenuti che hanno già il proprio layout.
- `settings_group(title, ..., help)`: sottotitolo non richiudibile (livello 4)
  per dare gerarchia a un pannello lungo senza annidare accordion.
- `20-components.css`: ritmo, hover e icona dai token; `15-bootstrap.css`
  fornisce già il bridge della palette e il chevron.
- **Decisione su `switch_input()`:** resta il nostro. `bslib::input_switch()`
  usa `form-switch` e una struttura di label diversa; adottarlo cambierebbe il
  markup e i tre test di *Options* senza un guadagno visibile.
- Test: heading, `aria-expanded`/`aria-controls`, stato aperto, icona e badge,
  griglia, valori duplicati, `open` sconosciuto, livello, gruppo.

### S5 — *Options* in cinque pannelli · `2b8e410`

- Pannelli: *Interface* (aperto), *Output*, *Data*, *Documents*,
  *Optional extensions*. Spariscono `hr` e `h6`; i titoli sono quelli dei
  pannelli.
- Tutti e nove gli ID restano, con lo stesso ordine interno.
- `chart_ext_ui(heading = FALSE)` non ripete più il titolo dentro il pannello.
- Validazione inline: `digits`, `width` ed `edit_threshold` restituiscono
  `field_errors` invece di un errore solo testuale. Il server invia
  `rcmdr-open-accordions` prima di `rcmdr-field-errors` da
  `session$onFlushed(once = TRUE)`: senza il flush i messaggi raggiungerebbero
  il corpo precedente del dialogo e la riapertura andrebbe persa. Il JS apre
  tutti i pannelli con l'API `Collapse` di Bootstrap e attende la transizione
  prima di focalizzare e scorrere. Anche i link del riepilogo usano lo stesso
  percorso.
- `.rcmdr-dialog-grid > .accordion` occupa tutte le colonne del corpo.
- Test: cinque pannelli e cinque valori, un solo pannello aperto, tutti gli ID,
  nessun `hr`/`h6`, tre errori inline, handler JS e regola di griglia.

### S6 — Chart Builder su accordion · `3952ab6`

- Scheda fissa `.rcmdr-section-card.rcmdr-chart-identity`: tipo, dataset,
  mapping, composizione e la nota sui mapping dinamici.
- `settings_accordion("chart_settings", open = "Options")` con *Options*,
  *Theme and labels*, *ggplot2 options*, *Output*.
- I valori dei pannelli sono chiavi inglesi stabili, i titoli sono tradotti:
  lo stato aperto non cambia con la lingua.
- Nessuna modifica al server, agli ID, ai valori o al comando. Il test del
  comando di riferimento resta verde.
- `.rcmdr-chart-builder > .rcmdr-accordion` perde il margine inferiore: il
  ritmo della colonna lo fornisce già la scheda.
- Test: una scheda identità, quattro pannelli, solo *Options* aperto, ognuno
  dei 29 ID statici presente una volta.

---

## 4. Lotto 3 — Chart Builder in profondità (S7–S9)

### S7 — Sottopannelli semantici di ggplot2 · `62f3fd8`

- Il pannello unico con diciotto controlli diventa quattro pannelli che
  nominano un compito: *Style* (position, alpha, bin width, jitter, point
  shape, smooth, confidence band, flip), *Axes* (formati X/Y, facet scales e
  colonne, coordinate polari e angolo), *Text* (titolo, caption, etichette X/Y,
  subtitle, tag, base size), *Theme* (tema ggplot2, palette, legenda, sfondo,
  griglia). *Output* resta larghezza e altezza.
- Cambia solo la posizione: ID, valori, default e chiamate del server identici.
  Reset, caricamento modello e comando generato non toccano i pannelli.
- Test: sei pannelli, solo *Options* aperto, ognuno dei 17 ID `chart_gg_*` una
  volta, e un controllo di appartenenza che nessun campo sia nel pannello
  sbagliato.

### S8 — Gruppi per tipo e stato dei pannelli · `e9f0391`

- Metadato opzionale `option_groups` nei descrittori: lista nominata con chiavi
  stabili (anche titolo inglese) e valori presi da `defaults`. Otto tipi core
  lo usano (density, boxplot, scatter, dot, strip, qq, means, violin); gli
  altri restano a un gruppo solo.
- `chart_option_groups()` scarta i nomi sconosciuti e mette nel primo gruppo le
  opzioni rimaste fuori: un refuso non può nascondere un controllo. Un test
  verifica che i gruppi coprano `defaults` esattamente, senza duplicati.
- `chart_option_controls()` partiziona i tag di `controls(spec)` in base
  all'ID `chart_opt_*`: nessun tipo ripete le proprie definizioni per avere un
  pannello. Un test confronta gli ID resi con quelli piatti per ogni tipo del
  registro, stat inclusi.
- `chart_options_ui()` rende `settings_accordion()` con ID stabile
  `chart_type_options`, livello 4 e classe `rcmdr-accordion-nested`. I valori
  aperti si leggono con `isolate()` e si filtrano sui gruppi del nuovo tipo:
  *Box* sparisce su un dot plot, *Layout* resta aperto.
- CSS: l'unico accordion annidato perde il margine e usa il passo piccolo del
  titolo; l'accordion dentro una griglia occupa tutte le colonne.

### S9 — Slider e colore · `55e4124`

- `slider_input()` disegna un handle noUiSlider e conserva ID, valore numerico,
  minimo, massimo e passo del vecchio `sliderInput()`. Tooltip con i decimali
  dello step (`wNumbFormat`), `update_on = "change"`, tastiera sulle frecce.
  Alpha, jitter, base size e notch width lo usano; jitter ha ora un limite
  0–0,5.
- `shinyWidgets` non sa spostare l'handle dal server: il wrapper ha un
  messaggio proprio, `rcmdr-set-slider`, che chiama `noUiSlider.set()` e lascia
  che l'evento `change` del binding aggiorni Shiny.
  `update_number_input()` instrada i quattro ID degli slider lì e tutto il resto
  su `updateNumericInput()`; reset, caricamento modello e reopen restano
  invariati.
- `color_input()` avvolge `spectrumInput()` per lo sfondo del grafico. Il
  binding riporta sempre hex, quindi il bianco di default arriva come
  `#ffffff`: `chart_background_is_white()` tratta `white`, `#ffffff` e `#fff`
  come la stessa superficie, così il comando resta identico. Un colore vero
  continua a produrre `par(bg = ...)` e `plot.background`.
- Galleria: slider Shiny e slider Studio affiancati, colore con il wrapper.
- Test: markup e decimali, handler e instradamento degli ID, il picker, i
  quattro ID nel builder, reset senza errori, lettura numerica e di colore,
  equivalenza del bianco nei due engine.

---

## 5. Scelte e deviazioni

| Punto | Piano | Fatto | Motivo |
|---|---|---|---|
| Firma di `settings_accordion()` | `(id, ...)` | `(..., id = NULL)` | con `id` prima di `...` i pannelli senza nome finivano nell'ID: difetto trovato dai test |
| `switch_input()` | valutare `bslib::input_switch()` | resta il nostro | markup, classi e tre test cambierebbero senza guadagno |
| Pannelli di *Options* | *Chart extensions* | *Optional extensions* | riusa la stringa già esistente, nessuna nuova chiave i18n |
| Errore di *Options* | solo messaggio | `field_errors` | l'errore deve portare al campo, non solo comparire |
| Pannelli del Chart Builder | 6 in totale | 4 in S6, 6 in S7 | S7 spezza *ggplot2 options* in *Style*, *Axes*, *Text*, *Theme*; S6 non anticipa il lavoro |
| Titolo della scheda fissa | “Chart and data” | `tr("Chart")` | evita una nuova chiave i18n; la scheda è concettualmente “Chart and data” |
| Sottogruppi per tipo | `settings_group()` dentro un pannello | un pannello per gruppo | il gruppo *è* la gerarchia: annidare un gruppo in un pannello avrebbe aggiunto un livello senza informazione |
| Accordion annidato | vietato dai token | ammesso solo per le opzioni per tipo | S8 chiede un accordion con ID proprio dentro *Options*; il livello 4 e la classe `rcmdr-accordion-nested` lo distinguono, `UI-TOKENS.md` registra l'eccezione |
| Coordinate polari | non elencate in S7 | nel pannello *Axes* | sono una proprietà degli assi: nessun altro pannello le ospiterebbe senza perdere l'ID |
| Jitter | nessun massimo | slider 0–0,5 | un handle ha bisogno di un limite; 0,5 copre l'uso reale |
| Aggiornamento dello slider | `updateNumericInput()` | messaggio `rcmdr-set-slider` | shinyWidgets cambia il range ma non il valore dell'handle |
| Sfondo bianco | `white` | `white` = `#ffffff` = `#fff` | il picker riporta sempre hex: senza normalizzazione il comando di default cambierebbe |

Nessuna modifica a ID, valori, comandi R, `dialog_spec()` o stringhe esistenti.
Le uniche stringhe nuove sono i valori stabili dei pannelli, che non sono
tradotti e non compaiono nell'interfaccia.

---

## 6. File toccati nei lotti 2 e 3

### Creati

- Nessuno: il lotto costruisce sui file dell'Onda 15.

### Modificati

- `R/ui-components.R`: componenti accordion, gruppo e badge.
- `R/dialogs-tools.R`: *Options* in pannelli, validazione inline.
- `R/chart-ext.R`: `heading` opzionale.
- `R/chart-studio.R`: scheda identità, sei pannelli, accordion per tipo,
  slider e color picker.
- `R/chart-types.R`: `option_groups`, `chart_option_groups()`,
  `chart_option_controls()`, notch width su slider.
- `R/chart-spec.R`, `R/chart-ggplot.R`: `chart_background_is_white()`.
- `R/widgets.R`: `slider_input()` su noUiSlider, `color_input()` su spectrum,
  `update_number_input()` e il messaggio dello slider.
- `NAMESPACE`: `export(color_input)`.
- `R/app.R`: messaggio `rcmdr-open-accordions` prima degli errori di campo.
- `inst/www/js/40-interactions.js`: `rcmdrShowAccordions`, focus dopo la
  transizione, handler `rcmdr-set-slider`.
- `inst/www/css/20-components.css`: ritmo dell'accordion, dei gruppi e
  dell'annidato.
- `inst/www/css/30-forms.css`: accordion a tutta larghezza nella griglia.
- `inst/www/css/40-dialogs.css`: accordion a tutta larghezza nel dialogo.
- `inst/www/css/55-shinywidgets.css`: tooltip dello slider.
- `inst/www/css/60-views.css`: margine dell'accordion nella colonna builder.
- `docs/upgrades/UI-TOKENS.md`: § 12.4, contratto dell'accordion e dei
  controlli desktop.
- `docs/upgrades/CHECKLIST.md`: S4–S9 chiusi.
- `tests/testthat/test-ui-components.R`, `test-accessibility.R`,
  `test-dialog-validation.R`, `test-phase1.R`, `test-chart-studio.R`,
  `test-chart-types.R`, `test-chart-theme.R`, `test-widget-library.R`.
- `tools/widget_gallery.R`: accordion, slider e colore usano i componenti
  reali.

---

## 7. Verifica

| Controllo | Esito |
|---|---|
| Suite completa del lotto 3 | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti |
| Test mirati S7 | Chart Studio, tipi, accessibilità |
| Test mirati S8 | copertura dei gruppi per ogni tipo, ID piatti = ID raggruppati, stato dei pannelli, livello 4 |
| Test mirati S9 | markup e decimali, handler JS, instradamento degli ID, picker, reset, bianco equivalente |
| Galleria in check mode | `gallery ok` |
| Comando di riferimento del Chart Builder | invariato, anche con sfondo `#ffffff` |
| Tutti gli ID di *Options* e del builder | presenti una volta |
| JS | `node --check` verde |
| Colori nei file nuovi | nessun letterale |

Log: `/tmp/opencode/tests-w16-batch3.log`.

---

## 8. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task |
|---|---|---|---|
| Il dropdown virtual select non è stato visto in un browser | forma e ombra non confermate | galleria pronta | QA |
| L'apertura dei pannelli su errore non ha un e2e | verificata a livello JS e R | e2e su macchina con browser | QA |
| La transizione del collapse non è misurata | 200 ms scelti per il focus | il focus attende comunque il frame | S5 |
| Slider, color picker e stato dei pannelli non sono stati visti in un browser | forma, tooltip e transizioni non confermati | galleria pronta; handler coperti dai test | QA |
| Jitter ha ora un limite 0–0,5 | un valore maggiore non è più digitabile | nessuno nell'uso reale | S9 |
| 26 e2e ancora saltati | copertura browser non esercitata | `RCMDRSHINY_E2E=1` | QA |

Nessun blocco di codice: il lotto è chiuso.

---

## 9. Prossimo passo

**Lotto 4 — listbox nei dialoghi e dialoghi densi (S10–S12):**

1. **S10** — `var_input()` sul listbox nativo dove la lista è corta e sul
   picker dove è lunga; stessi ID e stessa selezione.
2. **S11** — accordion nei dialoghi con più di 8–10 parametri (*Import*,
   *Frequency*, modelli, test), con `settings_group()` per i sottogruppi.
3. **S12** — validazione inline estesa ai dialoghi migrati, apertura dei
   pannelli e focus sul primo campo invalido.

Gate del lotto: nessun dialogo perde un ID o un valore; la suite resta verde;
la galleria copre le famiglie usate.

---

## 10. Domande aperte

- [ ] Conferma visiva del dropdown virtual select (posizione, ombra, chip) su
      Chrome e Firefox reali.
- [ ] Il titolo “Chart and data” vale una chiave i18n dedicata, o `tr("Chart")`
      basta anche nella versione italiana?
- [ ] La `<select multiple>` nativa è sufficiente per i 106 `var_input()`, o
      serve il picker anche nei dialoghi? La decisione è in S10.
- [ ] Il peso di Font Awesome è accettabile? Oggi sì, perché è locale.
- [ ] `--rcmdr-shadow-sm` è abbastanza distinto dall'ombra grande nei temi
      scuri?

---

## 11. Checklist di handoff

- [x] S1–S3 committati e handoff `b3355d2`.
- [x] S4 committato (`43634a9`).
- [x] S5 committato (`2b8e410`).
- [x] S6 committato (`3952ab6`).
- [x] S7 committato (`62f3fd8`).
- [x] S8 committato (`e9f0391`).
- [x] S9 committato (`55e4124`).
- [x] Suite completa verde: `EXIT=0`.
- [x] Galleria in check mode verde.
- [x] `UI-TOKENS.md` con il contratto dell'accordion e dei controlli desktop.
- [x] `CHECKLIST.md` aggiornata (S1–S9).
- [x] Diario aggiornato.
- [x] Nessun ID, valore o comando cambiato.
- [x] Utente informato: “lotto 3 pronto, puoi compattare il contesto”.

---

## 12. Artefatti

- `/tmp/opencode/tests-w16-batch3.log` — suite del lotto 3.
- `/tmp/opencode/tests-w16-batch2b.log` — suite del lotto 2 dopo il fix del flush.
- `/tmp/opencode/tests-w16-batch2.log` — prima suite del lotto 2.
- `/tmp/opencode/t-s4.log`, `t-s4b.log`, `t-s4c.log` — test mirati S4.
- `/tmp/opencode/t-s5.log` — test mirati S5.
- `/tmp/opencode/t-s6.log` — test mirati S6.
- `/tmp/opencode/t-s8.log` — test mirati S8.
- `/tmp/opencode/t-s9.log`, `t-s9b.log` — test mirati S9.
- `/tmp/opencode/tests-w16-batch1.log` — suite del lotto 1.
