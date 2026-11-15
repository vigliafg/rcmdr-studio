# Onda 8 — Hardening menu e ciclo di vita dei plugin

**Data:** 2026-11-15
**Stato:** Fase 1 completata (2.0.2); Fasi 2–3 pianificate
**Baseline:** RcmdrShiny 2.0.2
**Ondate precedenti:** 0–7, tutte chiuse
**Diario di riferimento:** [`diary/wave-07-platform.md`](diary/wave-07-platform.md)
**Checklist:** [`CHECKLIST.md`](CHECKLIST.md)

---

## 1. Contesto

Due audit sul codice hanno isolato due famiglie di debito che non sono
regressioni di una singola funzione ma **incoerenze trasversali**:

1. **Debito del menu**: lo stato di una voce (`enabled`, `inactive`, `porting`,
   `hidden`) è calcolato in modo affidabile solo al momento del rendering del
   menubar. I percorsi alternativi (preferiti, recenti, cronologia) lo ignorano,
   e la guardia server `command_enabled()` copre tre comandi su 288.
2. **Ciclo di vita dei plugin**: il caricamento è eager e globale; la modalità
   "lazy" viene drenata al primo accesso al catalogo; un plugin rotto impedisce
   l'avvio; il caricamento a runtime produce uno stato incoerente (menu vecchi,
   palette nuova) e un messaggio che suggerisce l'azione sbagliata.

Nessuno dei due blocchi richiede una riscrittura del motore. Entrambi si
risolvono con guardie uniche, qualche filtro di rendering, isolamento degli
errori e persistenza delle preferenze.

---

## 2. Diagnosi sintetica

### 2.1 Menu in stato di debito

Misure con nessun dataset attivo (288 voci, 57 gruppi):

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

Problemi verificati:

| ID | Problema | Evidenza |
|---|---|---|
| M1 | Preferiti/Recenti ignorano `inactive`, `porting` e `hidden` | `R/menus.R:595-627`; 4/4 link attivi nel test |
| M2 | `command_enabled()` non consulta `activation`; copre 3 comandi | `R/dialogs.R:494-506`; ANOVA apre il dialogo senza dataset |
| M3 | Click su voce grigia chiude tutto il menubar | `R/app.R:851-858` + `R/menus.R:397` |
| M4 | Voce grigia non focalizzabile, senza `aria-disabled` né motivo testuale | `R/menus.R:389-401` |
| M5 | Riapri dialogo da cronologia senza controllo di stato | `R/history.R:267-287` |
| M6 | Messaggio unico per `porting` e `inactive` in `launch()` | `R/app.R:1690-1703` |

### 2.2 Ciclo di vita dei plugin

| ID | Problema | Evidenza |
|---|---|---|
| P1 | Lazy drenato al primo `menu_tree()` (di fatto eager) | 0,000 s → 7,10 s; `R/menu-registry.R:458` |
| P2 | Plugin mancante/rotto blocca l'avvio; coda persa su errore | `R/plugins.R:322-325, 413-437` |
| P3 | Runtime load: menu e ricerca vecchi, palette nuova, messaggio "restart" errato | `R/app.R:1515, 1725-1731`; `R/plugins.R:585` |
| P4 | Nessuna selezione, scoperta o persistenza dei plugin | `R/preferences.R:46-56`; `R/health.R:28-30` |
| P5 | Conflitti tra plugin solo `warning()` | `R/plugins.R:198-203`; override UCA osservato |
| P6 | Costo plugin fuori dai budget | 5,69 s per 16 plugin; tree 0,7–1,5 s per sessione |
| P7 | Registro globale di processo, condiviso tra sessioni | `R/plugins.R:15-17` |

---

### 2.3 Stato di implementazione

| Fase | Contenuto | Stato | Rilascio |
|---|---|---|---|
| 1 | H8.1–H8.7: disponibilità, guardie, preferiti, accessibilità, errori plugin, messaggio reload | **completata 2026-11-15** | 2.0.2 |
| 2 | H8.8–H8.12: persistenza e Plugin Manager, conflitti, lazy documentato, benchmark | pianificata | 2.1.0 |
| 3 | H8.13: valutazione lazy reale / registry per-sessione | da valutare | — |

Il punto di ripresa per la Fase 2 è in
[`diary/wave-08-hardening.md`](diary/wave-08-hardening.md), sezione 0.

---

