# Onda 15 — Rifacimento visivo dell'interfaccia

**Data:** 2026-11-17  
**Stato:** in corso — U0, U1, U2, U3.1 e U3.2 completate il 17 novembre 2026  
**Baseline:** RcmdrShiny Studio 2.8.0  
**Dipende da:** Onda 0 (token e shell), Onda 5 (piattaforma dialoghi)  
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Dare all'interfaccia un aspetto contemporaneo senza riscrivere l'applicazione:
stessi comandi, stessi ID, stessi test di semantica. Cambia la pelle e la
gerarchia visiva, non il motore.

Al termine dell'onda:

- i controlli hanno una sola grammatica visiva (altezza, raggio, focus, stati);
- i dialoghi hanno header, corpo e footer con priorità leggibili;
- le icone sostituiscono le etichette ripetute;
- i temi (8) e le densità (2) restano tutti coerenti;
- CSS e JS non vivono più dentro `R/app.R`;
- nessun dialogo è stato riscritto: i 157 `dialog_spec()` restano identici.

---

## 2. Stato attuale (misurato)

| Area | Situazione | Conseguenza |
|---|---|---|
| CSS | 1.053 righe in una stringa dentro `app_css()` (`R/app.R`, righe 3–1058) | Nessun file, nessun Sass, nessun riuso fuori da `app.R` |
| JS | 699 righe in `app_js()` (`R/app.R`, righe 1061–1764) | Stessa cosa: tema, densità, drag dei modali, palette |
| Componenti | `R/ui-components.R` esiste ma è quasi inutilizzato: `section_card` 0 usi, `metric_card` 0, `split_view` 0, `empty_state` 18, `status_pill` 9 | La shell è costruita a mano con div e classi Bootstrap |
| bslib | In `Imports`, **0 componenti** usati (`card`, `accordion`, `input_switch`, `navset`, `layout_columns`) | Bootstrap 5 usato come HTML grezzo |
| Icone | 0 `icon()` / `bsicons` in tutta l'interfaccia | Azioni solo testuali, bottoni indistinguibili |
| Input nativi | 72 `selectInput`, 39 `textInput`, 13 `numericInput`, 15 `checkboxInput` diretti, 144 `actionButton` | Selectize di default, checkbox quadrati, bottoni identici |
| Dialoghi | 157 `dialog_spec()`, corpo reso in `.rcmdr-field-grid.rcmdr-dialog-grid` | Un solo wrapper, ma 1.053 righe di CSS non bastano a gerarchizzare |
| Temi | 8 temi + 2 densità via classi su `body` e variabili CSS | Base solida: i token esistono già |
| Test | 124 file; 15 e2e shinytest2 con ~100 selettori `.rcmdr-*` e 65 ID di input | Ogni rinomina è un test rotto: si aggiunge, non si rinomina |
| Asserzioni su CSS | `test-density.R` e `test-accessibility.R` leggono `app_css()` e cercano stringhe | `app_css()` deve restare la porta d'ingresso |

---

## 3. Principi e vincoli

1. **Nessun cambio di contratto.** ID degli input, nomi delle classi `.rcmdr-*`
   e `dialog_spec()` restano. Si aggiungono classi, non si sostituiscono.
2. **Il motore è intoccabile.** Nessuna modifica a command builder, dialoghi,
   plugin, i18n o semantica Rcmdr.
3. **Classica resta Classica.** Il restyle visivo vale per entrambe le
   modalità, ma la struttura, le etichette delle finestre e il layout della
   modalità Classica non cambiano.
4. **Offline e locale.** Nessun CDN, nessun font remoto, nessuna chiamata di
   rete: solo asset nel pacchetto.
5. **Niente dipendenze cosmetiche.** Icone inline con un helper, non un nuovo
   `Imports`. `shinyWidgets`/`bsicons` si valutano solo se un componente non è
   ragionevole da scrivere in casa.
6. **Accessibilità come criterio di accettazione.** Contrasto, focus visibile,
   ordine di tabulazione e riduzione del movimento sono parte del "fatto".
