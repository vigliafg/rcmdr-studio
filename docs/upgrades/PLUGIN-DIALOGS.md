# Dialoghi dei plugin — inventario e migrazione (Onda 17, T8)

**Data:** 2026-11-18  
**Ambito:** i 15 plugin in `plugins/`  
**Contratto:** [`../tests/testthat/test-plugin-dialogs.R`](../../tests/testthat/test-plugin-dialogs.R)
e le suite `test-plugins*.R`

---

## 1. API condivisa

I plugin usano già `RcmdrShiny::plugin_dialog()`, `entry_input()`,
`spin_input()`, `combo_input()`, `var_input()`, `radio_input()`,
`checkbox_input()` e `subset_input()`. Per raggruppare i dialoghi lunghi senza
copiare markup, l'API espone ora anche:

- `RcmdrShiny::settings_accordion(id, open, ...)`;
- `RcmdrShiny::settings_panel(title, value, grid = FALSE, ...)`.

Nessun comando, nessun ID di input e nessun `dialog_spec()` è cambiato. I
pannelli richiudono gli stessi controlli che i gestori `on_ok` già leggono.

## 2. Inventario

| Plugin | Dialoghi | Forma | T8 |
|---|---|---|---|
| ROC | 4 (singolo, confronto, logistico, Hosmer-Lemeshow) | 6 gruppi di opzioni | **migrato** ad accordion: Data options, AUC, CI, Plot, Smoothing, Test |
| UCA | 18+ qcc generati | fasi I/II e opzioni | **migrato** ad accordion: Phase I, Phase II, Parameters, Options |
| Export | 3 (xtable, latex, format.df) | 12–17 campi | **migrato** ad accordion: Content, Typesetting/Layout, File/Numbers |
| PcaRobust | 1 | 2 gruppi + testata | **migrato** ad accordion: Variables, Output, Plots |
| sos | 1 | ricerca + filtro | **migrato** ad accordion: Search, Filter |
| DoE | ~20 generati | 3–8 campi per dialogo | resta piatto: il dialogo è già una sola decisione |
| TeachingDemos | 11 generati | 3–5 campi | resta piatto: un accordion nasconderebbe l'intero modulo |
| NMBU | ~10 generati | 3–6 campi | resta piatto: fabbrica di campi brevi |
| EZR | 5+ | 3–5 campi | resta piatto: ogni dialogo è una sola azione |
| survival | 5 | 3–5 campi | resta piatto |
| TeachStat | 5 | 3–5 campi | resta piatto |
| HH | 5 | 3–5 campi | resta piatto |
| KMggplot2 | 4 | 3–4 campi | resta piatto |
| aRnova | 3 | 3 campi | resta piatto |
| FactoMineR | 2 | 2 campi | resta piatto |

**Migrati:** 5 plugin (ROC, UCA, Export, PcaRobust, sos).  
**Non migrati:** 10 plugin, tutti con dialoghi brevi o generati da una lista di
3–6 campi; sono elencati qui sotto e non hanno bisogno di un accordion.

## 3. Perché questi cinque

- **ROC** aveva già sei `fieldset` con legenda: l'accordo conserva la
  semantica dei gruppi e chiude ciò che non serve.
- **UCA** ripete la stessa struttura per 18+ diagrammi; le fasi sono gruppi
  naturali e il parametro di fase decide quali pannelli esistono.
- **Export** è il caso più lungo: 12–17 campi in fila, ora divisi fra contenuto,
  tipografia/layout e file.
- **PcaRobust** aveva due `fieldset` e una testata: i tre pannelli separano
  variabili, output e grafici.
- **sos** separava ricerca e filtro con un `<hr>`: due pannelli sono la stessa
  divisione, con un nome e uno stato di apertura.

## 4. Non migrati

DoE, TeachingDemos, NMBU, EZR, survival, TeachStat, HH, KMggplot2, aRnova e
FactoMineR restano piatti. Le ragioni sono nel § 2: sono dialoghi brevi, o
fabbriche che generano 3–6 campi per una singola decisione. Un accordion
aggiungerebbe un clic e nasconderebbe il modulo senza ridurre la densità.

## 5. Verifica

- `test-plugin-dialogs.R` rende i cinque dialoghi migrati, controlla
  `rcmdr-accordion`, i valori dei pannelli e gli ID dei campi letti da
  `on_ok`.
- Le suite `test-plugins.R`, `test-plugin-sdk.R` e `test-plugins-wave0.R`
  restano verdi.
- I 5 e2e dei plugin restano saltati senza `RCMDRSHINY_E2E=1`.

## 6. Limiti

- Nessun browser: apertura, chiusura e stato dei pannelli non sono stati visti
  a schermo.
- I plugin che non usano gli helper restano fuori per scelta, non per errore.
- Il contract dei plugin non è stato allargato oltre i due helper di layout:
  nessun plugin riceve accesso a stato o server.
