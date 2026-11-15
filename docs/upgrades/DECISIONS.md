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