7. **Un lotto = un commit verde.** Ogni passo lascia `R CMD check` e i test
   nella stessa condizione di prima.

---

## 4. Architettura target

### 4.1 Asset fuori da `app.R`

```
inst/www/css/
  tokens.css      # variabili, temi, densità, tipografia, spaziature
  base.css        # reset locale, tipografia, focus, utilità
  layout.css      # shell: topbar, sidebar, menubar, statusbar, tab strip
  components.css  # bottoni, campi, switch, segmented, card, badge, tabella
  dialogs.css     # modale, header/footer, griglia campi, anteprima comando
  views.css       # Data / Chart / Report / Workbench
  responsive.css  # breakpoint, stampa, reduced motion
inst/www/js/
  theme.js        # temi + densità
  shell.js        # tab strip, palette, scorciatoie
  dialogs.js      # drag dei modali, preset, anteprima
```

`app_css()` e `app_js()` restano le uniche porte d'ingresso: leggono i file e
restituiscono il testo concatenato. Così:

- `test-density.R` e `test-accessibility.R` continuano a funzionare senza
  modifiche;
- nulla dipende da `addResourcePath()` o da URL statici;
- il pacchetto funziona identico sotto `pkgload::load_all()` e da installato.

Il passaggio a `htmlDependency()` è rinviato: serve solo quando arriveranno
immagini o font, e non è necessario per questa onda.

### 4.2 La cucitura è `R/widgets.R`

I 157 dialoghi usano gli helper di `R/widgets.R` (`checkbox_input`,
`radio_input`, `spin_input`, `var_input`, `combo_input`, `entry_input`,
`help_text`, `file_input`, …). Modernizzare questi helper modernizza i dialoghi
senza toccarli. Nuovi helper, stessi ID e stessi valori:

| Helper nuovo | Sostituisce | Garanzia |
|---|---|---|
| `field()` | `form_group()` | stessi figli, label opzionale |
| `field_grid()` | div manuale `.rcmdr-field-grid` | stessa classe, in più `data-field` |
| `switch_input()` | `checkboxInput` | `<input type=checkbox>` con lo stesso ID |
| `segmented_input()` | `radioButtons` (≤ 4 scelte) | stessi radio, stessa semantica |
| `number_input()` | `numericInput` | `<input type=number>`, poi stepper JS opzionale |
| `icon()` | testo | SVG inline, `aria-hidden` di default |
| `modal_header()/modal_footer()` | `modalDialog()` a mano | stesso markup Bootstrap, più gerarchia |

Regola: **un helper non cambia mai il valore che Shiny legge.** Cambia solo
l'aspetto. Se un dialogo ha bisogno di un widget diverso, è una decisione a
parte, non un effetto collaterale del restyle.

### 4.3 Dialoghi

`dialog_modal()` in `R/dialogs.R` è l'unico punto da toccare per il chrome:

- header: icona della categoria, titolo, sottotitolo, chiusura;
- corpo: sezioni con icona, griglia a colonne, help testuale più leggero;
- footer: azione primaria a destra, secondarie a sinistra, hint contestuale;
- pannello "Comando R" e preset ridisegnati, ma con gli stessi ID
  (`dialog_preset_*`, `dialog_insert_script`, `dialog_help`).

I 157 `dialog_spec()` non si toccano, salvo aggiungere `icon` e `subtitle`
opzionali allo spec (retrocompatibili: default derivati da `category`).

### 4.4 Cosa non si usa

- **bslib components**: l'app ha già un layout proprio; affiancare `card()` e
  `layout_columns()` creerebbe due sistemi. bslib resta il fornitore di
  Bootstrap 5.
- **Sass**: i token sono già variabili CSS, sufficienti per 8 temi e 2 densità.
- **Framework JS**: 700 righe di JS nativo bastano; niente React/Vue.

---

## 5. Ondate interne

Le stime sono giornate di lavoro effettivo su una persona che conosce il
codice.

### U0 — Fondamenta tecniche (2–3 gg)

