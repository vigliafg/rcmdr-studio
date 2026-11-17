# Diario di handoff — Onda 15 — Rifacimento visivo dell'interfaccia

**Data:** 2026-11-17  
**Stato:** parziale — U0, U1, U2, U3.1 e U3.2 completate; U3.3–U5 da fare  
**Ondata precedente:** `wave-14-dependencies.md` (Onda 14, 2.7.0)  
**Ondata successiva:** Onda 15 — continuazione (U3.3 → U4 → U5)  
**Documento di settore:** [`15-ui-refresh.md`](../15-ui-refresh.md)  
**Contratto dei token:** [`UI-TOKENS.md`](../UI-TOKENS.md)  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo dell'ondata:** aspetto contemporaneo senza riscrivere l'app — stessi
comandi, stessi ID, stessi test di semantica; CSS e JS fuori da `R/app.R`;
controlli, dialoghi e viste con una sola grammatica visiva.

**Risultato dell'ondata fin qui:**

- **U0.4** — `docs/upgrades/UI-TOKENS.md`: ruoli dei 33 colori, scala
  tipografica, spaziature a 4 px, raggi, ombre, altezze, stati, regole di
  naming. La tabella di contrasto è calcolata dai valori reali delle 7 palette,
  non stimata: il minimo è 13.26:1 per il testo, 6.38:1 per il testo attenuato,
  9.41:1 per il testo sul primario. Due lacune documentate e assegnate a U1.4
  (chiuse lì): il bordo dei campi (1.62:1, sotto il 3:1 di WCAG 1.4.11) e il
  sottotitolo della hero in `light-cool` (4.29:1).
- **U1.1** — token di tipografia, spaziatura, raggio e ombra; tutti i
  `font-size` e i `border-radius` di `inst/www/css/` passano da un token. I
  valori grezzi sono ricondotti allo scalino più vicino (scarto massimo 1.6 px).
  La densità usa la scala: `compact` = `sm`/`md`/`xs`, `comfortable` = uno
  scalino sopra per etichette e help.
- **U1.2** — altezza uniforme dei controlli (34 px compatto, 40 px comodo) con
  `--rcmdr-control-h`, interlinea `1.4`, padding calcolato per riempire
  l'altezza, spazio per la freccia delle select. Un solo anello di focus:
  `outline` da 2 px in `--rcmdr-focus` con offset 2 px, su tutti i temi; l'alone
  Bootstrap è spento; il selectize mostra lo stesso outline sul contenitore.
  Modali e hero passano al raggio da 12 px.
- **U1.3** — sei ruoli di pulsante sulle classi Bootstrap già in uso: primario
  (pieno `primary`/`on-primary`), secondario (`outline-secondary`, `light`,
  `default`, `outline-dark`), contorno d'accento (`outline-primary`), fantasma
  (`link`), distruttivo (`outline-danger` e `danger` tinta), stato (`success`,
  `warning` tinte) e `outline-light` per la barra primaria. Altezza
  `--rcmdr-btn-h` (pari al campo) e `btn-sm` 6 px più basso. Riempimenti pieni
  solo su coppie garantite: nei temi scuri accento e stati sono chiari e il
  testo bianco sarebbe illeggibile.
- **U1.4** — `--rcmdr-border-strong` (≥ 3.07:1 su ogni superficie) per il
  confine di campi, select, checkbox e selectize; `test-contrast.R` ricalcola
  tutta la tabella di `UI-TOKENS.md` dalle palette. La hero ora usa
  `hero-from`/`hero-to` invece di `primary → accent`: nei temi scuri il testo
  bianco sull'accento stava a **1.67:1**. Il badge attenuato della topbar passa
  a `on-primary-muted` e i due colori fissi morti sono stati rimossi.
- **U2.1** — `field()`, `field_grid()`, `switch_input()`, `segmented_input()`,
  `number_input()` in `R/widgets.R`. Sono varianti di presentazione: stessi ID,
  stessi valori inviati, markup Shiny intatto; `spin_input()` delega a
  `number_input()` per non avere due implementazioni.
