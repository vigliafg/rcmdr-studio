# QA dei widget — Onda 16

**Data:** 2026-11-18  
**Stato:** S14 completato; verifica automatica verde, verifica visiva
manuale in sospeso (nessun browser disponibile in questo ambiente)  
**Documento di settore:** [`16-bslib-widgets.md`](16-bslib-widgets.md)  
**Contratto dei token:** [`UI-TOKENS.md`](UI-TOKENS.md)

---

## 1. Metodo

La qualità visiva dell'onda si misura su tre livelli, dal più economico al più
costoso:

1. **Token e contrasto, in R.** La matrice 8 temi × 2 densità ricalcola i
   rapporti WCAG dalle palette vere (`tests/testthat/test-theme-matrix.R`,
   `test-contrast.R`). Un componente nuovo non entra se una coppia scende
   sotto 4.5:1 per il testo o 3:1 per bordi, focus e controlli.
2. **Markup e CSS, in R.** I test leggono `app_css()` e `app_js()` e
   verificano che ogni famiglia usi i token, che il bridge non contenga
   colori letterali e che gli ID restino quelli del contratto.
3. **Occhio e tastiera, nel browser.** La galleria
   (`tools/widget_gallery.R`) mostra ogni famiglia nei suoi stati con il
   selettore di tema e densità. È l'unico livello che richiede un browser
   vero: qui non è stato possibile eseguirlo.

La suite completa resta il criterio di chiusura:

```bash
Rscript --vanilla -e 'testthat::test_local(reporter="summary")'
```

---

## 2. Comandi

```bash
# Matrice, contrasto, widget
Rscript --vanilla -e 'testthat::test_local(filter="theme-matrix|contrast|widget")'

# Galleria in sola verifica (non avvia il server)
RCMDRSHINY_GALLERY_CHECK=1 Rscript --vanilla tools/widget_gallery.R

# Galleria interattiva, per la checklist del § 6
Rscript tools/widget_gallery.R
```

La galleria è esclusa dal pacchetto (`.Rbuildignore`): non è una funzione
dell'app, è un banco di prova.

---

## 3. Esito automatico

| Controllo | Esito |
|---|---|
| 8 temi × 2 densità, classi e palette | verde |
| Coppie testo/sfondo, tutte le palette | verde (minimo misurato 4.5:1) |
| Bordi, focus e controlli | verde (minimo 3:1) |
| Chip dell'accordion e del picker | verde: heading su selection ≥ 9.05, muted su selection ≥ 5.04 |
| Focus su superficie e pannello muto | verde: minimo 4.83:1 |
| Nessun colore letterale nei fogli toccati | verde |
| Galleria, check mode | `gallery ok: 19195 bytes` |
| Suite completa | `EXIT=0`, 0 failure, 26 skip e 3 warning noti |

I minimali sono quelli della matrice, non una media: il tema più debole deve
passare, non quello medio.

---

## 4. Cosa è stato rifinito in S14

### 4.1 Tabelle (DT e rhandsontable)

- token `--rcmdr-table-row-h`: **2 rem (32 px)** in compatto, **2.5 rem
  (40 px)** in comodo;
- `table.dataTable` con header su `--rcmdr-surface-muted`, bordo inferiore a
  token, `position: sticky` per le tabelle che scorrono con la pagina;
- hover di riga su `--rcmdr-hover`, selezione su `--rcmdr-selection` con
  testo `--rcmdr-heading`, per tutte le palette (prima la regola esisteva
  solo per i temi scuri);
- filtro, lunghezza pagina, info e paginazione con la stessa altezza dei
  campi (`--rcmdr-control-h`) e gli stessi stati hover/current/disabled;
- rhandsontable usa lo stesso numero, letto da `ui_table_row_height()` in R,
  perché disegna la griglia da sé.

### 4.2 Editor (Ace)

`ui_ace_theme()` sceglie un tema **spedito con shinyAce**, senza rete:

| Palette | Tema |
|---|---|
| light, light-warm, light-cool, contrast, system | `textmate` |
| dark, dark-dim, dark-graphite | `tomorrow_night` |

L'editor viene ricostruito solo quando l'utente cambia palette, non a ogni
`tick()`: la cronologia di undo resta. `system` resta sul tema chiaro perché
il server non può conoscere la preferenza del client; è un limite dichiarato,
non un caso dimenticato.

### 4.3 Alert, progress, scrollbar

- `.alert-*` mappa le variabili Bootstrap `--bs-alert-*` sulle coppie di
  stato (`ok`, `warn`, `err`) o su `selection`/`heading` per info e primary;
- `.progress` usa la traccia muta e il riempimento `--rcmdr-primary`; i
  `bg-warning`, `bg-success` e `bg-danger` usati dalla scheda Data restano
  sulla palette;
- la scrollbar nativa conserva il comportamento del sistema e riceve solo
  `scrollbar-color` e il thumb WebKit, entrambi a token.

### 4.4 Menu, tab e dialoghi

Menu, tab, dropdown e modali erano già coperti dall'Onda 15 e dal lotto 1–4;
S14 non li riscrive. Le regole nuove non usano `!important` tranne dove
Bootstrap o DataTables lo impongono (paginazione, `bg-*`), come già
documentato nel contratto.

---

## 5. Cosa resta al fornitore

| Famiglia | Decisione |
|---|---|
| shinyFiles | Usa il modale di Bootstrap; i suoi bottoni ricadono su `.btn-default`, già mappato. Nessun override nuovo: il browser dei file resta quello della libreria. |
| plotly | Il grafico è SVG con il suo layout; la modebar è un contratto della libreria. Non si forza lo sfondo: si romperebbe il tema scelto dal grafico. |
| selectize | Resta per i pochi combo legacy; il bridge di `50-widgets.css` lo copre. Non è la famiglia nuova. |
| date picker | Rinviato all'Onda 17, T2: non c'è ancora un campo data nell'app. |

