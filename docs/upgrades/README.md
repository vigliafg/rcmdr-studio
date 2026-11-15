# RcmdrShiny Studio — Piano di upgrade

**Stato:** pianificazione approvata, implementazione non iniziata  
**Baseline funzionale:** `rstats-commander` — RcmdrShiny 1.13.0  
**Repository di sviluppo:** `rcmdr-studio`  
**Nome prodotto:** **RcmdrShiny Studio**  
**Nome package:** `RcmdrShiny` (invariato)

---

## 1. Perché esiste questo repository

`rstats-commander` ha raggiunto la parità funzionale con R Commander: 213
dialoghi core, 863 voci di menu implementate su 900 con i 15 plugin, 443 topic
di help, report R Markdown, document authoring e plugin API.

Questo repository nasce per **non toccare più quel risultato**. Il clone
funzionale resta congelato come base stabile e verificabile; `rcmdr-studio`
parte da una copia esatta di quel codice e sviluppa una linea di prodotto
diversa:

> **RcmdrShiny non è un clone di R Commander: è un workbench statistico
> browser-native ispirato a R Commander.**

Il motore statistico, la generazione dei comandi e la semantica Rcmdr restano
la fonte di verità. Cambia l'esperienza d'uso: dati, grafici e report diventano
tre studi collegati, con cronologia strutturata, command palette, progetto di
sessione e una modalità Classica sempre disponibile.

---

## 2. Decisioni bloccate

| Tema | Decisione |
|---|---|
| **Nome prodotto** | `RcmdrShiny Studio` |
| **Nome package** | `RcmdrShiny`, invariato |
| **Namespace e API** | Invariati; nessun rename degli export |
| **Posizionamento** | “A browser-native statistical workbench inspired by the R Commander” |
| **Ordine** | Fondazioni → **Data → Charts → Report** → Workbench → Navigazione/Dialoghi → Help/i18n → Piattaforma |
| **Compatibilità** | Comandi esistenti identici; novità opt-in; modalità Classica completa |
| **Default** | La modalità Studio è il default; Classica è il fallback |
| **Dipendenze** | Nuovi `Imports` ammessi se portano un beneficio netto; `Suggests` per le estensioni opzionali |
| **Statistica** | Nessuna nuova procedura, test, modello o distribuzione |

Le decisioni sono registrate in forma di ADR in
[`DECISIONS.md`](DECISIONS.md).

---

## 3. Principi

1. **Reproducible by design.** Ogni mutazione dei dati e ogni analisi genera un
   comando R visibile nel log, nello script e nel report.
2. **Le anteprime non sono esecuzioni.** Preview di grafici, Markdown e output
   girano in un ambiente isolato e non sporcano log, stato o `.GlobalEnv`.
3. **La cronologia è un cittadino di prima classe.** Ogni passo ha comando,
   dialogo, memoria, stato, output, plot e durata; da lì si può rilanciare,
   modificare, inserire nello script o nel report.
4. **Studio e Classica convivono.** Nessuna funzione esistente viene rimossa;
   la modalità Classica resta il contratto di compatibilità.
5. **Keyboard-first e accessibile.** Palette, scorciatoie, focus, ARIA e
   contrasto fanno parte della definizione di “fatto”.
6. **Locale e single-user.** Nessun cloud, nessuna autenticazione, nessuna
   collaborazione real-time.
7. **Plugin-friendly.** L'API cresce in modo additivo e versionato; i 15 plugin
   attuali restano testati.

---

## 4. Non-obiettivi

- Nessuna nuova procedura statistica, test, modello o distribuzione.
- Nessuna esecuzione di plugin Tk legacy.
- Nessun multiutente, cloud, autenticazione o collaborazione real-time.
- Nessun editor WYSIWYG tipo Word: il Report Studio resta Markdown + anteprima.
- Nessuna riscrittura del motore: i command builder e la semantica Rcmdr
  restano la fonte di verità.
- Nessuna finta cancellazione o esecuzione in background di codice R
  arbitrario: R è single-threaded e lo stato della sessione è condiviso.
- Nessun nuovo `Imports` puramente cosmetico: ogni dipendenza deve avere un
  beneficio netto e, dove ragionevole, un fallback.

---

## 5. Roadmap