- **U2.2** — `toolbar()`, `badge()`, `modal_header()`, `modal_footer()`,
  `tabs_strip()` in `R/ui-components.R`. `toolbar()` è il nome canonico di
  `studio_toolbar()`, che ora delega: una sola implementazione e i tre
  chiamanti non cambiano. `badge()` ha cinque stati sulle coppie `ok`/`warn`/
  `err` già misurate da `test-contrast.R`. `modal_header()` e `modal_footer()`
  costruiscono il chrome completo (icona, categoria, chiusura; azione primaria
  a destra) che U3.1 userà. `tabs_strip()` è un gruppo di pulsanti a pressione
  (`aria-pressed`), non un pattern ARIA tab: non implementa le frecce, quindi
  non promette ciò che non fa. Primi consumatori reali: i badge di stato di
  Report Studio, Script Studio e dei modelli del Chart Studio, che prima
  usavano `bg-success`/`bg-danger` di Bootstrap e nei temi scuri non seguivano
  la palette.
- **U2.3** — shell. La topbar ha una marca con icona; lingua e tema hanno
  un'etichetta nascosta (prima i due select erano senza nome accessibile). La
  barra di stato è una riga di fatti separati da bordi, non da `" | "` letti
  dallo screen reader, e la modalità è un badge. La striscia delle viste è una
  pillola con la coppia `primary`/`on-primary`. Le regole di shell duplicate
  tra `10-shell.css` e `30-forms.css` sono state consolidate in `10-shell.css`
  e `#main_tabs` è passato da `60-views.css` a `10-shell.css`. La modalità
  classica non cambia markup: stesso `tabsetPanel`, stessi `data-value`.
- **U2.4** — `switch_input()` adottato dove il valore è una preferenza:
  `auto_append` (Script classico e Studio) e `result_hint_auto`, che finisce
  nelle opzioni salvate. I 12 checkbox rimasti sono parametri di comando
  (ggstatsplot, Chart Studio), un'opzione di salvataggio del progetto o filtri
  di vista (galleria, output, palette): un interruttore prometterebbe un
  effetto immediato che non hanno. Un test fissa la distinzione.

- **U3.1 — chrome.** `dialog_modal()` non riscrive più il proprio modale:
  chiama `shiny::modalDialog()` con titolo e footer vuoti — così restano id
  `shiny-modal`, backdrop statico, `data-bs-keyboard="false"`, taglia e script
  di inizializzazione di Shiny — e inserisce `modal_header()` e
  `modal_footer()` nel `.modal-content` con `tagQuery()`. Il footer conserva i
  sei ID (`dialog_help`, `dialog_insert_script`, `dialog_reset`,
  `dialog_cancel`, `dialog_apply`, `dialog_ok`), il loro ordine nel DOM e
  quindi l'ordine di tabulazione; l'azione primaria sta nel gruppo di destra.
  Il titolo `h4` prende `id="rcmdr-dialog-title"` e il modale lo referenzia con
  `aria-labelledby`: prima nessun dialogo aveva un nome accessibile. Niente
  pulsante di chiusura: `Esc` e il backdrop sono disattivati, quindi una X
  chiuderebbe il modale senza passare dal gestore di *Cancel*. L'icona segue
  il ramo di menu del dialogo (dati: tabella, analisi: output, grafici:
  grafico, file: documento, modifica: codice, utilità: slider, aiuto: aiuto);
  `dialog_spec()` accetta un'icona esplicita e il set cresce di una voce,
  `chart`.
- **U3.1 — *Options*.** Interfaccia e densità sono due domande binarie e
  passano a `segmented_input()`; `stringsAsFactors`, `use_markdown` e
  `use_knitr` sono preferenze e passano a `switch_input()`; i tre numeri usano
  `number_input()`, il nome canonico. ID, valori e `on_ok()` invariati.
- **U3.2 — dati e import.** Stesso vocabolario in `dialogs-data.R` e
  `dialogs-import-text.R`: segmented per livelli del fattore, nomi dei
  livelli, separatore in esportazione, direzione del merge, statistica
  dell'aggregazione, provenienza dei dati e segno decimale; `number_input()`
  per righe e colonne del nuovo data set. Le etichette lunghe (metodo di
  binning, contrasti, i cinque delimitatori) restano radio: una striscia di
  pillole che va a capo è peggio di una lista.

**Cosa è pronto:** U0.1–U0.4, U1.1–U1.4, U2.1–U2.4, U3.1–U3.2.