## 3. Obiettivi e non obiettivi

### Obiettivi

- Una **sola fonte di verità** per la disponibilità di un comando, usata da
  rendering e da tutte le guardie server.
- Nessun percorso utente può aprire un dialogo o eseguire un comando
  dichiarato non disponibile, senza spiegazione.
- Il debito è **visibile e spiegato** in modo coerente in menubar, ricerca,
  preferiti, recenti, palette.
- Un plugin rotto **non impedisce l'avvio**, viene registrato come fallimento e
  diagnosticato.
- Scelta dei plugin **persistente** e gestibile da UI, con scoperta dei
  pacchetti installati.
- Semantica del caricamento differito **documentata e misurata**, non
  pubblicizzata in modo errato.

### Non obiettivi

- Nessuna nuova funzione statistica o comando.
- Nessuna modifica a `menu_id`, `item_id`, `command_id`, `core.yml`, formati
  dei progetti o API pubbliche esistenti.
- Nessun multiutente, autenticazione o isolamento multi-tenant.
- Nessuna riscrittura del motore dei menu o del registry.
- Nessuna esecuzione di dialoghi Tk legacy.

---

## 4. Decisioni di design

| ID | Decisione | Motivo |
|---|---|---|
| D1 | `command_availability(state, command)` è l'unica API interna per lo stato, e ritorna `status` + `reason` + `source` | Evita di duplicare la logica in rendering, `launch()`, cronologia e plugin |
| D2 | La disponibilità si calcola dalla riga di menu del comando, con **fallback** "implementato → enabled" quando il comando non ha una voce | I comandi plugin-only e gli alias non devono essere bloccati per errore |
| D3 | I preferiti restano memorizzati anche se non disponibili; la sezione li mostra disabilitati (o li omette se `hidden`) | Non si cancellano dati dell'utente; la UI resta coerente col menubar |
| D4 | Il caricamento a runtime **non** ricostruisce il tree della sessione: si chiede un reload della pagina. Il messaggio non parla più di riavvio di R | Ricaricare la pagina crea una nuova sessione e registra gli observer; riavviare R perde il plugin |
| D5 | I plugin salvati nelle preferenze sono un **default**, l'argomento esplicito di `run()`/`app()` vince; un plugin non installato viene registrato come fallimento e ignorato | Avvio robusto e comportamento prevedibile |
| D6 | Il registro plugin resta **globale di processo**; l'assunzione single-user diventa un ADR esplicito | Coerente con il posizionamento "locale e single-user" del progetto |
| D7 | Il lazy resta "differito al primo catalogo", documentato e misurato; il vero on-demand è una valutazione separata | Il redesign richiede predicati e menu già registrati; rischio alto, beneficio non dimostrato |

Le decisioni D4–D7 diventano ADR in [`DECISIONS.md`](DECISIONS.md) durante
l'implementazione (ADR-0xx).

---

## 5. Fase 1 — correzioni (rilascio 2.0.2, patch)

### H8.1 — `command_availability()` come fonte unica

**Problema:** stato calcolato in rendering, guardia server separata e parziale.

**Soluzione:**
- Nuova funzione interna in `R/activation.R`:
  `command_availability(state, command)` → lista con `status`, `reason`,
  `command`, `activation`, `install`.
- Indicizzare i comandi una volta per revisione del registry:
  `menu_leaves(menu_tree())` in una cache con chiave
  `(.plugin_registry$version, menu registry key)`.
- `reason`: stringa tradotta ("Not available for the current data set",
  "In porting", "Requires an optional package") derivata dallo stato e, per
  `hidden`, dal campo `install`.
- Fallback D2: comando senza riga → `porting` se non implementato, `enabled`
  altrimenti.
- `command_enabled()` diventa un wrapper deprecato che ritorna
  `identical(status, "enabled")`, mantenendo i test e i chiamanti esistenti.

**File:** `R/activation.R`, `R/menus.R` (helper di indice), `R/dialogs.R`.

**Test:** matrice di stati per comandi noti (`readDataSet`, `oneWayAnova`,
`saveDataSet`, `onCopy`, `CFA`, comando inesistente), casi con e senza
dataset, attivazione che lancia errore (deve dare `inactive`).

**Accettazione:** esiste un solo punto che decide lo stato; nessun test
esistente cambia semantica.

### H8.2 — Guardie di ingresso

