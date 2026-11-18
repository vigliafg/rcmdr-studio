# Diario di handoff — Onda 16 — bslib, shinyWidgets e sistema dei widget

**Data:** 2026-11-18  
**Stato:** lotti 1 e 2 completati (S1–S6); prossimo lotto S7–S9  
**Ondata precedente:** `wave-15-ui-refresh.md` (Onda 15, 2.8.0)  
**Documento di settore:** [`16-bslib-widgets.md`](../16-bslib-widgets.md)  
**Contratto dei token:** [`UI-TOKENS.md`](../UI-TOKENS.md)  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo dei primi due lotti

Il primo lotto ha preparato il terreno: specifica desktop, galleria di ogni
famiglia di widget, bridge dei temi, campi e selettori binari, elenchi
ricercabili. Il secondo lotto costruisce sopra quella base il componente che
riduce il carico visivo: un accordion con semantica di heading, usato prima su
*Options* e poi sul Chart Builder.

Al termine del lotto 2:

- `settings_accordion()`, `settings_panel()` e `settings_group()` sono il solo
  modo di costruire un accordion nell'app;
- *Options* è cinque pannelli e un errore apre il pannello giusto e porta il
  focus sul campo;
- il Chart Builder è una scheda “Chart and data” sempre visibile più quattro
  pannelli, con tutti i 29 ID statici invariati;
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
  `rcmdr-open-accordions` prima di `rcmdr-field-errors`; il JS apre tutti i
  pannelli con l'API `Collapse` di Bootstrap e attende la transizione prima di
  focalizzare e scorrere. Anche i link del riepilogo usano lo stesso percorso.
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

## 4. Scelte e deviazioni

| Punto | Piano | Fatto | Motivo |
|---|---|---|---|
| Firma di `settings_accordion()` | `(id, ...)` | `(..., id = NULL)` | con `id` prima di `...` i pannelli senza nome finivano nell'ID: difetto trovato dai test |
| `switch_input()` | valutare `bslib::input_switch()` | resta il nostro | markup, classi e tre test cambierebbero senza guadagno |
| Pannelli di *Options* | *Chart extensions* | *Optional extensions* | riusa la stringa già esistente, nessuna nuova chiave i18n |
| Errore di *Options* | solo messaggio | `field_errors` | l'errore deve portare al campo, non solo comparire |
| Pannelli del Chart Builder | 6 in totale | 4 in S6, 6 dopo S7 | S7 spezza *ggplot2 options* in *Style*, *Axes*, *Text*, *Theme*; S6 non anticipa il lavoro |
| Titolo della scheda fissa | “Chart and data” | `tr("Chart")` | evita una nuova chiave i18n; la scheda è concettualmente “Chart and data” |

Nessuna modifica a ID, valori, comandi R, `dialog_spec()` o stringhe esistenti.
Le uniche stringhe nuove sono i valori stabili dei pannelli, che non sono
tradotti e non compaiono nell'interfaccia.

---

## 5. File toccati nel lotto 2

### Creati

- Nessuno: il lotto costruisce sui file dell'Onda 15.

### Modificati

- `R/ui-components.R`: componenti accordion, gruppo e badge.
- `R/dialogs-tools.R`: *Options* in pannelli, validazione inline.
- `R/chart-ext.R`: `heading` opzionale.
- `R/chart-studio.R`: scheda identità e accordion.
- `R/app.R`: messaggio `rcmdr-open-accordions` prima degli errori di campo.
- `inst/www/js/40-interactions.js`: `rcmdrShowAccordions`, focus dopo la
  transizione.
- `inst/www/css/20-components.css`: ritmo dell'accordion e dei gruppi.
- `inst/www/css/40-dialogs.css`: accordion a tutta larghezza nel dialogo.
- `inst/www/css/60-views.css`: margine dell'accordion nella colonna builder.
- `docs/upgrades/UI-TOKENS.md`: § 12.4, contratto dell'accordion.
- `docs/upgrades/CHECKLIST.md`: S4–S6 chiusi.
- `tests/testthat/test-ui-components.R`, `test-accessibility.R`,
  `test-dialog-validation.R`, `test-phase1.R`, `test-chart-studio.R`.
- `tools/widget_gallery.R`: la card dell'accordion usa il componente reale.

---

## 6. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 26 e2e saltati; 3 warning noti |
| Test mirati S4 | componenti, accessibilità, galleria |
| Test mirati S5 | validazione, *Options*, densità, contract |
| Test mirati S6 | Chart Studio, tipi, estensioni, contract |
| Galleria in check mode | `gallery ok` |
| Comando di riferimento del Chart Builder | invariato |
| Tutti gli ID di *Options* e del builder | presenti una volta |
| Colori nei file nuovi | nessun letterale |

Log: `/tmp/opencode/tests-w16-batch2.log`.

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task |
|---|---|---|---|
| Il dropdown virtual select non è stato visto in un browser | forma e ombra non confermate | galleria pronta | QA |
| L'apertura dei pannelli su errore non ha un e2e | verificata a livello JS e R | e2e su macchina con browser | QA |
| La transizione del collapse non è misurata | 200 ms scelti per il focus | il focus attende comunque il frame | S5 |
| Il Chart Builder ha ancora 4 pannelli | S7 deve spezzare *ggplot2 options* | piano invariato | S7 |
| 26 e2e ancora saltati | copertura browser non esercitata | `RCMDRSHINY_E2E=1` | QA |

Nessun blocco di codice: il lotto è chiuso.

---

## 8. Prossimo passo

**Lotto 3 — Chart Builder in profondità (S7–S9):**

1. **S7** — *Style* (position, alpha, binwidth, jitter, shape, smooth, SE,
   flip), *Axes* (formati X/Y, facet scales, facet columns), *Text* (subtitle,
   tag, title, caption, xlab, ylab, base size), *Theme* (gg theme, palette,
   legend, background, grid), *Output* (width, height). Solo posizione: gli ID
   restano.
2. **S8** — gruppi di opzioni per tipo con `option_groups`, ID stabile
   `chart_type_options`, pannelli aperti letti con `isolate()` e filtrati sui
   gruppi disponibili; `settings_group()` per i sottogruppi.
3. **S9** — `slider_input()` su `noUiSliderInput` per i valori limitati e
   `color_input()` su `spectrumInput` per lo sfondo; stessi ID e stessi valori.

Gate del lotto: ogni `chart_gg_*` una volta, comando identico, stato dei
pannelli conservato al cambio tipo.

---

## 9. Domande aperte

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

## 10. Checklist di handoff

- [x] S1–S3 committati e handoff `b3355d2`.
- [x] S4 committato (`43634a9`).
- [x] S5 committato (`2b8e410`).
- [x] S6 committato (`3952ab6`).
- [x] Suite completa verde: `EXIT=0`.
- [x] Galleria in check mode verde.
- [x] `UI-TOKENS.md` con il contratto dell'accordion.
- [x] `CHECKLIST.md` aggiornata (S1–S6).
- [x] Diario aggiornato.
- [x] Nessun ID, valore o comando cambiato.
- [x] Utente informato: “lotto 2 pronto, puoi compattare il contesto”.

---

## 11. Artefatti

- `/tmp/opencode/tests-w16-batch2.log` — suite del lotto 2.
- `/tmp/opencode/t-s4.log`, `t-s4b.log`, `t-s4c.log` — test mirati S4.
- `/tmp/opencode/t-s5.log` — test mirati S5.
- `/tmp/opencode/t-s6.log` — test mirati S6.
- `/tmp/opencode/tests-w16-batch1.log` — suite del lotto 1.
