---
id: chart-studio
title: Chart Studio
type: task
category: graphs
keywords: [grafico, diagramma, builder, anteprima, galleria, tema, palette, esporta, plotly, ggplot2]
aliases: [chart-studio, chart-builder, chart-gallery]
dialogs: [chartRename, chartDelete, chartExport]
commands: [Hist, Boxplot, scatterplot, lineplot, Barplot, plotMeans]
packages: [graphics, RcmdrMisc, car, plotly, ggplot2]
related: [histogram, scatterplot, boxPlot, exporting-results]
language: it
status: documented
---

# Chart Studio

La scheda **Charts** costruisce grafici da una specifica visuale e produce il
comando R corrispondente. L'anteprima è isolata: non registra comandi e non
modifica la galleria finché non si preme **Applica**.

## Costruire un grafico

1. Scegliere il tipo di grafico nella galleria o nel selettore.
2. Indicare variabili, raggruppamenti e opzioni estetiche.
3. Controllare l'anteprima, che si aggiorna con un breve ritardo.
4. Premere **Applica** per registrare il comando e aggiungere il grafico alla
   galleria.

Il comando prodotto è esattamente quello che comparirebbe nello script; il
pulsante **Allo script** lo inserisce senza eseguirlo.

## Galleria

- Ricerca per titolo e tipo.
- Fissa i grafici che vuoi tenere in cima.
- Rinomina ed elimina con i dialoghi esistenti.
- Confronta due grafici affiancati.
- Esporta in PNG, PDF, SVG o HTML.

## Round-trip

La specifica del grafico resta allegata al risultato. **Riapri nel builder**
ripristina tipo, variabili, temi e opzioni senza rieseguire il comando.

## Temi e palette

Il pannello delle opzioni cambia palette, sfondo, dimensione del testo e tema
ggplot2. Le stesse scelte sono incluse nel comando, quindi il grafico è
riproducibile fuori dall'applicazione.

## Vedi anche

- `topic:scatterplot`
- `topic:histogram`
- `topic:exporting-results`