**Cosa non è pronto:** nessuna verifica visiva registrata (vedi § 7);
`tabs_strip()` aspetta il primo consumatore (U4); i modali secondari
(palette, scorciatoie, tour) non usano ancora il chrome comune; i lotti U3.3–
U3.5 non sono migrati.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `151d1cf` | `feat: compact density, stable view ids and window-style tabs` | lavoro pendente dell'utente, committato come step 0 |
| `eece2fe` | `test: make the benchmark smoke test independent of installed plugins` | sblocca la baseline verde |
| `5e1a385` | `docs: plan the interface refresh (wave 15)` | piano, roadmap, checklist |
| `658abf9` | `refactor(ui): move the stylesheet out of app.R into inst/www/css` | U0.1 |
| `40990e5` | `refactor(ui): move the inline JavaScript out of app.R into inst/www/js` | U0.2 |
| `093df03` | `feat(ui): add a dependency-free inline icon set` | U0.3 |
| `99574d9` | `docs: close U0 of the interface refresh and write the handoff diary` | diario U0 |
| `4b72724` | `docs: write the design token contract (U0.4)` | `UI-TOKENS.md` |
| `4083590` | `feat(ui): type scale, uniform controls and a single focus ring` | U1.1 e U1.2 condividono il commit: la densità contiene sia gli alias di tipografia sia l'altezza dei controlli |
| `b314130` | `feat(ui): button roles, accessible boundaries and measured contrast` | U1.3 e U1.4; condividono il commit perché `50-widgets.css` contiene sia i bottoni sia il bordo dei campi |
| `9b6178a` | `feat(ui): form helpers for fields, switches, segments and numbers` | U2.1, nessun cambio di markup nei dialoghi |
| `d3c13bb` | `feat(ui): shared components, refreshed shell and preference switches` | U2.2–U2.4 condividono il commit: `app.R` contiene sia la shell sia l'adozione di `switch_input()` |
| `17fc642` | `feat(ui): dialog chrome, Options showcase and the data/import batch` | U3.1 e U3.2: chrome, *Options* e i due dialoghi dati condividono il commit perché il vocabolario è lo stesso |

---

## 3. File creati e modificati

### Creati

- `docs/upgrades/UI-TOKENS.md`
- `tests/testthat/test-ui-tokens.R`
- `tests/testthat/test-buttons.R`
- `tests/testthat/test-contrast.R`
- `tests/testthat/helper-tokens.R` (parser delle palette e formula WCAG)
- `tests/testthat/test-widgets.R`
- `tests/testthat/test-shell.R`

### Modificati

- `inst/www/css/00-tokens.css`: `--rcmdr-focus` in ogni palette; scala
  tipografica, pesi, interlinea, spaziature, raggi, geometria del focus.
- `inst/www/css/30-forms.css`: densità come alias della scala; altezza
  controlli; interlinea; padding della select.
- `inst/www/css/20-components.css`: un solo `:focus-visible` globale; rimosso
  l'override di `.rcmdr-help-topic`; raggi e corpi da token.
- `inst/www/css/40-dialogs.css`: rimosso l'override di focus della palette;
  `modal-content` e hero a `--rcmdr-radius-lg`; raggi e corpi da token.
- `inst/www/css/50-widgets.css`: spento l'alone Bootstrap su
  `form-control`/`form-select`/`form-check-input`/`btn`; focus del selectize
  con lo stesso outline; input interno senza anello.
- `inst/www/css/10-shell.css`, `60-views.css`, `70-refine.css`: raggi, corpi e
  ombra del menubar da token; rimosso il `:focus-visible` locale.
