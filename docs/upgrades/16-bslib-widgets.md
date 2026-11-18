# Onda 16 — bslib, shinyWidgets, accordion e sistema dei widget

**Data:** 2026-11-18  
**Stato:** pianificata — 15 step in 5 lotti da 3  
**Baseline:** RcmdrShiny Studio 2.8.0  
**Dipende da:** Onda 15 (token, componenti, viste, matrice 8 × 2)  
**Documento padre:** [`README.md`](README.md)  
**ADR collegata:** [`DECISIONS.md`](DECISIONS.md) — ADR-016

---

## 1. Obiettivo

Ridurre il carico visivo delle schermate con molti parametri e adottare due
librerie già coerenti con Bootstrap 5, senza riaprire il contratto dell'app:

- **bslib** per l'architettura dei parametri: accordion, pannelli, gruppi;
- **shinyWidgets** per i pochi controlli che oggi mancano o sono deboli:
  selezione ricercabile, slider per valori limitati, selettore di colore;
- **accordion** nel Chart Builder e nei dialoghi con più di 8–10 parametri,
  così i campi visibili sono quelli che servono e il resto è a una riga di
  distanza;
- **un sistema di widget unico** per campi, dropdown, listbox, checkbox,
  radio, switch, slider e colore: stessa altezza, stesso bordo, stesso focus,
  stesso comportamento da tastiera;
- **aspetto desktop** in tutta l'interfaccia: densità, bordi da 1 px,
  elevazione discreta solo sulle superfici flottanti, hover netti, nessun
  controllo lasciato al disegno predefinito del browser.

Non è un cambio di motore: comandi R, ID degli input, valori letti dal server,
`dialog_spec()`, modalità Classica e i18n restano quelli di prima.

Al termine dell'onda:

- ogni famiglia di input ha una specifica visiva e una galleria che la rende
  verificabile in tutte le 8 palette × 2 densità;
- il Chart Builder passa da una colonna di ~30 controlli a una scheda
  “Chart and data” sempre visibile e 6 pannelli richiudibili;
- i dialoghi *Options*, *Import text data*, *Frequency Distributions*,
  *Models* e i test statistici raggruppano i parametri per compito;
- picker, slider e color picker sono usati solo dove aggiungono qualcosa;
- ogni nuovo componente supera la matrice 8 temi × 2 densità e i controlli di
  accessibilità;
- nessuna nuova dipendenza “cosmetica” entra senza un ADR che la giustifichi.

---

## 2. Stato attuale (misurato)

| Area | Situazione | Conseguenza |
|---|---|---|
| Asset | 1.743 righe CSS in 8 file, 698 righe JS in 8 file, assemblati da `app_css()`/`app_js()` | Base pronta per due fogli di bridge senza toccare `R/app.R` |
| bslib | 0.9.0 in `Imports`; usato solo per `page_fluid()` e `bs_theme(version = 5)`; **0 componenti** | L'accordion è disponibile senza nuove dipendenze |
| shinyWidgets | assente da `Imports` e dalla libreria locale | Va aggiunto e verificato widget per widget |
| Chart Builder | 29 controlli statici + fino a 9 opzioni dinamiche + mapping, in 3 schede e 2 `hr` nella stessa colonna | La colonna è lunga 3–4 schermate; i parametri rari sono mescolati a quelli frequenti |
| Dialoghi | corpo reso in un unico `.rcmdr-field-grid.rcmdr-dialog-grid`; *Options* ha 9 controlli + estensione grafici in 5 sezioni con `hr`/`h6` | Le sezioni sono solo visive: non si possono chiudere |
| Altri dialoghi densi | *Import text data* ~10 controlli, *Frequency Distributions* ~10, modelli 6–10, test 5–8 | Stesso problema, meno grave |
| Famiglie widget | text/number/textarea/select/checkbox/radio/switch sono già tokenizzate; selectize e dropdown hanno override; checkbox e radio conservano la forma Bootstrap | Manca una specifica unica e un banco di prova che le mostri tutte insieme |
| Elenchi | `var_input()` usa `selectizeInput` in 106 punti | Non è un listbox desktop: mostra tag, non righe selezionabili |
| Controlli speciali | slider e colore assenti o affidati a campi testuali; date assente | I parametri limitati non si leggono a colpo d'occhio |
| Galleria | assente | Non esiste un posto dove vedere ogni widget in ogni stato |
| Validazione | `dialog_validation_ui()` e `rcmdrFocusField()` cercano il campo per ID | Un campo dentro un pannello chiuso non è raggiungibile: serve aprirlo |
| Temi | 8 temi × 2 densità, contrasto verificato da `test-theme-matrix.R` | Ogni componente esterno va mappato sui token, non tematizzato a mano |
| Test | 132 file, 776 blocchi `test_that`; contract su tutti i dialoghi; 26 e2e saltati senza browser | Gli ID sono il contratto: si aggiungono classi, non si rinominano |

