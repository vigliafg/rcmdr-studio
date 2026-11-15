# Audit — debito del menu e ciclo di vita dei plugin

**Data:** 2026-11-15
**Baseline:** RcmdrShiny 2.1.0
**Metodo:** lettura del codice, misure su R 4.5.2, test mirati con `testServer`
**Ambito:** due audit richiesti prima del piano Onda 8. Le correzioni sono
tracciate nei commit `0735a2f` (2.0.2) e `4538bd8` (2.1.0).

---

## Parte A — Menu in stato di debito

### A.1 Stati e resa

`command_status()` (`R/activation.R:304`) assegna a ogni voce uno di quattro
stati:

| Stato | Condizione | Resa |
|---|---|---|
| `enabled` | implementato e `activation` vera | `<a class="rcmdr-menu-item">` |
| `inactive` | `activation` falsa (dataset, variabili, modello) | `<span class="disabled">` |
| `porting` | comando non implementato | `<span class="disabled">` |
| `hidden` | `install` falsa (pacchetto/capability) | omesso dal DOM |

Con nessun dataset attivo, sulle 288 voci del core:

| Gruppo | enabled | inactive | porting | hidden |
|---|---|---|---|---|
| Analyze | 79 | 74 | 0 | 1 |
| Data | 9 | 18 | 0 | 0 |
| Edit | 0 | 0 | 9 | 0 |
| File | 24 | 1 | 3 | 0 |
| Graphs | 1 | 21 | 1 | 1 |
| Help | 16 | 1 | 0 | 1 |
| Reports | 9 | 0 | 0 | 0 |
| Transform | 0 | 12 | 0 | 0 |
| Utilities | 5 | 0 | 0 | 2 |
| **Totale** | **143** | **127** | **13** | **5** |

Casi limite verificati:

- **Edit** si apre con 9 voci, tutte `porting`.
- **Transform** e **Analyze** sono prevalentemente o interamente grigi senza
  dataset.
- Nessuno dei 57 gruppi resta vuoto dopo il filtro `hidden`.
- Le voci `hidden` misurate: `CFA` (`sem`), `stemAndLeaf` (`aplpack`), `appNap`,
  `installSoftware`, `browseEnglishManual`.

### A.2 Percorsi alternativi

Il rendering era l'unica vera barriera. Prima di 2.0.2:

| Percorso | Controllo di stato | Esito |
|---|---|---|
| Menubar | `command_status` per voce | corretto |
| Ricerca sidebar | `command_status` | corretto ma solo tooltip |
| Palette | `command_status` + `aria-disabled` + click bloccato | corretto e spiegato |
| Preferiti/Recenti | **nessuno** | link attivi anche per `porting`/`hidden` |
| Cronologia (riapri dialogo) | **nessuno** | dialogo riaperto senza dataset |
| `launch()` | `command_enabled()` con 3 casi speciali | copertura 3/288 |

Prove eseguite:

- Preferiti con `saveDataSet`, `CFA`, `onCopy`, `numericalSummaries` e nessun
  dataset: **4 link attivi su 4**.
- `testServer` con `menu_command = "oneWayAnova"` e nessun dataset: il dialogo
  ANOVA si apriva (1355 caratteri di UI), pur essendo la voce `inactive`.
- `saveDataSet` da preferito: `command_enabled` vero, comando diretto
  `download_dataset_rdata`, `req(name)` fallisce in silenzio senza dataset.
- `CFA` con `sem` assente: link presente e dialogo apribile nonostante
  `install` falsa.
- `onCopy` (`porting`): la guardia scattava prima del ramo "not ported" e
  mostrava il messaggio sbagliato ("not available for the current data set").

### A.3 Difetti e correzioni