- `docs/upgrades/README.md`, `CHECKLIST.md`, `15-ui-refresh.md`: stato.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Suite completa | `testthat::test_local()` | vedere § 4.1 |
| Token | `test_local(filter="ui-tokens")` | verde |
| Contrasto | `test_local(filter="contrast")` | verde (243 asserzioni) |
| Bottoni | `test_local(filter="buttons")` | verde (34 asserzioni) |
| Helper di form | `test_local(filter="widgets")` | verde (41 asserzioni) |
| Densità | `test_local(filter="density")` | verde |
| Accessibilità | `test_local(filter="accessibility")` | verde |
| Componenti | `test_local(filter="ui-components")` | verde (158 asserzioni) |
| Shell | `test_local(filter="shell")` | verde (10 asserzioni) |
| Chrome dei dialoghi | `test_local(filter="dialogs")` | verde |
| Contratto | `test_local(filter="dialog-contract")` | verde: chrome su tutti gli ID |
| *Options* | `test_local(filter="phase1")` | verde |
| Dati e import | `test_local(filter="data-studio-dialogs")` | verde |
| Integrazione | `test_local(filter="app-integration")` | verde (warning rgl senza X11) |
| Struttura CSS | controllo su graffe e dichiarazioni | 0 problemi |

### 4.1 Esito della suite

`EXIT=0`. Nessun failure, 22 test e2e saltati (richiedono
`RCMDRSHINY_E2E=1`), 3 warning già noti: rgl senza X11, `rgl.init` in fallback,
`match_font()` deprecato in systemfonts. I quattro file di test nuovi o
aggiornati sono verdi; `test-shell.R` aggiunge due warning rgl perché avvia il server per
leggere la barra di stato, e `test-dialog-contract.R` impiega circa due minuti
perché rende il chrome di tutti i dialoghi.

**Artefatti:** `/tmp/opencode/tests-u3a.log` (batch corrente),
`/tmp/opencode/tests-u2d.log`, `/tmp/opencode/tests-u2.log`,
`/tmp/opencode/tests-u1.log`.

---

## 5. Decisioni

- **Scala di tipografia a 6 passi** (4 di testo + 2 display), non a 4: le
  metriche (21.6 px) e il titolo della hero (26.4 px) non sono testo corrente e
  non vanno schiacciati su un passo da 16 px. I quattro passi di testo sono
  `12 / 13 / 14 / 16`.
- **I valori grezzi si normalizzano, non si duplicano.** `.68`, `.78`, `.82`,
  `.85`, `.86`, `.88`, `.9`, `.92`, `1.1rem` sono diventati `xs`, `xs`, `sm`,
  `sm`, `sm`, `md`, `md`, `md`, `lg`. Lo scarto massimo è 1.6 px e nessun
  paragrafo cambia numero di righe.
- **`compact` è la base, `comfortable` è +1.** Etichette e help salgono di uno
  scalino; i controlli restano a 14 px in entrambe, perché 14 px è il minimo
  leggibile per un campo. La densità comoda non deve diventare “tutto più
  grande”, solo “più arioso”.
- **Altezza con `min-height`, non `height`.** Le textarea devono crescere. Il
  padding è calcolato perché il contenuto riempia 34/40 px; le select hanno
  `padding-right: 1.9rem` per non finire sotto la freccia.
- **Un solo focus ring.** Un `outline` pieno in `--rcmdr-focus` (l'accento del
  tema, minimo 5.83:1) è l'indicatore; l'alone in `rgba` è solo rinforzo. Le
  regole locali (`.rcmdr-help-topic`, `.rcmdr-palette-result`) sono state
  rimosse: erano tre ring diversi nello stesso prodotto.
- **`--rcmdr-focus` separato da `--rcmdr-accent`.** Oggi hanno lo stesso
  valore; il focus è un requisito di accessibilità e deve poter cambiare da
  solo, per esempio in `contrast`.
- **`modal-content` e hero a 12 px subito.** Sono superfici grandi, dove la
  direzione approvata prevede 12–14 px; le card aspettano U2 perché il loro
  restyle è lì.
- **`--rcmdr-radius` e `--rcmdr-control-min` restano alias.** I selettori
  esistenti e i test che citano `--rcmdr-control-min` non cambiano; gli alias
  si eliminano quando i consumatori saranno migrati.
- **Sei ruoli, non quattro.** Il piano diceva primario/secondario/ghost/
  pericolo. L'app usa anche `outline-primary` (23 volte), `btn-light` (sulla
  hero), `btn-outline-light` (sulla topbar) e due bottoni di stato: senza un
  ruolo esplicito sarebbero rimasti i colori di Bootstrap, cioè un secondo
  sistema. I ruoli sono sei e ognuno ha una coppia di token.
