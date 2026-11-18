# Token di interfaccia — Onda 15

**Stato:** U0.4 completata; scala tipografica e spaziature introdotte in U1.1,
altezze e focus in U1.2.  
**Documento di settore:** [`15-ui-refresh.md`](15-ui-refresh.md)  
**Fogli di stile:** `inst/www/css/` (composti da `app_css()`).

Questo documento è il contratto dei token. Se un componente ha bisogno di un
colore, una misura o uno stato che non è qui, la risposta è **aggiungere un
token con un ruolo**, non scrivere un valore nel selettore.

---

## 1. Regole

1. **Il token descrive un ruolo, non un aspetto.** `--rcmdr-muted` dice “testo
   secondario”, non “grigio”. Se il tema cambia, il ruolo resta.
2. **Un ruolo, un token.** Due nomi per lo stesso ruolo sono un errore: il
   secondo viene eliminato, non affiancato.
3. **Nessun colore o misura grezza nel CSS nuovo.** I valori ammessi in un
   selettore sono `0`, `100%`, `auto`, unità di viewport e `calc()` su token.
   Le eccezioni esistenti si migrano quando si tocca il componente.
4. **I token globali stanno in `:root`.** I token di colore stanno in ogni
   palette, perché ogni tema deve poterli ridefinire.
5. **La densità non cambia la semantica.** `compact` e `comfortable` cambiano
   solo misure (altezze, spaziature, corpo del testo), mai colori o ruoli.
6. **Il contrasto è misurato, non stimato.** Ogni nuova coppia
   testo/sfondo entra nella tabella del § 4 con il rapporto calcolato su tutti
   i temi (WCAG 2.1, formula della luminanza relativa).

---

## 2. Dove vivono i token

| File | Contenuto |
|---|---|
| `00-tokens.css` | palette (7 regole colore), scala tipografica, spaziature, raggi, ombre, focus |
| `10-shell.css` | shell: topbar, barra laterale, barra di stato, striscia delle viste |
| `15-bootstrap.css` | bridge dei componenti bslib/Bootstrap: variabili `--bs-accordion-*`, chevron, focus |
| `20-components.css` | componenti condivisi: badge, toolbar, schede, chrome dei modali, viste |
| `30-forms.css` | token di densità (`--rcmdr-label-*`, `--rcmdr-control-*`, `--rcmdr-btn-*`, `--rcmdr-field-gap`, `--rcmdr-help-size`) e i componenti `field`, switch, segmented |
| `40-dialogs.css` | usa i token; nessuna definizione |
| `55-shinywidgets.css` | bridge di picker/listbox, slider e color picker; nessun colore letterale |
| altri file | solo `var(--rcmdr-…)` |

I nomi dei file sono storici (U0 ha estratto blocchi contigui). U2 ha
consolidato le regole di shell in `10-shell.css`, togliendole da `30-forms.css`
e `60-views.css`; una divisione per strati più stretta non serve finché ogni
regola ha un solo posto dove vivere.

---

## 3. Token di colore

Ogni palette definisce gli stessi 33 token. Le palette sono:

`light` (default), `light-warm`, `light-cool`, `dark`, `dark-dim`,
`dark-graphite`, `contrast` (alto contrasto, chiaro).

