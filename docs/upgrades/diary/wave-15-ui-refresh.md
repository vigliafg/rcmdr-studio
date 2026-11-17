# Diario di handoff — Onda 15 — Rifacimento visivo dell'interfaccia

**Data:** 2026-11-17  
**Stato:** parziale — U0, U1 e U2.1 completate; U2.2–U5 da fare  
**Ondata precedente:** `wave-14-dependencies.md` (Onda 14, 2.7.0)  
**Ondata successiva:** Onda 15 — continuazione (U2.2 → U3.1 → U5)  
**Documento di settore:** [`15-ui-refresh.md`](../15-ui-refresh.md)  
**Contratto dei token:** [`UI-TOKENS.md`](../UI-TOKENS.md)  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo dell'ondata:** aspetto contemporaneo senza riscrivere l'app — stessi
comandi, stessi ID, stessi test di semantica; CSS e JS fuori da `R/app.R`;
controlli, dialoghi e viste con una sola grammatica visiva.

**Risultato di questo batch:**

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

**Cosa è pronto:** U0.1–U0.4, U1.1–U1.4, U2.1.

**Cosa non è pronto:** nessuna verifica visiva registrata (vedi § 7), i widget
nuovi non sono ancora adottati dai dialoghi (U2.2–U3.1), U2.2–U5.

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

---

## 3. File creati e modificati

### Creati

- `docs/upgrades/UI-TOKENS.md`
- `tests/testthat/test-ui-tokens.R`
- `tests/testthat/test-buttons.R`
- `tests/testthat/test-contrast.R`
- `tests/testthat/helper-tokens.R` (parser delle palette e formula WCAG)
- `tests/testthat/test-widgets.R`

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
| Contrasto | `test_local(filter="contrast")` | verde (215 asserzioni) |
| Bottoni | `test_local(filter="buttons")` | verde (34 asserzioni) |
| Helper di form | `test_local(filter="widgets")` | verde (34 asserzioni) |
| Densità | `test_local(filter="density")` | verde |
| Accessibilità | `test_local(filter="accessibility")` | verde |
| Componenti | `test_local(filter="ui-components")` | verde |
| Integrazione | `test_local(filter="app-integration")` | verde (warning rgl senza X11) |
| Struttura CSS | controllo su graffe e dichiarazioni | 0 problemi |

### 4.1 Esito della suite

`EXIT=0`. Nessun failure, 22 test e2e saltati (richiedono
`RCMDRSHINY_E2E=1`), 3 warning già noti: rgl senza X11, `rgl.init` in fallback,
`match_font()` deprecato in systemfonts. I quattro file di test nuovi sono
verdi.

**Artefatti:** `/tmp/opencode/tests-u2.log` (batch corrente),
`/tmp/opencode/tests-u1.log` (batch precedente).

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

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| Evidenziazione del tour in `#f59e0b` | colore intenzionale, non un token di tema | lasciato | U5.2 |
| `filter: brightness()` sui bottoni pieni | non è un token: è una trasformazione | accettato: scala testo e sfondo insieme e non aggiunge palette; se un tema lo rende sporco si passa a una coppia `-hover` per tema | U5.2 |
| Gli helper di U2.1 non sono ancora usati dai dialoghi | CSS e helper esistono ma nessun dialogo li adotta | l'adozione è U2.4 (`switch_input` nei 15 checkbox diretti) e U3.1 (*Options*) | U2.4 |
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

1. **U2.2 — componenti condivisi.** `toolbar()`, `modal_header()`,
   `modal_footer()`, `tabs_strip()`, `badge()` in `R/ui-components.R`, con
   `rcmdr_icon()`. Nessun cambio di ID; i componenti si aggiungono.
2. **U2.3 — shell.** Topbar, tab strip, statusbar e sidebar passano ai
   componenti; la topbar deve usare `btn-outline-light` e i badge giusti.
3. **U2.4 — adozione degli helper.** I 15 `checkboxInput` diretti passano a
   `switch_input()` dove il valore è una preferenza; i gruppi radio brevi a
   `segmented_input()`. Solo presentazione: gli `on_ok()` non cambiano.

Poi **U3.1 — chrome dei dialoghi e *Options*** è la prima pillola visibile:
header con icona, corpo in griglia, footer con l'azione primaria a destra.

### Task dell'ondata

| ID | Task | Priorità | Note |
|---|---|---|---|
| U2.2 | Componenti condivisi | alta | toolbar, modale, tab, badge |
| U2.3 | Shell | alta | topbar, tab, statusbar, sidebar |
| U2.4 | Adozione di switch e segmented | media | 15 checkbox diretti |
| U3.1 | Chrome + *Options* | alta | prima pillola visibile |
| U4–U5 | Viste, matrice temi, QA | media | |

---

## 10. Comandi per riprendere

```bash
cd ~/Documenti/GitHub/rcmdr-studio
git status
git log --oneline -6
Rscript -e 'testthat::test_local(filter="ui-tokens|contrast|buttons|widgets|density")'
Rscript -e 'pkgload::load_all("."); cat(as.character(app_css()))' | grep -c -- '--rcmdr-'
# anteprima locale (l'app è già avviata su 3841 in questa sessione)
RCMDRSHINY_PORT=3841 RCMDRSHINY_BROWSER=FALSE ./start.sh
```

**Baseline attesa:** suite completa verde, 22 skip e2e, 3 warning noti
(rgl, `match_font`). `app_css()` cresce di circa 2 KB per la scala.

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

- [x] `CHECKLIST.md` aggiornata (U0.4, U1.1, U1.2, U1.3, U1.4, U2.1).
- [x] `15-ui-refresh.md` e `README.md` segnano l'onda in corso.
- [x] `UI-TOKENS.md` scritto e coerente con il codice.
- [x] Diario scritto.
- [x] Diario committato.
- [ ] Utente informato: “diario pronto, puoi compattare il contesto”.