---

## 3. Principi e vincoli

1. **Stesso contratto.** ID, valori, comandi, `dialog_spec()` e stringhe i18n
   non cambiano. Un widget può cambiare solo il markup e l'aspetto.
2. **Classica resta Classica.** Il `tabsetPanel` e i `data-value` non si
   toccano. I dialoghi sono condivisi: l'accordion vale anche in modalità
   Classica, ed è accettato.
3. **Una sola implementazione per controllo.** Non si aggiunge un secondo
   switch, un secondo segmented o una seconda card. Se una libreria offre un
   equivalente, resta il nostro helper.
4. **La libreria è un dettaglio.** Ogni widget esterno passa da un wrapper in
   `R/widgets.R`; i dialoghi chiamano il wrapper, non la libreria.
5. **Offline.** Nessun CDN, nessun font remoto: le dipendenze sono nel
   pacchetto e i loro asset sono serviti da Shiny.
6. **Accessibilità come criterio.** Heading semantics, `aria-expanded`,
   tastiera, focus visibile, `prefers-reduced-motion`, contrasto: senza questi
   il passo non è chiuso.
7. **Un passo = un commit verde.** Dopo tre passi ci si ferma, si scrive il
   diario e l'utente compatta il contesto.
8. **Niente framework UI.** bslib resta il fornitore di Bootstrap 5; non si
   adottano Fluent, Semantic, shinydashboard o React.
9. **Desktop first.** Un controllo deve sembrare parte di un'applicazione
   desktop: 1 px di bordo, raggio contenuto, elevazione solo se flottante,
   hover immediato, focus a anello, nessun effetto “mobile”.
10. **Una famiglia per volta.** Ogni famiglia di widget ha la sua specifica,
    la sua galleria e il suo test; non si ristilizza “tutto insieme” senza un
    criterio verificabile.

---

## 4. Architettura target

### 4.0 Specifica desktop

La specifica vale per ogni famiglia e viene verificata nella galleria
(`tools/widget_gallery.R`) e nella matrice 8 × 2.

| Elemento | Regola |
|---|---|
| Altezza | 34 px compatto / 40 px comodo per campi e bottoni; nessuna eccezione per widget esterni |
| Bordo | 1 px `--rcmdr-border-strong` sui controlli; `--rcmdr-border` sulle superfici decorative |
| Raggio | 6 px sui controlli, 8 px su dropdown e pannelli, 12 px su modali |
| Elevazione | solo su dropdown, popover, modali; un `--rcmdr-shadow-sm` nuovo per i menu, il grande resta ai modali |
| Hover | cambia bordo e superficie, non sposta il contenuto; nessuna transizione oltre 150 ms |
| Focus | un solo anello da 2 px, offset 2 px, visibile su tutte le palette |
| Disabled | opacità e cursore coerenti, nessun hover, valore ancora leggibile |
| Errore | bordo `--rcmdr-danger` + messaggio; mai solo il colore |
| Checkbox/radio | 16 px, quadrato 2 px di raggio o cerchio, segno netto, stato indeterminato |
| Dropdown | superficie, bordo 1 px, ombra piccola, ricerca sticky, massimo 320 px di altezza |
| Listbox | 8–10 righe, hover di riga, selezione d'accento, tastiera con Ctrl/Shift |
| Tabelle | righe da 32 px in compatto, header sticky, hover e selezione coerenti |
| Movimento | 120–150 ms; `prefers-reduced-motion` azzera tutto |
| Cursore | default sui campi, pointer su bottoni, link e righe cliccabili |

### 4.1 Cosa prendiamo da bslib

| Componente | Uso | Perché |
|---|---|---|
| `accordion()` / `accordion_panel()` | Chart Builder, *Options*, *Import*, *Frequency*, modelli, test | Marcamento Bootstrap 5, stato e ARIA già gestiti; niente JS nostro |
| `input_switch()` | solo se `switch_input()` può delegare senza cambiare ID e test | Manutenzione a monte, stesso `<input type=checkbox>` |
| `tooltip()` / `popover()` | **fuori onda** | Richiedono nuove stringhe o spostano l'help fuori dal testo: si valutano dopo |
| `card()`, `navset_*()`, `layout_columns()` | **no** | Duplicherebbero `.rcmdr-section-card`, la shell e le griglie già esistenti |

### 4.2 Cosa prendiamo da shinyWidgets

