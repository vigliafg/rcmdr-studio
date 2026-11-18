# Architecture Decision Records — RcmdrShiny Studio

Questo file registra le decisioni che vincolano l'implementazione. Ogni ADR
ha stato, contesto, decisione, conseguenze e alternative scartate.

---

## ADR-001 — Nuovo repository e baseline congelata

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

`rstats-commander` ha raggiunto la parità funzionale con R Commander. Il
progetto vuole evolvere oltre il “clone funzionale” senza perdere la base
stabile e verificabile.

### Decisione

- `rstats-commander` resta congelato come clone funzionale.
- `rcmdr-studio` parte da una copia esatta del codice tracciato di
  `rstats-commander`.
- Le nuove funzioni vivono solo in `rcmdr-studio`.
- Le correzioni critiche al motore possono essere portate indietro con un
  cherry-pick esplicito, non automatico.

### Conseguenze

- Storia git indipendente.
- Possibilità di divergere senza rompere il clone.
- La sincronizzazione upstream Rcmdr resta documentata in `UPSTREAM.md`.

### Alternative scartate

- Branch nello stesso repository: mescola due cicli di vita e rende il clone
  meno stabile.
- Fork GitHub con history condivisa: non isola davvero il progetto.

---

## ADR-002 — Nome prodotto e nome package

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

“RcmdrShiny” descrive un port di Rcmdr su Shiny e rafforza l'idea di clone.

### Decisione

- Nome prodotto/UI: **RcmdrShiny Studio**.
- Nome package: **`RcmdrShiny`**, invariato.
- Namespace, export, URL e installazione restano compatibili.
- README, DESCRIPTION, NEWS e UI usano il nuovo posizionamento; `NOTICE` e
  `UPSTREAM` conservano l'attribuzione a Rcmdr.

### Conseguenze

- Nessun costo di migrazione per gli utenti.
- Il rebranding è comunicativo e visivo, non tecnico.
- Un eventuale rename del package diventa una decisione separata e futura.

### Alternative scartate

- Rinominare il package subito: rompe installazioni, URL e test.
- Mantenere solo “RcmdrShiny”: non comunica la nuova identità.

---

## ADR-003 — Ordine di implementazione

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

Data, Charts e Report sono le aree richieste. Si possono parallelizzare, ma
condividono stato, shell e componenti.

### Decisione

1. Fondazioni (Onda 0).
2. Data Studio.
3. Chart Studio.
4. Report Studio.
5. Workbench.
6. Navigazione, dialoghi, workflow.
7. Help, i18n, onboarding.
8. Progetto, performance, Plugin SDK, QA.

### Conseguenze

- Il Chart Studio riusa il modello dati.
- Il Report Studio riusa la galleria grafici.
- Meno conflitti su `app.R` e sui componenti condivisi.

### Alternative scartate

- Charts per primo: richiede comunque il modello dati e la cronologia.
- Tutto in parallelo: rischio alto di incoerenza UX e merge conflict.

---

## ADR-004 — Compatibilità e modalità Classica

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

La parità funzionale è un asset. Una modernizzazione troppo aggressiva può
rompere flussi, test e aspettative.

### Decisione

- I comandi generati dai dialoghi esistenti restano identici.
- Le nuove funzioni sono opt-in o attivabili da feature flag.
- La modalità **Classica** mantiene layout, tab e flussi attuali.
- La modalità **Studio** è il default.
- La scelta è persistita in `localStorage` e nelle preferenze.

### Conseguenze

- Migrazione graduale.
- Rollback immediato.
- I test esistenti restano il contratto di non regressione.

### Alternative scartate

- Sostituire tutto in un colpo: rischio troppo alto.
- Nessun default nuovo: la modernizzazione non si vedrebbe.

---

## ADR-005 — Dipendenze

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

La libertà sui default e sui nuovi `Imports` è stata concessa, ma il package
deve restare installabile e verificabile.

### Decisione

- `Imports` solo per funzionalità core: `commonmark`, `yaml`, `bsicons`,
  `shinyjs`, `sortable`, `later`.