| ID | Difetto | Correzione | Commit |
|---|---|---|---|
| M1 | Preferiti/Recenti ignorano lo stato | `menu_sections_ui()` usa `command_status`; disabilitati con motivo, `hidden` omessi, stelle conservate | `0735a2f` |
| M2 | `command_enabled()` copre 3 comandi | `command_availability()` unica fonte; wrapper deprecato | `0735a2f` |
| M3 | Click su voce grigia chiude il menu | il listener ignora `.rcmdr-menu-item.disabled` | `0735a2f` |
| M4 | Voce grigia non focalizzabile e senza motivo accessibile | `aria-disabled`, `tabindex="0"`, motivo `visually-hidden` + `title` | `0735a2f` |
| M5 | Cronologia senza controllo | `history_open_dialog()` verifica la disponibilità | `0735a2f` |
| M6 | Messaggio unico per `porting`/`inactive` | `command_status_message()` distingue i tre casi | `0735a2f` |

### A.4 Cosa resta

- Un hint di gruppo quando tutte le voci sono grigie (Edit/Transform).
- Pulizia guidata dei preferiti che puntano a comandi `hidden`.
- Stringhe del debito non tradotte in `inst/i18n/it.tsv` (fallback inglese).

---

## Parte B — Ciclo di vita dei plugin

### B.1 Selezione e caricamento

| Via | Cosa accetta | Momento |
|---|---|---|
| `run(plugins = ...)` / `app(plugins = ...)` | pacchetti, script, liste inline | prima di `shinyApp()` |
| `Utilities > Manage Rcmdr plug-ins...` | pacchetti installati + script | runtime |
| Preferenze (`plugins`) | pacchetti e script | all'avvio, da 2.1.0 |

Prima di 2.1.0 non esistevano scoperta dei pacchetti installati né persistenza.
Il registro è globale di processo (`.plugin_registry`, `R/plugins.R:15`).

### B.2 Misure

Macchina di sviluppo, R 4.5.2, 16 pacchetti plugin installati (15 first-party +
`Demo`):

| Scenario | Tempo |
|---|---|
| Load eager di 16 plugin | **5,69 s** (aRnova 3,57 s; EZR 0,77 s) |
| `menu_tree()` a freddo dopo il load | 1,48 s |
| `menu_tree()` caldo | 0,71 s |
| `load_plugins(lazy = TRUE)` | 0,000 s |
| Primo `menu_tree()` dopo il lazy | **7,10 s**, coda svuotata |
| Benchmark 2.1.0: load 1 plugin | 831 ms |
| Benchmark 2.1.0: menu tree caldo (1 plugin) | 100 ms |

Conclusione: il "lazy" differisce il lavoro al primo accesso al catalogo, che
nel server avviene subito; non è caricamento per plugin su richiesta.

### B.3 Caricamento a runtime

Prima di 2.0.2 il dialogo diceva "restart RcmdrShiny" e il server catturava
`tree`/`leaves` una volta per sessione (`R/app.R:1515`). Risultato:

- menu e ricerca sidebar restavano vecchi;
- la palette vedeva subito i comandi nuovi (indice invalidato dalla versione);
- riavviare R **rimuoveva** il plugin, quindi l'istruzione portava all'azione
  sbagliata.

Da 2.0.2 il messaggio chiede il reload della pagina (F5), che crea una nuova
sessione e ricostruisce i menu; il registro resta nel processo R.

### B.4 Errori e conflitti

| Comportamento (pre-2.0.2) | Evidenza | Correzione |
|---|---|---|
| Plugin mancante blocca l'avvio | `Package 'X' is not installed.` da `app()` | `0735a2f`: `tryCatch` per plugin, `plugin_failures()` |
| Errore al plugin N lascia caricati 1..N-1 | verificato con `load_plugins(list(A, B_rotto))` | accettato e registrato |
| Coda lazy svuotata prima del successo | errore = coda persa | coda processata voce per voce, esiti registrati |
| Conflitti tra plugin solo `warning()` | override UCA su `randomnessFTest`, `randomnessNTest` | `4538bd8`: `plugin_conflicts()` in health/diagnostics/notifica |
| Riregistrazione stesso nome silenziosa | il vecchio comando sparisce | documentato; da valutare |

### B.5 Difetti e stato

