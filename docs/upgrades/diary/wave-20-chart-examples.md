# Diario di handoff — Onda 20 — Esempi dal R Graph Gallery

**Data:** 2026-11-19  
**Stato:** completata (3.2.0)  
**Decisione:** ADR-020  
**Piano:** [`../20-chart-examples.md`](../20-chart-examples.md)

---

## 0. Punto di ripresa

**Stato:** branch `main`, modifica chiusa, suite verde.

**Baseline:** RcmdrShiny Studio 3.1.0 (Onda 19).

**Prossimo task:** nessuno per questa onda. I tipi P2/P3 restano per l'Onda 21
o per un plugin.

---

## 1. Risultato

- Il Chart Studio ha una quarta modalità **Examples** con 28 ricette curate,
  anteprime locali e link alla R Graph Gallery.
- Il dettaglio mostra descrizione, fonte, codice e **Apri nel builder**.
- Il loader è condiviso con **Models**: una sola strada per una ricetta.
- Otto tipi nuovi: lollipop, dumbbell, doughnut, area impilata, ridgeline e
  beeswarm.
- `ggridges` e `ggbeeswarm` sono in `Suggests`; i tipi compaiono solo se
  installati. Nessuna dipendenza obbligatoria nuova.
- Help inglese e italiano aggiornati: motore unico ggplot2, Examples, tipi
  estesi.

---

## 2. File principali

- `R/chart-examples.R` — registro, dati, spec, codice, mapping, filtri.
- `R/chart-examples-ui.R` — toolbar, griglia, dettaglio, server.
- `R/chart-types-extra.R` — sei descrittori.
- `R/chart-studio.R` — quarta modalità, loader condiviso, server Examples.
- `R/chart-ggplot.R` — layer dei nuovi tipi, fix `chart_option_input_id()`.
- `R/chart-spec.R` — titoli dei nuovi tipi.
- `R/chart-types.R` — `chart_type_ids()` e registrazione.
- `tools/build_chart_examples.R` — build e `--check`.
- `inst/www/chart-examples/` — 26 PNG, manifest, NOTICE.
- Test: `test-chart-examples.R`, `test-chart-types-extra.R`, aggiornamenti a
  `test-chart-ggplot.R`.

---

## 3. Deviazioni dal piano

| Punto | Piano | Reale |
|---|---|---|
| Catalogo | 20 esempi | 26: 20 sui tipi esistenti + 6 sui tipi nuovi |
| Tipi | P1 e P2 | P1 senza dipendenze + ridgeline/beeswarm (package installati) |
| Radar | previsto P1 | aggiunto con un generatore di codice che chiude il poligono |
| Altri P2 | treemap, waffle, parallel, dendrogram | rinviati: package non installati o modello dati dedicato |
| Manifest | checksum | la verifica controlla id e presenza dei file: il PNG non è deterministico per metadati |

---

## 4. Verifiche

| Verifica | Esito |
|---|---|
| `testthat::test_local()` | `EXIT=0`; 0 failure; 29 e2e saltati; 3 warning noti (`/tmp/opencode/tests-w20-pre.log`) |
| `node --check` | verde (`/tmp/opencode/app-w20.js`) |
| App HTTP | 200 su `http://127.0.0.1:3841/` |
| Anteprime | 28/28; manifest coerente; 850 KB |
| Mapping | solo colonne compatibili; nessun side effect |
| Classic | invariata; nessun test Classic modificato |

---

## 5. Limiti

- La verifica visiva nel browser reale non è disponibile (Chrome 157 non
  naviga http(s)); 29 test e2e restano saltati. Il limite è già registrato in
  `QA-WIDGETS.md` e `ACCESSIBILITY.md`.
- I tipi con package opzionale non hanno anteprima se il package manca; la
  galleria li esclude e il builder non li offre.
- Treemap, waffle, dendrogramma, mappe, network/flow, 3D e animazione
  restano fuori: richiedono un modello dati o un plugin.
- Il manifest usa id + presenza file, non il checksum: la generazione PNG non
  è byte-identica tra esecuzioni.

---

## 6. Prossimo passo

Nessun task obbligatorio. Se si vuole estendere:

1. radar e parallel coordinates come tipi dedicati;
2. treemap/waffle/dendrogramma con package opzionali;
3. mappe e network come plugin, non nel core.