- `Suggests` per le estensioni: `svglite`, `styler`, `cicerone`,
  `colourpicker`; restano `plotly`, `rmarkdown`, `knitr`, `rgl`.
- Ogni nuova dipendenza deve avere un fallback o un beneficio netto.
- Niente framework UI alternativi o esecuzione in background fragile.

### Conseguenze

- Più affidabilità su Report Studio e shell.
- `R CMD check` leggermente più lungo.
- Le funzioni opzionali degradano senza errore.

### Alternative scartate

- Zero nuove dipendenze: costringe a reimplementare preview, icone e drag &
  drop in modo peggiore.
- Dipendenze pesanti (`shinyWidgets`, `reactable`, `future`): duplicano ciò che
  già esiste e aumentano la superficie di rischio.

---

## ADR-006 — Nessuna nuova procedura statistica

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

L'obiettivo è modernizzare l'esperienza, non allargare il catalogo statistico.

### Decisione

- Il catalogo resta quello di RcmdrShiny 1.13.0.
- Le nuove funzioni orchestrano, presentano, salvano e rendono riproducibili i
  comandi esistenti.
- Workflow guidati, preset, cronologia e template non aggiungono test, modelli
  o distribuzioni.

### Conseguenze

- Scope misurabile.
- Nessun carico di validazione statistica nuova.
- La qualità si concentra su UX, affidabilità e documentazione.

---

## ADR-007 — Cronologia parallela al log

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

`state$log` è un vettore di stringhe usato da script, report e test. Serve una
cronologia più ricca per rerun, modifica e inserimento nel report.

### Decisione

- `state$log` resta esattamente com'è.
- `state$history` è una lista di record strutturati:
  `id`, `time`, `source`, `command`, `dialog_id`, `dialog_memory`, `status`,
  `output`, `messages`, `plot_id`, `duration_ms`.
- `run_command()` alimenta entrambi.
- La UI usa `history`; il resto del motore continua a usare `log`.

### Conseguenze

- Nessuna rottura di compatibilità.
- Possibilità di rerun, edit e inserimento contestuale.
- Memoria aggiuntiva limitata da un cap configurabile.

### Alternative scartate

- Sostituire `state$log` con record: rompe test e API.
- Ricostruire la cronologia parsando il log: fragile.

---

## ADR-008 — Anteprime isolate

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

Chart Studio e Report Studio hanno bisogno di anteprime frequenti. Eseguire
codice nello stato della sessione può produrre effetti collaterali.

### Decisione

- `R/preview.R` valuta le anteprime in un ambiente figlio isolato.
- Le anteprime non chiamano `run_command()`, non aggiungono a `state$log`,
  `state$output` o `state$plots`.
- I device grafici e i file temporanei vengono chiusi e puliti.
- Le anteprime sono soggette a debounce e a un timeout.

### Conseguenze

- La UI può aggiornare l'anteprima senza inquinare la sessione.
- L'“Apply” resta l'unico punto in cui il comando viene eseguito e loggato.

### Alternative scartate

- Eseguire tutto in `.GlobalEnv`: effetto collaterale inevitabile.
- Usare `callr` per ogni preview: overhead e condivisione dati complessa.

---

## ADR-009 — Modalità Studio e Classica

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

La nuova information architecture riduce il numero di tab e unisce
Console/Output/Messages. Non tutti gli utenti possono volere questo cambio.

### Decisione

- `state$options$ui_mode`: `"studio"` (default) o `"classic"`.
- Studio: `Home | Data | Charts | Report | Script | Console | Environment | Help`.
- Classica: le attuali 8 tab, Output e Messages separati.
- La modalità è un'opzione persistita, non un build separato.

### Conseguenze

- Un solo codice, due layout.
- I test E2E coprono entrambe le modalità.
- Le funzioni nuove possono essere nascoste in Classica se non mature.

### Alternative scartate

- Due applicazioni separate: duplicazione e divergenza.
- Solo modalità Studio: perdita del contratto di compatibilità.

---

