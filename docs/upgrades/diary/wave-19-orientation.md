# Diario di handoff — Onda 19 — Orientamento

**Data:** 2026-11-19  
**Stato:** lotto 1 completato (O1–O3); prossimo lotto O4–O6  
**Baseline:** RcmdrShiny Studio 3.0.0 (Onda 18)  
**Documento di settore:** [`19-orientation.md`](../19-orientation.md)  
**ADR:** [`DECISIONS.md`](../DECISIONS.md) — ADR-019  
**Onda precedente:** [`wave-18-desktop-workspace.md`](wave-18-desktop-workspace.md)

---

## 1. O1 — Verità sul filtro · `1184e0e`

**File:** `R/data-studio.R`, `R/app.R`, `inst/i18n/it.tsv`,
`tests/testthat/test-data-studio-grid.R`.

- Nuovo `data_filter_label()`: descrive il filtro dalla terna
  `column`/`value`/`dates` e restituisce `""` quando non c'è filtro.
- Nuovo `data_view_state()`: righe visibili, totale, colonne, `filtered` e
  `filter_label`. È puramente descrittivo e non tocca il filtro.
- Nuovo `data_view_shape()`: forma breve per la status bar
  (`1 of 4 x 2`) e lunga per `data_info`
  (`1 of 4 rows x 2 columns, 2 cells`).
- `data_grid_plan()` resta la decisione sulle soglie e legge il dataset
  intero: il paging server-side è una proprietà del dataset, non della vista.
- `data_info` e status bar leggono la vista: con un filtro attivo nessuna
  delle due mostra più il solo totale. Se il filtro non riduce le righe, il
  conteggio non si ripete, ma la chip dice che il filtro è attivo.
- La status bar aggiunge `filter: <label>` come fatto separato.
- Test: helper puri (filtro testo, intervallo date, filtro che non riduce) e
  un `testServer` con filtro attivo che verifica `1 of 4 x 2` e
  `filter: a 2`.

**Deviazione:** in O1 il filtro è testo semplice; la chip arriva in O2, come
previsto dal piano.

---

## 2. O2 — Grammatica visiva dello stato · `2fe2d57`

**File:** `R/ui-components.R`, `inst/www/css/20-components.css`,
`R/app.R`, `inst/i18n/it.tsv`, `tests/testthat/test-orientation.R`.

- `context_chip(text, icon, tone)` è un **wrapper sottile di `badge()`**, non
  un secondo sistema di badge: la grammatica condivide classi, token e test
  di contrasto già esistenti.
- Nuovo tono `accent` per "sei qui": bordo `--rcmdr-accent`, superficie e
  testo del corpo, così il contrasto resta quello misurato.
- Sette icone inline nuove: `file`, `folder`, `arrow`, `funnel`, `lock`,
  `server`, `undo` (`plus` esisteva già). Nessuna dipendenza, nessun CDN.
- I limiti in `data_info` diventano chip: `editing disabled` (warning,
  lucchetto) e `server-side paging` (neutra, server).
- La chip del filtro in status bar usa l'imbuto.
- Test: ogni icona è SVG con `aria-hidden`; ogni chip ha testo oltre al
  colore; il tono `accent` usa solo token, senza colori letterali.

**Deviazione:** le icone sono sette, non otto, perché `plus` era già nel set.

---

## 3. O3 — Riga di contesto nelle viste · `1f520a4`

**File:** `R/workspace.R`, `R/app.R`, `inst/www/css/10-shell.css`,
`inst/i18n/it.tsv`, `tests/testthat/test-orientation.R`.

- `workspace_context_line()` costruisce una riga sola:
  `Studio · <vista>` + chip dataset + chip filtro (solo Data Studio) + chip
  `Rows`/`Cells`.
- La riga è **testo, non un controllo**: nessun tab stop in più, nessun
  pulsante. La pulizia del filtro resta nella toolbar.
- `workspace_context_ui` è renderizzata nella shell Studio, sotto la view bar;
  la modalità Classica non la vede perché non usa `workspace_shell_ui`.
- CSS: riga da 28 px, chip inline, `overflow-x: auto` sotto 992 px.
- Test: la riga nomina luogo, dataset e filtro; ogni vista ha il suo luogo;
  nessun elemento focalizzabile; il server la rende con `main_tabs = "data"`.

**Deviazione:** la chip del filtro non è cliccabile. Il piano la ammetteva
come opzione; tenerla statica evita un tab stop in più e lascia **Clear
filter** nel posto in cui l'utente lo cerca.

---

## 4. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 29 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w19-lotto1.log`) |
| `node --check` | verde sul JS composto (`/tmp/opencode/app-o3.js`) |
| Filtro | `1 of 4 x 2` in status bar e `1 of 4 rows x 2 columns, 2 cells` in `data_info` |
| Chip | testo sempre presente; icone decorative; tono accent senza colori letterali |
| Contesto | 8 viste coperte; nessun controllo nella riga |
| Classic | nessuna regola nuova applicata; shell Classica invariata |