- **Riempimenti pieni solo su `primary`/`on-primary`.** L'accento e i colori di
  stato sono chiari nei temi scuri: un bottone bianco su `#78b9ff` sta a 2:1.
  Per questo l'hover dei pieni è un `filter: brightness()` (scala testo e
  sfondo insieme) e i contorni virano su una superficie (`hover`, `selection`,
  `err-bg`), non su un riempimento saturo.
- **Il confine dei controlli ha un token suo.** `--rcmdr-border` resta
  decorativo (1.62:1); `--rcmdr-border-strong` è scelto per stare appena sopra
  il 3:1 sulla superficie più chiara e più scura di ogni palette, così il campo
  è riconoscibile senza diventare una gabbia nera.
- **La hero dipinge i propri token.** Il gradiente era `primary → accent`, ma
  l'accento è chiaro nei temi scuri: il testo bianco scendeva a 1.67:1. Ora usa
  `hero-from`/`hero-to`, che esistevano già e non erano consumati.
- **Gli helper non riscrivono Shiny.** `switch_input()` e `segmented_input()`
  avvolgono `checkboxInput()`/`radioButtons()`: il binding, gli ID e i valori
  inviati restano quelli di Shiny. `field()` serve ai controlli costruiti a
  mano, non sostituisce il wrapper che Shiny mette già attorno ai suoi input.
- **`spin_input()` delega a `number_input()`.** Due nomi per la stessa cosa non
  sono due implementazioni: `number_input()` è il nome canonico, `spin_input()`
  resta per i dialoghi Rcmdr e chiama il primo.
- **La shell del modale resta di Shiny.** Costruire a mano `#shiny-modal`,
  backdrop e script di bootstrap avrebbe voluto dire copiare gli interni di
  Shiny e restare indietro a ogni aggiornamento. `tagQuery()` inserisce il
  nostro chrome dentro la shell che Shiny genera: attributi, taglia e
  inizializzazione restano suoi, l'aspetto è nostro.
- **Niente X nel dialogo.** `Esc` e il backdrop sono disattivati perché il
  dialogo ha un `Cancel` che azzera lo stato; una X di Bootstrap lo
  aggirerebbe. Se un giorno i dialoghi diventassero annullabili senza stato da
  pulire, la X si aggiunge con `modal_header(close = TRUE)`.
- **L'icona segue il ramo di menu, non il singolo dialogo.** 157 dialoghi non
  giustificano 157 icone: il ramo (`data`, `analyze`, `graphs`, …) dà
  un'indagine visiva immediata e `dialog_spec(icon=)` lascia la scelta
  esplicita dove serve.
- **Segmented solo per etichette corte.** Due o tre parole stanno in una
  striscia; «Treatment (dummy) contrasts» no. La regola è la lunghezza
  dell'etichetta, non il numero di scelte.
- **Un solo `toolbar()`.** `studio_toolbar()` resta come alias delegante: i
  tre chiamanti non cambiano, ma l'implementazione è una. Il ruolo ARIA
  `toolbar` compare solo quando c'è un'etichetta, così non si annuncia una
  barra senza nome.
- **`tabs_strip()` non è ARIA tabs.** Il pattern `tab` richiede le frecce; il
  componente usa `aria-pressed` su pulsanti normali, che è vero e resta
  raggiungibile da tastiera. Il primo consumatore è U4 (striscia documenti),
  quindi per ora è coperto solo dai test.
- **La striscia delle viste resta `tabsetPanel`.** Sostituirla con un
  componente avrebbe voluto dire reimplementare il binding di Shiny e cambiare
  il markup della modalità classica: si veste con i token e la coppia
  `primary`/`on-primary`, senza riscriverla.
- **Un interruttore solo per le preferenze.** `switch_input()` promette un
  effetto immediato; un parametro che finisce in un comando o un filtro di
  vista non lo ha. Per questo l'adozione è 3 su 15, non 15 su 15.