## ADR-010 — Progetto di sessione

**Stato:** accettata  
**Data:** 2026-11-13

### Contesto

La sessione Shiny è effimera. Dataset, script, report, plot e preset vanno
persi al riavvio.

### Decisione

- Formato `.rcmdrproj` basato su YAML, versionato.
- Contiene riferimenti a dataset (con opzione di includerli), dataset/modello
  attivo, documenti, metadati plot, preset, preferiti, preferenze e cronologia
  opzionale.
- Autosave e recovery separati dal file progetto principale.
- Export bundle ZIP con dati, plot e report.

### Conseguenze

- Sessione ripristinabile.
- Necessità di gestire path relativi, portabilità e sicurezza dei dati.
- La cronologia può essere esclusa per ridurre dimensione e rumore.

### Alternative scartate

- Salvare solo il workspace `.RData`: non cattura UI, preset e report.
- Salvarlo tutto in `.GlobalEnv`: non è un progetto.

---

## ADR-011 — Disponibilità dei comandi come fonte unica

**Stato:** accettata
**Data:** 2026-11-15

### Contesto

Lo stato `enabled`/`inactive`/`porting`/`hidden` era calcolato nel rendering,
mentre `launch()` usava una guardia separata che copriva solo tre comandi. I
percorsi alternativi (preferiti, recenti, cronologia) potevano quindi aprire
dialoghi non disponibili.

### Decisione

- `command_availability(state, command)` legge la riga di menu del comando e
  ritorna stato, motivo, path e condizioni.
- Rendering, `launch()`, cronologia e sezioni laterali usano la stessa fonte.
- Un comando senza riga di menu ricade su "implementato → enabled", così i
  comandi solo-palette non vengono bloccati.

### Conseguenze

- Un solo punto da modificare quando cambia la semantica dello stato.
- `command_enabled()` resta come wrapper deprecato per un rilascio.
- L'indice comando→riga è memorizzato in cache per versione del registry.

### Alternative scartate

- Duplicare la logica in ogni percorso: divergenza garantita.
- Bloccare `open_dialog()` globalmente: rompe i flussi contestuali del Data
  Studio già validati.

---

## ADR-012 — Caricamento plugin: isolamento e reload della pagina

**Stato:** accettata
**Data:** 2026-11-15

### Contesto

Un plugin mancante bloccava l'avvio dell'app e un plugin caricato a runtime
produceva menu vecchi ma palette nuova, con l'istruzione di riavviare R che
avrebbe eliminato il plugin.

### Decisione

- Ogni plugin viene caricato in un `tryCatch`; i fallimenti sono registrati in
  `plugin_failures()` e mostrati in health/diagnostics, senza interrompere gli
  altri plugin.
- I menu sono catturati per sessione: dopo un caricamento a runtime si chiede
  il reload della pagina; la palette vede subito i comandi nuovi.
- Il messaggio non suggerisce più di riavviare R.

### Conseguenze

- Avvio robusto anche con plugin rotti o disinstallati.
- Un plugin caricato a runtime non compare nel menubar fino al reload.
- Il retry di un plugin fallito è esplicito, non automatico.

### Alternative scartate

- Ricostruire observer e tree a runtime: costo e rischio elevati per un caso
  raro.
- Disabilitare silenziosamente i plugin rotti: il debito resterebbe invisibile.

---

## ADR-013 — Registro plugin globale, assunzione single-user

**Stato:** accettata
**Data:** 2026-11-15

### Contesto

`.plugin_registry` è un oggetto di processo, condiviso da tutte le sessioni
Shiny. Il progetto è locale e single-user, ma il comportamento va esplicitato.

### Decisione

- Il registro resta globale di processo.
- La selezione persistente dei plugin (Fase 2) è un default di avvio, non un
  isolamento per sessione.
- Un registry per-sessione è fuori perimetro e richiede un ADR dedicato.

### Conseguenze

- Caricare o scaricare plugin in una sessione cambia palette, help e comandi
  delle altre sessioni.