| Widget | Wrapper nostro | Dove | Perché |
|---|---|---|---|
| `virtualSelectInput()` | `picker_input()` | elenchi lunghi e selezione multipla (variabili, livelli) | Ricerca, gruppi, “seleziona tutto” e virtual scrolling: il più vicino a un listbox desktop |
| `pickerInput()` | `picker_input()` | alternativa a `virtualSelectInput()` | Si sceglie **uno** dei due in S3, non entrambi |
| `noUiSliderInput()` | `slider_input()` | parametri numerici limitati: alpha, jitter, base size, notch width | Un valore bounded si legge meglio su un binario che in una casella |
| `spectrumInput()` | `color_input()` | sfondo del grafico | Oggi è un `textInput` in cui si può scrivere qualsiasi cosa |
| `airDatepickerInput()` | `date_input()` | **rinviato** | Non c'è oggi un campo data: si aggiunge solo quando serve |
| `switchInput()`, `materialSwitch()`, `awesomeRadio()`, `awesomeCheckbox()` | — | **no** | Duplicano `switch_input()`/`segmented_input()` e portano uno stile proprio |
| `radioGroupButtons()` | — | **no** | `segmented_input()` fa già lo stesso con i nostri token |
| `dropdown()`, `searchInput()`, `knobInput()` | — | **no** | UI già coperta o fuori contesto |

### 4.3 Cosa resta nostro

`card_head()`, `note()`, `action_row()`, `toolbar()`, `tabs_strip()`,
`badge()`, `empty_state()`, `segmented_input()`, `switch_input()`,
`number_input()`, `field()`, `field_grid()`, `listbox_input()` per il
multi-select nativo, le 18 icone e il chrome dei modali. Le librerie non li
sostituiscono.

### 4.4 Il bridge dei temi

Due nuovi file, caricati da `app_css_files()` in quest'ordine:
`00-tokens.css`, `10-shell.css`, **`15-bootstrap.css`**, `20-components.css`,
`30-forms.css`, `40-dialogs.css`, `50-widgets.css`, **`55-shinywidgets.css`**,
`60-views.css`, `70-refine.css`.

| File | Contenuto |
|---|---|
| `inst/www/css/15-bootstrap.css` | variabili `--bs-accordion-*` mappate su `--rcmdr-*`; chevron disegnato con `::after` e `currentColor` (il data URI di Bootstrap non segue il tema); focus, hover, densità, `prefers-reduced-motion` |
| `inst/www/css/55-shinywidgets.css` | `.bootstrap-select`, `.noUi-*`, `.sp-*` mappati su superficie, bordo, testo, focus e altezza controllo; nessun colore letterale |

Regole:

- si dichiarano **una volta** con `var(--rcmdr-*)`: le palette cambiano il
  valore alla radice, non serve un blocco per tema;
- niente `!important` se non per il reduced motion;
- il foglio deve restare **dopo** le dipendenze di Shiny nell'ordine del
  `<head>`: lo si verifica con l'app avviata, non solo con `renderTags()`;
- ogni colore nuovo è un token esistente o non si aggiunge.

### 4.5 API dell'accordion

In `R/ui-components.R`:

```r
settings_accordion(id = NULL, ..., open = NULL, multiple = TRUE,
                   level = 3L, class = NULL)
settings_panel(title, ..., value = NULL, icon = NULL, badge = NULL,
               grid = TRUE)
settings_group(title, ..., help = NULL)
```

- `settings_accordion()` avvolge `bslib::accordion()`, aggiunge la classe
  `rcmdr-accordion` e post-processa ogni `.accordion-header` con
  `role="heading"` e `aria-level = level` (bslib non emette un heading).
- `settings_panel()` compone titolo, icona e badge; se `grid = TRUE` avvolge
  il corpo in `field_grid()`, così i campi mantengono la griglia esistente.
- `settings_group()` è un gruppo **non** richiudibile dentro un pannello:
  titolo, griglia e nota. Serve a evitare accordion annidati.
- `open` si passa all'accordion per valore (`open = c("Options")`), non al
  singolo pannello: è il contratto di bslib.
- I valori dei pannelli devono essere unici nell'accordion; un test lo
  verifica.
- Nel corpo dei dialoghi `.rcmdr-dialog-grid > .accordion` occupa tutte le
  colonne (`grid-column: 1 / -1`).

### 4.6 Stato, errori e riapertura

- L'accordion ha un `id` stabile quando serve leggerne lo stato
  (`input$<id>` restituisce i valori aperti).
- Se un `renderUI` ricostruisce i pannelli (cambio tipo di grafico), si
  riaprono i valori ancora disponibili letti con `isolate()`, altrimenti i
  default.
- Se la validazione fallisce, il dialogo apre **tutti** i pannelli e poi
  focalizza il primo campo invalido: un errore non deve restare nascosto.
  L'apertura è un messaggio JS generico (`rcmdr-open-accordions`), non una
  mappa campo → pannello.

### 4.7 Dove va l'accordion

