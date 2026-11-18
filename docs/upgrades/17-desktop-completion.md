# Onda 17 — Completamento desktop

**Data:** 2026-11-18  
**Stato:** in corso — T1–T6 fatti (lotti 1–2), prossimo lotto T7–T9  
**Baseline:** RcmdrShiny Studio 2.8.0 + Onda 16  
**Dipende da:** Onda 16 (sistema dei widget, accordion, Chart Builder)  
**Documento padre:** [`README.md`](README.md)  
**Rinvii registrati in:** [`16-bslib-widgets.md`](16-bslib-widgets.md) § 8

---

## 1. Obiettivo

Chiudere ciò che l'Onda 16 lascia fuori: l'aiuto contestuale, i campi data, il
feedback, le interazioni da desktop (pannelli ridimensionabili, menu
contestuali, drag-and-drop), le tabelle di sola lettura, i dialoghi dei plugin
e il rendering pigro delle viste pesanti.

L'Onda 16 ha reso omogenei i widget e ha raggruppato i parametri. Questa onda
si occupa di ciò che rende un'applicazione “desktop” oltre i controlli:
- l'aiuto che compare dove serve, senza spostare l'attenzione;
- i campi che mancano (date);
- il feedback immediato e non invadente;
- la possibilità di adattare lo spazio di lavoro;
- le azioni rapide col tasto destro e con la tastiera;
- il trascinamento là dove è naturale;
- le tabelle che restano leggibili con molti dati.

Nessun comando R, ID, valore o stringa i18n cambia se non per le nuove
funzioni esplicitamente previste (filtro data, menu contestuali, drag-and-drop).

---

## 2. Eredità dell'Onda 16 (assunta conclusa)

| Area | Cosa è già disponibile |
|---|---|
| Widget | specifica desktop, galleria, campi, checkbox/radio, switch, dropdown, listbox, picker |
| Accordion | `settings_accordion()`, `settings_panel()`, `settings_group()` |
| Chart Builder | scheda fissa + 6 pannelli, opzioni per tipo raggruppate |
| Dialoghi | *Options*, *Import*, *Frequency*, modelli e test a pannelli |
| Variabili | `var_input()` sulla famiglia scelta, stesso aspetto in tutti i dialoghi |
| QA | matrice 8 × 2 estesa, `QA-WIDGETS.md`, galleria di sviluppo |

Se l'Onda 16 devia su un punto, questa onda si adatta: le tappe presuppongono
gli helper, non i dettagli.

---

## 3. Cosa arriva dall'Onda 16

| Voce rinviata | Perché era fuori | Tappa |
|---|---|---|
| Tooltip e popover | servono stringhe e un pattern accessibile | T1 |
| Campi data | mancava il caso d'uso | T2 |
| Notifiche e attesa | il feedback non era omogeneo | T3 |
| Pannelli ridimensionabili | richiedono separatori e persistenza | T4 |
| Menu contestuali | richiedono tastiera, Esc e ritorno del focus | T5 |
| Drag-and-drop | richiede un'alternativa da tastiera | T6 |
| Tabelle di sola lettura | `reactable` è una dipendenza nuova | T7 |
| Dialoghi dei plugin | 15 plugin, dopo gli helper stabili | T8 |
| Help e palette | possono usare listbox e picker nuovi | T9 |
| Rendering pigro | va misurato, non promesso | T10 |
| e2e, screenshot, regressione visiva | dipendono dal browser | T11 |
| Chiusura | — | T12 |

---

## 4. Non previsto

| Elemento | Motivo |
|---|---|
| `bslib::card()`, `navset_*()`, `layout_columns()` | duplicano la shell e le griglie esistenti |
| `reactable` al posto di DT nei dati editabili | DT è integrato con selezione, filtri e test |
| Nuovi parametri statistici o di grafico | cambiano i comandi, non la pelle |
| Riscrittura di shell, tab o menu | fatta nell'Onda 15 |
| Framework UI alternativi | bslib resta il fornitore di Bootstrap 5 |