- I menubar delle sessioni già aperte restano quelli catturati all'avvio.

### Alternative scartate

- Registry per sessione: rompe cache globali e test, beneficio non dimostrato.

---

## ADR-014 — Nessun lazy reale e nessun registry plugin per-sessione

**Stato:** accettata
**Data:** 2026-11-15

### Contesto

L'audit dell'Onda 8 ha misurato il ciclo di vita dei plugin: 5,69 s per
caricare 16 plugin, 7,10 s per materializzare la coda differita al primo
catalogo, 0,71–1,48 s per costruire l'albero dei menu. Il registro
`.plugin_registry` è globale di processo e l'applicazione è locale,
single-user.

H8.13 chiedeva se valesse la pena implementare un caricamento davvero
on-demand (per gruppo di menu) e un registro per-sessione.

### Decisione

- **No al lazy reale per ora.** Il caricamento resta "differito al primo
  accesso al catalogo". L'opzione `RcmdrShiny.lazy_plugins` resta per
  compatibilità, ma la documentazione non promette caricamento su richiesta.
- **No al registry per-sessione.** Il registro resta globale di processo e
  l'assunzione single-user di ADR-013 resta valida.
- **Trigger di rivalutazione**, da verificare prima di riaprire la decisione:
  - requisito multiutente o più sessioni con selezioni diverse;
  - "startup shell" stabilmente sopra il budget di 3 s;
  - catalogo plugin abbastanza grande da rendere il caricamento eager
    percepibile (> 20 plugin o > 10 s);
  - necessità di scaricare un singolo plugin senza toccare gli altri.

### Conseguenze

- Il costo del caricamento resta concentrato all'avvio della sessione, non
  distribuito sulle azioni dell'utente.
- Un load/unload a runtime continua a influenzare le altre sessioni; i menu
  restano catturati per sessione e richiedono il reload della pagina.
- Health e diagnostics espongono fallimenti, conflitti e tempo di
  materializzazione, così il comportamento è osservabile.

### Alternative scartate

- **Lazy per gruppo di menu**: richiede menu e predicati disponibili senza
  caricare il namespace del plugin, quindi separare contributo statico e
  dinamico; impatto alto su registry, cache e attivazione, beneficio non
  dimostrato dalle misure.
- **Registry per-sessione**: rompe cache globali, help condiviso ed estensioni
  (preset, workflow, chart type) e non è giustificato dal posizionamento
  single-user.

### Verifica

- Baseline 2.1.0: suite 3401 pass; benchmark plugin entro budget (load 1
  plugin 831 ms, tree caldo 100 ms).
- Le misure e le prove sono in
  [`audit-menu-plugin.md`](audit-menu-plugin.md).

---

## ADR-015 — ggplot2 e plotly come dipendenze obbligatorie

**Stato:** accettata
**Data:** 2026-11-15

### Contesto

`ggplot2` e `plotly` erano in `Suggests`: l'engine ggplot2 e l'interattività
dipendevano da un'installazione separata, con documentazione condizionale e
funzionalità che cambiavano da macchina a macchina. L'installazione standard
non li installava.

### Decisione

- Spostare `ggplot2` e `plotly` in `Imports`.
- Accettare il costo di dipendenze obbligatorie e transitive.
- Mantenere il probe `ggplotly_available()`: l'installazione garantisce i
  pacchetti, non la compatibilità delle versioni.

### Conseguenze

- `install.packages("RcmdrShiny")` installa automaticamente i due pacchetti.
- L'engine ggplot2 è sempre disponibile; plotly e HTML export sono sempre
  offerti quando il tipo ha un'espressione interattiva.
- `R CMD check` richiede entrambi i pacchetti; il peso dell'installazione
  aumenta.
- `svglite`, `htmlwidgets`, `rgl` e i pacchetti di report restano in
  `Suggests`.

### Alternative scartate

- Istruzioni di installazione manuale o prompt in `start.sh`: non è
  un'installazione automatica.
- `configure`/`.onLoad` che installano pacchetti: vietato dalle policy e non
  riproducibile.