| Superficie | Pannelli | Note |
|---|---|---|
| Chart Builder | *Options*, *Style*, *Axes*, *Text*, *Theme*, *Output* | “Chart and data” resta una scheda sempre visibile: è l'identità del grafico |
| *Options* | *Interface*, *Output*, *Data*, *Documents*, *Chart extensions* | prima vetrina, in S3 |
| *Import text data* | *Source*, *Parsing*, *Variables*, *Options* | i `conditionalPanel` restano dentro i pannelli |
| *Frequency Distributions* | *Variables*, *Tests*, *Output* | |
| Modelli | *Model*, *Data*, *Options* | formula e nome sempre nel primo pannello |
| Test statistici | *Variables*, *Hypothesis*, *Options* | |
| Report Studio | — | l'insert usa già `<details>`; non si migra per non avere due pattern |
| Plugin | — | fuori onda; usano gli stessi helper e potranno aderire dopo |

---

## 5. Sequenza degli step

Cinque lotti da tre. Stima: **14–16 giornate** effettive.

| Lotto | Step | Tema | Stima |
|---|---|---|---|
| 1 | S1–S3 | Specifica desktop, galleria, famiglie di widget | 4 gg |
| 2 | S4–S6 | Accordion e prima migrazione | 2 gg |
| 3 | S7–S9 | Chart Builder in profondità | 3 gg |
| 4 | S10–S12 | Listbox nei dialoghi e dialoghi densi | 3,5 gg |
| 5 | S13–S15 | Accessibilità, rifinitura desktop, chiusura | 2,5 gg |

### Lotto 1 — Il sistema dei widget

#### S1 — Inventario, specifica desktop, dipendenze, galleria

**Obiettivo:** avere un inventario completo dei widget, una specifica scritta e
un banco di prova che li mostri tutti, prima di cambiarne uno.

**File:** `DESCRIPTION`, `start.sh`, `R/app.R` (`app_css_files()`),
`inst/www/css/15-bootstrap.css`, `inst/www/css/55-shinywidgets.css`,
`docs/upgrades/UI-TOKENS.md`, `tools/widget_gallery.R`,
`tests/testthat/test-ui-tokens.R`, `tests/testthat/test-widgets.R`.

**Cosa cambia:**

- `shinyWidgets` in `Imports` con la versione minima verificata; installazione
  locale e `sessionInfo()` registrato nel diario;
- inventario delle famiglie: testo, numero, textarea, search, file, select
  singola/multipla, selectize, picker/listbox, checkbox, radio, switch,
  segmented, slider, colore, date, tabelle, editor, foglio;
- specifica desktop in `UI-TOKENS.md` (§ 4.0), con un token
  `--rcmdr-shadow-sm` per i menu;
- bridge CSS: `15-bootstrap.css` per `--bs-accordion-*` e i componenti
  Bootstrap, `55-shinywidgets.css` per picker, slider e colore;
- `tools/widget_gallery.R`: app Shiny di sviluppo, **non spedita**, che mostra
  ogni famiglia in tutti gli stati (normale, hover, focus, disabled, errore,
  read-only) con selettore di tema e densità;
- inventario di compatibilità Bootstrap 5 per `virtualSelectInput`,
  `pickerInput`, `noUiSliderInput`, `spectrumInput`.

**Accettazione:** l'app non cambia visivamente; la galleria rende tutte le
famiglie; nessun URL `http(s)` nelle dipendenze; i token superano il contrasto
in tutte le palette; la galleria non è inclusa nel pacchetto installato.

**Commit:** `build(ui): add the widget gallery and the desktop spec`

#### S2 — Campi, checkbox, radio, switch

**Obiettivo:** togliere gli ultimi segni del disegno predefinito del browser e
dare a campi e selettori binari la stessa mano.

**File:** `inst/www/css/30-forms.css`, `inst/www/css/50-widgets.css`,
`inst/www/css/55-shinywidgets.css`, `tests/testthat/test-widgets.R`,
`tests/testthat/test-contrast.R`.

**Cosa cambia:**

- checkbox e radio con `appearance: none`: 16 px, quadrato a 2 px di raggio o
  cerchio, segno netto, stato indeterminato, disabled, invalid, focus;
- switch rifinito sulla stessa griglia (36 × 20, pomello, on/off leggibili);
- campi testo, numero, textarea, search, input-group e file: bordo 1 px,
  hover, focus, placeholder, read-only, invalid, disabled;
- select nativa: freccia, padding e option hover coerenti; multi-select
  nativa come listbox a righe;
- test: markup e ID invariati; ogni stato presente nella galleria; contrasto
  8 temi × 2 densità.

**Accettazione:** nella galleria non resta un controllo con l'aspetto del
browser; i valori e gli ID sono quelli di prima; la matrice è verde.

**Commit:** `feat(ui): refine the field, checkbox and radio families`

#### S3 — Dropdown, listbox, picker

**Obiettivo:** scegliere **un** widget per ogni ruolo di elenco e dargli
l'aspetto di un menu desktop.

