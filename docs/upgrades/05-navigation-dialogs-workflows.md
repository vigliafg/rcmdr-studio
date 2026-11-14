# Onda 5 — Navigazione, dialoghi e workflow guidati

**Stato:** completata (vedi `diary/wave-05-navigation-dialogs-workflows.md`)
**Dipende da:** Onde 0–4  
**Sblocca:** un'esperienza “da prodotto” sopra il catalogo esistente  
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Rendere il catalogo di 863 voci utilizzabile senza conoscerlo a memoria:

- command palette evoluta;
- preferiti, recenti, ricerca menu;
- scorciatoie e breadcrumb;
- dialoghi con preset, validazione e anteprima;
- workflow guidati che orchestrano dialoghi esistenti;
- suggerimenti contestuali sulle variabili.

Nessuna nuova procedura statistica: i workflow compongono ciò che esiste.

---

## 2. Navigazione

### 2.1 Command palette

Estendere l'Onda 0:

- ricerca fuzzy su label, path, keyword, help, dataset, variabili, cronologia;
- filtri per tipo (`menu`, `dialog`, `help`, `data`, `history`);
- preferiti in cima;
- recenti;
- stato disabilitato con motivo;
- `Ctrl+K`, frecce, `Enter`, `Esc`;
- “Esegui”, “Apri”, “Inserisci nello script”, “Copia comando”.

### 2.2 Menu search e preferiti

- campo di ricerca nella sidebar;
- filtro live con evidenziazione;
- stella per preferito;
- sezione “Preferiti” e “Recenti” in cima;
- collapse/expand all;
- stato di espansione persistito.

### 2.3 Breadcrumb

Nei dialoghi e nelle palette:

```text
Statistiche > Riassunti > Riassunti numerici
```

Serve a capire da dove viene un comando e a tornare al menu.

### 2.4 Task

| ID | Task | File |
|---|---|---|
| N5.1 | Palette evoluta | `R/command-palette.R` |
| N5.2 | Preferiti/recenti | `R/menus.R`, `R/state.R` |
| N5.3 | Menu search | `R/menus.R` |
| N5.4 | Breadcrumb | `R/dialogs.R`, `R/menus.R` |
| N5.5 | Scorciatoie complete | `R/shortcuts.R` |

---

## 3. Dialog platform 2.0

### 3.1 Anteprima comando

Già introdotta nell'Onda 0. Qui si completa:

- preview per tutti i dialoghi che restituiscono `commands`;
- preview per i dialoghi che restituiscono `report`, `interactive`, `tab`;
- messaggio chiaro quando il dialogo non produce un comando diretto;
- “Apri nello Script” e “Copia”.

### 3.2 Preset

```r
state$dialog_presets <- list(
  numericalSummaries = list(
    "Default didattico" = list(
      mean = TRUE, sd = TRUE, quantiles = TRUE, groups = NULL
    ),
    "Confronto gruppi" = list(
      mean = TRUE, sd = TRUE, groups = "Species"
    )
  )
)
```

UI:

- select preset;
- “Salva preset”;
- “Elimina”;
- “Esporta/Importa”.

### 3.3 Validazione inline

- `field_errors` da `on_ok`;
- messaggi sotto il campo;
- focus sul primo errore;
- `aria-invalid`;
- nessun errore solo nel toast.

### 3.4 Dialoghi più usabili

- selectors con tipo, missing e conteggio;
- ricerca nelle variabili;
- drag & drop per multi-selezione (dove serve);
- help inline;
- “Reset” e “Duplica”;
- responsive su schermi medi;
- memoria per dialogo;
- “Apri nello Script” senza eseguire.

### 3.5 Task

| ID | Task | File |
|---|---|---|
| N5.6 | Preview completa | `R/dialogs.R` |
| N5.7 | Preset UI e persistenza | `R/dialogs.R`, `R/state.R` |
| N5.8 | Validazione inline | `R/dialogs.R`, `R/widgets.R` |
| N5.9 | Selector arricchiti | `R/widgets.R` |
| N5.10 | Responsive e accessibilità dialogo | `R/dialogs.R`, CSS |

---

## 4. Workflow guidati

### 4.1 Concetto

Un workflow è una sequenza di passi che usa i dialoghi esistenti e produce:

- comandi nel log;
- una sezione di script;
- una bozza di report.

Non introduce nuovi test o modelli: li orchestra.

### 4.2 Modello

```r
workflow_spec <- list(
  id = "describe",
  title = "Descrivi i dati",
  description = "Summary, missing e distribuzioni principali.",
  steps = list(
    list(
      id = "summary",
      title = "Riassunti numerici",
      dialog = "numericalSummaries",
      memory = list(...),
      optional = FALSE
    ),
    list(
      id = "missing",
      title = "Valori mancanti",
      dialog = "countMissing",
      optional = TRUE
    ),
    list(
      id = "plots",
      title = "Distribuzioni",
      dialog = "Histogram",
      optional = TRUE
    )
  ),
  report_section = "## Descrizione dei dati"
)
```

### 4.3 UI

- pannello workflow persistente (drawer o tab);
- lista passi con stato;
- “Apri passo” → dialogo esistente;
- dopo `apply_dialog_result`, il workflow registra il comando e avanza;
- “Salta”, “Indietro”, “Annulla”;
- “Genera sezione report” alla fine.