- Meta-pacchetto: garantisce l'installazione ma aggiunge un artefatto da
  mantenere.

---

## ADR-016 — bslib e shinyWidgets nel vocabolario UI

**Stato:** accettata  
**Data:** 2026-11-18  
**Sostituisce in parte:** ADR-005 (dipendenze), limitatamente al rifiuto di
`shinyWidgets`. L'elenco di ADR-005 riflette il 2026-11-13 e non va letto come
stato corrente di `DESCRIPTION`.

### Contesto

L'Onda 15 ha costruito un CSS e un set di componenti propri. Il prezzo è che
ogni comportamento nuovo (pannelli richiudibili, switch, picker) andrebbe
scritto e mantenuto a mano, compresi ARIA, stato e tastiera. Il Chart Builder
e i dialoghi densi mostrano il limite: decine di controlli in una colonna,
senza una gerarchia richiudibile. `bslib` è già un `Imports` e fornisce
Bootstrap 5; `shinyWidgets` colma tre lacune reali (picker ricercabile, slider,
color picker). ADR-005 lo escludeva in blocco come “duplicato di ciò che già
esiste”: la valutazione resta valida per la maggior parte dei suoi widget, non
per questi tre.

### Decisione

- **bslib** si usa per i componenti strutturali che non vogliamo mantenere:
  `accordion()`/`accordion_panel()` e, solo se ID e test restano identici,
  `input_switch()`. Non si adottano `card()`, `navset_*()` o
  `layout_columns()`: duplicherebbero la shell e le griglie esistenti.
- **shinyWidgets** entra in `Imports` con una versione minima verificata.
  Si adottano **solo**:
  - `virtualSelectInput()` oppure `pickerInput()` — uno solo, scelto in S3 —
    per gli elenchi lunghi e la selezione multipla;
  - `noUiSliderInput()` per i numeri limitati;
  - `spectrumInput()` per i colori.
  Gli altri widget (switch, radio/checkbox decorati, dropdown, date picker)
  restano fuori finché non c'è un caso d'uso e un test.
- Le famiglie di campi, checkbox, radio, switch e listbox hanno una specifica
  desktop comune (altezze, bordo 1 px, raggio, elevazione, hover, focus,
  disabled, invalid) e una galleria di sviluppo (`tools/widget_gallery.R`) che
  le mostra in tutte le 8 palette × 2 densità. La specifica è parte della
  decisione, non un dettaglio di stile.
- Ogni widget esterno passa da un wrapper in `R/widgets.R`
  (`picker_input()`, `slider_input()`, `color_input()`): i dialoghi non
  chiamano la libreria.
- Un solo punto di tematizzazione: `15-bootstrap.css` per le variabili
  `--bs-*` e `55-shinywidgets.css` per le classi dei widget. Nessun colore
  letterale; si usano i token dell'Onda 15.
- La matrice 8 temi × 2 densità e i test di accessibilità si estendono ai
  nuovi componenti: senza questo, la dipendenza non è accettata.

### Conseguenze

- Meno codice nostro da mantenere per accordion e switch.
- Una dipendenza in più da installare, con peso CSS/JS da misurare.
- I widget esterni possono divergere da Bootstrap 5: l'inventario del primo
  step è un gate, non una formalità.
- I dialoghi sono condivisi tra Studio e Classica: l'accordion cambia anche
  l'aspetto dei dialoghi in modalità Classica, mentre le tab e i `data-value`
  restano identici.
- La documentazione dei token deve dire chi possiede ogni componente.

### Alternative scartate

- **Scrivere l'accordion in casa**: sarebbe un secondo sistema di collapse,
  con ARIA, stato e animazioni da mantenere; bslib è già installato.
- **Adottare shinyWidgets in blocco**: introdurrebbe switch, segmented e
  checkbox decorati in concorrenza con i nostri helper, cioè tre linguaggi
  visivi.
- **shiny.fluent / shiny.semantic / shinydashboard**: framework UI completi,
  incompatibili con la shell e i token esistenti.