- **`:has()` per il segmented.** Il radio è nascosto ma resta nel DOM e nel
  tab order; l'anello di focus e lo stato scelto si disegnano sull'etichetta
  con `:has(input:checked)` / `:has(input:focus-visible)`. È l'unico modo di
  tenere insieme semantica nativa e aspetto a pillola.

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| U1.1 | 4 taglie | 4 di testo + 2 display | metriche e hero non sono testo corrente |
| U1.1–U1.2 | due commit | un commit | la densità contiene sia gli alias di tipografia sia `--rcmdr-control-h`: le hunk sono inseparabili senza riscrivere il file |
| U1.1 | “raggi a token” | anche i valori grezzi dei componenti | senza normalizzarli il test “solo token” non poteva esistere |
| U1.2 | verifica chiaro/scuro | non registrata | Chrome headless non raggiunge localhost in questo ambiente (vedi § 7); l'app resta su `http://127.0.0.1:3841` per il controllo dell'utente |
| U1.3 | quattro varianti | sei ruoli | l'app usa anche `outline-primary`, `light`, `outline-light` e due bottoni di stato |
| U1.3–U1.4 | due commit | un commit | `50-widgets.css` contiene sia i bottoni sia il bordo dei campi |
| U1.4 | test di contrasto | test + helper condiviso | la formula WCAG serve anche a `ui-tokens`; un helper evita due parser |
| U2.1 | cinque helper nuovi | `number_input()` è il nome canonico e `spin_input()` delega | due nomi per la stessa cosa non devono diventare due implementazioni |
| U2.1 | `number_input()` con stepper JS | nessuno stepper | il `<input type=number>` nativo ha già i suoi controlli; un secondo stepper sarebbe decorazione |
| U2.2 | cinque componenti nuovi | `toolbar()` è il nome canonico di `studio_toolbar()`, che delega | due nomi per la stessa cosa non devono diventare due implementazioni |
| U2.2 | cinque componenti nuovi | primo consumatore reale solo per `badge()` e `toolbar()` | `modal_header()`/`modal_footer()` servono a U3.1 e `tabs_strip()` a U4: si aggiungono ora perché i test li fissano prima dell'uso |
| U2.4 | 15 `checkboxInput` → `switch_input()` | 3 switch, 12 checkbox | gli altri sono parametri di comando, opzioni di salvataggio o filtri: un interruttore mentirebbe sull'effetto |
| U2.3 | “la shell non contiene più classi Bootstrap scritte a mano” | la shell usa ancora utility (`d-flex`, `gap-2`) | sono il layout di Bootstrap, non un secondo sistema di colore; la loro sostituzione è U4.1, dove la shell viene rifatta |
| U3.1 | un componente `modal_header()`/`modal_footer()` per ogni modale | i dialoghi del catalogo li usano; palette, scorciatoie e tour no | hanno footer e bisogni diversi (nessun footer, `easyClose = TRUE`); il chrome comune si estende quando U4 rifà quelle viste |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| Evidenziazione del tour in `#f59e0b` | colore intenzionale, non un token di tema | lasciato | U5.2 |
| `filter: brightness()` sui bottoni pieni | non è un token: è una trasformazione | accettato: scala testo e sfondo insieme e non aggiunge palette; se un tema lo rende sporco si passa a una coppia `-hover` per tema | U5.2 |
| `tabs_strip()` senza consumatore | codice coperto dai test ma non ancora usato | il primo uso arriva in U4 (striscia dei documenti), che è anche il posto dove il componente può cambiare forma | U4 |
| I modali secondari hanno il chrome vecchio | palette, scorciatoie e tour usano `modalDialog(title=)` | non sono dialoghi del catalogo e hanno footer propri; si allineano in U4/U5 | U4 |
| Utility Bootstrap nella shell | l'accettazione di U2 chiede una shell senza classi scritte a mano | rimandato: U4.1 rifà la shell, sostituirle ora sarebbe lavoro buttato | U4.1 |
| Chrome headless non carica `http://127.0.0.1` | nessuno screenshot automatico | l'app è avviata su `3841` per un controllo manuale; gli e2e restano la verifica di struttura | U5.1 |
| 22 test e2e saltati senza `RCMDRSHINY_E2E=1` | copertura browser non esercitata in questo batch | eseguirli prima della chiusura di U3 | U3 |

---

## 8. Domande aperte

- [ ] 14 px per i controlli anche in `comfortable`: è abbastanza? La densità
      comoda compensa con padding e spazio, non con il corpo del testo. Da
      rivedere sui dialoghi reali in U3.