**File:** `R/widgets.R`, `inst/www/css/55-shinywidgets.css`,
`tests/testthat/test-widgets.R`, `tools/widget_gallery.R`.

**Cosa cambia:**

- prototipo di `virtualSelectInput`, `pickerInput` e listbox nativa nella
  galleria;
- decisione scritta per ruolo:
  - scelta singola corta → `<select>` nativa stilizzata;
  - elenco lungo o multiplo → `virtualSelectInput()` (preferito) oppure
    `pickerInput()`, mai entrambi;
  - listbox sempre visibile → `<select multiple>` nativa con
    `listbox_input()`;
- wrapper `picker_input()` e `listbox_input()`, con normalizzazione del vuoto
  al confine del chiamante;
- dropdown: superficie, bordo 1 px, ombra piccola, ricerca sticky, massimo
  320 px, chip, gruppi, stato vuoto, tastiera e type-ahead;
- primo uso reale: mapping del Chart Builder.

**Accettazione:** stessa selezione letta dal server; tastiera completa; 8 × 2
verde; se `virtualSelectInput` o `pickerInput` non reggono Bootstrap 5 o i
token, si sceglie il listbox nativo e la decisione va nel diario.

**Commit:** `feat(ui): add the dropdown and listbox families`

**Gate del lotto 1:** la galleria, nelle 8 palette × 2 densità, non mostra
controlli con l'aspetto del browser. Se il gate non passa, ci si ferma e si
rivede la specifica prima dell'accordion.

---

### Lotto 2 — Accordion e prima migrazione

#### S4 — Componente accordion

**Obiettivo:** avere l'API `settings_accordion()` / `settings_panel()` /
`settings_group()` con stile, ARIA e test.

**File:** `R/ui-components.R`, `inst/www/css/20-components.css`,
`inst/www/css/30-forms.css`, `tests/testthat/test-ui-components.R`,
`tests/testthat/test-accessibility.R`.

**Cosa cambia:**

- componenti come da § 4.5;
- heading semantics (`role="heading"`, `aria-level`), `aria-expanded` e
  `aria-controls` verificati sul markup di bslib;
- chevron con `::after` e `currentColor`; focus ring unico; hover su superficie;
- densità: padding di header e body da `--rcmdr-space`;
- `switch_input()`: si valuta la delega a `bslib::input_switch()`; si adotta
  solo se ID, valore e test restano identici, altrimenti resta com'è e la
  decisione va nel diario.

**Accettazione:** un accordion di prova con due pannelli rende una sola volta
gli ID, valori unici, `open` rispettato, icona e badge; nessun colore letterale;
test verdi.

**Commit:** `feat(ui): add the settings accordion component`

#### S5 — *Options* come prima vetrina

**Obiettivo:** migrare un dialogo reale e chiudere il cerchio su validazione e
pannelli.

**File:** `R/dialogs-tools.R`, `R/dialogs.R` (se serve il wrapper del corpo),
`inst/www/css/40-dialogs.css`, `inst/www/js/40-interactions.js`,
`tests/testthat/test-dialogs.R`, `tests/testthat/test-dialog-contract.R`.

**Cosa cambia:**

- *Options* in cinque pannelli; `hr` e `h6` spariscono, i titoli sono quelli
  dei pannelli; tutti i 9 ID e l'ordine interno restano;
- `.rcmdr-dialog-grid > .accordion { grid-column: 1 / -1; }`;
- su errore di validazione: messaggio `rcmdr-open-accordions`, apertura di
  tutti i pannelli, poi focus sul primo campo;
- test: gli ID ci sono ancora, *Apply* salva le stesse preferenze, il contract
  passa.

**Accettazione:** *Options* si apre con *Interface* aperto e gli altri chiusi;
un errore su *digits* apre *Output* e porta il focus lì; nessun altro dialogo
cambia.

**Commit:** `feat(ui): group the Options dialog into accordion panels`

#### S6 — Guscio del Chart Builder su accordion

**Obiettivo:** la colonna dei parametri diventa una scheda fissa più un
accordion, senza cambiare un solo ID.

**File:** `R/chart-studio.R`, `inst/www/css/60-views.css`,
`tests/testthat/test-chart-studio.R`.

**Cosa cambia:**

- “Chart and data” resta una `.rcmdr-section-card` sempre visibile (tipo,
  dataset, mapping, compose);
- il resto va in `settings_accordion("chart_settings", ...)` con *Options*
  aperto, *Theme*, *ggplot2* e *Output* chiusi;
- il preview e il comando generato restano nella colonna di destra, invariati;
- nessuna modifica al server.

**Accettazione:** tutti gli ID statici esistono una volta; il comando di un
grafico di riferimento è identico byte per byte; lo stato iniziale dei
pannelli è quello dichiarato.

**Commit:** `feat(chart): put the builder parameters into accordion panels`

