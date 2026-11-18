# Onda 19 — Orientamento

**Data:** 2026-11-18  
**Stato:** pianificata — 9 step in 3 lotti (O1–O9), versione 3.1.0  
**Baseline:** RcmdrShiny Studio 3.0.0 (Onda 18)  
**Dipende da:** Onda 18 (workspace, status bar, geometria, soglie dati),
Onda 16 (token e widget), Onda 6.5 (menu-first)  
**Documento padre:** [`README.md`](README.md)  
**ADR collegata:** [`DECISIONS.md`](DECISIONS.md) — ADR-019

---

## 1. Obiettivo

L'Onda 18 ha costruito lo **spazio** desktop: menu-first, due slot, pannelli,
geometria, status bar, dati grandi. L'Onda 19 chiude una cosa diversa: che in
quello spazio l'utente **sappia sempre dove si trova**. Il punto di partenza
non è estetico, è di fiducia: oggi, con un filtro attivo, la griglia mostra 12
righe e la status bar continua a dire "5.000 × 5". Due numeri veri e
incompatibili nella stessa schermata.

L'orientamento si misura con quattro domande, a cui **ogni** schermata deve
rispondere senza che l'utente cerchi:

1. **Dove sono?** Vista, slot, pannello, dialogo.
2. **Su cosa sto lavorando?** Dataset, forma visibile, filtro, selezione,
   modello.
3. **Cosa è appena successo?** Ultima azione, errore, undo, operazione in
   corso.
4. **Cosa posso fare adesso, e come torno indietro?** Passo successivo,
   chiusura, ripristino.

La "welcome window" discussa all'avvio è **il primo caso** di questa onda, non
il tema: è la domanda 4 applicata a un'app che non ha ancora dati.

Al termine:

- la forma mostrata è sempre quella visibile, e il totale appare solo se
  diverso;
- ogni vista ha una riga di contesto con vista, dataset, filtro e selezione;
- lo stato usa una grammatica visiva coerente: **colore + icona + testo**,
  quattro significati, token esistenti;
- la status bar ha una gerarchia invece di dodici fatti equivalenti;
- i due slot sono etichettati e distinguibili senza indovinare;
- `Esc` e **Reset layout** hanno una regola unica e prevedibile;
- la Home diventa la schermata di avvio quando non c'è né dataset né progetto,
  con quattro porte e "continua senza dati";
- ogni stato vuoto dice qual è il passo successivo;
- la suite completa è verde e il limite browser resta documentato.

Nessun comando R, ID, valore o stringa i18n esistente cambia. La modalità
Classica resta strutturalmente identica (`tabsetPanel`, `data-value`).

---

## 2. Non-obiettivi

| Elemento | Motivo |
|---|---|
| Una dashboard globale o una nuova schermata "mappa" | l'orientamento è informazione nel posto giusto, non una pagina in più |
| Un colore per dataset o per vista | rompe gli 8 temi, il daltonismo e crea semantica falsa |
| Navigazione icona-sola | peggiore per l'utente classico e per lo screen reader |
| Tracciamento dell'utente o analytics | l'app resta locale e offline |
| Nuove dipendenze | icone SVG inline e token esistenti bastano |
| Modifica della modalità Classica | è il contratto di compatibilità |
| Welcome modale a **ogni** avvio | l'app è una sessione con più dataset, non un file per avvio |
| Nuove procedure statistiche o grafici | cambia l'orientamento, non il motore |
| Riscrittura della status bar da zero | si riorganizza, non si sostituisce |

---

## 3. Stato di partenza (misurato)

| Area | Situazione | Conseguenza |
|---|---|---|
| Forma visibile | `data_info` e status bar leggono `dataset(state)` | con un filtro mostrano il totale, non le righe visibili |
| Filtro | controlli nella toolbar, pulsante **Clear filter** | nessun indicatore "filtro attivo" fuori dai controlli |
| Riga di contesto | breadcrumb solo in dialoghi e workflow | le viste principali non dicono dove sei |
| Due slot | nessuna intestazione; solo l'anello di focus distingue | "due Data Studio" sembrano due sessioni |
| Status bar | 12 fatti: versione, modalità, forma, dataset, comandi, history, modello, plot, selezione, undo, busy, errore | elenco, non gerarchia; illeggibile a zoom 200% |
| Ritorno | **Back to workspace** nel modeless; **Reset layout** non lo chiude | aspettative incoerenti |
| `Esc` | livelli diversi si comportano diversamente | l'utente non sa cosa aspettarsi |
| Stati vuoti | "No active data set", "Environment is empty" | dicono cosa manca, non cosa fare |
| Avvio | Home con card; **New Data Set** in File > New | il primo gesto non è esplicito per chi viene da SPSS |
| Grammatica visiva | token semantici completi; 18 icone inline | mancano chip di stato e un uso coerente del colore |
| Test | matrice 8 × 2 e contrasto verdi; 29 e2e saltati | la resa visiva resta non verificata |