- **reactable al posto di DT**: sostituzione di un widget integrato con
  selezione, filtri e test, non un restyling.

---

## ADR-018 — Workspace a due slot, menu-first e undo applicativo

**Stato:** proposta per l'Onda 18  
**Data:** 2026-11-18  
**Dipende da:** ADR-016 (widget), Onda 17 (split, menu contestuali, viste
pigre), T13 (editor legato al dataset)

### Contesto

L'Onda 17 ha dato all'app il comportamento desktop: split, menu contestuali,
drag-and-drop, palette, notifiche, viste pigre. Restano tre distanze dal
modello desktop:

1. la navigazione è ancora a tre livelli (topbar, sidebar menu, tab
   principali);
2. il workspace è una vista alla volta; non si possono affiancare Data e
   Chart;
3. manca un undo applicativo: `Ctrl+Z` vive solo negli editor di testo.

Aggiungere un altro widget non risolve nessuna delle tre. Serve una decisione
di architettura, non un restyling.

### Decisione

- **Menu-first in Studio.** Una menu bar `role="menubar"` è la navigazione
  principale; la sidebar diventa un drawer opzionale. Tema, lingua e densità
  passano in View/Options. La modalità Classica mantiene il suo `tabsetPanel`
  e i suoi `data-value`.
- **Workspace a due slot, non MDI.** Primario e secondario possono mostrare
  due viste diverse; la stessa vista non può essere duplicata. Il separatore
  usa `split_pane()` e la geometria è versionata. Non si adotta un framework
  di docking né si promettono finestre flottanti libere.
- **Undo applicativo limitato a dati e galleria.** Lo stack salva snapshot
  prima/dopo con un tetto di voci e byte. Navigazione, tema, lingua, dialoghi e
  testo restano fuori: il testo è di Ace, i dialoghi non sono stato del lavoro.
  L'undo non riesegue comandi; rimette lo snapshot e invalida le viste.
- **La selezione a intervallo è un modo esplicito.** La griglia DT passa da
  “Rows” a “Cells” con un controllo; in Cells si copia TSV. La selezione riga
  resta il default per non rompere l'inspector.
- **La densità desktop è chrome, non una terza densità.** Cambiano topbar,
  menu, toolbar, raggi e superfici in Studio; la matrice resta 8 temi × 2
  densità. Classica non è toccata.
- **Nessuna dipendenza nuova.** Workspace, undo, selezione e geometria si
  costruiscono con CSS/JS nostri e con gli helper esistenti. Un motore di
  tabelle diverso resta un gate separato (T7/T13).

### Conseguenze

- La shell cambia in modo visibile, ma comandi, ID, `dialog_spec()` e i18n
  restano invariati.
- Gli output Shiny hanno un solo id: due slot richiedono un registro delle
  viste e il divieto di duplicarle.
- Lo stack di undo consuma memoria: va limitato e svuotato al caricamento di
  un progetto.
- La menu bar deve gestire `Alt`, `F10`, frecce, `Esc` e focus return; non è
  solo markup.
- La verifica visiva resta condizionata dal browser: senza Chrome funzionante
  il gate S11 scrive il limite, non finge una copertura.

### Alternative scartate

- **Electron/Tauri subito**: aggiunge file dialog e finestre native, ma non
  risolve menu, workspace, undo o densità; è un'onda separata.
- **Docking libero tipo VS Code**: richiede pannelli flottanti, focus
  manager, serializzazione e test che non abbiamo; due slot coprono il caso
  reale.
- **Undo a inversione di comandi**: non tutti i comandi R sono invertibili;
  lo snapshot è più onesto e più semplice.
- **Terza densità “desktop”**: triplica la matrice e confonde la scelta;
  la chrome si corregge una volta per Studio.
- **`reactable`/`rtabulator` per il workspace**: il problema è la shell, non
  la tabella.

---

## ADR-019 — Orientamento: verità, contesto e grammatica visiva

**Stato:** proposta per l'Onda 19  
**Data:** 2026-11-18  
**Dipende da:** ADR-016 (token e widget), ADR-018 (workspace, status bar,
geometria), Onda 18 (dati grandi)