| ID | Task | File |
|---|---|---|
| U0.1 | Estrarre il CSS nei file di `inst/www/css/`; `app_css()` diventa un compositore | `R/app.R`, `inst/www/css/*` |
| U0.2 | Estrarre il JS nei file di `inst/www/js/`; `app_js()` diventa un compositore | `R/app.R`, `inst/www/js/*` |
| U0.3 | `rcmdr_icon()` con un set stroke 24x24 proprio (SVG inline, stile Bootstrap Icons) | `R/ui-components.R` |
| U0.4 | Documentare token e scala in `docs/upgrades/UI-TOKENS.md` | docs |

**Accettazione:** applicazione visivamente identica a prima; `test-density`,
`test-accessibility` e i 15 e2e verdi; nessun ID o classe rinominata.

### U1 — Token, tipografia, densità (3–4 gg)

- Scala tipografica (4 taglie, 2 pesi, interlinea), spaziature a 4 px.
- Altezze uniformi dei controlli (`--rcmdr-control-h`), raggi e ombre a token.
- Un solo anello di focus, visibile su tutti e 8 i temi.
- Bottoni: primario, secondario, ghost, pericolo; dimensione `sm` coerente.
- Stati: hover, focus, disabled, errore, caricamento.
- Test: contrasto WCAG calcolato sui token di ogni tema.

**Accettazione:** nessun colore o misura hard-coded nei file CSS nuovi;
`test-accessibility` esteso con i controlli di contrasto.

### U2 — Componenti condivisi (5–7 gg)

- `R/ui-components.R`: `field`, `field_grid`, `switch_input`,
  `segmented_input`, `number_input`, `toolbar`, `modal_header`,
  `modal_footer`, `tabs_strip`, `badge`.
- Restyle di topbar, tab strip, statusbar, sidebar e ricerca menu.
- Sostituzione dei `checkboxInput` diretti (15): `switch_input()` dove il
  valore è una preferenza, checkbox dove è un parametro del comando.

**Accettazione:** ogni componente ha un test di rendering e un esempio nella
documentazione interna; la shell non contiene più div con classi Bootstrap
scritte a mano.

### U3 — Dialoghi, a lotti (8–10 gg)

| Lotto | Ambito |
|---|---|
| U3.1 | Chrome comune + dialogo *Options* (vetrina) |
| U3.2 | Dati e import (`R/dialogs-data.R`, `dialogs-import-text.R`) |
| U3.3 | Statistiche (`R/dialogs-stats.R`, `dialogs-summaries.R`) |
| U3.4 | Grafici (`R/dialogs-graphs.R`) |
| U3.5 | Modelli, report, progetto, script (`dialogs-models*.R`, `report-studio.R`, `project-dialogs.R`, `document-dialogs.R`) |

Per ogni lotto: si migra, si aggiornano i test che citano i selettori toccati,
si committa verde. I dialoghi non migrati restano corretti perché gli helper
sono retrocompatibili.

**Accettazione:** i 13 file con helper migrati rendono con il nuovo chrome;
`get_dialog_spec()` per i 157 ID restituisce ancora uno spec valido;
nessuna regressione nei test dei dialoghi.

### U4 — Viste Studio (6–8 gg)

- Home, Data Studio, Chart Studio, Report Studio, Workbench, Help.
- Card, tabelle (`DT`, `rhandsontable`), toolbar, stati vuoti, badge di stato.
- Coerenza tra pannello largo e pannello stretto (1280 px vs 991 px).

**Accettazione:** nessuna vista usa più markup a mano dove esiste un
componente; layout verificato a 991, 1280 e 1600 px.

### U5 — Rifinitura e QA (4–5 gg)

- 8 temi × 2 densità: matrice di verifica visuale e di contrasto.
- Tastiera: ordine di tabulazione, `Esc`, focus trap nei modali, skip link.
- `prefers-reduced-motion`, zoom 200 %, stampa del report.
- Screenshot "prima/dopo" in `docs/upgrades/` e aggiornamento del topic di
  aiuto sull'interfaccia.
- `NEWS.md` e checklist.

**Accettazione:** [`ACCESSIBILITY.md`](ACCESSIBILITY.md) spuntata; nessun
elemento interattivo senza focus visibile; nessun contrasto sotto 4.5:1 sul
testo normale.