---

## 5. Architettura e decisioni

### 5.1 Tooltip e popover

- `help_tip(text, placement = "top")` avvolge `bslib::tooltip()` con un trigger
  **focusabile** (`<button type="button">`), non solo `hover`.
- Il contenuto è collegato con `aria-describedby`; `Esc` chiude; il focus resta
  sul trigger.
- Non sostituisce `help_text()`: lo completa per i parametri che non hanno
  spazio per una riga di aiuto.
- Le stringhe nuove passano da `tr()` e vanno in tutte le lingue; nessun testo
  hard-coded.

### 5.2 Campi data

- `date_input()` e `date_range_input()` su `airDatepickerInput()`, con lingua
  corrente, `min`/`max`, pulsante di cancellazione e chiusura automatica.
- Primo uso: filtro del Data Studio quando la colonna è `Date` o `POSIXct`.
  Il filtro resta di vista, non cambia il comando R.
- Il valore letto dal server è una data o un intervallo, non una stringa
  libera.

### 5.3 Feedback

- Notifiche con `shiny::showNotification()` stilata sui token: tipi, durata,
  chiusura, massimo tre in coda.
- Indicatori di attesa per operazioni lunghe (knit, import, preview) con
  `aria-busy` e un testo `aria-live`.
- Stato di successo/errore inline dove l'azione avviene, non solo in Console.
- Nessuna dipendenza nuova: `bslib` 0.9.0 non espone `toast()`.

### 5.4 Pannelli ridimensionabili

- `split_pane(id, first, second, orientation, initial, min)` con separatore
  `role="separator"`, `aria-orientation`, `aria-valuemin/max/now`.
- Tastiera: frecce per spostare, Home/End per gli estremi, doppio clic o
  doppio Invio per tornare alla misura iniziale.
- Dimensioni salvate nelle preferenze (`state$options$layouts`), con una
  versione per poter cambiare i default senza rompere i file.
- Applicazione: Chart builder/preview, griglia/inspector del Data Studio,
  outline/editor/preview del Report.
- Minimi garantiti; a zoom 200% i pannelli collassano a una colonna.

### 5.5 Menu contestuali

- `context_menu()` + JS: tasto destro su intestazione/colonna della griglia,
  scheda della galleria, linguetta del documento.
- Tastiera: tasto Menu o `Shift`+`F10`; `Esc` chiude; il focus torna
  all'elemento di partenza.
- Le voci riusano gli stessi handler delle toolbar: nessuna logica duplicata.
- Il menu è `role="menu"` con `menuitem`, si posiziona dentro il viewport e se
  ne apre uno solo alla volta.

### 5.6 Drag-and-drop

- HTML5 drag-and-drop per riordinare le colonne del Data Studio, l'ordine dei
  grafici fissati e il drop di un file sull'area dati.
- Alternativa da tastiera: “Sposta su/giù” nel menu contestuale.
- Il file droppato passa dallo stesso percorso del file picker, con conferma;
  niente esecuzione silenziosa.
- L'ordine è persistito e annullabile con i checkpoint esistenti.

### 5.7 Tabelle di sola lettura

- Gate: prototipo `reactable` per glossario, topic Help, registro documenti e
  confronto modelli. Si misura peso, tema e tastiera.
- Se il gate passa, `reactable` entra **solo** per le tabelle di sola lettura;
  DT resta per dati editabili, selezione e filtri.
- Se non passa, si tiene DT e si rifiniscono header sticky, densità e
  selezione.

### 5.8 Dialoghi dei plugin

- Inventario dei 15 plugin; migrazione per famiglie con `settings_accordion()`,
  `listbox_input()` e `date_input()` dove servono.
- Nessun cambio di comandi o ID; il contract dei plugin è il gate.
- I plugin che non usano gli helper restano fuori e vengono elencati.

### 5.9 Rendering pigro

