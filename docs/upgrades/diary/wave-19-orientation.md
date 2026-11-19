# Diario di handoff — Onda 19 — Orientamento

**Data:** 2026-11-19  
**Stato:** lotto 1 completato (O1–O3); prossimo lotto O4–O6  
**Baseline:** RcmdrShiny Studio 3.0.0 (Onda 18)  
**Documento di settore:** [`19-orientation.md`](../19-orientation.md)  
**ADR:** [`DECISIONS.md`](../DECISIONS.md) — ADR-019  
**Onda precedente:** [`wave-18-desktop-workspace.md`](wave-18-desktop-workspace.md)

---

## 1. O1 — Verità sul filtro · `1184e0e`

**File:** `R/data-studio.R`, `R/app.R`, `inst/i18n/it.tsv`,
`tests/testthat/test-data-studio-grid.R`.

- Nuovo `data_filter_label()`: descrive il filtro dalla terna
  `column`/`value`/`dates` e restituisce `""` quando non c'è filtro.
- Nuovo `data_view_state()`: righe visibili, totale, colonne, `filtered` e
  `filter_label`. È puramente descrittivo e non tocca il filtro.
- Nuovo `data_view_shape()`: forma breve per la status bar
  (`1 of 4 x 2`) e lunga per `data_info`
  (`1 of 4 rows x 2 columns, 2 cells`).
- `data_grid_plan()` resta la decisione sulle soglie e legge il dataset
  intero: il paging server-side è una proprietà del dataset, non della vista.
- `data_info` e status bar leggono la vista: con un filtro attivo nessuna
  delle due mostra più il solo totale. Se il filtro non riduce le righe, il
  conteggio non si ripete, ma la chip dice che il filtro è attivo.
- La status bar aggiunge `filter: <label>` come fatto separato.
- Test: helper puri (filtro testo, intervallo date, filtro che non riduce) e
  un `testServer` con filtro attivo che verifica `1 of 4 x 2` e
  `filter: a 2`.

**Deviazione:** in O1 il filtro è testo semplice; la chip arriva in O2, come
previsto dal piano.

---

## 2. O2 — Grammatica visiva dello stato · `2fe2d57`

**File:** `R/ui-components.R`, `inst/www/css/20-components.css`,
`R/app.R`, `inst/i18n/it.tsv`, `tests/testthat/test-orientation.R`.

- `context_chip(text, icon, tone)` è un **wrapper sottile di `badge()`**, non
  un secondo sistema di badge: la grammatica condivide classi, token e test
  di contrasto già esistenti.
- Nuovo tono `accent` per "sei qui": bordo `--rcmdr-accent`, superficie e
  testo del corpo, così il contrasto resta quello misurato.
- Sette icone inline nuove: `file`, `folder`, `arrow`, `funnel`, `lock`,
  `server`, `undo` (`plus` esisteva già). Nessuna dipendenza, nessun CDN.
- I limiti in `data_info` diventano chip: `editing disabled` (warning,
  lucchetto) e `server-side paging` (neutra, server).
- La chip del filtro in status bar usa l'imbuto.
- Test: ogni icona è SVG con `aria-hidden`; ogni chip ha testo oltre al
  colore; il tono `accent` usa solo token, senza colori letterali.

**Deviazione:** le icone sono sette, non otto, perché `plus` era già nel set.

---

## 3. O3 — Riga di contesto nelle viste · `1f520a4`

**File:** `R/workspace.R`, `R/app.R`, `inst/www/css/10-shell.css`,
`inst/i18n/it.tsv`, `tests/testthat/test-orientation.R`.

- `workspace_context_line()` costruisce una riga sola:
  `Studio · <vista>` + chip dataset + chip filtro (solo Data Studio) + chip
  `Rows`/`Cells`.
- La riga è **testo, non un controllo**: nessun tab stop in più, nessun
  pulsante. La pulizia del filtro resta nella toolbar.
- `workspace_context_ui` è renderizzata nella shell Studio, sotto la view bar;
  la modalità Classica non la vede perché non usa `workspace_shell_ui`.
- CSS: riga da 28 px, chip inline, `overflow-x: auto` sotto 992 px.
- Test: la riga nomina luogo, dataset e filtro; ogni vista ha il suo luogo;
  nessun elemento focalizzabile; il server la rende con `main_tabs = "data"`.

**Deviazione:** la chip del filtro non è cliccabile. Il piano la ammetteva
come opzione; tenerla statica evita un tab stop in più e lascia **Clear
filter** nel posto in cui l'utente lo cerca.

---

## 4. Verifica

| Controllo | Esito |
|---|---|
| Suite completa | `EXIT=0`; 0 failure; 29 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w19-lotto1.log`) |
| `node --check` | verde sul JS composto (`/tmp/opencode/app-o3.js`) |
| Filtro | `1 of 4 x 2` in status bar e `1 of 4 rows x 2 columns, 2 cells` in `data_info` |
| Chip | testo sempre presente; icone decorative; tono accent senza colori letterali |
| Contesto | 8 viste coperte; nessun controllo nella riga |
| Classic | nessuna regola nuova applicata; shell Classica invariata |

---

## 5. Problemi noti e rinvii

| Problema | Impatto | Rinvio |
|---|---|---|
| Limiti ancora in `data_info` e non nella riga di contesto | lieve duplicazione con le chip | O4/O8 |
| La status bar ha ancora dodici fatti | leggibilità a zoom 200% | O4 |
| Nessuna intestazione dei due slot | split ambiguo | O5 |
| `Esc` e reset incoerenti | ritorno imprevedibile | O6 |
| Nessun browser | resa visiva non verificata | test manuale su desktop |

---

## 6. Prossimo passo

Lotto 2: **O4** status bar a priorità, **O5** intestazioni degli slot,
**O6** ritorno prevedibile. Handoff dopo O6.
