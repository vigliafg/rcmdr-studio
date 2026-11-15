# Onda 10 — Opzioni grafiche: boxplot, istogramma, scatter

**Data:** 2026-11-15
**Stato:** implementata (2.3.0)
**Baseline:** RcmdrShiny 2.2.0
**Documento padre:** [`README.md`](README.md)

---

## 1. Obiettivo

Colmare i buchi del builder sui grafici più usati, mantenendo il default
identico al comando del dialogo: boxplot completo (base e ggplot2), istogramma
con scala anche in ggplot2, scatter con regressione, banda di confidenza,
ellisse e jitter.

## 2. Task

| ID | Task | Base | ggplot2 |
|---|---|---|---|
| G10.1 | Boxplot: notch, notchwidth, varwidth, orizzontale, outlier, larghezza | ✅ `Boxplot(...)`; orizzontale via `boxplot(...)` | ✅ `geom_boxplot(...)`; orizzontale via `coord_flip` |
| G10.2 | Boxplot: punti sovrapposti | — | ✅ `geom_jitter` |
| G10.3 | Istogramma: frequenza/densità/percentuale | già presente | ✅ `after_stat(density)` / percent |
| G10.4 | Scatter: regressione, ellisse, griglia, jitter | ✅ `regLine`, `ellipse`, `grid`, `jitter=list(...)` | ✅ `geom_smooth(method="lm")`, `stat_ellipse`, jitter |
| G10.5 | Scatter: loess e banda di confidenza | loess con `smooth=TRUE` | ✅ `geom_smooth(method=, se=)` |
| G10.6 | Test, help, NEWS, diario | ✅ | ✅ |

## 3. Compatibilità

- Con le opzioni ai default il comando generato resta **identico** a prima.
- `notchwidth` viene emesso solo con `notch=TRUE`.
- Per il boxplot orizzontale base si usa `boxplot()` (stats) perché
  `car::Boxplot()` rifiuta `horizontal=TRUE`; perde `id=list(method="y")`, che è
  una funzione car.
- Il jitter base è passato come `jitter=list(x=, y=)` perché `car` non accetta
  `jitter=TRUE` con gruppi.

## 4. Fuori perimetro

- Punti sovrapposti nel boxplot base.
- Banda di confidenza esplicita nel boxplot/scatter base oltre a quanto offre
  `car`.
- Altri argomenti non modellati: restano nello script manuale finché non si
  introduce il campo “argomenti R aggiuntivi” (proposta separata).

## 5. Criteri di chiusura

- Test dei comandi con e senza opzioni.
- Preview e apply verdi per base e ggplot2.
- Default invariati.
- Documentazione aggiornata e `R CMD check` OK.
