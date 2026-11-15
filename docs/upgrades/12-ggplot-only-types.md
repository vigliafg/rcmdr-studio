# Onda 12 — Tipi ggplot-only

**Data:** 2026-11-15
**Stato:** implementata (2.5.0)
**Baseline:** RcmdrShiny 2.4.0
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Aggiungere al Chart Studio gli oggetti statistici che esistono solo in ggplot2 e
non hanno un equivalente Rcmdr: violino, ECDF, densità 2D e heatmap. I tipi
sono disponibili **solo** con l'engine ggplot2; il motore base li rifiuta con un
messaggio esplicito.

## 2. Task

| ID | Tipo | Mapping | Opzioni | Comando |
|---|---|---|---|---|
| G12.1 | Violino | numerica, gruppo?, facet | trim, scale, adjust, boxplot sovrapposto | `geom_violin` (+ `geom_boxplot`) |
| G12.2 | ECDF | numerica, gruppo?, facet | pad, stile linea | `stat_ecdf` |
| G12.3 | Densità 2D | x, y numeriche, facet | bins, bandwidth, punti | `geom_density_2d` (+ `geom_point`) |
| G12.4 | Heatmap | x, y, valore numerico, facet | colori basso/alto, valori | `geom_tile` + `scale_fill_gradient` |

## 3. Architettura

- Ogni tipo dichiara `engines` (`"ggplot2"` per questi quattro; default
  `c("base","ggplot2")` per gli altri).
- `chart_type_choices(engine)` filtra le scelte; la UI aggiorna la select quando
  cambia engine e riporta a `histogram` se il tipo corrente non è disponibile.
- `chart_type_available(id, engine)` e la validazione rifiutano l'engine base.
- L'Advanced dialog non esiste per questi tipi: il pulsante mostra “No advanced
  dialog is available”.
- Palette: il violino e l'ECDF usano le palette discrete; la heatmap usa
  `scale_fill_gradient(low, high)`.

## 4. Fuori perimetro

- Facet grid a due variabili.
- Heatmap con raggruppamento/annotazioni arbitrarie.
- Altri oggetti ggplot-only (contour filled, ribbon, errorbar dedicati).

## 5. Criteri di chiusura

- I quattro tipi generano comandi validi, passano validazione e preview.
- Il base engine li rifiuta con messaggio.
- Scelte UI filtrate per engine e round-trip.
- Test, documentazione, suite e check verdi.