---

## 4. Principi e vincoli

1. **Quattro domande, una superficie.** Ogni schermata risponde almeno a
   "dove sono" e "su cosa"; le altre due dove servono.
2. **Un fatto, un posto.** Il nome del dataset non vive in topbar *e* status
   bar; i conteggi di comandi, history e plot vivono nelle loro viste.
3. **La forma mostrata è quella visibile.** Se un filtro riduce le righe, il
   numero visibile è primo e il totale è un'aggiunta ("12 di 5.000").
4. **Il filtro è vista, non dato.** Non colora le righe, non è un avviso, non
   entra nel comando.
5. **Colore ridondante.** Ogni significato è colore **+ icona + parola**. Togli
   il colore e il messaggio resta.
6. **Quattro significati, quattro token.** `accent` = sei qui; `warning` = un
   limite vale; `danger` = è fallito; `selection` = selezionato. Nient'altro.
7. **Niente nuova chrome.** Si riusano `studio_breadcrumb()`, `badge()`,
   `note()` e `rcmdr_icon()`; non si aggiungono barre.
8. **Classica intatta.** Ogni regola nuova è confinata a
   `body.rcmdr-mode-studio`.
9. **Tastiera e screen reader prima.** Le chip sono testo; le icone sono
   decorative o nominate; nulla dipende dal colore.
10. **Offline.** Icone SVG inline, nessun CDN, nessun font remoto.
11. **Un lotto = tre step verdi.** Dopo O3, O6 e O9 ci si ferma, si scrive il
    diario e si consegna.

---

## 5. Architettura target

### 5.1 Il modello di orientamento

| Domanda | Superficie | Cosa mostra |
|---|---|---|
| Dove sono | view switcher + riga di contesto | vista attiva, slot, pannello, dialogo (breadcrumb) |
| Su cosa lavoro | riga di contesto + status bar | dataset, forma visibile/totale, filtro, selezione, modello |
| Cosa è successo | status bar + annunci + notifiche | ultima azione, undo, errore, busy |
| Cosa posso fare | stati vuoti + Home Avvio + pannelli | passo successivo, "continua senza dati", chiusura, reset |

### 5.2 Verità sul filtro

`data_grid_plan()` resta la decisione sulle soglie (righe e celle) e continua
a leggere il dataset intero: il paging server-side è una proprietà del
dataset, non della vista. Accanto nasce un secondo helper, puramente
descrittivo:

- `data_view_state(state, frame)` → `visible_rows`, `total_rows`, `columns`,
  `filtered` (logico), `filter_label` (es. `x > 0` o intervallo date);
- `data_view_shape(state, frame)` → testo pronto (`12 di 5.000 × 5`), usato
  da `data_info`, status bar e riga di contesto;
- nessun nuovo stato: il filtro resta `input$data_filter_column` /
  `data_filter_value` / `data_filter_dates`.

### 5.3 Grammatica visiva dello stato

| Significato | Token | Icona | Testo | Dove |
|---|---|---|---|---|
| Sei qui | `--rcmdr-accent` | icona della vista | nome della vista | view tab, intestazione slot |
| Un limite vale | `--rcmdr-warning` | lucchetto / server | "Editing disabled", "Server-side paging" | chip di contesto |
| È fallito | `--rcmdr-danger` | triangolo | messaggio | status bar, notifica |
| È selezionato | `--rcmdr-selection` | — | conteggio | griglia, status bar |

Regole:

- `context_chip(icon, text, tone)` in `R/ui-components.R`: sfondo
  `surface-muted`, bordo 1 px, icona 14 px, testo sempre presente;
- le icone nuove (file, cartella, più, freccia, imbuto, lucchetto, server,
  undo) entrano in `rcmdr_icon_paths()`, SVG inline;
- nessun colore letterale: solo token, e le coppie testo/sfondo passano la
  matrice 8 × 2;