- Prima si misura: tempo di `app_ui()`, cambio vista, Gallery, Models,
  risultati Help, preview Report.
- Poi si differisce il `renderUI` delle viste pesanti alla prima apertura, con
  cache e invalidazione sui cambi di dati.
- Nessun cambio funzionale; i test verificano primo render, invalidazione e
  assenza di dati stantii.

---

## 6. Sequenza degli step

Quattro lotti da tre. Stima: **14–16 giornate**.

| Lotto | Step | Tema | Stima |
|---|---|---|---|
| 1 | T1–T3 | Aiuto contestuale, date, feedback | 3,5 gg |
| 2 | T4–T6 | Pannelli, menu contestuali, drag-and-drop | 5 gg |
| 3 | T7–T9 | Tabelle, plugin, Help/palette | 4,5 gg |
| 4 | T10–T12 | Prestazioni, QA, chiusura | 3 gg |

### Lotto 1 — Aiuto e campi speciali

#### T1 — Tooltip e popover

**Obiettivo:** l'aiuto di un parametro compare dove serve, senza rubare il
focus e senza sostituire il testo esistente.

**File:** `R/ui-components.R`, `R/widgets.R`, `R/chart-studio.R`,
`inst/www/css/20-components.css`, `tests/testthat/test-ui-components.R`,
`tests/testthat/test-accessibility.R`, `inst/i18n/*.tsv`.

**Cosa cambia:** `help_tip()`; trigger focusabile; `aria-describedby`; `Esc`;
uso nel Chart Builder e nei dialoghi con parametri densi; stringhe `tr()`.

**Accettazione:** il tooltip si apre con focus e con hover, si chiude con `Esc`,
non intrappola il focus, non duplica l'help testuale; contrasto e 8 × 2 verdi.

**Commit:** `feat(ui): add accessible parameter tooltips`

#### T2 — Campi data e intervalli

**Obiettivo:** colmare l'unica famiglia di input ancora assente.

**File:** `R/widgets.R`, `R/app.R` (filtro Data Studio),
`inst/www/css/55-shinywidgets.css`, test.

**Cosa cambia:** `date_input()` e `date_range_input()`; filtro data quando la
colonna è `Date`/`POSIXct`; lingua, `min`/`max`, cancellazione.

**Accettazione:** il filtro restituisce le stesse righe di un filtro testuale
equivalente; il valore è una data; tastiera e locale correnti; nessun comando R
nuovo.

**Commit:** `feat(data): add date fields and a date filter`

#### T3 — Notifiche, attesa e stato

**Obiettivo:** un feedback unico per tutte le operazioni.

**File:** `inst/www/css/20-components.css`, `inst/www/js/40-interactions.js`,
`R/app.R`, test.

**Cosa cambia:** notifiche stilate, coda massima, chiusura; `aria-busy` e
`aria-live` per knit/import/preview; stato inline di successo/errore.

**Accettazione:** nessuna notifica sovrapposta oltre tre; lo screen reader
annuncia l'attesa e l'esito; nessuna dipendenza nuova.

**Commit:** `feat(ui): unify notifications and busy states`

**Gate del lotto 1:** tooltip, date e notifiche nelle 8 palette × 2 densità;
tastiera e screen reader verificati.

---

### Lotto 2 — Interazioni desktop

#### T4 — Pannelli ridimensionabili

**Obiettivo:** lo spazio di lavoro si adatta, come in un'applicazione desktop.

**File:** `R/ui-components.R`, `R/chart-studio.R`, `R/data-studio.R`,
`R/report-studio.R`, `inst/www/js/40-interactions.js`,
`inst/www/css/10-shell.css`, `inst/www/css/60-views.css`, test.

**Cosa cambia:** `split_pane()`; separatore da tastiera; persistenza; doppio
clic per il default; minimi e collasso a una colonna.

**Accettazione:** il separatore è raggiungibile con Tab, si muove con le
frecce, annuncia il valore; la misura sopravvive al riavvio; nessun overflow a
zoom 200%.