**Problema:** `launch()` copre 3 comandi; la cronologia non controlla nulla.

**Soluzione:**
- `launch()` usa `command_availability()` e mostra il motivo corretto:
  - `porting` → "This command has not been ported yet."
  - `inactive` → "Not available for the current data set." (o motivo
    specifico)
  - `hidden` → "Not available in this environment."
- `history_open_dialog()` verifica la disponibilità del dialogo prima di
  riaprirlo; in caso negativo notifica e non apre.
- `state$open_dialog()` e `open_dialog_memory()` restano senza guardia
  globale: sono chiamati da azioni contestuali già valide (Data Studio,
  suggerimenti). La motivazione va in un commento e in un test.

**File:** `R/app.R`, `R/history.R`, `R/dialogs.R`.

**Test (`testServer`):** senza dataset, `menu_command = "oneWayAnova"` non apre
il dialogo e produce la notifica; `history_open_dialog` su un dialogo
`inactive` non apre; un comando `porting` produce il messaggio "not ported".

**Accettazione:** nessun percorso `launch`/cronologia apre un dialogo con
stato diverso da `enabled`.

### H8.3 — Preferiti e recenti coerenti col menubar

**Problema:** M1, M6.

**Soluzione:**
- `menu_sections_ui()` calcola lo stato con `command_availability()`:
  - `enabled` → link come oggi;
  - `inactive`/`porting` → riga disabilitata con motivo, stella conservata
    per poter rimuovere il preferito;
  - `hidden` → omessa dalla sezione (il dato resta in preferenze).
- Nessuna cancellazione automatica di preferiti o recenti.
- Etichetta di sezione invariata; nessun cambio di ID o persistenza.

**File:** `R/menus.R`.

**Test:** sezione con preferiti misti (`enabled`, `inactive`, `porting`,
`hidden`) → un solo link, due righe disabilitate, una assente; test di
non-regressione sul contenuto delle preferenze.

**Accettazione:** il comportamento della sezione è identico a quello del
menubar per gli stessi comandi.

### H8.4 — Interazione e accessibilità delle voci disabilitate

**Problema:** M3, M4.

**Soluzione:**
- JS: il listener di cattura ignora i click su
  `.rcmdr-menu-item.disabled`; il menu resta aperto e il tooltip leggibile.
- Markup: `aria-disabled="true"`, `tabindex="0"` sulle voci disabilitate;
  `aria-label` o testo `visually-hidden` che include il motivo.
- Mantenere `title` per il mouse.
- Le voci disabilitate restano escluse dall'attivazione con Invio (nessun
  handler), ma sono raggiungibili per leggere il motivo.
- Non introdurre un banner di gruppo: con 57 gruppi sarebbe rumore; il motivo
  per voce è sufficiente. Un test verifica che nessun gruppo resti vuoto.

**File:** `R/app.R` (CSS/JS), `R/menus.R`.

**Test:** snapshot HTML della voce disabilitata (attributi ARIA); E2E gated che
clicca una voce grigia e verifica che il gruppo resti `open`. Audit manuale
tastiera e screen reader annotato in `ACCESSIBILITY.md`.

**Accettazione:** click su voce grigia non chiude il menu; la voce è
focalizzabile e il motivo è annunciato.

### H8.5 — Isolamento degli errori dei plugin

**Problema:** P2.

**Soluzione:**
- `.plugin_registry$failures`: lista di `list(name, stage, message, time)`.
- `load_plugins_now()` avvolge ogni plugin in `tryCatch`, continua con i
  successivi, ritorna un riepilogo; l'API pubblica resta
  `list_plugins()`/`invisible`.
- `plugins_ensure_loaded()` processa la coda una voce alla volta: i successi
  vengono rimossi, i fallimenti registrati e **non** ritentati
  automaticamente (retry solo esplicito).
- `health_status()` e `diagnostics_report()` espongono `plugin_failures`; la
  Home mostra un avviso se non vuoto.
- All'avvio di sessione, se ci sono fallimenti, una notifica una tantum.
- `unload_plugins()` azzera anche i fallimenti.

**File:** `R/plugins.R`, `R/health.R`, `R/diagnostics.R`, UI Home.

**Test:** plugin mancante non blocca `load_plugins`; il successivo viene
caricato; il fallimento è in health/diagnostics; la coda non perde i plugin
non ancora tentati; retry esplicito funziona.