| Token | Ruolo | Note |
|---|---|---|
| `--rcmdr-bg` | sfondo della pagina | dietro le finestre |
| `--rcmdr-surface` | superficie primaria | card, campi, modali |
| `--rcmdr-surface-muted` | superficie secondaria | barre, header di tabella |
| `--rcmdr-surface-sunken` | superficie incassata | pannelli codice, output |
| `--rcmdr-text` | testo normale | ≥ 14.25:1 su ogni superficie |
| `--rcmdr-heading` | titoli | più scuro/più luminoso del testo |
| `--rcmdr-muted` | testo secondario e help | ≥ 6.38:1 |
| `--rcmdr-disabled` | testo disabilitato | esente WCAG; ≥ 3.5:1 comunque |
| `--rcmdr-link` | link | distinto dall'accento |
| `--rcmdr-border` | bordi decorativi | card, tabelle, separatori; non il confine di un controllo |
| `--rcmdr-border-strong` | confine dei controlli | ≥ 3:1 su ogni superficie (§ 4) |
| `--rcmdr-primary` | barra superiore, intestazioni | |
| `--rcmdr-on-primary` | testo sul primario | ≥ 9.41:1 |
| `--rcmdr-on-primary-muted` | testo secondario sul primario | ≥ 7.42:1 |
| `--rcmdr-accent` | azione, selezione, focus | ≥ 5.83:1 su superficie |
| `--rcmdr-hover` | sfondo hover | |
| `--rcmdr-selection` | selezione di testo/riga | |
| `--rcmdr-mark-bg` / `--rcmdr-mark-text` | evidenziazione ricerca | coppia inscindibile |
| `--rcmdr-hero-from` / `--rcmdr-hero-to` | gradiente della home | |
| `--rcmdr-ok-bg` / `--rcmdr-ok-fg` | stato positivo | coppia inscindibile |
| `--rcmdr-warn-bg` / `--rcmdr-warn-fg` | stato di avviso | coppia inscindibile |
| `--rcmdr-err-bg` / `--rcmdr-err-fg` | stato di errore | coppia inscindibile |
| `--rcmdr-danger` | testo/icona di pericolo | su superficie |
| `--rcmdr-warning` | testo/icona di avviso | su superficie |
| `--rcmdr-success` | testo/icona di successo | su superficie |
| `--rcmdr-shadow` | ombra di elevazione | modali e superfici grandi; colore incluso nel valore |
| `--rcmdr-shadow-sm` | ombra di menu e dropdown | colore incluso nel valore |
| `--rcmdr-focus` | anello di focus | = accento, definito per tema |
| `--rcmdr-focus-ring` | alone tenue per widget e stati “corrente” | rinforzo, non indicatore unico |
| `--rcmdr-focus-width` / `--rcmdr-focus-offset` | geometria unica del focus | `2px` / `2px` |

> **Perché `--rcmdr-focus` e `--rcmdr-accent` sono due token?** Oggi hanno lo
> stesso valore in tutti i temi. Sono separati perché un tema ad alto
> contrasto può volere un focus di colore diverso dall'accento, e perché il
> focus è un requisito di accessibilità, non una scelta estetica.

---

## 4. Contrasto misurato

Rapporti calcolati sui valori di `00-tokens.css`. Il minimo è su tutte le
palette; **AA** per testo normale è 4.5:1, per testo grande 3:1, per componenti
non testuali 3:1.

| Coppia | Minimo | Massimo | Esito |
|---|---:|---:|---|
| `text` su `surface` | 13.26 | 21.00 | AA |
| `text` su `surface-muted` | 11.57 | 18.76 | AA |
| `text` su `surface-sunken` | 14.25 | 19.26 | AA |
| `text` su `bg` | 14.32 | 21.00 | AA |
| `heading` su `surface` | 12.76 | 21.00 | AA |
| `muted` su `surface` | 7.48 | 16.48 | AA |
| `muted` su `surface-muted` | 6.38 | 14.72 | AA |
| `link` su `surface` | 7.94 | 10.88 | AA |
| `on-primary` su `primary` | 9.41 | 21.00 | AA |
| `on-primary-muted` su `primary` | 7.42 | 21.00 | AA |
| `accent` su `surface` | 5.83 | 9.68 | AA (anche 3:1 UI) |
| `focus` su `surface` | 5.83 | 9.68 | AA (3:1 UI) |
| `ok-fg` su `ok-bg` | 6.88 | 10.66 | AA |
| `warn-fg` su `warn-bg` | 5.99 | 10.95 | AA |
| `err-fg` su `err-bg` | 6.68 | 10.89 | AA |
| `danger` su `surface` | 6.50 | 8.88 | AA |
| `warning` su `surface` | 5.43 | 10.47 | AA |
| `success` su `surface` | 5.69 | 11.33 | AA |
| `on-primary` su `hero-from` | 10.96 | 21.00 | AA |
| `on-primary` su `hero-to` | 6.72 | 21.00 | AA |
| `on-primary-muted` su `hero-from` | 8.37 | 21.00 | AA |
| `on-primary-muted` su `hero-to` | 5.13 | 21.00 | AA |
| `border-strong` su `surface` | 3.53 | 21.00 | 3:1 UI |
| `border-strong` su `surface-muted` | 3.07 | 18.76 | 3:1 UI |
| `border-strong` su `surface-sunken` | 3.61 | 19.26 | 3:1 UI |
| `disabled` su `surface` | 3.57 | 8.86 | esente (testo inattivo) |
| `border` su `surface` | **1.62** | 21.00 | decorativo, mai confine di un controllo |