---

## 6. Fuori perimetro

- Nessuna modifica ai comandi R generati, ai command builder, ai plugin.
- Nessuna rinomina di ID, classi `.rcmdr-*`, export o file.
- Nessun cambio alla struttura della modalità Classica.
- Nessun tema nuovo oltre agli 8 esistenti.
- Nessun font remoto, nessuna icon library da CDN.
- Nessuna migrazione a bslib components o a un framework JS.

---

## 7. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| I test leggono stringhe CSS (`test-density`, `test-accessibility`) | Medio | `app_css()` resta compositore; si aggiornano le asserzioni solo se cambia un nome, nello stesso commit |
| 15 e2e con ~100 selettori `.rcmdr-*` | Alto | Solo aggiunte; migrazione per lotto con test aggiornati contestualmente |
| Contrasto insufficiente nei 6 temi non-standard | Alto | Test automatico del rapporto di contrasto sui token, non a occhio |
| Header del modale trascinabile già in produzione | Medio | Il nuovo header mantiene `pointerdown` su `.modal-header` e ignora bottoni/link, come oggi |
| Doppio sistema visivo (vecchio + nuovo) durante la migrazione | Medio | Helper retrocompatibili: i dialoghi non migrati restano coerenti, non "rotti" |
| Crescita di CSS/JS inline | Basso | ~1.500 righe totali: nessun impatto misurabile; minifica rinviata |
| Conflitto con il lavoro non committato presente nel repo | Alto | **Passo 0: committare o mettere da parte il working tree prima di iniziare** |

---

## 8. Strategia di test

| Livello | Cosa |
|---|---|
| Unit | Rendering di ogni componente: markup, ID, attributi ARIA |
| Contratto | `app_css()` contiene i token e le classi attese; ogni tema definisce tutti i token |
| Dialoghi | Per ogni lotto, render dei `dialog_spec()` del lotto e test dei valori degli input |
| e2e | 15 file shinytest2: aggiornati per lotto, mai disattivati |
| Accessibilità | Contrasto calcolato in R + checklist manuale tastiera/lettore di schermo |
| Visuale | Screenshot deterministici con `vdiffr`/Chrome headless solo per la vetrina |

---

## 9. Stima

| Fase | Giornate |
|---|---|
| U0 Fondamenta | 2–3 |
| U1 Token e tipografia | 3–4 |
| U2 Componenti | 5–7 |
| U3 Dialoghi | 8–10 |
| U4 Viste | 6–8 |
| U5 QA | 4–5 |
| **Totale** | **28–37** |

Corrisponde a **4–6 settimane di calendario** a tempo parziale, oppure 6–7
settimane piene includendo review e correzioni. La prima pillola visibile
(U0 + U1 + U2 + U3.1) è pronta in circa **una settimana** e riguarda la
schermata *Options* e il chrome dei modali: è il punto in cui si decide se la
direzione piace.

---

## 10. Criteri di chiusura

- [ ] CSS e JS non superano le 30 righe complessive dentro `R/app.R`.
- [ ] `R/widgets.R` è l'unico punto in cui si creano controlli di form.
- [ ] Nessun dialogo usa più `checkboxInput`, `numericInput` o `radioButtons`
      direttamente.
- [ ] 8 temi × 2 densità verificati; contrasto ≥ 4.5:1 sul testo normale.
- [ ] Focus visibile su ogni elemento interattivo; `Esc` chiude i modali.
- [ ] Test unit, contract, dialoghi e 15 e2e verdi.
- [ ] Screenshot prima/dopo e topic di aiuto aggiornati.
- [ ] `NEWS.md` e `CHECKLIST.md` aggiornati; diario dell'onda scritto.

---

## 11. Primo passo operativo

1. Committare il lavoro in corso (31 file modificati) o spostarlo su un ramo.
2. U0.1–U0.2: estrarre CSS e JS, nessun cambio visivo, test verdi.
3. U1: token e tipografia.
4. U2 + U3.1: componenti e dialogo *Options*.
5. Rivedere la schermata, poi proseguire con i lotti U3.2–U3.5.