**Accettazione:** `run(plugins = c("Valido", "Inesistente"))` avvia l'app,
carica il valido e mostra il fallimento.

### H8.6 — Messaggio del caricamento a runtime

**Problema:** P3.

**Soluzione:**
- Messaggio: "Plugin loaded. Reload the page (F5) to see its menus.
  Restarting R removes the plugin."
- Notifica con azione "Reload now" opzionale (`session$reload()`), mai
  automatica: perderebbe lo stato di sessione.
- Documentare in `writing-plugins` e nella vignetta `plugins.Rmd` che:
  - i menu sono catturati all'avvio sessione;
  - la palette vede subito i comandi nuovi;
  - il reload è sufficiente e mantiene il registro nel processo R.
- Valutare (non obbligatorio in 2.0.2) un avviso esplicito quando la palette
  contiene comandi non presenti nel menubar.

**File:** `R/plugins.R`, `inst/help-topics/topics/writing-plugins.md`,
`vignettes/plugins.Rmd`.

**Test:** il testo del messaggio è asserito; test manuale del flusso
load → palette → reload.

**Accettazione:** nessuna istruzione che porti l'utente a riavviare R.

### H8.7 — Chiusura Fase 1

- Test unit/integration nuovi e suite completa verdi.
- `R CMD check` OK su 2.0.2.
- `NEWS.md` 2.0.2, `DESCRIPTION` 2.0.2.
- `CHECKLIST.md` aggiornata, diario `wave-08-hardening.md` creato.
- E2E gated eseguiti e documentati (o debito esplicito).

---

## 6. Fase 2 — gestione plugin (rilascio 2.1.0, minor)

### H8.8 — Persistenza e Plugin Manager

**Problema:** P4.

**Soluzione:**
- `preferences_snapshot()` aggiunge `plugins` (character: nomi pacchetto e
  path di script); `preferences_load()` li ripristina con validazione e
  fallimenti registrati.
- Semantica di `app(plugins = ...)`:
  - `NULL` → usa i plugin salvati;
  - `character()` → nessun plugin (esplicito);
  - vettore → quelli indicati, senza unire i salvati.
- Nuovo dialogo `Manage plugins...` in Utilities:
  - elenca i pacchetti installati `RcmdrShinyPlugin.*` con versione e stato;
  - checkbox per la selezione; campo path per script;
  - "Apply" scrive le preferenze e mostra "Reload to apply";
  - "Reload now" opzionale.
- Il dialog `loadPlugins` esistente resta per il caricamento ad hoc di uno
  script, ma rimanda al manager per la selezione persistente.
- Salvataggio robusto: plugin non più installati vengono ignorati e
  registrati come fallimenti al lancio successivo.

**File:** `R/preferences.R`, `R/plugins.R`, `R/dialogs.R`, `R/app.R`,
`inst/menus/core.yml` (nuova voce), topic help.

**Test:** roundtrip preferenze; semantica `NULL`/`character()`/vettore;
dialogo con elenco finto; avvio con plugin salvato mancante.

**Accettazione:** dopo un riavvio dell'app la selezione è ricordata senza
modificare codice R; un plugin mancante non blocca l'avvio.

### H8.9 — Conflitti visibili

**Problema:** P5.

**Soluzione:**
- `.plugin_registry$conflicts`: lista strutturata alimentata da
  `check_conflicts()` (override di comandi, dialoghi, predicati, alias help).
- Il `warning()` resta per compatibilità console, ma il conflitto è anche in
  health/diagnostics e in una notifica una tantum.
- I conflitti con il core restano errori (nessun override implicito).

**File:** `R/plugins.R`, `R/health.R`, `R/diagnostics.R`, UI Home.

**Test:** override tra plugin registrato e visibile; clash col core ancora
`stop()`.

**Accettazione:** l'override UCA osservato nell'audit compare in health.

### H8.10 — Semantica del caricamento differito

**Problema:** P1.

**Soluzione:**
- Documentare che `RcmdrShiny.lazy_plugins` differisce il caricamento al
  **primo accesso al catalogo**, non al primo uso del plugin.
- Aggiungere a health/diagnostics il tempo di materializzazione e il numero di
  plugin accodati.
- Rinominare solo nella documentazione come "deferred plugin loading"; il nome
  dell'opzione resta per compatibilità.