### 4.4 Workflow iniziali

| Workflow | Passi | Comandi esistenti |
|---|---|---|
| **Descrivi i dati** | Summary, missing, histogram/boxplot | `numericalSummaries`, `countMissing`, `Histogram`, `Boxplot` |
| **Confronta gruppi** | Summary per gruppi, t-test/ANOVA, boxplot | `numericalSummaries`, `independentSamplesTTest`, `oneWayAnova`, `Boxplot` |
| **Modello lineare** | Fit, summary, diagnostica, effect plot | `linearModel`, `summarizeModel`, `plotModel`, `EffectPlots` |
| **Sopravvivenza** | KM, log-rank, Cox | `Survfit`, `Survdiff`, `CoxModel` |
| **Prepara il report** | Nuovo Rmd, insert dataset, insert plot, knit | `newRmd`, `report_insert_*`, `document_knit` |

### 4.5 Regole

- ogni passo è opzionale o obbligatorio;
- il workflow non esegue nulla senza il dialogo;
- il workflow non duplica la logica di validazione;
- i comandi restano quelli del dialogo;
- il report generato è una bozza modificabile.

### 4.6 Task

| ID | Task | File |
|---|---|---|
| N5.11 | Workflow model e registry | `R/workflows.R` |
| N5.12 | Workflow UI | `R/workflows.R`, `R/app.R` |
| N5.13 | Integrazione con dialoghi/cronologia | `R/workflows.R`, `R/dialogs.R` |
| N5.14 | Cinque workflow iniziali | `R/workflows.R` |
| N5.15 | Generazione sezione report | `R/workflows.R`, `R/report.R` |

---

## 5. Suggerimenti contestuali

### 5.1 “Cosa posso fare con questa variabile?”

In base a:

- tipo (numeric, factor, character, logical, date);
- numero di livelli;
- missing;
- dataset attivo;
- modello attivo.

Suggerisce:

- summary;
- histogram/density;
- boxplot;
- table;
- t-test/ANOVA;
- correlation;
- recode/bin;
- set label.

### 5.2 Implementazione

- funzione pura `variable_suggestions(state, variable)`;
- UI nell'inspector del Data Studio e nel menu contestuale;
- ogni suggerimento apre il dialogo esistente con memoria.

### 5.3 Task

| ID | Task | File |
|---|---|---|
| N5.16 | Suggerimenti per variabile | `R/suggestions.R` |
| N5.17 | UI inspector/menu | `R/data-studio.R`, `R/menus.R` |

---

## 6. Riproducibilità

| Azione | Comando? | Note |
|---|---|---|
| Palette: esegui menu | Sì | Stesso comando |
| Palette: apri dialogo | No | Solo apertura |
| Preferito/recente | No | Preferenza |
| Preset dialogo | No | Salvataggio input |
| Workflow: passo | Sì | Esegue il dialogo |
| Workflow: sezione report | No | Testo |
| Suggerimento | Sì/No | Dipende dall'azione scelta |

---

## 7. Test e accettazione dell'Onda 5

### Unit

- `test-command-palette-advanced.R`
- `test-menu-search.R`
- `test-dialog-presets.R`
- `test-dialog-validation.R`
- `test-workflows.R`
- `test-variable-suggestions.R`

### E2E

1. `Ctrl+K`, cerca “logistica”, apri il dialogo.
2. Aggiungi un preferito, riapri la palette, verifica l'ordine.
3. Salva un preset di `numericalSummaries`, riapri, applicalo.
4. Avvia workflow “Descrivi i dati”, completa due passi, genera sezione report.
5. Su una variabile factor, apri i suggerimenti e lancia un boxplot.

### Criterio finale

> Un utente che non conosce il menu può trovare, configurare e concatenare le
> analisi esistenti senza perdere la tracciabilità dei comandi.

---

## 8. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| Palette troppo lenta | Indice cache, limite risultati, debounce |
| Preferiti persistenti male | Salvataggio nel progetto + localStorage |
| Preset incompatibili con nuove versioni | Versione preset + validazione |
| Workflow duplica la logica dei dialoghi | Solo orchestrazione, nessuna validazione propria |
| Suggerimenti fuorvianti | Regole semplici basate su tipo, non su inferenza |
| Dialoghi troppi eterogenei | Campi opzionali e fallback |

---

## 9. Fuori perimetro

- Nuovi test/modelli nei workflow.
- Raccomandazioni statistiche automatiche.
- Assistente AI.
- Nuove procedure.

---

## 10. Checklist di chiusura

- [x] Palette evoluta.
- [x] Preferiti.
- [x] Recenti.
- [x] Menu search.
- [x] Breadcrumb.
- [x] Scorciatoie complete.
- [x] Preview comando completa.
- [x] Preset dialoghi.
- [x] Validazione inline.
- [x] Selector arricchiti.
- [x] Dialoghi responsive/accessibili.
- [x] Workflow model/registry.
- [x] Workflow UI.
- [x] Integrazione dialoghi/cronologia.
- [x] Cinque workflow.
- [x] Sezione report da workflow.
- [x] Suggerimenti variabile.
- [x] Test unit e E2E verdi.
