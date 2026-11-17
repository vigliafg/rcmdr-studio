# Diario di handoff — Onda 15 — Rifacimento visivo dell'interfaccia

**Data:** 2026-11-17  
**Stato:** parziale — U0 completata, U1–U5 da fare  
**Ondata precedente:** `wave-14-dependencies.md` (Onda 14, 2.7.0)  
**Ondata successiva:** Onda 15 — continuazione (U0.4 → U1 → U5)  
**Documento di settore:** [`15-ui-refresh.md`](../15-ui-refresh.md)  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo dell'ondata:** aspetto contemporaneo senza riscrivere l'app —
stessi comandi, stessi ID, stessi test di semantica; CSS e JS fuori da
`R/app.R`; controlli, dialoghi e viste con una sola grammatica visiva.

**Risultato effettivo (U0):**

- il foglio di stile non è più una stringa dentro `R/app.R`: 1.053 righe in
  8 file di `inst/www/css/`, lette e inlineate da `app_css()`;
- lo script non è più una stringa: 698 righe in 8 file di `inst/www/js/`,
  inlineate da `app_js()`;
- esiste `rcmdr_icon()` con 17 icone SVG inline, senza nuove dipendenze;
- il working tree è stato committato (densità, id delle viste, tab strip,
  hint del risultato) e la suite è verde.

**Cosa è pronto:** U0.1, U0.2, U0.3. La base tecnica per U1–U5.

**Cosa non è pronto:** nessun cambiamento visibile. I token non sono ancora
estesi, i componenti non sono ancora migrati, i dialoghi hanno il chrome di
prima.

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `151d1cf` | `feat: compact density, stable view ids and window-style tabs` | lavoro pendente dell'utente, committato come step 0 |
| `eece2fe` | `test: make the benchmark smoke test independent of installed plugins` | sblocca la baseline verde |
| `5e1a385` | `docs: plan the interface refresh (wave 15)` | piano, roadmap, checklist |
| `658abf9` | `refactor(ui): move the stylesheet out of app.R into inst/www/css` | U0.1 |
| `40990e5` | `refactor(ui): move the inline JavaScript out of app.R into inst/www/js` | U0.2 |
| `093df03` | `feat(ui): add a dependency-free inline icon set` | U0.3 |

---

## 3. File creati e modificati

### Creati

- `inst/www/css/00-tokens.css` (256 righe, palette e densità)
- `inst/www/css/10-shell.css` (59)
- `inst/www/css/20-components.css` (193)
- `inst/www/css/30-forms.css` (139)
- `inst/www/css/40-dialogs.css` (148)
- `inst/www/css/50-widgets.css` (77)
- `inst/www/css/60-views.css` (135)
- `inst/www/css/70-refine.css` (47)
- `inst/www/js/00-boot.js` (32)
- `inst/www/js/10-dialogs.js` (135)
- `inst/www/js/20-theme.js` (79)
- `inst/www/js/30-script.js` (96)
- `inst/www/js/40-interactions.js` (99)
- `inst/www/js/50-menubar.js` (107)
- `inst/www/js/60-help.js` (43)
- `inst/www/js/70-keyboard.js` (107)
- `tests/testthat/test-ui-components.R`
- `docs/upgrades/15-ui-refresh.md`
- `docs/upgrades/diary/wave-15-ui-refresh.md` (questo file)

### Modificati

- `R/app.R`: `app_css()` e `app_js()` sono compositori; aggiunti `app_asset()`
  e `app_asset_text()`. Circa 1.750 righe in meno.
- `R/ui-components.R`: `rcmdr_icon_paths()` e `rcmdr_icon()`.
- `tests/testthat/test-performance.R`: conteggio righe del benchmark derivato
  dai plugin installati.
- `docs/upgrades/README.md`, `docs/upgrades/CHECKLIST.md`: indice e stato.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Suite completa | `testthat::test_local()` | verde, `EXIT=0`; 22 skip e2e, 3 warning noti |
| Densità | `test_local(filter="density")` | verde |
| Accessibilità | `test_local(filter="accessibility")` | verde |
| Integrazione app | `test_local(filter="app-integration")` | verde (warning rgl senza X11) |
| Componenti UI | `test_local(filter="ui-components")` | verde |
| Equivalenza CSS | script di split | 1.046 righe non vuote identiche a prima, a meno del blocco token |
| Equivalenza JS | script di split | 685 righe non vuote identiche a prima |
| UI servita | `renderTags(app_ui())` | CSS e JS presenti in `<head>` (78 KB) |

**Artefatti:** `/tmp/opencode/tests-u0.log` (suite), `/tmp/opencode/split_css.R`
e `split_js.R` (script usa-e-getta di estrazione).

---

## 5. Decisioni e ADR

- **Asset inline, non `htmlDependency()`.** `system.file("www", ...)` +
  `readLines` + `<style>`/`<script>`: identico sotto pkgload e da installato,
  nessun `addResourcePath()`, nessun URL da rompere, test che leggono
  `app_css()` ancora validi. Si passa a `htmlDependency()` solo quando
  serviranno font o immagini.