| Onda | Documento | Focus | Dipende da |
|---|---|---|---|
| **0** | [`00-foundations.md`](00-foundations.md) | Identità, design system, shell, palette, cronologia, anteprima comando, accessibilità | — |
| **1** | [`01-data-studio.md`](01-data-studio.md) | Data Studio: registro dataset, griglia, inspector, operazioni, undo, import | 0 |
| **2** | [`02-chart-studio.md`](02-chart-studio.md) | Chart Studio: chart spec, anteprima live, builder, galleria, export, round-trip | 0 |
| **3** | [`03-report-studio.md`](03-report-studio.md) | Report Studio: split preview, outline, celle, template, inserimento output, knit manager | 0, 2 |
| **4** | [`04-workbench.md`](04-workbench.md) | Script multi-buffer, Console, Output cards, Environment, dashboard modelli | 0 |
| **5** | [`05-navigation-dialogs-workflows.md`](05-navigation-dialogs-workflows.md) | Palette evoluta, preferiti, preset dialoghi, workflow guidati | 0–4 |
| **6** | [`06-help-i18n-onboarding.md`](06-help-i18n-onboarding.md) | Help full-text, “Try it”, mappa errori, tour, italiano, cambio lingua | 0 |
| **7** | [`07-platform-plugins-quality.md`](07-platform-plugins-quality.md) | Progetto `.rcmdrproj`, autosave/recovery, performance, Plugin SDK v2, QA | 0–6 |
| **8** | [`08-hardening-menus-plugins.md`](08-hardening-menus-plugins.md) | Debito del menu, accessibilità, robustezza e ciclo di vita dei plugin | 0–7 |
| **9** | [`09-ggplot-integration.md`](09-ggplot-integration.md) | ggplot2 di prima classe: 11 tipi, mapping estesi, temi, facet, scale | 0–8 |

Dopo l'Onda 0, le ondate 1–3 sono parallelizzabili. L'ordine consigliato resta
**Data → Charts → Report** perché il Chart Studio riusa il modello dati e il
Report Studio riusa la galleria grafici.

**Onda 0 completata il 14 novembre 2026.** Il diario di handoff è
[`diary/wave-00-foundations.md`](diary/wave-00-foundations.md).

**Onda 1 completata il 14 novembre 2026.** Il diario di handoff è
[`diary/wave-01-data-studio.md`](diary/wave-01-data-studio.md).

**Onda 2 completata il 14 novembre 2026.** Il diario di handoff è
[`diary/wave-02-chart-studio.md`](diary/wave-02-chart-studio.md).

**Onda 3 completata il 14 novembre 2026.** Il diario di handoff è
[`diary/wave-03-report-studio.md`](diary/wave-03-report-studio.md).

**Onda 4 completata il 14 novembre 2026.** Il diario di handoff è
[`diary/wave-04-workbench.md`](diary/wave-04-workbench.md).

**Ordine di grandezza:** 35–45 settimane-uomo per una persona esperta. Non è
una stima contrattuale.

---

## 6. Dipendenze

### Nuovi `Imports` proposti

| Pacchetto | Motivo | Fallback |
|---|---|---|
| `commonmark` | Anteprima Markdown del Report Studio | Renderer `<pre>` già presente |
| `yaml` | File progetto, preset, front matter | Parser interno già presente |
| `bsicons` | Iconografia coerente con Bootstrap 5 | Testo/emoji |
| `shinyjs` | Focus, enable/disable, show/hide | JS custom |
| `sortable` | Riordino drag-and-drop | Pulsanti su/giù |
| `later` | Debounce e scheduling | `reactiveTimer` |

### Nuovi `Suggests` proposti

| Pacchetto | Motivo |
|---|---|
| `svglite` | Export SVG dei grafici |
| `styler` | Formattazione codice nello Script |
| `cicerone` | Tour guidati, se non si vuole un tour custom |
| `colourpicker` | Selettore colori nel Chart Studio |

Restano `Suggests` già presenti: `plotly`, `rmarkdown`, `knitr`, `rgl`,
`lattice`, `ggplot2`, `car`, `lme4`, `effects`, `vdiffr`, `pkgdown`.

### Da evitare salvo necessità concreta

`reactable` (DT è sufficiente), `shinyWidgets` (selectize + JS coprono i casi),
`promises`/`future`/`callr` per esecuzione in background (condivisione dello
stato fragile). Meglio busy state e progresso onesto.

---

## 7. Definition of Done

Per ogni ondata e per ogni task rilevante:

- [ ] Ogni mutazione dei dati o analisi produce un comando R.
- [ ] I comandi esistenti restano identici nei golden test.
- [ ] Unit test per le funzioni pure; integration/E2E per il flusso principale.
- [ ] `R CMD check` pulito su core e plugin; help inventory e link checker verdi.
- [ ] Topic di help + vignetta + screenshot per le funzioni nuove.
- [ ] Accessibilità: tastiera, focus visibile, ARIA, contrasto.
- [ ] Performance misurata e documentata; nessun leak evidente.
- [ ] Feature flag e modalità Classica non regrediscono.
- [ ] Nessuna nuova procedura statistica.