### Contesto

L'Onda 18 ha chiuso lo spazio desktop, ma non ha chiuso l'orientamento. Il
caso misurato è netto: con un filtro attivo la griglia mostra 12 righe mentre
la status bar e `data_info` leggono `dataset(state)` e continuano a dire
"5.000 × 5". Due numeri veri e incompatibili nella stessa schermata.

Accanto a questo difetto ci sono tre assenze:

1. le viste principali non hanno una riga di contesto (il breadcrumb esiste
   solo nei dialoghi e nei workflow);
2. i due slot non sono etichettati: senza anello di focus sembrano due
   sessioni;
3. la status bar elenca dodici fatti con lo stesso peso, illeggibili a zoom
   200%.

Aggiungere una welcome window risolverebbe solo il primo gesto e lascerebbe
gli altri tre. L'orientamento è un problema di superficie, non di schermata.

### Decisione

- **Modello a quattro domande.** Dove sono, su cosa lavoro, cosa è successo,
  cosa posso fare. Ogni superficie nuova deve rispondere ad almeno le prime
  due; nessuna dashboard globale.
- **La forma mostrata è quella visibile.** `data_view_state()` descrive la
  vista (righe visibili, totale, filtro); `data_grid_plan()` resta la
  decisione sulle soglie e legge il dataset intero. Con filtro, il numero
  visibile è primo e il totale è un'aggiunta ("12 di 5.000 × 5").
- **Il filtro è vista, non dato.** Non colora le righe, non è un avviso, non
  entra nel comando; usa una chip neutra con imbuto. Il giallo resta riservato
  ai limiti (editor disattivato, paging server-side).
- **Colore ridondante, quattro significati.** `accent` = sei qui; `warning` =
  un limite vale; `danger` = è fallito; `selection` = selezionato. Ogni
  significato è colore **+ icona + testo**; nessun colore letterale e nessuna
  informazione affidata al solo colore. Le coppie passano la matrice 8 × 2.
- **Status bar a priorità.** Tre gruppi: identità (dataset, forma, filtro),
  selezione, ultima azione. Versione e conteggi (comandi, history, plot)
  escono dalla barra e vivono nelle loro viste. A 1280 px restano al massimo
  sei voci.
- **Home Avvio, non welcome modale.** Quando non c'è dataset e non c'è
  progetto recente, la Home mostra quattro porte: importa, crea, apri
  progetto, continua senza dati. Nessuna modale a ogni avvio; l'eventuale
  `show_start` (`auto`/`always`/`never`) è una preferenza futura.
- **Ritorno a un livello.** `Esc` chiude un solo livello (menu → dialogo →
  pannello → selezione); **Reset layout** chiude anche il modeless, senza
  toccare dati, undo e history.

### Conseguenze

- Due helper descrittivi nuovi (`data_view_state()`, `data_view_shape()`) e
  nessun nuovo stato: il filtro resta negli input esistenti.
- `context_chip()` e otto icone inline entrano nel vocabolario; nessuna
  dipendenza.
- I test devono coprire tre casi: filtro attivo, filtro assente, dataset
  assente.
- La status bar perde la versione: va in **Help > About**, dove è già il
  posto naturale.
- La resa visiva resta non verificabile senza browser; il limite va scritto,
  non aggirato.

### Alternative scartate

- **Welcome modale a ogni avvio**: l'app è una sessione con più dataset e
  progetti, non un file per avvio; la modale diventerebbe un ostacolo.
- **Dashboard di stato**: una schermata in più non risolve l'ambiguità dei
  numeri; la risolve il numero corretto.
- **Un colore per dataset o per vista**: rompe 8 temi e daltonismo, e crea
  semantica falsa ("il rosso è il dataset sbagliato?").
- **Icone da sole nella navigazione**: peggiori per l'utente classico e per
  lo screen reader.
- **Cronologia delle viste**: aggiunge un concetto e un comando; il view
  switcher copre il caso reale.
