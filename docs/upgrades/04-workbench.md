# Onda 4 — Workbench: Script, Console, Output, Environment, Models

**Stato:** implementata — 14 novembre 2026
**Dipende da:** Onda 0 (cronologia, shell, design system)  
**Sblocca:** un ambiente di lavoro completo oltre i dialoghi  
**Documento padre:** [`README.md`](README.md)
**Diario di handoff:** [`diary/wave-04-workbench.md`](diary/wave-04-workbench.md)

---

## 1. Obiettivo

Colmare il divario tra “GUI a dialoghi” e “workbench statistico”:

- **Script**: più documenti, celle, outline, diagnostica, formattazione;
- **Console**: input R diretto, storico, output strutturato;
- **Output/Messages**: card per comando, ricerca, rerun, inserimento;
- **Environment**: esplorazione oggetti, dataset registry, model registry;
- **Models**: dashboard di confronto e diagnostica.

Nessuna nuova procedura statistica: si orchestrano i comandi esistenti.

---

## 2. Stato attuale

| Area | File | Situazione |
|---|---|---|
| Script | `R/app.R`, `R/document.R` | Un buffer, Ace, run selection/all/chunk, mode selector |
| Output | `R/app.R`, `R/commands.R` | Testo accumulato in `state$output` |
| Messages | `R/app.R` | Testo accumulato in `state$messages` |
| Environment | `R/app.R` | DT con nome, classe, dimensione |
| Modelli | `R/state.R`, `R/dialogs.R` | `state$active_model`, comandi diretti |
| Cronologia | — | Solo `state$log`, nessun record strutturato |

Limiti:

- un solo script aperto;
- nessuna console R;
- output non strutturato e non filtrabile;
- environment passivo, senza anteprima o azioni;
- nessuna vista d'insieme dei modelli;
- nessun rerun contestuale.

---

## 3. Script

### 3.1 Multi-buffer

```r
state$scripts <- list(
  "script-1" = list(
    id = "script-1",
    path = NULL,
    text = "",
    dirty = FALSE,
    mode = "r"
  )
)
state$active_script <- "script-1"
```

UI: tab dei documenti sopra l'editor, con dirty indicator, close e new.

### 3.2 Modalità notebook/celle

- parsing dei chunk Rmd/Rnw e delle sezioni;
- “Run cell”, “Run above”, “Run below”;
- output inline collassabile;
- outline laterale;
- conversione script ↔ Rmd.

### 3.3 Editor

- diagnostica di parsing in tempo reale;
- find/replace;
- folding, bracket matching, multi-cursor (Ace);
- autocompletamento per variabili, dataset, modelli e comandi;
- format con `styler` (Suggests), altrimenti disabilitato;
- autosave e recovery.

### 3.4 Task

| ID | Task | File |
|---|---|---|
| W4.1 | Registro script e tab | `R/state.R`, `R/script-studio.R`, `R/app.R` |
| W4.2 | Celle e run above/below | `R/document.R`, `R/script-studio.R` |
| W4.3 | Outline e diagnostica | `R/script-studio.R` |
| W4.4 | Find/replace, folding, autocomplete | `R/script-studio.R`, JS |
| W4.5 | Format e autosave | `R/script-studio.R` |

---

## 4. Console

### 4.1 Obiettivo

Una console R dentro l'app, per chi vuole digitare comandi senza usare i
dialoghi.

### 4.2 Design

```text
┌──────────────────────────────────────────────────────────────┐
│ Console | Output | Messages                                   │
├──────────────────────────────────────────────────────────────┤
│ > summary(Dataset)                                           │
│   Sepal.Length ...                                           │
│                                                              │
│ > plot(Dataset$Sepal.Length)                                 │
│   [plot captured]                                            │
├──────────────────────────────────────────────────────────────┤
│ > [input]                                            [Esegui]│
└──────────────────────────────────────────────────────────────┘
```

### 4.3 Comportamento

- input con `Enter` per eseguire, `Shift+Enter` per nuova riga;
- storico con frecce su/giù;
- comandi loggati e presenti in cronologia;
- append allo script secondo l'opzione `auto_append`;
- output catturato come oggi;
- plot catturati e aggiunti alla galleria;
- errori mostrati come card, non solo testo.

### 4.4 Limiti espliciti