---

## 5. Problemi noti e rinvii

| Problema | Impatto | Rinvio |
|---|---|---|
| Limiti ancora in `data_info` e non nella riga di contesto | lieve duplicazione con le chip | O4/O8 |
| La status bar ha ancora dodici fatti | leggibilità a zoom 200% | O4 |
| Nessuna intestazione dei due slot | split ambiguo | O5 |
| `Esc` e reset incoerenti | ritorno imprevedibile | O6 |
| Nessun browser | resa visiva non verificata | test manuale su desktop |

---

## 6. Prossimo passo

Lotto 2: **O4** status bar a priorità, **O5** intestazioni degli slot,
**O6** ritorno prevedibile. Handoff dopo O6.

---

## Lotto 2 — Gerarchia e ritorno (O4–O6)

**Data:** 2026-11-19 · suite verde, `node --check` verde.

### O4 — Status bar a priorità · `161f128`

**File:** `R/app.R`, `R/console-studio.R`, `R/history-ui.R`,
`R/chart-studio.R`, `inst/www/css/10-shell.css`, test.

- La status bar ha tre gruppi con nome accessibile: **Identity** (dataset,
  forma visibile, filtro), **Selection**, **Last action**. Busy ed errore
  restano un quarto gruppo presente solo quando servono.
- A 1280 px si vedono al massimo cinque fatti (dataset, forma, filtro,
  selezione, ultima azione), entro il limite di sei.
- Versione → **Help > About** (già presente). Conteggi spostati dove servono:
  `%d command(s)` in Console, `%d history step(s)` in History,
  `%d plot(s)` nella Gallery di Chart Studio. Model e badge di modalità non
  sono più fatti di stato: il model badge è nel topbar, la modalità nel suo
  interruttore.
- Sotto 992 px la forma visibile è nascosta (`rcmdr-status-optional`): resta
  in `data_info`, quindi non si perde; separatori rimossi e spaziatura ridotta.
- `aria-live="polite"`, `role="status"`, `aria-atomic="false"` invariati.

### O5 — Intestazioni dei due slot · `54e3f8a`

**File:** `R/workspace.R`, `R/app.R`, `inst/www/css/60-views.css`,
`inst/i18n/it.tsv`, test.

- `workspace_slot_header(role, view)` produce `Primary · Data Studio` /
  `Secondary · Help centre`; bordo sinistro `accent` per il primario,
  `border-strong` per il secondario. Il colore non è mai solo: c'è la parola.
- `workspace_slot_label(role, view)` dà il nome accessibile
  `Primary view: <vista>` / `Secondary view: <vista>` alla regione.
- L'intestazione compare solo quando c'è lo split (o il focus su uno dei due
  slot); la vista singola resta senza header ridondante.
- `data-rcmdr-focus-region` e `tabindex="-1"` invariati: `F6` non cambia.
- Sotto 992 px restano il nome della vista; ruolo e separatore si nascondono.

### O6 — Ritorno prevedibile · `51593fc`

**File:** `inst/www/js/66-modeless.js`, `R/app.R`,
`docs/upgrades/ACCESSIBILITY.md`, test.

- Un solo gestore `Esc` per il pannello modeless, in cattura, con la regola
  **un tasto = un livello**: se un livello interno (tooltip, menu, selezione
  celle) ha già chiamato `preventDefault`, il pannello resta aperto. Con una
  modale aperta, `Esc` chiude la modale e non il pannello sotto.
- Chiusura con pulsante o con `Esc` passano dalla stessa funzione
  `closeAndReturn()`, che riporta il focus al trigger.
- **Reset layout** chiude il modeless e manda il focus a `workspace-primary`
  (il menu che ha lanciato il comando è già chiuso). Non tocca dati, undo,
  history: il test lo verifica.
- `ACCESSIBILITY.md` aggiornato con la regola dei livelli e il focus return.