### Lacune chiuse in U1.4

| Lacuna | Com'è stata chiusa |
|---|---|
| Bordo dei campi | nuovo token `--rcmdr-border-strong` (≥ 3.07:1 su ogni superficie), applicato a `form-control`, `form-select`, `form-check-input` e selectize. `--rcmdr-border` resta per i bordi decorativi. |
| Sottotitolo della hero | il gradiente ora usa `--rcmdr-hero-from`/`--rcmdr-hero-to` invece di `primary → accent`: l'accento è chiaro nei temi scuri e il testo bianco scendeva a **1.67:1**. Con i token della hero il minimo è 5.13:1. In `light-cool` e `light-warm` la seconda tinta è stata scurita per lasciare margine. |
| Badge della topbar | `text-white-50` di Bootstrap scendeva a 4.14:1 sulla barra primaria: ora è `--rcmdr-on-primary-muted` (≥ 7.42:1). Rimossi i due colori fissi `#7ee2a8` e `#ffb3ad`, che erano rimasti senza consumatori. |
| Alone del focus | l'alone in `rgba(..., .28)` non raggiunge 3:1. Per questo il focus usa un `outline` pieno in `--rcmdr-focus` (5.83:1 minimo) e l'alone resta solo come rinforzo visivo. |

`tests/testthat/test-contrast.R` ricalcola questa tabella da `app_css()`: ogni
coppia è un'asserzione, quindi una palette nuova non può entrare senza i suoi
numeri.

---

## 5. Scala tipografica

Quattro taglie di testo più due display. I nomi descrivono la dimensione, non
l'elemento: la stessa taglia serve a un'etichetta e a una cella di tabella.

| Token | Valore | px | Uso |
|---|---|---:|---|
| `--rcmdr-text-xs` | `.75rem` | 12 | help, metadati, badge, note |
| `--rcmdr-text-sm` | `.8125rem` | 13 | etichette, controlli, celle |
| `--rcmdr-text-md` | `.875rem` | 14 | prosa dei dialoghi, testo comodo |
| `--rcmdr-text-lg` | `1rem` | 16 | titoli di card, corpo dei documenti |
| `--rcmdr-text-xl` | `1.35rem` | 21.6 | valori delle metriche |
| `--rcmdr-text-2xl` | `1.65rem` | 26.4 | titolo della hero |

Pesi e interlinea:

| Token | Valore | Uso |
|---|---|---|
| `--rcmdr-weight-normal` | `400` | testo |
| `--rcmdr-weight-strong` | `600` | etichette, titoli, enfasi |
| `--rcmdr-leading-tight` | `1.25` | titoli |
| `--rcmdr-leading-normal` | `1.5` | prosa |
| `--rcmdr-leading-ui` | `1.4` | controlli e righe compatte |

Regole di impiego:

- niente `font-size` sotto `.75rem`: 12 px è il pavimento, anche nei metadati;
- i pesi sono due. `700` e `800` non si usano: a 13 px il grassetto pieno
  diventa una macchia;
- la dimensione del testo dei controlli viene dalla densità, non dal singolo
  dialogo (`--rcmdr-control-size`).

In U1.1 i valori grezzi sparsi nei componenti (`.68`, `.78`, `.82`, `.85`,
`.86`, `.88`, `.9`, `.92`, `1.1rem`) sono stati ricondotti allo scalino più
vicino. Lo scarto massimo è 1.6 px (il `+` dei documenti, da 17.6 a 16 px);
nessun blocco di testo cambia riga. Da qui in avanti un `font-size` grezzo in
`inst/www/css/` è un errore, e `test-ui-tokens.R` lo intercetta.