**Commit:** `feat(ui): add keyboard-accessible split panes`

#### T5 — Menu contestuali

**Obiettivo:** le azioni rapide del desktop, senza duplicare la toolbar.

**File:** `R/ui-components.R`, `inst/www/js/40-interactions.js`,
`inst/www/js/50-menubar.js`, `inst/www/css/20-components.css`, test.

**Cosa cambia:** `context_menu()`; tasto destro, tasto Menu, `Shift`+`F10`;
`Esc`; focus di ritorno; voci che chiamano gli stessi handler. Non intercetta
il menu già fornito da `rhandsontable` nel foglio di calcolo.

**Accettazione:** un solo menu aperto; posizione dentro il viewport; voci
raggiungibili da tastiera; stessi effetti dei bottoni equivalenti.

**Commit:** `feat(ui): add desktop context menus`

#### T6 — Drag-and-drop

**Obiettivo:** riordinare e importare con il gesto naturale, con una via
alternativa da tastiera.

**File:** `R/data-studio.R`, `R/chart-studio.R`,
`inst/www/js/40-interactions.js`, `inst/www/css/60-views.css`, test.

**Cosa cambia:** riordino colonne, ordine dei grafici fissati, file drop con
conferma; “Sposta su/giù” nel menu contestuale; persistenza e undo.

**Accettazione:** l'ordine è persistito; il drop passa dal percorso di import
esistente; l'alternativa da tastiera produce lo stesso risultato.

**Commit:** `feat(ui): add drag-and-drop with a keyboard alternative`

**Gate del lotto 2:** le tre interazioni convivono nelle viste senza
sovrapporsi; zoom 200% e reduced motion verdi.

---

### Lotto 3 — Tabelle, plugin, Help

#### T7 — Tabelle di sola lettura

**Obiettivo:** decidere con una misura se `reactable` merita di entrare.

**File:** `R/help-ui.R`, `R/models-studio.R`, `R/document.R` (registro),
`tests/testthat/test-help-ui.R`, test delle tabelle.

**Cosa cambia:** prototipo `reactable` per glossario, topic Help, registro e
confronto modelli; tema dai token; header sticky; tastiera. Se il gate non
passa, si tiene DT e si rifinisce.

**Accettazione:** nessuna tabella editabile passa a `reactable`; contrasto,
tastiera e 8 × 2 verdi; il peso aggiunto è misurato e documentato.

**Commit:** `feat(ui): evaluate read-only tables`

#### T8 — Dialoghi dei plugin

**Obiettivo:** i 15 plugin usano lo stesso vocabolario dei dialoghi core.

**File:** `plugins/*/R/dialogs.R`, `tests/testthat/test-plugins*.R`,
`tests/testthat/test-dialog-contract.R`.

**Cosa cambia:** accordion e listbox nei dialoghi dei plugin, per famiglie;
nessun cambio di comandi o ID.

**Accettazione:** contract dei plugin verde; i dialoghi non migrati sono
elencati; e2e dei plugin dove il browser funziona.

**Commit:** `feat(plugins): group the plugin dialogs`

#### T9 — Help centre e command palette

**Obiettivo:** ricerca e filtri con i widget nuovi, non con quelli vecchi.

**File:** `R/help-ui.R`, `R/command-palette.R`,
`inst/www/css/40-dialogs.css`, test.

**Cosa cambia:** filtri Help con picker/listbox; risultati con conteggio e
`aria-live`; palette con listbox, evidenziazione e tastiera; stato vuoto.

**Accettazione:** la ricerca resta full-text; la tastiera della palette è
invariata; nessuna nuova stringa non tradotta.

**Commit:** `feat(help): use the new listbox in Help and the palette`

**Gate del lotto 3:** contract core e plugin verdi; Help e palette accessibili.

---

### Lotto 4 — Prestazioni, QA, chiusura

#### T10 — Rendering pigro

**Obiettivo:** le viste pesanti non pagano il costo finché non si aprono.