---

## 6. Checklist manuale (browser)

Da eseguire su `Rscript tools/widget_gallery.R`, una voce per ogni tema
(`light`, `light-warm`, `light-cool`, `dark`, `dark-dim`, `dark-graphite`,
`contrast`, `system`) e per ogni densità (`compact`, `comfortable`).

1. **Superfici.** Nessun controllo conserva il bianco o il grigio del
   browser; l'editor Ace è scuro nei tre temi scuri.
2. **Tabelle.** Le righe misurano 32/40 px, l'header resta fermo mentre le
   righe scorrono, filtro e paginazione hanno l'altezza dei campi.
3. **Accordion.** Solo il primo pannello è aperto; il terzo contiene picker,
   slider e colore; l'header ha un solo anello di focus.
4. **Tastiera.** Su un header: `Tab` entra, `Invio`/`Spazio` apre, `↑`/`↓`
   cambiano header, `Home`/`End` vanno ai bordi, `Esc` non viene intercettato.
5. **Picker.** `Invio` apre, le frecce scorrono, la ricerca filtra, `Esc`
   chiude e il focus torna al combo; il combo è annunciato con il testo della
   label.
6. **Slider.** Le frecce cambiano il valore, `Home`/`End` vanno ai limiti, il
   tooltip mostra i decimali dello step, l'handle ha `role="slider"` e il nome
   della label.
7. **Colore.** `Tab` raggiunge il replacer, `Invio`/`Spazio` aprono la
   palette, `Esc` la chiude, il valore resta una stringa di colore.
8. **Alert e progress.** Un avviso resta leggibile in ogni palette; la barra
   di avanzamento non è gialla di default nei temi scuri.
9. **Zoom 200%.** I titoli dell'accordion vanno a capo, i campi restano
   raggiungibili, nessun testo viene tagliato, il focus resta visibile.
10. **Movimento ridotto.** Con `prefers-reduced-motion`, apertura e slider
    non animano; il focus continua a spostarsi.

---

## 7. Limiti di questa verifica

- **Nessun browser disponibile** in questo ambiente: la checklist del § 6 è
  scritta ma non eseguita, e non ci sono screenshot delle 8 × 2.
- I **26 test e2e** restano saltati (`RCMDRSHINY_E2E=1` li abilita): non
  provano né la galleria né i widget esterni.
- La matrice verifica **colori e misure**, non la resa del testo reale: un
  font di sistema molto diverso può cambiare l'a capo, non il contrasto.
- Ace con tema `system` resta chiaro finché l'utente non sceglie una palette
  scura (vedi § 4.2).
- plotly e shinyFiles non sono stati rifiniti oltre il bridge esistente: la
  loro chrome appartiene alle librerie.

Questi limiti sono gli stessi registrati nel diario dell'onda e nella
checklist di chiusura.

---

## 8. Gate `reactable` (Onda 17, T7)

**Domanda:** conviene spostare le tabelle di sola lettura — glossario,
topic Help, registro documenti e confronto modelli — su `reactable`?

**Prototipo:** `reactable 0.4.5` installato in una libreria temporanea
(`/tmp/opencode/rlib`), tabella di confronto modelli resa con
`reactable(compact = TRUE, striped = TRUE, bordered = FALSE)` e tema dai
token. Nessun file del repository è stato cambiato per il prototipo.

| Misura | Valore |
|---|---|
| `reactable` installato | 3,5 MB |
| `reactR` installato (dipendenza nuova) | 1,9 MB |
| Asset front-end `reactable` | 3.312.830 byte (3,3 MB) |
| React 18 | 170.431 byte |
| core-js | 93.205 byte |
| htmlwidgets | 33.190 byte |
| Totale front-end aggiunto | circa 3,6 MB |
| Asset CSS + JS dell'app oggi | 165 KB |
| Nuove dipendenze dichiarate | `reactable`, `reactR` |
| Tastiera | nessuna navigazione di riga o colonna nel widget: va aggiunta |
| Tema | `reactableTheme()` accetta i token, ma li applica lato JS |
| ARIA | la tabella nasce lato client dentro un `div`; il `<table>` non è nel primo HTML |

**Esito: il gate non passa.**

- Il peso front-end è circa **22 volte** tutti gli asset attuali
  dell'applicazione, per quattro tabelle di sola lettura.
- Il markup utile non è nel primo HTML: senza JavaScript non c'è tabella.
  Le tabelle native invece sono leggibili subito e conservano semantica,
  selezione del testo e stampa.
- La tastiera non è fornita dal widget: sarebbe comunque JS nostro, sopra un
  runtime React.
- DT resta la scelta per i dati editabili, la selezione e i filtri; per il
  solo leggere una tabella nativa è più leggera e più accessibile.

**Cosa è stato rifinito al posto del widget:**

- header `position: sticky` per `.rcmdr-table`, `.rcmdr-models-table` e
  `.rcmdr-help-body thead th`;
- lo stesso ritmo di riga di DT (`--rcmdr-table-row-h`, 32/40 px secondo la
  densità);
- `table_scroll()`: regione `role="region"`, `tabindex="0"` e nome, così una
  tabella lunga si raggiunge e si scorre da tastiera senza perdere il
  `<table>` interno;
- overflow orizzontale nel corpo Help, dove i topic possono contenere tabelle
  larghe.

La decisione è vincolante per l'onda: nessuna tabella editabile passa a
`reactable`, e il test `test-readonly-tables.R` fallisce se la dipendenza
rientra da DESCRIPTION o da un `reactable::` nel codice.