- Aggiungere un test che dimostri che la coda è vuota dopo `menu_tree()` e che
  il caricamento è avvenuto una sola volta (cache).
- Valutare la rimozione dell'opzione in 3.0 se non porta beneficio misurabile.

**File:** `R/plugins.R` (commenti/roxygen), `R/health.R`,
`vignettes/plugins.Rmd`, `inst/help-topics/topics/writing-plugins.md`.

**Accettazione:** nessuna documentazione promette caricamento on-demand.

### H8.11 — Benchmark del ciclo plugin

**Problema:** P6.

**Soluzione:**
- Nuovi scenari in `R/benchmark.R` / `tests/benchmarks/benchmark.R`:
  - load di 1 plugin;
  - load dei 15 plugin;
  - primo catalogo dopo lazy;
  - `menu_tree()` caldo;
  - conteggio plugin/fallimenti.
- Budget espliciti e registrazione in `TEST-MATRIX.md`; superamento = messaggio,
  non errore, come oggi.
- Registrare i numeri della baseline 2.0.1 nell'audit/diario per confronto.

**Accettazione:** i cinque scenari esistono, sono eseguiti e documentati.

### H8.12 — Chiusura Fase 2

- `NEWS.md` 2.1.0, `DESCRIPTION` 2.1.0, README/help/vignetta aggiornati.
- `R CMD check` OK; contratti dei 15 plugin verdi.
- Diario e checklist aggiornati.

---

## 7. Fase 3 — valutazioni (nessun rilascio pianificato)

### H8.13 — Lazy reale e registro per sessione

Solo se emerge una necessità concreta:

- **Lazy reale per gruppo di menu:** richiede menu e predicati disponibili
  senza caricare il namespace del plugin, quindi una separazione tra
  contributo statico (menu) e contributo dinamico (dialoghi, comandi). Impatto
  alto su registry, cache e attivazione.
- **Registro per sessione:** spostare `.plugin_registry` nello stato della
  sessione. Rompe l'assunzione single-user e le cache globali; richiede ADR e
  migrazione dei test.
- Output atteso: ADR con decisione go/no-go e stima, non implementazione
  automatica.

---

## 8. Mappa raccomandazioni → task

| Audit | Raccomandazione | Task |
|---|---|---|
| Menu | Filtrare preferiti/recents con lo stato | H8.3 |
| Menu | `launch()` unica guardia con messaggi distinti | H8.1, H8.2 |
| Menu | Non chiudere il menu su voce disabilitata | H8.4 |
| Menu | `aria-disabled`, focus, motivo accessibile | H8.4 |
| Menu | Test unit/integration/E2E | H8.2, H8.3, H8.4 |
| Plugin | Isolamento errori per plugin | H8.5 |
| Plugin | Messaggio reload invece di restart | H8.6 |
| Plugin | Lazy onesto o rimosso | H8.10 |
| Plugin | Persistenza e selezione da UI | H8.8 |
| Plugin | Conflitti visibili in health/diagnostics | H8.9 |
| Plugin | Benchmark plugin | H8.11 |
| Plugin | Registry per-sessione / lazy reale | H8.13 |

---

## 9. Ordine, dipendenze e rilasci

```text
H8.1 ──┬─> H8.2
       └─> H8.3
H8.4 (indipendente)
H8.5 ──> H8.8
H8.6 (indipendente)
H8.10 ──> H8.11
```

| Rilascio | Contenuto | Tipo |
|---|---|---|
| **2.0.2** | H8.1–H8.7 | Patch: nessun cambio visibile di API, solo comportamento |
| **2.1.0** | H8.8–H8.12 | Minor: nuova preferenza, nuovo dialogo, nuovi campi health |
| — | H8.13 | Solo ADR/spike |

Ogni fase = un commit di codice + test, un commit di documentazione, diario
aggiornato prima della compattazione.

---

## 10. Piano di test