**File:** `R/app.R`, `R/chart-studio.R`, `R/models-studio.R`, `R/help-ui.R`,
`R/report-studio.R`, test.

**Cosa cambia:** misure prima/dopo; `renderUI` differito alla prima apertura;
cache e invalidazione; nessun cambio funzionale.

**Accettazione:** primo render più leggero, dati mai stantii; i test di
invalidazione passano; nessuna regressione nelle viste.

**Commit:** `perf(ui): render heavy views on first open`

#### T11 — e2e, screenshot, regressione visiva

**Obiettivo:** chiudere la verifica visiva rimasta in sospeso dall'Onda 15.

**File:** `tests/testthat/*-e2e.R`, `tools/help_screenshots.R`,
`docs/upgrades/QA-WIDGETS.md`.

**Cosa cambia:** esecuzione dei 26 e2e su un browser funzionante; screenshot
delle viste e dei dialoghi; baseline di regressione; matrice 8 × 2.

**Accettazione:** e2e verdi; screenshot rigenerati; le differenze accettate
sono documentate; se il browser non è disponibile, il limite resta scritto.

**Commit:** `test(ui): run the browser suite and refresh the screenshots`

#### T12 — Chiusura

**Obiettivo:** documentare e consegnare.

**File:** `NEWS.md`, `inst/help-topics/topics/about.md`,
`docs/upgrades/CHECKLIST.md`, `docs/upgrades/README.md`,
`docs/upgrades/diary/wave-17-desktop-completion.md`,
`docs/upgrades/QA-WIDGETS.md`.

**Cosa cambia:** NEWS, topic, checklist, diario, QA; suite completa; app
riavviata; push.

**Accettazione:** `EXIT=0`; working tree pulito; limiti documentati.

**Commit:** `docs: close wave 17`

---

## 7. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| Tooltip solo hover | inaccessibile | trigger focusabile + `Esc` + test |
| Fuso orario e locale delle date | filtro sbagliato | test con date e `POSIXct`; locale dalla lingua |
| Split pane che rompe il layout a zoom 200% | reflow pessimo | minimi, collasso a una colonna, test |
| Menu contestuali con logica duplicata | azioni divergenti | stessi handler delle toolbar |
| Drag-and-drop inaccessibile | utenti da tastiera esclusi | “Sposta su/giù” nel menu |
| `reactable` pesante o non tematizzabile | dipendenza inutile | gate in T7; DT resta il default |
| Plugin troppo eterogenei | migrazione incompleta | lotti per famiglia; contract |
| Rendering pigro con dati stantii | risultati sbagliati | invalidazione testata |
| Browser non disponibile per e2e | QA visiva rinviata | limite documentato, come nell'Onda 15 |

---

## 8. Criteri di chiusura

- [ ] 12 step, 4 lotti, handoff dopo T3, T6, T9, T12.
- [ ] Nessun comando o ID cambiato; nuove funzioni solo dove previsto.
- [ ] Tooltip, date, notifiche, split pane, menu contestuali e drag-and-drop
      accessibili da tastiera.
- [ ] Tabelle: decisione su `reactable` motivata e misurata.
- [ ] Plugin migrati per famiglia; contract verde.
- [ ] Help e palette usano i widget nuovi.
- [ ] Rendering pigro misurato, senza dati stantii.
- [ ] 8 temi × 2 densità, zoom 200%, reduced motion.
- [ ] e2e e screenshot eseguiti dove il browser funziona.
- [ ] NEWS, topic, checklist, diario e QA aggiornati.

---

## 9. Protocollo di handoff

Dopo **T3**, **T6**, **T9** e **T12**:

1. suite completa e log in `/tmp/opencode/tests-w17-<lotto>.log`;
2. aggiornamento di `docs/upgrades/diary/wave-17-desktop-completion.md`;
3. checkpoint git pulito e push;
4. stop: l'utente compatta il contesto e riprende con `continua`.

Il diario viene creato alla fine del lotto 1.