| ID | Difetto | Stato |
|---|---|---|
| P1 | Lazy non riduce il lavoro | documentato e misurato (2.1.0); ADR-014: no-go al lazy reale |
| P2 | Plugin rotto blocca l'avvio | risolto (2.0.2) |
| P3 | Runtime load incoerente | risolto a livello di messaggio/documentazione; i menu restano per-sessione |
| P4 | Nessuna selezione/persistenza/scoperta | risolto (2.1.0) |
| P5 | Conflitti silenziosi | risolto (2.1.0) |
| P6 | Costo fuori dai budget | coperto da 4 scenari benchmark (2.1.0) |
| P7 | Registro globale condiviso | ADR-013: assunzione single-user; ADR-014: no-go al registry per-sessione |

### B.6 Cosa resta

- Pulsante "Reload now" nella notifica del manager (con conferma).
- Versione e stato per plugin installato, non solo il nome.
- Cache di `installed.packages()` (oggi ricalcolato a ogni apertura).
- Scaricare un singolo plugin senza `unload_plugins()` globale.
- Copertura E2E del Plugin Manager (aggiunta in `test-plugin-manager-e2e.R`,
  gated da `RCMDRSHINY_E2E=1`).

---

## Riproduzione delle misure

```bash
# stati del menu senza dataset
Rscript -e 'pkgload::load_all(quiet=TRUE); s<-AppState(new.env()); l<-menu_leaves(menu_tree()); print(table(vapply(l$command,function(c) command_availability(s,c)$status, character(1))))'

# lazy: coda e materializzazione
Rscript -e 'pkgload::load_all(quiet=TRUE); options(RcmdrShiny.lazy_plugins=TRUE); load_plugins(as.list(installed_plugin_packages())); print(length(plugins_pending())); system.time(menu_tree())'

# benchmark plugin
Rscript tests/benchmarks/benchmark.R --quick
```

I numeri dipendono dalla macchina e dai pacchetti plugin installati; i budget
di riferimento sono in `R/benchmark.R` (`benchmark_budgets()`).

---

## Parte C — Mapping UI → comando e workflow

### C.1 Metodo

- **Contract sweep** su tutti i 235 dialoghi: rendering della UI con uno stato
  ricco (dataset con numeriche, fattore, carattere; modello `lm` attivo),
  estrazione degli input renderizzati, costruzione di un input realistico e
  chiamata a `on_ok()`.
- Verifica che il risultato sia una lista ben formata: `commands` carattere
  senza `NA`, `memory` lista, `error` non vuoto quando presente.
- Verifica delle chiavi di memoria usate dai workflow contro gli id resi dal
  dialogo.
- Test espliciti di mapping per i dialoghi più usati.

### C.2 Risultati

- **235/235** dialoghi renderizzano e `on_ok()` non lancia eccezioni con input
  sintetico.
- **0** risultati vuoti o malformati.
- **Tutti** gli step di workflow con dialogo hanno chiavi di memoria consumate
  (l’unico alias noto è `linearModel`: `model_name` → input `linearModel_model`).
- **1 difetto reale trovato e corretto**: il dialogo delle correlazioni passava
  `"Spearman"` a `cmd_correlation_matrix()`, che confrontava con `"spearman"`;
  il comando generato era `cor(..., use=...)` **senza** `method="spearman"`.
  Corretto normalizzando `tolower(type)` nel builder e coperto da test.

### C.3 Copertura

| Prima | Dopo |
|---|---|
| 38/235 dialoghi referenziati esplicitamente nei test | 235/235 passano il contract sweep |
| 20 file di test chiamano `on_ok` | + mapping esplicito per istogramma, bar graph, scatterplot, correlazioni, export |
| Nessuna traccia del dialogo che ha completato uno step | `workflow_step_trace()` registra dialogo e comandi per step |
| Chiavi di memoria sconosciute ignorate in silenzio | `RcmdrShiny.strict_memory=TRUE` avvisa; test dedicato |

### C.4 Limite residuo

Il contract sweep dimostra che UI e `on_ok` sono **coerenti strutturalmente**
(nessun input rotto, nessun crash), non che ogni singola opzione produca
l’argomento giusto. Quello resta coperto dai test di mapping per dialogo; il
sweep non sostituisce la semantica.
