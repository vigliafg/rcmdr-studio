# QA del rifacimento visivo — Onda 15 (U5)

**Data:** 2026-11-17  
**Ambito:** U5.1 (matrice 8 temi × 2 densità, e2e, screenshot) e U5.2
(tastiera, focus, `Esc`, reduced motion, zoom 200%).  
**Riferimenti:** [`15-ui-refresh.md`](15-ui-refresh.md),
[`UI-TOKENS.md`](UI-TOKENS.md), [`diary/wave-15-ui-refresh.md`](diary/wave-15-ui-refresh.md).

---

## 1. Matrice temi × densità

I temi sono `ui_themes()`: `system`, `light`, `light-warm`, `light-cool`,
`dark`, `dark-dim`, `dark-graphite`, `contrast`. Le densità sono `compact` e
`comfortable`. `system` non è una palette: il client lo risolve in `light` o
`dark` con `prefers-color-scheme`.

`tests/testthat/test-theme-matrix.R` percorre le 16 combinazioni e verifica:

| Controllo | Cosa dimostra |
|---|---|
| accettazione, salvataggio e rilettura | ogni scelta attraversa `set_ui_theme()`/`set_ui_density()` e torna uguale |
| blocchi palette | ogni tema risolve in un blocco `body.rcmdr-*` con i token di base |
| classi del client | ogni tema ha la sua classe (`rcmdr-light`, `rcmdr-dark`, …) e ogni densità la sua (`rcmdr-density-compact`, `rcmdr-density-comfortable`) |
| densità | il blocco comodo contiene solo token di spaziatura, mai un colore; `--rcmdr-control-h` è 2.125rem contro 2.5rem |
| contrasto | testo, testo attenuato, testo sul primario ≥ 4.5:1 e bordo dei controlli ≥ 3:1 in tutte le combinazioni |

Comando:

```bash
Rscript --vanilla -e 'testthat::test_local(filter="theme-matrix|contrast|density|accessibility", reporter="summary")'
```

Esito: **0 failure**. La matrice da sola produce 177 asserzioni; con
`test-contrast.R` e `test-density.R` la copertura dei token è completa.

## 2. Tastiera, focus e movimento

| Requisito | Verifica |
|---|---|
| anello di focus unico | `test-accessibility.R` legge l'unica regola `:focus-visible` e il token `--rcmdr-focus-width` |
| `Esc` e backdrop | il contratto è quello di Bootstrap: la palette e le scorciatoie mantengono `easyClose`, tour e recupero progetto il backdrop statico; nessun `data-bs-keyboard="false"` viene aggiunto dai componenti |
| focus dentro il modale | il guscio è ancora `shiny::modalDialog()`, quindi il focus trap di Bootstrap resta attivo; il chrome viene solo iniettato con `tagQuery()` |
| reduced motion | il blocco `@media (prefers-reduced-motion: reduce)` azzera animazioni, transizioni e scroll fluido |
| reflow a zoom 200% | ogni vista a più colonne (`.rcmdr-shell-body`, `.rcmdr-data-layout`, `.rcmdr-chart-layout`, `.rcmdr-script-workspace`, `.rcmdr-help-layout`, `.rcmdr-report-workspace`) ha un breakpoint che la porta a una colonna |
| palette da tastiera | le frecce e `Enter` sono nel gestore JS; `Ctrl+K` apre, `Esc` chiude |

## 3. e2e nel browser

Comando previsto:

```bash
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript --vanilla \
  -e 'testthat::test_file("tests/testthat/test-wave0-e2e.R")'
```

In questo ambiente il browser non è utilizzabile: `chromote` avvia Chrome ma
`Page.navigate` va in timeout anche su `about:blank`, e un tentativo diretto su
`http://127.0.0.1:3841` restituisce la stessa attesa. Non è un errore
dell'app: i 26 test e2e restano saltati e vanno eseguiti su una macchina con
un Chrome funzionante. La suite R-level (markup, token, CSS, contrasto) è
verde e copre la struttura; l'e2e coprirebbe solo l'interazione reale.

## 4. Screenshot

`tools/help_screenshots.R` è il percorso previsto per le immagini
(`RCMDRSHINY_SCREENSHOTS=1`). In questo ambiente non produce file: Chrome non
carica la pagina e Firefox headless termina senza immagine. Le immagini in
`inst/help-topics/assets/screenshots/` restano quelle precedenti al
rifacimento finché non vengono rigenerate su una macchina con browser
funzionante.

## 5. Checklist manuale (per il controllo visivo)

Con l'app su `http://127.0.0.1:3841`:

- [ ] **Temi**: per ognuno degli 8 temi aprire Home, Data Studio, Chart
      Studio, Report Studio, Script e Help; nessun testo illeggibile, nessun
      bordo invisibile, la hero resta leggibile.
- [ ] **Densità**: con *Compact* e *Comfortable* aprire un dialogo con griglia
      di campi e la palette; i campi restano allineati e il footer non va a
      capo in modo strano.
- [ ] **Dialoghi**: aprire un dialogo del catalogo, poi palette, scorciatoie,
      tour e recupero progetto; la testata è la stessa in tutti.
- [ ] **Tastiera**: `Tab`/`Shift+Tab` nella topbar, nella sidebar e in un
      dialogo; `Ctrl+K`, frecce, `Enter`, `Esc`; `Ctrl+Enter` nello script.
- [ ] **Zoom 200%**: le viste a due o tre colonne si impilano, nessuno
      scorrimento orizzontale.
- [ ] **Reduced motion**: con l'opzione di sistema attiva, aprire un dialogo e
      la palette; nessuna transizione percepibile.
- [ ] **Alto contrasto**: tema *High contrast* su tutte le viste; i bordi dei
      controlli restano visibili.

## 6. Esito

- Matrice 8 × 2: **verde** (R-level).
- Contrasto e bordi: **verde** su tutte le palette.
- Tastiera e focus: **verde** per i contratti R/CSS; l'interazione reale resta
  da confermare con l'e2e.
- e2e: **non eseguibili in questo ambiente** (Chrome headless bloccato).
- Screenshot: **non generabili in questo ambiente**.