**Gate del lotto 2:** *Options* e Chart Builder nelle 8 palette × 2 densità;
nessuna regressione nel contract.

---

### Lotto 3 — Chart Builder in profondità

#### S7 — Sottopannelli semantici di ggplot2

**Obiettivo:** spezzare il blocco unico di 18 controlli in pannelli che
raccontano un compito.

**File:** `R/chart-studio.R`, `tests/testthat/test-chart-studio.R`.

**Pannelli:** *Style* (position, alpha, binwidth, jitter, shape, smooth, SE,
flip), *Axes* (formati X/Y, facet scales, facet columns), *Text* (subtitle,
tag, title, caption, xlab, ylab, base size), *Theme* (gg theme, palette,
legend, background, grid), *Output* (width, height).

**Cosa cambia:** solo la posizione dei controlli; gli ID restano. Reset,
caricamento modello e anteprima continuano a leggere gli stessi input.

**Accettazione:** ogni `chart_gg_*` compare una volta; un modello caricato
aggiorna i campi anche se il pannello è chiuso; il comando resta identico.

**Commit:** `feat(chart): split the ggplot2 options into semantic panels`

#### S8 — Gruppi di opzioni per tipo e stato dei pannelli

**Obiettivo:** anche le opzioni dinamiche (3–9 per tipo) hanno una gerarchia,
e il cambio tipo non perde i pannelli aperti.

**File:** `R/chart-types.R`, `R/chart-studio.R`,
`tests/testthat/test-chart-types.R`, `tests/testthat/test-chart-studio.R`.

**Cosa cambia:**

- metadato opzionale `option_groups` nei descrittori dei tipi core; default
  un gruppo solo;
- `chart_options_ui()` costruisce un accordion con ID stabile
  `chart_type_options`; `open` viene letto con `isolate()` e filtrato sui
  gruppi disponibili;
- `settings_group()` per i sottogruppi interni, senza accordion annidati.

**Accettazione:** per ogni tipo disponibile, l'insieme degli ID renderizzati
coincide con i controlli attesi; nessun duplicato; il comando resta identico;
cambiando tipo i pannelli ancora validi restano aperti.

**Commit:** `feat(chart): group the per-type options and keep the open panels`

#### S9 — Slider e colore

**Obiettivo:** rendere leggibili i parametri limitati e correggere il campo
colore libero.

**File:** `R/widgets.R`, `R/chart-studio.R`, `R/dialogs-stats.R` (se serve),
`inst/www/css/55-shinywidgets.css`, test.

**Cosa cambia:**

- `slider_input()` su `noUiSliderInput()` per alpha, jitter, base size, notch
  width: stesso ID, stesso valore numerico, stesso `min`/`max`/`step`;
- `color_input()` su `spectrumInput()` per lo sfondo del grafico: il valore
  resta una stringa di colore, il comando non cambia;
- nessun nuovo parametro statistico: si cambia solo il controllo.

**Accettazione:** i comandi di default sono identici; i valori sono letti come
numeri e come stringhe di colore; focus e tastiera presenti; resa verificata
sulle 8 palette.

**Commit:** `feat(ui): use sliders and a colour picker for bounded parameters`

**Gate del lotto 3:** tutti i 25 tipi (meno quelli non disponibili)
renderizzati; un grafico per famiglia con comando identico; nessuna opzione
persa.

---

### Lotto 4 — Listbox nei dialoghi e dialoghi densi

#### S10 — `var_input()` sulla famiglia scelta

**Obiettivo:** far sì che tutte le selezioni di variabili abbiano lo stesso
aspetto, non solo quelle del Chart Builder.

**File:** `R/widgets.R`, `tests/testthat/test-widgets.R`,
`tests/testthat/test-dialog-contract.R`, test dei dialoghi rappresentativi.

**Cosa cambia:**

- `var_input()` delega a `listbox_input()` o `picker_input()` scelto in S3,
  mantenendo `descriptions`, `multiple`, `selected` e la larghezza;
- i 106 punti di chiamata non cambiano: è la cucitura a cambiare;
- se il contract completo non regge (valori, ID, ordinamento, descrizioni), si
  torna a `selectizeInput` e si documenta il perché.

**Accettazione:** contract e dialoghi verdi; la selezione letta dal server è
identica; tastiera e 8 × 2 verdi; nessun dialogo cambia ID.

**Commit:** `feat(ui): give every variable selector the same listbox`

#### S11 — Dialoghi dati e distribuzioni

**Obiettivo:** raggruppare i dialoghi con molti parametri di lettura e
distribuzione.

**File:** `R/dialogs-import-text.R`, `R/dialogs-stats.R`,
`tests/testthat/test-dialogs.R`, `tests/testthat/test-dialog-contract.R`.

**Cosa cambia:**