---

## 8. Registro dei rischi

| Rischio | Probabilità | Impatto | Mitigazione |
|---|---|---|---|
| Le anteprime eseguono codice e sporcano lo stato | Media | Alto | Preview in ambiente isolato, dry-run, test di non interferenza |
| `app.R` diventa un monolite ingestibile | Alta | Alto | Moduli Shiny separati per studio |
| Regressioni sui comandi esistenti | Media | Alto | Golden test invariati; nuove funzioni opt-in |
| Plugin rotti dall'API 2.0 | Media | Alto | API additiva, versionata, test su tutti i plugin |
| Performance su dataset grandi | Alta | Medio | Soglie, server-side, lazy loading, cache |
| Cambio lingua live troppo invasivo | Media | Basso | Rende reattivi menu/pannelli; fallback restart |
| Rebranding confuso | Bassa | Medio | Package stabile; cambia il nome prodotto/UI |
| Scope creep | Alta | Alto | Ondate, feature flag, Definition of Done |

---

## 9. Tracciamento

- [`CHECKLIST.md`](CHECKLIST.md): tutte le task con stato e note.
- [`DECISIONS.md`](DECISIONS.md): ADR e motivazioni.
- Ogni documento di settore contiene: stato attuale, stato target,
  architettura, task, regole di riproducibilità, test, criteri di accettazione,
  rischi e fuori perimetro.

Legenda stato:

| Simbolo | Significato |
|---|---|
| `[ ]` | Da fare |
| `[~]` | In corso |
| `[x]` | Fatto |
| `[!]` | Bloccato |
| `[-]` | Rinviato / fuori perimetro |

---

## 10. Handoff tra ondate

Alla fine di ogni ondata il contesto della sessione viene compattato
dall'utente. Il passaggio tra ondate è quindi governato da un **diario di
handoff** che deve essere completo e autosufficiente.

### Protocollo di chiusura ondata

Prima della compattazione del contesto:

1. Aggiornare `CHECKLIST.md` con stato, commit e note.
2. Creare `docs/upgrades/diary/wave-XX-<slug>.md` usando
   [`diary/TEMPLATE.md`](diary/TEMPLATE.md).
3. Inserire nel diario almeno:
   - obiettivo e risultato dell'ondata;
   - commit prodotti;
   - file creati/modificati;
   - test eseguiti e risultato;
   - decisioni prese e ADR aggiornati;
   - deviazioni dal piano;
   - problemi noti e blocchi;
   - domande aperte;
   - prossimi passi esatti, con ID task;
   - comandi per verificare la baseline.
4. Aggiornare il documento di settore se lo scope è cambiato.
5. Committare e pushare il diario.
6. Comunicare all'utente: “diario pronto, puoi compattare il contesto”.

### Protocollo di apertura ondata

All'inizio dell'ondata successiva:

1. Leggere il diario più recente, `CHECKLIST.md` e il documento di settore.
2. Eseguire i test di baseline indicati nel diario.
3. Riprendere dai “Prossimi passi” del diario.
4. Non assumere che il contesto precedente sia disponibile: il diario è la
   fonte di verità.

### Regola

> Se non è nel diario, non è successo. Il diario è il contratto di handoff tra
> una sessione e la successiva.

---

## 11. Come aggiornare questi documenti

1. Una modifica di scope aggiorna il documento di settore **e** `CHECKLIST.md`.
2. Una decisione architetturale nuova diventa un ADR in `DECISIONS.md`.
3. Un task chiuso cita il commit o la PR nella colonna “Note” della checklist.
4. I criteri di accettazione non si cancellano: si spostano in “Fuori
   perimetro” con una motivazione.
5. La chiusura di ogni ondata produce un diario in `docs/upgrades/diary/`.

---

## 12. Milestone

| Milestone | Contenuto | Criterio |
|---|---|---|
| **M0 — Studio shell** | Onda 0 | Palette, cronologia, anteprima comando, modalità Studio/Classica |
| **M1 — Data Studio beta** | Onda 1 | Import → filtro → edit → nuova colonna → undo → export |
| **M2 — Chart Studio beta** | Onda 2 | Build → preview → apply → gallery → export |
| **M3 — Report Studio beta** | Onda 3 | Template → insert → preview → knit → download |
| **M4 — Workbench beta** | Onda 4 | Console, output cards, environment, dashboard modelli |
| **M5 — Studio 2.0** | Onde 5–7 | Navigazione, help, progetto, performance, Plugin SDK v2 |