- il filtro usa la chip **neutra** con l'imbuto, non il giallo: il giallo
  significa "limite", non "vista filtrata".

### 5.4 Riga di contesto nelle viste

Una sola riga, sotto la view bar, costruita con `studio_breadcrumb()`:

```
Studio · Data Studio · [▦ D]  [⏷ filtro: x > 0 · 12 di 5.000]  [Rows]
```

- è testo statico, non un controllo (nessun tab stop in più);
- la chip del filtro è l'unica eccezione: se cliccabile, è un pulsante con
  nome accessibile che chiama `data_filter_clear`;
- le viste senza dataset mostrano `Studio · Chart Studio` e basta;
- nei dialoghi resta il breadcrumb attuale, invariato.

### 5.5 Gerarchia della status bar

Tre gruppi, separati da bordo, non da pipe:

1. **Identità**: dataset + forma visibile + chip filtro.
2. **Selezione**: righe/colonne/celle non vuote.
3. **Ultima azione**: undo o errore o busy (uno alla volta, il più recente).

Escono dalla barra: versione, numero comandi, passi di history, numero plot.
La versione va in **Help > About**; i conteggi nelle intestazioni di Console,
History e Plots. A 1280 px restano al massimo sei voci; sotto 992 px le voci
di priorità 3 si compattano in un solo elemento.

### 5.6 Intestazioni dei due slot

- `Primary · Data Studio` con bordo sinistro `accent`;
- `Secondary · Chart Studio` con bordo `border`;
- la differenza è **posizione + etichetta + bordo**, non due tinte;
- il nome è il `aria-label` della regione di focus già esistente;
- sotto 992 px l'intestazione si riduce al nome della vista.

### 5.7 Ritorno coerente

- `Esc` chiude **un** livello: menu aperto → dialogo → pannello modeless →
  selezione. Mai due insieme.
- **Reset layout** chiude il pannello modeless e ripristina la vista, senza
  toccare dati, history, log o undo.
- Il focus torna sempre al trigger; il modeless mantiene **Back to workspace**.
- Nessuna cronologia delle viste in questa onda: il view switcher basta.

### 5.8 Home in stato Avvio

Regola unica:

```
nessun dataset attivo e nessun progetto recente
        → Home "Avvio": quattro porte
altrimenti
        → Home normale (Continue, Recent, Projects, Checklist)
```

Le quattro porte:

1. **Importa un file** (CSV, Excel, SPSS, Stata, SAS, Minitab) → wizard
   esistente;
2. **Crea un data set vuoto** → dialogo `newDataSet` esistente;
3. **Apri un progetto** → lista progetti esistente;
4. **Continua senza dati** → Script/Console, con una riga che spiega che è
   possibile.

Niente modale a ogni avvio. Se in futuro si vorrà il pattern classico, sarà
una preferenza (`show_start`: `auto` / `always` / `never`), con `Esc` =
"continua senza dati", focus trap e variabile d'ambiente per i test.

### 5.9 Stati vuoti azionabili

Ogni stato vuoto dice cosa manca **e** qual è il passo successivo, con il
pulsante che esegue l'azione esistente:

| Vista | Stato vuoto | Azione |
|---|---|---|
| Data Studio | nessun dataset | Importa / Crea |
| Environment | nessun oggetto | Importa / Esegui comando |
| Plots | nessun grafico | Apri Chart Studio |
| Report | nessun documento | Nuovo documento |
| Console | nessun comando | Apri Script |
| Help | nessun risultato | Cancella ricerca |

---

## 6. Sequenza degli step

### Lotto 1 — Verità e contesto

#### O1 — Verità sul filtro

**Obiettivo:** un solo numero vero per la forma visibile.

**File:** `R/data-studio.R`, `R/app.R`,
`tests/testthat/test-data-studio-grid.R`, `inst/i18n/it.tsv`.

**Cosa cambia:** `data_view_state()` e `data_view_shape()`; `data_info` e
status bar mostrano "12 di 5.000 × 5"; chip filtro neutra; **Clear filter**
resta e annuncia l'effetto.

**Accettazione:** con filtro attivo nessuna superficie mostra il solo totale;
senza filtro il testo resta identico a oggi; il filtro non tocca dati né
comandi; test server e test puri.

**Commit:** `fix(ui): tell the truth about the filtered grid`

#### O2 — Grammatica visiva dello stato

**Obiettivo:** colore, icona e testo per ogni significato.