| Livello | Cosa aggiungere | File |
|---|---|---|
| Unit | `command_availability` (matrice), `menu_sections_ui`, preferenze plugin, conflitti, fallimenti | `test-menus.R`, `test-activation.R`, `test-preferences.R`, `test-plugins.R` |
| Integration | `launch` bloccato con dataset assente; cronologia; load plugin con errore; avvio con plugin salvato mancante | `test-app-integration.R`, `test-plugins.R`, `test-preferences.R` |
| Golden | Nessun cambiamento atteso; rieseguire i test dei comandi | `test-command-builders-*.R` |
| Contratto menu | Copertura 782 comandi invariata | `test-menu-registry.R`, `test-plugins-compat.R` |
| E2E (gated) | Click su voce grigia non chiude il menu; preferito disabilitato non apre; load plugin → reload → menu presente | `test-menu-platform-e2e.R`, nuovo `test-plugin-manager-e2e.R` |
| Accessibilità | Attributi ARIA e focus su voce disabilitata; audit manuale | `test-accessibility.R`, `ACCESSIBILITY.md` |
| Performance | 5 scenari plugin | `benchmark.R` |

Regola invariata: i test E2E sono gated da `RCMDRSHINY_E2E=1`; nella suite
normale restano skip espliciti.

---

## 11. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| `command_availability` troppo costosa per comando | Rendering lento | Indice cached per versione registry; test di performance sul menubar |
| Comandi senza riga di menu bloccati per errore | Plugin/palette inutilizzabili | Fallback D2 + test dedicati |
| Preferenze plugin puntano a pacchetti rimossi | Avvio rotto | H8.5 (isolamento) + validazione + fallimento visibile |
| Reload richiesto all'utente confonde | UX | Messaggio esplicito, azione "Reload now", documentazione |
| `tabindex` sulle voci disabilitate altera la navigazione | Accessibilità | Test keyboard e ordine di focus; E2E |
| Conflitti registrati ma ignorati dall'utente | Override silenziosi | Notifica una tantum + health |
| Lazy reale richiesto a metà fase | Scope creep | H8.13 separato, solo ADR |
| Modifica del registro plugin per-sessione | Regressioni multi-sessione | Fuori perimetro, ADR |

---

## 12. Definition of Done

Una fase è chiusa quando:

- [ ] Tutti i task della fase sono `[x]` in `CHECKLIST.md`.
- [ ] `testthat::test_local()` verde, 0 fail.
- [ ] `R CMD check --no-manual` **Status: OK**.
- [ ] I contratti dei 15 plugin restano verdi.
- [ ] Nessun `menu_id`/`item_id`/`command_id` o formato modificato.
- [ ] `NEWS.md`, `DESCRIPTION`, help e vignette aggiornati.
- [ ] `TEST-MATRIX.md` e `ACCESSIBILITY.md` aggiornati se toccati.
- [ ] Diario di handoff creato e pushato.
- [ ] E2E gated eseguiti e documentati (o debito dichiarato con motivo).
- [ ] Utente informato del rilascio e dei cambi di comportamento.

---

## 13. Fuori perimetro

- Riscrittura del registry dei menu o dei command builder.
- Isolamento multiutente o registry per sessione.
- Caricamento automatico di tutti i plugin installati: la selezione resta
  esplicita e persistita.
- Modifica del formato `.rcmdrproj` o dei bundle.
- Nuovi stati oltre `enabled`/`inactive`/`porting`/`hidden`.
- Esecuzione di plugin Tk legacy.

---

## 14. Comandi di verifica

```bash
# unit + integration + golden
Rscript -e 'testthat::test_local()'

# suite con conteggi
Rscript -e 'pkgload::load_all(quiet=TRUE); d <- as.data.frame(testthat::test_dir("tests/testthat", reporter="silent")); cat(nrow(d), sum(d$passed), sum(d$failed), sum(d$skipped), "\n")'

# E2E menu e plugin manager
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-menu-platform-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-plugin-manager-e2e.R")'

# benchmark plugin
Rscript tests/benchmarks/benchmark.R

# package
R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```

---

## 15. Aggiornamenti richiesti alla documentazione

- `CHECKLIST.md`: sezione Onda 8 con i task H8.x.
- `README.md` (indice upgrade): riga Onda 8 con link a questo documento.
- `DECISIONS.md`: ADR per D4–D7 durante l'implementazione.
- `NEWS.md`: 2.0.2 (fix menu e robustezza plugin), 2.1.0 (gestione plugin).
- `docs/upgrades/diary/wave-08-hardening.md`: diario di chiusura.
- `inst/help-topics/topics/writing-plugins.md` e `vignettes/plugins.Rmd`:
  caricamento, reload, persistenza.
- `TEST-MATRIX.md`: scenari plugin e conteggi aggiornati.
- `ACCESSIBILITY.md`: voci disabilitate e motivo accessibile.