La densità usa la scala come sorgente: `compact` prende `sm`/`md`/`xs`,
`comfortable` sale di uno scalino per etichette e help. I controlli restano a
`md` in entrambe, perché 14 px è la misura leggibile minima per un campo.

---

## 6. Spaziature

Scala a 4 px. Il valore è il passo, non il pixel: `--rcmdr-space-3` è “tre
passi”, cioè 12 px.

| Token | Valore | px |
|---|---|---:|
| `--rcmdr-space-1` | `.25rem` | 4 |
| `--rcmdr-space-2` | `.5rem` | 8 |
| `--rcmdr-space-3` | `.75rem` | 12 |
| `--rcmdr-space-4` | `1rem` | 16 |
| `--rcmdr-space-5` | `1.5rem` | 24 |
| `--rcmdr-space-6` | `2rem` | 32 |

`--rcmdr-space` resta come alias del passo usato dai layout esistenti
(8 px in `compact`, 12 px in `comfortable`), così i selettori che lo usano non
cambiano. I micro-spazi interni a un controllo (padding di un badge, distanza
di un'icona) possono scendere sotto 4 px: sono ritocchi ottici, non spaziatura
di layout.

---

## 7. Raggi

| Token | Valore | px | Uso |
|---|---|---:|---|
| `--rcmdr-radius-xs` | `.25rem` | 4 | marche, chip, miniature |
| `--rcmdr-radius-sm` | `.375rem` | 6 | pannelli codice, output |
| `--rcmdr-radius-md` | `.5rem` | 8 | controlli, card, toolbar |
| `--rcmdr-radius-lg` | `.75rem` | 12 | modali, hero |
| `--rcmdr-radius-pill` | `999px` | — | pillole di stato, segmented |

`--rcmdr-radius` resta l'alias di `--rcmdr-radius-md` per i 17 selettori che
lo usano. I valori grezzi sparsi (`.3rem`, `.35rem`, `.4rem`, `.45rem`) sono
stati ricondotti allo scalino più vicino in U1.1: lo scarto massimo è 0.8 px e
non è percepibile. La direzione visiva approvata prevede 12–14 px per le card:
il passaggio da `md` a `lg` avviene in U2 insieme al restyle delle card, non
come effetto collaterale di U1. Modali e hero usano già `lg`.

---

## 8. Ombre

| Token | Ruolo |
|---|---|
| `--rcmdr-shadow` | elevazione di modali e superfici grandi |
| `--rcmdr-shadow-sm` | elevazione di menu, dropdown, tooltip e popover |

L'ombra include il colore e cambia per tema: nei temi scuri è più opaca, in
`contrast` è assente o quasi. Un componente non scrive mai `box-shadow` con
colori propri. In U1.1 l'unico valore grezzo rimasto (il dropdown del menubar)
è stato ricondotto a questo token; l'Onda 16 aggiunge la variante piccola per
le superfici flottanti.

---

## 9. Controlli, altezze e stati

Altezza unica dei controlli:

| Token | `compact` | `comfortable` |
|---|---|---|
| `--rcmdr-control-h` | `2.125rem` (34 px) | `2.5rem` (40 px) |
| `--rcmdr-control-min` | `var(--rcmdr-control-h)` (compatibilità) | idem |

La stessa altezza vale per `input`, `select`, `selectize` e i gruppi di input.
Le aree di testo (`textarea`) hanno `min-height`, non `height`: devono poter
crescere.

### 9.1 Pulsanti

| Token | `compact` | `comfortable` |
|---|---|---|
| `--rcmdr-btn-h` | `var(--rcmdr-control-h)` (34 px) | idem (40 px) |
| `--rcmdr-btn-h-sm` | `calc(var(--rcmdr-control-h) - .375rem)` (28 px) | 34 px |

Un pulsante è alto come un campo; `btn-sm` scende di 6 px, che è la misura che
fa stare sei azioni su una riga di toolbar. Il contenuto è centrato con
`inline-flex`, quindi un'icona e il testo non hanno bisogno di margini
artificiali; `white-space: nowrap` evita che un'etichetta vada a capo dentro un
gruppo.

Sei ruoli, tutti sulle classi Bootstrap già presenti nei dialoghi:

| Ruolo | Classi | Colori |
|---|---|---|
| primario | `btn-primary` | riempimento `primary` / testo `on-primary` |
| secondario | `btn-outline-secondary`, `btn-outline-dark`, `btn-light`, `btn-default` | `surface` + `border`; hover `hover`, attivo `selection` |
| contorno d'accento | `btn-outline-primary` | testo e bordo `accent`; hover `hover` + `heading` |
| fantasma | `btn-link` | trasparente; hover `hover` |
| distruttivo | `btn-outline-danger` (contorno), `btn-danger` (tinta) | `danger` / `err-fg` su `err-bg` |
| stato | `btn-success`, `btn-warning` | coppie `ok-*`, `warn-*` |
| sulla barra primaria | `btn-outline-light` | `on-primary`; hover invertito con `primary` |

Regola dura: un riempimento pieno usa solo una coppia garantita
(`primary`/`on-primary`). L'accento e i colori di stato sono **chiari** nei
temi scuri: usarli come sfondo con testo bianco scenderebbe sotto 2:1. Per
questo l'hover dei pulsanti pieni è un `filter: brightness()` (che scala testo
e sfondo insieme) e l'hover dei pulsanti a contorno è una superficie
(`hover`/`selection`/`err-bg`), non un riempimento saturo.