- *Import text data*: *Source* (nome, posizione, path/URL), *Parsing*
  (separatore, decimale, missing, header), *Variables* (stringsAsFactors),
  *Options* (help);
- *Frequency Distributions*: *Variables*, *Tests*, *Output*;
- i `conditionalPanel` restano dentro il pannello che li possiede.

**Accettazione:** contract verde; tutti gli ID presenti; i pannelli
condizionali si aprono e si chiudono senza perdere valori; un errore apre il
pannello giusto grazie alla regola generale di S5.

**Commit:** `feat(dialogs): group the data and distribution dialogs`

#### S12 — Dialoghi modelli e test

**Obiettivo:** completare i dialoghi densi rimasti.

**File:** `R/dialogs-stats.R`, `R/dialogs-models.R`,
`R/dialogs-models-extra.R`, test.

**Cosa cambia:**

- modelli: *Model* (nome, formula), *Data* (subset, weights, remove),
  *Options* (famiglia/link o extra del tipo);
- test: *Variables*, *Hypothesis* (alternativa, confidenza), *Options*
  (varianze, ecc.);
- nessuna modifica agli `on_ok`.

**Accettazione:** contract e test dei dialoghi rappresentativi verdi; gli ID
restano; i valori di default sono gli stessi.

**Commit:** `feat(dialogs): group the model and test dialogs`

**Gate del lotto 4:** contract completo; nessun campo perso o duplicato; la
selezione variabile è la stessa in tutti i dialoghi.

---

### Lotto 5 — Accessibilità, rifinitura desktop, chiusura

#### S13 — Accessibilità ed errori

**Obiettivo:** chiudere i requisiti trasversali sui nuovi componenti.

**File:** `inst/www/js/70-keyboard.js` (se serve),
`tests/testthat/test-accessibility.R`,
`tests/testthat/test-theme-matrix.R`.

**Cosa cambia:**

- heading semantics e `aria-level` verificati su ogni accordion;
- frecce tra header (solo se Bootstrap non le offre) e `Esc` invariato;
- focus ring unico, `prefers-reduced-motion`, contrasto dei nuovi token;
- prova di errore: campo in pannello chiuso → apertura + focus;
- tastiera di picker/listbox: apertura, frecce, Invio, Esc, type-ahead.

**Accettazione:** il focus non finisce mai su un elemento `display:none`; i
test di tastiera passano; nessuna violazione di contrasto.

**Commit:** `test(ui): cover accordions and widgets across themes and keyboard`

#### S14 — Rifinitura desktop e QA visiva

**Obiettivo:** controllare i widget specialistici e chiudere l'aspetto
“desktop” su tutta l'interfaccia.

**File:** `inst/www/css/50-widgets.css`, `inst/www/css/60-views.css`,
`tools/widget_gallery.R`, `docs/upgrades/QA-WIDGETS.md`,
`tests/testthat/test-theme-matrix.R`.

**Cosa cambia:**

- audit e rifinitura di DT (filtri, paginazione, selezione), Ace,
  rhandsontable, shinyFiles, plotly, menu, tab, alert e progress;
- tabelle con righe da 32 px in compatto, header sticky, hover e selezione;
- scrollbar e cursori coerenti; nessun controllo con l'aspetto del browser;
- galleria: screenshot per le 8 palette × 2 densità dove il browser funziona;
- matrice 8 × 2 estesa a un accordion con picker, slider e color picker;
- `QA-WIDGETS.md`: metodo, comandi, esito, limiti e checklist manuale.

**Accettazione:** matrice verde; nessuna violazione di contrasto; la galleria
mostra ogni famiglia negli stati previsti; i limiti e2e/screenshot sono
documentati.

**Commit:** `test(ui): finish the desktop polish and the widget QA`

#### S15 — Chiusura

**Obiettivo:** documentare, verificare e consegnare.

**File:** `NEWS.md`, `inst/help-topics/topics/about.md`,
`docs/upgrades/UI-TOKENS.md`, `docs/upgrades/CHECKLIST.md`,
`docs/upgrades/README.md`, `docs/upgrades/diary/wave-16-bslib-widgets.md`,
`docs/upgrades/QA-WIDGETS.md`.

**Cosa cambia:**

- NEWS: accordion, famiglie di widget, cosa resta nostro;
- topic `about-studio`: dove sono i pannelli e come si comportano;
- `UI-TOKENS.md`: bridge `--bs-*`, token `--rcmdr-shadow-sm` e proprietà dei
  widget;
- checklist e diario chiusi; limiti e2e/screenshot ripetuti;
- suite completa, app riavviata, push.

**Accettazione:** `EXIT=0`; 26 e2e saltati e 3 warning noti; working tree
pulito.

**Commit:** `docs: close wave 16`

---

## 6. Matrice di adozione