R è single-threaded. I comandi interattivi (`readline`, `menu`, `browser`,
`scan`, `file.choose`, `select.list`) possono bloccare la sessione. La console:

- rileva i pattern e mostra un avviso prima dell'esecuzione;
- non promette cancellazione reale;
- mostra busy state e durata;
- documenta il limite nell'help.

### 4.5 Task

| ID | Task | File |
|---|---|---|
| W4.6 | Console UI e input | `R/console-studio.R`, `R/app.R` |
| W4.7 | Storico comandi | `R/console-studio.R` |
| W4.8 | Output card e rerun | `R/history.R`, `R/console-studio.R` |
| W4.9 | Rilevamento comandi interattivi | `R/console-studio.R` |

---

## 5. Output e Messages

### 5.1 Output cards

Ogni esecuzione diventa una card:

```text
[ok] 12:31:04 · 42 ms · dialog:numericalSummaries
summary(Dataset)
▸ Output (12 righe)
[ Copia ] [ Rerun ] [ Apri dialogo ] [ Inserisci nello Script ] [ Report ]
```

Funzioni:

- ricerca full-text nell'output;
- filtro per stato (ok/error/warning);
- filtro per fonte (dialog/script/console);
- collapse/expand;
- copia output o comando;
- rerun;
- apri dialogo con memoria;
- inserisci nello script/report;
- pin della card.

### 5.2 Messages

- filtro per severità;
- raggruppamento per comando;
- “vai al comando”;
- clear singolo o globale;
- warning/error con contesto.

### 5.3 Task

| ID | Task | File |
|---|---|---|
| W4.10 | Output cards | `R/history.R`, `R/console-studio.R` |
| W4.11 | Ricerca/filtri output | `R/console-studio.R` |
| W4.12 | Messages per severità | `R/console-studio.R` |

---

## 6. Environment

### 6.1 Object explorer

Colonne:

- nome;
- tipo/classe;
- dimensione;
- anteprima;
- azioni.

Azioni:

- View (dataset);
- Summary;
- Plot;
- str;
- Save;
- Remove;
- Set active dataset/model.

### 6.2 Dataset registry

Già introdotto nel Data Studio. Nell'Environment mostra:

- nome;
- righe × colonne;
- fonte;
- modified;
- attivo;
- azioni.

### 6.3 Model registry

```r
model_registry(state) -> data.frame(
  name, class, formula, family, data, n, aic, bic, r2, active
)
```

Riconoscere:

- `lm`, `glm`, `aov`, `anova`, `coxph`, `survreg`, `lmer`, `glmer`, `polr`,
  `multinom`, `nls`, `loess`, ecc.

### 6.4 Task

| ID | Task | File |
|---|---|---|
| W4.13 | Object explorer | `R/environment-studio.R`, `R/app.R` |
| W4.14 | Anteprima oggetto | `R/environment-studio.R` |
| W4.15 | Azioni rapide | `R/environment-studio.R`, `R/dialogs.R` |
| W4.16 | Dataset registry view | `R/environment-studio.R` |
| W4.17 | Model registry | `R/models-studio.R`, `R/state.R` |

---

## 7. Models dashboard

### 7.1 Obiettivo

Una vista d'insieme dei modelli fittati, senza aggiungere procedure.

### 7.2 Contenuto

- tabella modelli: nome, classe, formula, famiglia, dati, n, AIC, BIC, R²;
- modello attivo evidenziato;
- confronto AIC/BIC;
- azioni per modello:
  - Summary;
  - Anova;
  - Effects;
  - Diagnostics;
  - Influence;
  - Stepwise;
  - Plot;
  - Export;
  - Set active;
  - Reopen dialog con memoria (se disponibile).

### 7.3 Implementazione

- `model_registry()` scansiona `state$env`;
- usa i comandi diretti esistenti (`summarizeModel`, `aic`, `bic`, `VIF`,
  `OutlierTest`, `plotModel`);
- `set_dialog_memory()` per riaprire il dialogo del modello con i parametri
  precedenti;
- nessun nuovo test statistico.

### 7.4 Task

| ID | Task | File |
|---|---|---|
| W4.18 | Model registry | `R/models-studio.R` |
| W4.19 | Dashboard tabella/confronto | `R/models-studio.R` |
| W4.20 | Azioni modello | `R/models-studio.R`, `R/dialogs.R` |
| W4.21 | Reopen dialog con memoria | `R/models-studio.R`, `R/history.R` |