Stati e token:

| Stato | Come si vede | Token |
|---|---|---|
| default | superficie + bordo | `surface`, `border`, `border-strong` |
| hover | sfondo leggermente pieno | `hover` |
| focus | anello unico | `focus`, `focus-width`, `focus-offset` |
| attivo/selezionato | accento su superficie | `accent`, `selection` |
| disabilitato | una superficie piatta, cursore `not-allowed` | `surface-muted`, `border`, `disabled` |
| errore | bordo e testo di errore | `err-fg`, `danger` |
| caricamento | testo/icona di avviso, nessuna animazione obbligatoria | `warning` |

L'anello di focus è **uno**: `outline: var(--rcmdr-focus-width) solid
var(--rcmdr-focus)` con `outline-offset: var(--rcmdr-focus-offset)`. Non ci
sono due regole `:focus-visible` globali, non ci sono outline da 2 e da 3 px
nello stesso prodotto. Il selectize, che disegna il proprio campo, riceve lo
stesso outline sul contenitore e l'alone (`--rcmdr-focus-ring`) solo come
rinforzo; l'input nascosto al suo interno non aggiunge un secondo anello.
Con `prefers-reduced-motion` non si anima nulla.

---

## 10. Densità

| Token | `compact` | `comfortable` |
|---|---|---|
| `--rcmdr-space` | 8 px | 12 px |
| `--rcmdr-field-gap` | `.4rem` | `1rem` |
| `--rcmdr-label-size` | `text-sm` (13) | `text-md` (14) |
| `--rcmdr-label-gap` | `.1rem` | `.5rem` |
| `--rcmdr-control-size` | `text-md` (14) | `text-md` (14) |
| `--rcmdr-control-pad` | `.4rem .5rem` | `.55rem .75rem` |
| `--rcmdr-control-h` | 34 px | 40 px |
| `--rcmdr-section-gap` | `.4rem` | `1rem` |
| `--rcmdr-help-size` | `text-xs` (12) | `text-sm` (13) |

`compact` è il default: nessuna classe sul `body` significa compatto. La
classe `rcmdr-density-comfortable` aggiunge il respiro; la classe
`rcmdr-density-compact` esiste solo per rendere esplicito il default.

La densità è una preferenza persistita (`state$options$density`) e viene
applicata via `rcmdr-theme` con il resto del tema: non c'è un secondo canale.

---

## 11. Convenzioni di nome

```
--rcmdr-<categoria>-<passo>
        │           └─ xs | sm | md | lg | xl | 2xl | 1..6
        └─ colore semantico, misura, stato