**File:** `R/ui-components.R`, `inst/www/css/20-components.css`,
`tests/testthat/test-accessibility.R`, `test-theme-matrix.R`,
`test-contrast.R`.

**Cosa cambia:** `context_chip()`; otto icone nuove inline; quattro
significati con token esistenti; nessun colore letterale.

**Accettazione:** ogni chip ha testo oltre al colore; ogni icona è decorativa
o nominata; le coppie passano la matrice 8 × 2; nessuna nuova dipendenza.

**Commit:** `feat(ui): add a visual grammar for state`

#### O3 — Riga di contesto nelle viste

**Obiettivo:** "dove sono" e "su cosa" in una riga.

**File:** `R/app.R`, `R/workspace.R`, `R/ui-components.R`,
`inst/www/css/10-shell.css`, `inst/www/css/60-views.css`, test.

**Cosa cambia:** breadcrumb generalizzato alle viste Studio; chip dataset,
filtro e modalità selezione; nessun tab stop in più.

**Accettazione:** ogni vista Studio ha la riga; nessun overflow a 640 px;
screen reader legge vista e dataset; Classica invariata.

**Commit:** `feat(ui): show the view context line`

**Handoff 1:** suite completa, diario, push, stop.

### Lotto 2 — Gerarchia e ritorno

#### O4 — Status bar a priorità

**Obiettivo:** sei fatti leggibili invece di dodici equivalenti.

**File:** `R/app.R`, `inst/www/css/10-shell.css`,
`tests/testthat/test-status-keyboard.R`, `test-desktop-chrome.R`.

**Cosa cambia:** tre gruppi (identità, selezione, ultima azione); versione in
**Help > About**; conteggi nelle viste; compattazione sotto 992 px.

**Accettazione:** a 1280 px ≤ 6 voci; nessuna informazione persa (tutte
raggiungibili altrove); `aria-live` invariato; zoom 200% senza overflow.

**Commit:** `refactor(ui): give the status bar a hierarchy`

#### O5 — Intestazioni dei due slot

**Obiettivo:** primario e secondario riconoscibili senza indovinare.

**File:** `R/app.R`, `R/workspace.R`, `inst/www/css/60-views.css`, test.

**Cosa cambia:** intestazione con ruolo e vista; bordo `accent`/`border`;
nome accessibile della regione.

**Accettazione:** con split attivo si legge quale slot è quale; `F6` continua
a funzionare; sotto 992 px resta il nome della vista.

**Commit:** `feat(ui): label the workspace slots`

#### O6 — Ritorno prevedibile

**Obiettivo:** `Esc` e reset fanno quello che l'utente si aspetta.

**File:** `inst/www/js/70-keyboard.js`, `R/preferences.R`, `R/app.R`,
`docs/upgrades/ACCESSIBILITY.md`, test.

**Cosa cambia:** regola unica per `Esc`; **Reset layout** chiude il modeless;
focus al trigger; nessun effetto su dati, undo e history.

**Accettazione:** un `Esc` = un livello; reset con pannello aperto lo chiude;
test di focus return; nessuna regressione sui menu.

**Commit:** `fix(ui): make returning from a panel predictable`

**Handoff 2:** suite completa, diario, push, stop.

### Lotto 3 — Avvio e chiusura

#### O7 — Home in stato Avvio

**Obiettivo:** il primo gesto è esplicito, senza mentire sul "dataset
obbligatorio".

**File:** `R/app.R`, `R/ui-components.R`, `inst/www/css/60-views.css`,
`inst/i18n/it.tsv`, test.

**Cosa cambia:** quattro porte; **New data set** in evidenza; "Continua senza
dati"; la Home normale resta quando c'è un dataset o un progetto recente.

**Accettazione:** con dataset attivo la Home non cambia; "Continua senza dati"
porta a Script/Console; nessuna modale; quattro azioni raggiungibili da
tastiera.

**Commit:** `feat(home): start from the data doors`

#### O8 — Stati vuoti azionabili e annunci

**Obiettivo:** nessun vicolo cieco.

**File:** `R/app.R`, `R/workspace.R`, `R/data-studio.R`, `R/i18n.R`
(stringhe), test.

**Cosa cambia:** ogni stato vuoto ha un'azione; filtro applicato/pulito
annunciato; errore persistente leggibile; nessun testo lungo in status bar.

**Accettazione:** le sei viste della tabella 5.9 hanno un'azione; annunci
`polite`; nessuna stringa esistente modificata.