- [ ] `--rcmdr-font-size` è definito ma non consumato (era il corpo base
      Bootstrap). Toglierlo in U2 o usarlo per il testo dei documenti?
- [ ] L'alias `--rcmdr-control-min` serve solo ai test: eliminarlo quando
      `test-density.R` sarà riscritto per `--rcmdr-control-h`.
- [ ] `:has()` nel segmented richiede Chrome 105+/Firefox 121+. Le versioni in
      uso oggi lo supportano; se un client vecchio resta indietro, il fallback
      è un radio normale, non una pillola rotta. Da verificare in U3.1.
- [ ] Il `filter: brightness()` dei bottoni pieni piace? Va guardato sui temi
      scuri reali; in alternativa si aggiunge una coppia `-hover` per palette.

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. **U3.3 — statistiche.** `R/dialogs-stats.R` (11 `spin_input`, 25
   `radio_input`) e `R/dialogs-summaries.R`: `number_input()` per i numeri,
   `segmented_input()` per le scelte corte (tipo di intervallo, ipotesi,
   correzione), radio dove le etichette sono lunghe. I test dei costruttori di
   comando (`test-command-builders-stats.R`) sono la rete: stessi ID, stessi
   valori.
2. **U3.4 — grafici.** `R/dialogs-graphs.R`, con particolare attenzione alle
   opzioni che finiscono nei comandi ggplot.
3. **U3.5 — modelli, report, progetto, script.** `dialogs-models*.R`,
   `report-studio.R`, `project-dialogs.R`, `document-dialogs.R`.

Poi **U4.1** rifà la shell (e chiude l'accettazione “niente utility a mano”),
**U4.2–U4.5** le viste, **U5** la matrice temi e la QA.

### Task dell'ondata

| ID | Task | Priorità | Note |
|---|---|---|---|
| U3.3 | Lotto statistiche | alta | 11 numeri, 25 radio |
| U3.4 | Lotto grafici | alta | opzioni nei comandi ggplot |
| U3.5 | Modelli, report, progetto, script | media | ultimo lotto |
| U4.1 | Shell | alta | chiude le utility a mano |
| U4.2–U4.5 | Viste | media | Data, Chart, Report, Workbench |
| U5 | Matrice temi, QA, NEWS | media | |

---

## 10. Comandi per riprendere

```bash
cd ~/Documenti/GitHub/rcmdr-studio
git status
git log --oneline -6
Rscript -e 'testthat::test_local(filter="ui-tokens|contrast|buttons|widgets|shell|density")'
Rscript -e 'pkgload::load_all("."); cat(as.character(app_css()))' | grep -c -- '--rcmdr-'
# anteprima locale (l'app è già avviata su 3841 in questa sessione)
RCMDRSHINY_PORT=3841 RCMDRSHINY_BROWSER=FALSE ./start.sh
```

**Baseline attesa:** suite completa verde, 22 skip e2e, 3 warning noti
(rgl, `match_font`). `app_css()` cresce di circa 2 KB per la scala e di circa
1,5 KB per badge, schede e chrome dei modali.

---

## 11. Note di contesto

- La direzione visiva approvata è in `/tmp/opencode/rcmdr-design-preview/`
  (`app.R` + `current.css`); gli screenshot di riferimento sono
  `/tmp/opencode/preview-light.png` e `preview-dark.png`. Non fanno parte del
  repository.
- I token sono l'unico posto in cui si scrive un colore o una misura di
  sistema. Il test `test-ui-tokens.R` fallisce se compare un `font-size` o un
  `border-radius` grezzo in `inst/www/css/`.
- Il contrasto è calcolato con la formula WCAG della luminanza relativa:
  `test-contrast.R` legge le palette da `app_css()` e la tabella di
  `UI-TOKENS.md` è un'asserzione, non una nota.
- Protocollo concordato: **tre step, poi stop**; l'utente compatta il contesto
  e la sessione riprende da questo diario.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata (U0.4, U1, U2, U3.1, U3.2).
- [x] `15-ui-refresh.md` e `README.md` segnano l'onda in corso.
- [x] `UI-TOKENS.md` scritto e coerente con il codice.
- [x] Diario scritto.
- [x] Diario committato.
- [ ] Utente informato: “diario pronto, puoi compattare il contesto”.
