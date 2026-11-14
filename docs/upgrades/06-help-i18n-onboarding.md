# Onda 6 — Help, i18n e onboarding

**Stato:** implementata (2026-11-14)
**Dipende da:** Onda 0 (shell, palette, design system)  
**Sblocca:** autonomia dell'utente e documentazione di prodotto  
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Rendere l'help un vero centro di documentazione e apprendimento:

- ricerca full-text con ranking e filtri;
- topic correlati, comandi ed esempi;
- “Try it” per gli esempi eseguibili;
- mappa errore → topic;
- glossario e scorciatoie;
- tour iniziale;
- italiano completo;
- cambio lingua il più possibile live.

L'help resta offline e locale. Nessun servizio esterno.

---

## 2. Stato attuale

| Elemento | File | Situazione |
|---|---|---|
| Registry | `R/help.R` (1.002 righe) | Topic Markdown, YAML front matter, ricerca pesata, categorie |
| UI | `R/help-ui.R` | Tab Help, risultati, categorie, topic |
| Server | `R/help-server.R` | Ricerca, navigazione, recenti, help inline |
| Diagnostica | `R/diagnostics.R` | Report per issue |
| Contenuti | `inst/help-topics/` | 443 topic, 21 traduzioni italiane |
| Tooling | `tools/*help*.R` | Inventario, link check, generazione |
| CI | `.github/workflows/help.yaml` | Test, inventory, link check |

Limiti:

- ricerca a sottostringa pesata, non indice full-text;
- nessun filtro per tipo/plugin/categoria nella UI;
- nessun “Try it”;
- nessuna mappa errore → topic;
- nessun glossario;
- tour assente;
- italiano limitato a 21 topic core;
- cambio lingua richiede restart.

---

## 3. Help center

### 3.1 Indice full-text

```r
help_index_build(topics) -> list(
  terms = list(term = list(doc = weight)),
  docs = data.frame(id, title, category, type, language, length)
)
```

Ranking:

- titolo: peso 5;
- keyword: peso 4;
- heading: peso 3;
- corpo: peso 1;
- alias: peso 4;
- match esatto: boost.

Filtri:

- core/plugin;
- categoria;
- tipo (`guide`, `reference`, `tutorial`, `troubleshooting`);
- lingua.

### 3.2 Risultati

- snippet con evidenziazione;
- categoria e tipo;
- “correlati”;
- “comandi citati”;
- “dialoghi correlati”;
- “apri nel dialogo” quando esiste.

### 3.3 Topic

- TOC interno;
- link a dialoghi e comandi;
- esempi con `Run` se marcati `runnable: true`;
- “Vedi anche”;
- “Segnala un problema” → diagnostics;
- copia link;
- apri in nuova tab? No, resta nel pannello.

### 3.4 Task

| ID | Task | File |
|---|---|---|
| H6.1 | Indice full-text | `R/help-index.R`, `R/help.R` |
| H6.2 | Ranking e filtri | `R/help.R`, `R/help-server.R` |
| H6.3 | Snippet e correlati | `R/help-ui.R` |
| H6.4 | Topic TOC e link | `R/help-ui.R` |
| H6.5 | “Try it” | `R/help-server.R`, `R/preview.R` |

---

## 4. “Try it”

### 4.1 Regole

- solo esempi marcati nel front matter:

```yaml
examples:
  - code: "summary(Dataset)"
    runnable: true
```

- l'esecuzione passa da `run_command()`, quindi è loggata;
- se il comando usa un dataset che non esiste, offri di scegliere un dataset;
- conferma prima di eseguire;
- nessuna esecuzione automatica.

### 4.2 UI

```text
```r
summary(Dataset)
```
[ Esegui ] [ Copia ] [ Inserisci nello Script ]
```

### 4.3 Task

| ID | Task | File |
|---|---|---|
| H6.6 | Parser esempi | `R/help.R` |
| H6.7 | UI esempi e conferma | `R/help-ui.R`, `R/help-server.R` |
| H6.8 | Esecuzione loggata | `R/help-server.R`, `R/commands.R` |

---

## 5. Mappa errore → topic

### 5.1 Obiettivo

Quando un comando fallisce, offrire un link al topic o al suggerimento
rilevante.

### 5.2 Regole

```r
error_help_topic(message) -> topic_id | NULL
```

Pattern iniziali:

- “object not found” → data import / active dataset;
- “could not find function” → package mancante / plugin;
- “contrasts can be applied only to factors” → factor conversion;
- “NA/NaN/Inf” → missing data;
- “pandoc not found” → report/knit;
- “there is no package called” → install packages.

### 5.3 UI

Nella card di errore:

```text
[!] Errore: object 'Dataset' not found
    [Apri help: importare i dati] [Riprova]
```

### 5.4 Task

| ID | Task | File |
|---|---|---|
| H6.9 | Mappa errori | `R/help-errors.R` |
| H6.10 | UI errore contestuale | `R/console-studio.R`, `R/app.R` |

---