---

## 8. Riproducibilità

| Azione | Comando? | Note |
|---|---|---|
| Console input | Sì | `run_command()` |
| Run cell/above/below | Sì | `run_command()` |
| Rerun da card | Sì | Stesso comando |
| Apri dialogo | No | Ripristina input |
| Environment preview | No | `str`/`summary` in preview isolata |
| Set active | No | Stato |
| Model summary | Sì | Comando esistente |
| Export | Sì/No | Dipende dal formato |

---

## 9. Test e accettazione dell'Onda 4

### Unit

- `test-script-registry.R`
- `test-script-cells.R`
- `test-console.R`
- `test-output-cards.R`
- `test-environment.R`
- `test-model-registry.R`
- `test-models-dashboard.R`

### E2E

1. Apri la Console.
2. Esegui `summary(Dataset)`.
3. Verifica output card, log e cronologia.
4. Rerun dalla card.
5. Apri Environment, seleziona dataset, View.
6. Fitta un modello, apri Models, confronta AIC.
7. Apri Script, esegui una cella.

### Criterio finale

> L'utente può lavorare a tre livelli — dialoghi, console, script — con lo
> stesso log, la stessa cronologia e gli stessi oggetti.

---

## 10. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| Console blocca su input interattivo | Rilevamento pattern + avviso + help |
| Multi-script rompe il mode selector | Registro + `state$document` sincronizzato |
| Output cards consumano memoria | Cap cronologia e trimming |
| Model registry su oggetti grandi | Solo metadati, non copie |
| Reopen dialog non sempre possibile | Fallback “apri dialogo vuoto” + codice |
| Autosave confligge con Report Studio | Un solo servizio autosave condiviso |

---

## 11. Fuori perimetro

- Debugger R interattivo.
- Esecuzione in background o cancellazione.
- IDE completo con git integrato.
- Nuove procedure statistiche.

---

## 12. Checklist di chiusura

- [ ] Registro script e tab.
- [ ] Celle e run above/below.
- [ ] Outline e diagnostica.
- [ ] Find/replace e autocomplete.
- [ ] Format e autosave.
- [ ] Console UI.
- [ ] Storico comandi.
- [ ] Output cards.
- [ ] Ricerca/filtri output.
- [ ] Messages per severità.
- [ ] Object explorer.
- [ ] Anteprima oggetto.
- [ ] Azioni rapide.
- [ ] Dataset registry view.
- [ ] Model registry.
- [ ] Models dashboard.
- [ ] Azioni modello.
- [ ] Reopen dialog.
- [ ] Help topic e vignetta.
- [ ] Test unit e E2E verdi.

---

## 13. Risultato consegnato

- **Script Studio** in `R/script-studio.R`: tab dei documenti condivisi con il
  Report Studio, celle ricavate dal parse R, Run cell/Run above/Run below,
  outline, diagnostica, find/replace, formattazione con `styler`, autosave e
  completamento dei nomi.
- **Console** in `R/console-studio.R`: input diretto, richiama storico con
  frecce su/giù, esecuzione via `run_command()`, stato e durata, guardia sui
  comandi interattivi, ricerca e filtro per stato.
- **Output cards**: card per esecuzione con stato, fonte, durata, comando,
  output collassabile, pin, rerun, apertura dialogo, inserimento nello script
  e nel report, copia; filtri per testo, stato e fonte.
- **Messages**: messaggi strutturati con severità, comando e passo di
  cronologia; filtro per severità e testo e rerun contestuale.
- **Environment** in `R/environment-studio.R`: explorer oggetti con classe,
  tipo e dimensione, anteprima read-only, azioni riproducibili
  Summary/str/Plot/Save/Remove, registry dei dataset e vista modelli.
- **Models** in `R/models-studio.R`: registry dei modelli riconosciuti,
  dashboard con formula, famiglia, dati, n, AIC, BIC, R² e delta AIC, azioni
  Summary/ANOVA/Effects/Diagnostics/Influence/VIF/Stepwise/AIC/BIC/Export,
  set active e reopen con memoria.
- **Dialoghi** `environmentSave` e `modelExport`.
- **Test** dedicati per registro script, celle, console, output, environment,
  model registry, dashboard e integrazione Workbench.
- **Documentazione**: topic `workbench`, vignetta `workbench.Rmd`, README,
  NEWS e DESCRIPTION.
