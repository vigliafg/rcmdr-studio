# Onda 11 — Completamento degli altri tipi

**Data:** 2026-11-15
**Stato:** implementata (2.4.0)
**Baseline:** RcmdrShiny 2.3.0
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Completare le opzioni degli otto tipi rimasti dopo boxplot, istogramma e
scatter: densità, linee, barre, dot plot, strip chart, QQ, medie, xyplot. Per
ogni tipo le opzioni sono esposte in entrambi gli engine quando hanno senso;
dove il motore base non le supporta, restano specifiche ggplot2 e documentate.

## 2. Task

| ID | Tipo | Opzioni aggiunte | Base | ggplot2 |
|---|---|---|---|---|
| G11.1 | Densità | kernel, adjust, rug, grid | ✅ | adjust |
| G11.2 | Linee | line type (line/step/area), linetype, linewidth, gruppo | gruppo ignorato | ✅ |
| G11.3 | Barre | width, statistic (count/percent) | — | ✅ |
| G11.4 | Dot plot | bin (base), binaxis, stackdir, dotsize, binwidth | ✅ bin | ✅ |
| G11.5 | Strip | method, jitter width/height, shape | ✅ method | ✅ |
| G11.6 | QQ | distribuzione, linea, envelope, grid | ✅ tutti | distribuzione e linea |
| G11.7 | Medie | connect, error width, point size | ✅ connect | ✅ tutti |
| G11.8 | XYplot | type (p/l/b), layout, smooth | ✅ | ✅ |

## 3. Regole

- I default restano **identici** ai comandi precedenti: gli argomenti nuovi
  compaiono solo quando cambiati.
- Le opzioni non supportate dal motore base sono etichettate “(ggplot2)” e non
  entrano nel comando base.
- `cmd_qqplot` omette `distribution="norm"` perché è già il default di
  `car::qqPlot`.
- `cmd_xyplot` con smooth produce `type="smooth"` o `c("p","smooth")`.

## 4. Fuori perimetro

- Nuovi tipi ggplot-only (violin, ECDF, area): valutabili in un'onda separata.
- Banda di confidenza per tipi base diversi dallo scatter.
- Campo “argomenti R aggiuntivi” persistito.

## 5. Criteri di chiusura

- Default invariati e test dei nuovi argomenti.
- Preview/apply verdi per i tipi toccati.
- Documentazione e check aggiornati.