## 6. Glossario e scorciatoie

- topic `glossary` con termini statistici e di interfaccia;
- topic `keyboard-shortcuts` aggiornato con la nuova mappa;
- link contestuali dal testo;
- ricerca include il glossario.

### Task

| ID | Task | File |
|---|---|---|
| H6.11 | Glossario | `inst/help-topics/topics/glossary.md` |
| H6.12 | Scorciatoie aggiornate | `inst/help-topics/topics/keyboard-shortcuts.md` |

---

## 7. Onboarding

### 7.1 Tour iniziale

Quattro passi:

1. **Dati** — import, Data Studio, inspector.
2. **Grafici** — Chart Studio, anteprima, galleria.
3. **Report** — Report Studio, template, knit.
4. **Palette** — `Ctrl+K`, preferiti, cronologia.

Comportamento:

- parte al primo avvio;
- dismissibile;
- “Non mostrare più” in `localStorage`;
- riavviabile da Help > Tour.

### 7.2 Checklist primo avvio

Nella Home:

- importa un dataset;
- esegui un summary;
- crea un grafico;
- crea un report;
- salva un progetto.

### 7.3 Task

| ID | Task | File |
|---|---|---|
| H6.13 | Tour engine | `R/onboarding.R` |
| H6.14 | Tour UI e persistenza | `R/onboarding.R`, `R/app.R` |
| H6.15 | Checklist Home | `R/app.R` |

---

## 8. Internazionalizzazione

### 8.1 Stato

- `tr()` usa gettext con dominio `R-RcmdrShiny`;
- 21 topic core tradotti in italiano;
- il resto fallback in inglese;
- cambio lingua richiede restart.

### 8.2 Obiettivi

1. Audit delle stringhe non tradotte nella UI.
2. Completare i topic core in italiano.
3. Cambio lingua live per:
   - menu;
   - pannelli dinamici;
   - help;
   - messaggi server-side.
4. Fallback restart per le etichette statiche, se la re-renderizzazione completa
   è troppo invasiva.
5. Persistenza della lingua nel progetto/preferenze.

### 8.3 Implementazione live

- rendere la shell un `uiOutput("app_shell")` ricostruibile;
- `current_language()` legge un'opzione reattiva;
- `tr()` resta invariato;
- `session$reload` come fallback.

### 8.4 Task

| ID | Task | File |
|---|---|---|
| H6.16 | Audit stringhe | script/tool |
| H6.17 | Topic italiani | `inst/help-topics/topics/it/` |
| H6.18 | Lingua reattiva | `R/i18n.R`, `R/app.R` |
| H6.19 | Persistenza lingua | `R/state.R`, `R/project.R` |

---

## 9. Riproducibilità

| Azione | Comando? | Note |
|---|---|---|
| Ricerca help | No | Sola lettura |
| “Try it” | Sì | `run_command()` con conferma |
| Apri dialogo da help | No | Navigazione |
| Cambio lingua | No | Preferenza |
| Tour | No | UI |

---

## 10. Test e accettazione dell'Onda 6

### Unit

- `test-help-index.R`
- `test-help-ranking.R`
- `test-help-filters.R`
- `test-help-examples.R`
- `test-help-errors.R`
- `test-onboarding.R`
- `test-i18n.R`

### E2E

1. Cerca “regressione logistica”, apri il topic.
2. Filtra per plugin.
3. Esegui un esempio “Try it” su un dataset attivo.
4. Provoca un errore `object not found`, apri il topic consigliato.
5. Cambia lingua e verifica menu/help.
6. Riavvia il tour.

### Criterio finale

> L'utente trova la risposta nel contesto, può eseguire un esempio in modo
> tracciato e non è costretto a riavviare per cambiare lingua.

---

## 11. Rischi specifici

| Rischio | Mitigazione |
|---|---|
| Indice troppo grande | Costruzione lazy + cache |
| “Try it” esegue codice pericoloso | Solo esempi marcati, conferma, log |
| Errore mappato male | Pattern conservativi + link generico |
| Lingua live rompe layout | Shell reattiva + test; fallback restart |
| Tour fastidioso | Dismissibile e riavviabile |
| Traduzioni incomplete | Fallback inglese + inventory |

---

## 12. Fuori perimetro

- Help online o sincronizzazione cloud.
- AI assistant.
- Traduzioni automatiche.
- Nuove procedure.

---

## 13. Checklist di chiusura

- [x] Indice full-text.
- [x] Ranking e filtri.
- [x] Snippet e correlati.
- [x] TOC topic.
- [x] “Try it”.
- [x] Parser esempi.
- [x] Esecuzione loggata.
- [x] Mappa errori.
- [x] UI errore contestuale.
- [x] Glossario.
- [x] Scorciatoie aggiornate.
- [x] Tour engine.
- [x] Tour UI.
- [x] Checklist Home.
- [x] Audit stringhe.
- [x] Topic italiani.
- [x] Lingua reattiva.
- [x] Persistenza lingua.
- [x] Test unit e E2E verdi.