```

- colore: `surface`, `border`, `text`, `muted`, `accent`, `ok`, `warn`, `err`;
- misura: `space`, `radius`, `control`, `text`;
- stato: `hover`, `selection`, `disabled`, `focus`.

Un token nuovo richiede: la riga in **tutte** le palette (se è un colore), la
riga in questa tabella, il consumo in almeno un selettore. Un token che nessuno
usa viene rimosso.

---

## 12. Specifica desktop e widget esterni

La specifica vale per ogni famiglia di input. La verifica visiva vive in
`tools/widget_gallery.R` (applicazione di sviluppo, esclusa dal pacchetto):
mostra ogni famiglia negli stati normale, hover, focus, disabled, errore e
read-only, con selettore di tema e densità.

### 12.1 Proprietà

| Componente | Fornitore | Regola |
|---|---|---|
| Accordion, card, navset | bslib | solo accordion in questa onda; card e navset restano nostri |
| Picker, listbox, slider, colore | shinyWidgets | dietro `picker_input()`, `listbox_input()`, `slider_input()`, `color_input()` |
| Campi, checkbox, radio, switch, segmented | nostro CSS | nessun widget esterno equivalente |
| Icone | nostro set | 18 SVG inline |
| Tabelle | DT | nessuna sostituzione nei dati editabili |

`shinyWidgets` porta con sé i propri asset (virtual-select, bootstrap-select,
nouislider, spectrum, air-datepicker) e Font Awesome: sono tutti serviti dal
pacchetto, nessun CDN. Il peso va misurato a ogni aggiornamento della
dipendenza.

### 12.2 Famiglie e stato

| Famiglia | Implementazione | Stato |
|---|---|---|
| Testo, numero, textarea, search | Shiny + `30-forms.css` | tokenizzato e rifinito in S2 |
| Select singola/multipla | Shiny + `50-widgets.css` | tokenizzata; listbox nativa da rifinire |
| Variabili (`var_input`) | `selectizeInput` | da migrare alla famiglia scelta (Onda 16, S10) |
| Picker/listbox ricercabile | shinyWidgets | da introdurre (Onda 16, S3) |
| Checkbox, radio | Bootstrap + `50-widgets.css` | 16 px, segno netto, indeterminato e stati (S2) |
| Switch | nostro `.rcmdr-switch` | pronto |
| Segmented | nostro `.rcmdr-segmented` | pronto |
| Slider, colore | shinyWidgets | da introdurre (Onda 16, S9) |
| Date | shinyWidgets | rinviato all'Onda 17, T2 |

### 12.3 Regole desktop

| Elemento | Regola |
|---|---|
| Altezza | 34 px compatto / 40 px comodo, anche per i widget esterni |
| Bordo | 1 px `--rcmdr-border-strong` sui controlli |
| Raggio | 6 px controlli, 8 px dropdown, 12 px modali |
| Elevazione | solo su dropdown, tooltip, popover e modali; `--rcmdr-shadow-sm` per i menu |
| Hover | cambia bordo e superficie, non sposta il contenuto; massimo 150 ms |
| Focus | un solo anello da 2 px, offset 2 px |
| Disabled | opacità e cursore coerenti, valore leggibile |
| Errore | bordo `--rcmdr-danger` più messaggio, mai solo colore |
| Checkbox/radio | 16 px, quadrato a 2 px o cerchio, segno netto, indeterminato |
| Dropdown | ricerca sticky, massimo 320 px, ombra piccola |
| Listbox | 8–10 righe, hover di riga, selezione d'accento |
| Tabelle | righe da 32 px in compatto, header sticky |
| Movimento | 120–150 ms; `prefers-reduced-motion` azzera |
| Cursore | default sui campi, pointer su bottoni, link e righe cliccabili |

---

## 13. Verifica

```bash
# I token sono definiti una volta e usati
Rscript -e 'pkgload::load_all("."); cat(as.character(app_css()))' | grep -c -- '--rcmdr-'

# Densità, pulsanti e focus
Rscript -e 'testthat::test_local(filter="density|buttons|accessibility")'

# Contrasto: ricalcola la tabella del § 4 da tutte le palette
Rscript -e 'testthat::test_local(filter="contrast")'

# Galleria dei widget (applicazione di sviluppo, non spedita)
Rscript tools/widget_gallery.R
```

La suite completa resta il criterio di chiusura di ogni lotto:
`testthat::test_local()` con `EXIT=0`.