- **Blocco token in testa.** Nel CSS l'unico riordino è lo spostamento delle
  palette: sono definizioni di custom property più due regole di tema, quindi
  la cascata non cambia. Verificato riga per riga.
- **Split contiguo, non semantico.** Per U0 i file sono blocchi contigui presi
  dagli ancoraggi esistenti: l'obiettivo era togliere le stringhe da `app.R`
  senza toccare il CSS. La riorganizzazione per strati è U1.
- **Icone proprie, non `bsicons`.** 17 icone stroke 24×24 con
  `currentColor`, decorative per default (`aria-hidden`), nominabili con
  `title` (`role="img"` + `aria-label`). Nessun nuovo `Imports`.
- **Nessun `R CMD check` in questo batch.** La suite è verde; il check
  completo si esegue alla chiusura di U1.

Nessun ADR nuovo: sono decisioni di implementazione coerenti con l'ADR sulla
leggerezza delle dipendenze (Onda 14).

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| U0.1 | file per strato (tokens/base/layout/…) | file per blocchi contigui con nomi per contenuto | garantire testo identico; la tassonomia è U1 |
| U0.3 | set Bootstrap Icons | set stroke proprio | nessuna dipendenza e nessun asset da scaricare |
| — | non previsto | fix del test benchmark | la suite non era verde su una macchina con i 16 plugin installati |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| `test-app-integration` avverte su rgl senza X11 | nessuno | `rgl.useNULL()`; warning già presente prima | — |
| 22 test e2e saltati senza `RCMDRSHINY_E2E=1` | copertura browser non esercitata in questo batch | eseguirli prima della chiusura di U3 | U3 |
| `app_asset()` ha un fallback su `inst/www` relativo alla CWD | solo per sessioni senza pkgload | usare `pkgload::load_all()` come fa `start.sh` | — |
| `R/app.R` è ancora il file più grande (shell + server) | manutenzione | fuori perimetro di questa onda | — |

---

## 8. Domande aperte

- [ ] I token di tipografia vanno in `00-tokens.css` o in un nuovo
      `05-typography.css`? Decisione rimandata a U1.1.
- [ ] Le icone entrano nella topbar già in U1 o solo in U2.3? Il piano dice
      U2.3; nessuna urgenza.

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. **U0.4** — `docs/upgrades/UI-TOKENS.md`: scala tipografica, spaziature,
   raggi, ombre, altezze, stati, elenco dei token esistenti e dei nuovi.
2. **U1.1** — scala tipografica e spaziature in `00-tokens.css` /
   `30-forms.css`, senza cambiare i valori attuali dei 2 temi base.
3. **U1.2** — altezza uniforme dei controlli (`--rcmdr-control-h`) e anello di
   focus unico; verifica sui temi chiaro e scuro.

Poi, nella sessione successiva: U1.3 (bottoni), U1.4 (test di contrasto),
U2.1 (helper di form).

### Task dell'ondata

| ID | Task | Priorità | Note |
|---|---|---|---|
| U0.4 | `UI-TOKENS.md` | alta | sblocca U1 |
| U1.1 | Scala tipografica e spaziature | alta | token, non valori |
| U1.2 | Controlli uniformi e focus | alta | 8 temi |
| U1.3 | Varianti bottone | media | primario/secondario/ghost |
| U1.4 | Test di contrasto | alta | ≥ 4.5:1 |
| U2.1–U2.4 | Componenti e shell | media | dopo U1 |
| U3.1 | Chrome + *Options* | alta | prima pillola visibile |

---

## 10. Comandi per riprendere

```bash
cd ~/Documenti/GitHub/rcmdr-studio
git status
git log --oneline -6
Rscript -e 'testthat::test_local(filter="density|accessibility|ui-components")'
Rscript -e 'pkgload::load_all("."); cat(nchar(as.character(app_css())), "\n")'
```

**Baseline attesa:** suite completa verde (`EXIT=0`), 22 skip e2e, nessun
failure. `app_css()` ≈ 51 KB, `app_js()` ≈ 27 KB, entrambi in `<head>`.

---

## 11. Note di contesto

- L'anteprima di direzione visiva è in `/tmp/opencode/rcmdr-design-preview/`
  (`app.R` + `current.css`); i server temporanei erano su 3838 (app reale) e
  3839 (anteprima). Non fanno parte del repository.
- Gli screenshot di riferimento: `/tmp/opencode/preview-light.png` e
  `preview-dark.png`.
- Il protocollo concordato con l'utente: **tre step, poi stop**; l'utente
  compatta il contesto e la sessione riprende da questo diario.
- I test e2e si eseguono con `RCMDRSHINY_E2E=1` e non sono stati eseguiti in
  questo batch.
- `app_css()` compone i file nell'ordine di `app_css_files()`; aggiungere un
  file significa aggiornare quella funzione, non toccare `app_ui()`.

---

## 12. Aggiornamenti alla checklist

- [x] `CHECKLIST.md` aggiornata (U0.1–U0.3).
- [x] Documento di settore coerente (U0.3 corretto).
- [x] Diario scritto.
- [ ] Diario committato e pushato.
- [ ] Utente informato: “diario pronto, puoi compattare il contesto”.