### Verifica lotto 2

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 29 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w19-lotto2.log`) |
| `node --check` | verde sul JS composto (`/tmp/opencode/app-o6.js`) |
| Status bar | 3 gruppi + stato; ≤ 6 fatti a 1280 px; nessuna informazione persa |
| Slot | intestazione e nome accessibile solo con split; F6 invariato |
| `Esc` | livello interno vince; modale sopra il pannello; focus al trigger |
| Reset | chiude il modeless; dati, undo e history invariati |

### Problemi noti e rinvii

| Problema | Impatto | Rinvio |
|---|---|---|
| Limiti ancora in `data_info` | duplicazione con le chip di stato | O8 |
| Nessun browser | resa visiva e focus return non provati a schermo | test manuale desktop |
| Focus del reset non verificabile senza DOM | dipende dal messaggio `rcmdr-focus` | e2e quando il browser torna |

### Prossimo passo

Lotto 3: **O7** Home in stato Avvio (quattro porte, “Continua senza dati”),
**O8** stati vuoti azionabili e annunci, **O9** chiusura a 3.1.0 con ADR-019.

---

## Lotto 3 — Avvio e chiusura (O7–O9)

**Data:** 2026-11-19 · suite verde, `node --check` verde, app HTTP 200.

### O7 — Home in stato Avvio · `5abf133`

**File:** `R/app.R`, `R/workspace.R`, `inst/www/css/60-views.css`,
`inst/i18n/it.tsv`, test.

- `home_start_state(state)` è la regola esplicita: nessun dataset attivo,
  nessun progetto aperto e nessun progetto recente. `home_pane_ui(state)` è la
  Home normale in ogni altro caso; Classica continua a chiamarla senza stato.
- `home_start_ui()` mostra **quattro porte**: *Import a file* (wizard
  `dataImportWizard`), *New data set* (`newDataSet`, unica azione primaria),
  *Open a project* (`projectOpen`) e *Continue without data*.
- *Continue without data* porta a **Script** e annuncia «You can work without
  data.»; la pagina dice già che script e console sono sempre disponibili.
- Nessuna modale all'avvio. Lo stato Avvio è uno stato della Home; la variante
  modale (`show_start`) resta una preferenza futura, non implementata.
- La vista Home è l'unica che si aggiorna anche su `tick()`: il resto del
  workspace non paga la dipendenza.
- Test: quattro porte, nessuna card *Continue* nello stato Avvio; dataset o
  progetto recente riportano la Home normale; la pagina nomina il lavoro senza
  dati.

### O8 — Stati vuoti azionabili · `a00d116`

**File:** `R/app.R`, `R/environment-studio.R`, `R/chart-studio.R`,
`R/report-studio.R`, `R/help-server.R`, test.

| Vista | Prima | Ora |
|---|---|---|
| Data Studio | solo testo | *Import...* (`dataImportWizard`) e *New data set* (`newDataSet`) |
| Environment | solo testo | *Import data* e *Open script* |
| Charts (gallery e dettaglio) | solo testo | *Build a chart* → `chart_mode = build` |
| Report | solo testo | *New document* (`newRmd`) e *Open* (`loadRmd`/`loadRnw`) |
| Console | solo testo | *Open script* |
| Help (ricerca e filtri) | solo testo | *Clear search* → stesso percorso di *Clear filters* |

- Gli stati vuoti usano `empty_state(action = ...)` e gli ID già esistenti;
  nessun comando nuovo. Le sei viste della tabella 5.9 hanno un'azione.
- Il filtro annuncia la forma visibile quando si applica
  («Filter applied: a 2 (1 of 4 rows x 2 columns, 2 cells)») e quando si
  pulisce («Filter cleared (4 x 2)»); il valore è debounced, quindi la digitazione
  non produce un annuncio per tasto.
- La status bar tiene l'errore a una riga leggibile (massimo 120 caratteri,
  prima riga); il testo completo resta nel `title` e nel pannello Output.
- `help_empty_clear` e `help_clear_filters` condividono `clear_help_filters()`,
  così il comportamento è uno solo.

### O9 — Chiusura · `docs: close wave 19`

- `DESCRIPTION` 3.1.0; NEWS con la sezione *Orientation*; README con lo stato
  3.1 e il riassunto dell'onda; topic About invariato (legge la versione dal
  pacchetto); piano Onda 19 segnato chiuso; checklist O7–O9 completata.
- Nessun comando, dialogo, ID o stringa esistente è cambiato.

### Verifica lotto 3 e chiusura

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 29 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w19-lotto3-pre.log`) |
| `node --check` | verde sul JS composto (`/tmp/opencode/app-w19.js`) |
| App HTTP | `200` su `http://127.0.0.1:3841/` con `RCMDRSHINY_BROWSER=FALSE` |
| Home Avvio | quattro porte, una primaria, nessuna modale; Home normale con dataset o progetto recente |
| Stati vuoti | 6 su 6 con azione; nessun nuovo comando |
| Annunci | filtro applicato/pulito e «lavoro senza dati» su live region `polite` |
| Errore | una riga in status bar, testo completo altrove |
| Classic | `tabsetPanel` e `data-value` invariati; nessun test Classic modificato |

### Limiti e rinvii

| Problema | Impatto | Rinvio |
|---|---|---|
| Browser non navigabile (Chrome 157) | resa visiva, focus return e zoom 200% non provati a schermo; 29 e2e saltati | verifica manuale desktop prima della release |
| Test a cinque compiti con utenti SPSS/Minitab | misura di successo non raccolta | manuale, come onde 16–18 |
| `show_start` (`auto`/`always`/`never`) | pattern modale non disponibile | preferenza futura, fuori onda |

**Stato onda:** chiusa a 3.1.0. Nove step verdi, tre handoff (O3, O6, O9).