**Commit:** `feat(ui): make every empty state actionable`

#### O9 — Chiusura

**Obiettivo:** consegnare.

**File:** `NEWS.md`, `DESCRIPTION` (3.1.0), `README.md`, topic About,
`CHECKLIST.md`, piano e diario.

**Cosa cambia:** versione 3.1.0; NEWS; README; topic; checklist; diario
`diary/wave-19-orientation.md`.

**Accettazione:** suite `EXIT=0`; `node --check`; app HTTP 200; push;
nessun comando o ID cambiato.

**Commit:** `docs: close wave 19`

**Handoff 3:** suite completa, diario finale, push, stop.

---

## 7. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| Riga di contesto duplica la status bar | più rumore | un fatto, un posto: contesto = vista+dataset+filtro; status = selezione+azione |
| Status bar compressa a zoom 200% | testo illeggibile | priorità e compattazione sotto 992 px; test a 640 px |
| Chip colorate incoerenti negli 8 temi | accessibilità | solo token; matrice 8 × 2 e contrasto in CI |
| Il filtro sembra un avviso | falsa semantica | chip neutra con imbuto; giallo riservato ai limiti |
| Home Avvio nasconde il lavoro in corso | regressione | regola esplicita: solo senza dataset e senza progetto recente |
| Test che assumono la Home attuale | suite rossa | casi separati per stato Avvio e stato normale |
| Reset layout troppo distruttivo | perdita di contesto | chiude solo il modeless; dati, undo e history intatti |
| Nessun browser | verifica visiva assente | test statici su markup, CSS e token; limite scritto nel diario |

---

## 8. Misure di successo

| Misura | Prima | Dopo |
|---|---|---|
| Numeri discordanti griglia/status con filtro | sì | 0 |
| Viste con riga di contesto | 0 | 8 |
| Voci visibili in status bar a 1280 px | 12 | ≤ 6 |
| Slot distinguibili senza focus | no | sì (etichetta + bordo) |
| `Esc` con regola unica | no | sì |
| Stati vuoti con azione | parziale | 6 su 6 |
| Primo gesto con dati disponibili | 1 clic + ricerca | 1 clic |
| Domande "dove sono?" nel test a 5 compiti | da misurare | ≤ 1 per sessione |
| Contrasto 8 × 2 | verde | verde |

Il test a cinque compiti (importa, riassumi, grafico, filtro, esporta) va
eseguito con almeno tre persone che usano SPSS/Minitab; si registrano tempo
per compito e numero di domande di orientamento. Senza browser funzionante
resta manuale, come per le onde 16–18.

---

## 9. Criteri di chiusura

- [ ] 9 step verdi, 3 handoff (O3, O6, O9).
- [ ] Forma visibile e totale coerenti in griglia, `data_info` e status bar.
- [ ] Riga di contesto in tutte le viste Studio; Classica invariata.
- [ ] Grammatica visiva con quattro significati, icone e test di contrasto.
- [ ] Status bar a priorità, senza informazioni perse.
- [ ] Slot etichettati; `F6` invariato.
- [ ] `Esc` a un livello; reset chiude il modeless.
- [ ] Home Avvio con quattro porte e "continua senza dati".
- [ ] Sei stati vuoti azionabili.
- [ ] Suite completa `EXIT=0`; `node --check`; app HTTP 200; push.
- [ ] Limite browser e verifica manuale scritti nel diario.

---

## 10. Protocollo di handoff

Come nelle onde 16–18:

1. tre step;
2. suite completa e `node --check`;
3. diario in `docs/upgrades/diary/wave-19-orientation.md`;
4. commit e push;
5. stop per compattare il contesto.

Ai gate O3, O6 e O9 il diario elenca cosa è chiuso, le deviazioni, i limiti e
il prossimo lotto.

---

## 11. Domande aperte

- [ ] La Home Avvio deve essere lo stato della Home o una modale una-tantum?
      (proposta: stato della Home, modale solo come preferenza futura)
- [ ] "Continua senza dati" è un'azione primaria o secondaria?
- [ ] Quali conteggi meritano di restare in status bar: nessuno, o solo i
      comandi?
- [ ] La chip del filtro deve essere cliccabile ovunque o solo in Data Studio?
- [ ] Le intestazioni degli slot servono anche senza split (per ricordare il
      ruolo della vista)?
- [ ] Serve una cronologia delle viste ("indietro") o il view switcher basta?