| Esigenza | Libreria | Wrapper | Prima applicazione | Rischio |
|---|---|---|---|---|
| Gruppi richiudibili | bslib | `settings_accordion()` | *Options*, Chart Builder | medio: ARIA e stato |
| Switch manutenuto | bslib | `switch_input()` (condizionale) | 7 chiamate | basso |
| Elenco lungo o multiplo | shinyWidgets | `picker_input()` | Chart mapping, `var_input()` | medio: valore vuoto, BS5 |
| Listbox sempre visibile | nativa | `listbox_input()` | `var_input()` | medio: 106 chiamate |
| Numero limitato | shinyWidgets | `slider_input()` | alpha, jitter, size, notch | basso |
| Colore | shinyWidgets | `color_input()` | sfondo grafico | basso |
| Campi e binari | nostro CSS | `field()`, `checkbox_input()`, `radio_input()`, `switch_input()` | ovunque | basso |
| Tabelle | DT | — | Data Studio | basso: solo rifinitura |
| Icone | nostro set | — | ovunque | nessun cambio |

---

## 7. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| shinyWidgets non è allineato a Bootstrap 5 su un widget | stile rotto o JS in errore | inventario in S1; un widget non conforme non entra |
| `virtualSelectInput`/`pickerInput` pesanti o incompatibili | esperienza peggiore del selectize | prototipo in S3; fallback al listbox nativo |
| `var_input()` cambiato in 106 punti | contract rosso | S10 è un passo isolato e reversibile; il contract è il gate |
| I widget esterni non seguono le 8 palette | terzo linguaggio visivo | bridge in `55-shinywidgets.css` + matrice in S14 |
| L'accordion perde lo stato al cambio tipo | pannelli che si richiudono | ID stabile + `isolate()` + default espliciti |
| Un errore finisce in un pannello chiuso | validazione invisibile | apertura di tutti i pannelli + focus (S5) |
| bslib non emette heading | navigazione screen reader debole | `role="heading"` + `aria-level` in `settings_accordion()` |
| Cambio di markup e test fragili | suite rossa | ID invariati; si aggiornano solo le asserzioni strutturali |
| Peso delle dipendenze | installazione più lenta | misurare CSS/JS in S1; niente widget in più |
| Classic mode | i dialoghi cambiano aspetto anche lì | accettato: le tab restano identiche, i dialoghi sono condivisi |
| Scope creep (tooltip, date, reactable) | onda che non chiude | lista “fuori onda” in § 8 |

---

## 8. Fuori onda

- `tooltip()`/`popover()`: rimandati; l'help testuale resta dove è.
- `airDatepickerInput()`: nessun campo data oggi.
- `reactable` o sostituzione di DT: progetto separato.
- `bslib::card()`/`navset_*()`/`layout_columns()`: duplicano la shell.
- Nuovi parametri statistici o di grafico (limiti assi, colori personalizzati):
  cambierebbero i comandi, non solo la pelle.
- Migrazione dei dialoghi dei plugin: useranno gli helper quando vorranno.
- Lazy rendering dei pannelli: l'accordion non riduce il DOM; non si promette
  un guadagno di prestazioni.
- Risistemazione della shell, delle tab o dei menu: fatta nell'Onda 15.

---

## 9. Criteri di chiusura

- [ ] 15 step, 5 lotti, ognuno con commit verde e handoff dopo il terzo.
- [ ] Nessun ID, valore, comando o stringa i18n cambiato.
- [ ] Ogni famiglia di widget ha specifica, galleria e test.
- [ ] Nessun controllo con l'aspetto predefinito del browser nella galleria.
- [ ] Chart Builder con “Chart and data” fisso e 6 pannelli; nessuna opzione
      persa.
- [ ] *Options*, *Import*, *Frequency*, modelli e test raggruppati.
- [ ] `var_input()` usa la famiglia scelta in tutti i 106 punti.
- [ ] 8 temi × 2 densità verdi, nuovi componenti inclusi.
- [ ] Accessibilità: heading, aria, tastiera, focus, reduced motion.
- [ ] Errore in pannello chiuso → pannello aperto e campo focalizzato.
- [ ] `NEWS.md`, topic, token, checklist, diario e QA aggiornati.
- [ ] e2e e screenshot: eseguiti dove il browser funziona; altrimenti limite
      documentato.

---

## 10. Protocollo di handoff

Dopo **S3**, **S6**, **S9**, **S12** e **S15**:

1. suite completa (`Rscript --vanilla -e 'testthat::test_local()'`) e log in
   `/tmp/opencode/tests-w16-<lotto>.log`;
2. aggiornamento di `docs/upgrades/diary/wave-16-bslib-widgets.md` con: cosa è
   fatto, deviazioni, problemi, prossimo passo;
3. checkpoint git pulito e push;
4. stop: l'utente compatta il contesto e riprende con `continua`.

Il diario viene creato alla fine del lotto 1 e aggiornato agli handoff
successivi.
