---
id: workbench
title: Workbench
type: task
category: workbench
keywords: [script, console, output, messaggi, ambiente, oggetti, modelli, celle, diagnostica, riesegui, formatta, autosalvataggio, AIC, BIC]
aliases: [script-studio, console-studio, environment-studio, model-registry, models-dashboard]
dialogs: [environmentSave, modelExport]
commands: [summary, str, plot, rm, saveRDS, save, AIC, BIC]
packages: [styler]
related: [report-studio, data-studio, chart-studio, exporting-results]
language: it
status: documented
---

# Workbench

Il Workbench raccoglie gli strumenti di lavoro quotidiano: script, console,
output, messaggi, ambiente e registro dei modelli. Tutte le schede condividono
lo stesso motore di comandi.

## Script

- Più documenti aperti, con celle eseguibili.
- Esecuzione della cella, del codice sopra e del codice sotto.
- Outline delle sezioni e diagnostica di sintassi.
- Ricerca e sostituzione, completamento e formattazione opzionale con `styler`.
- Autosalvataggio e recupero.

## Console

La console accetta comandi R come il prompt. I comandi sono registrati nella
cronologia e nell'output con lo stesso formato dei dialoghi. I prompt interattivi
non possono essere gestiti dal browser: la console li blocca e lo segnala.

## Output e messaggi

Le card dell'output mostrano stato, durata, comando e risultato, con azioni per
rieseguire, aprire il dialogo, copiare o inserire nello script. I messaggi sono
raggruppati per gravità e filtrabili.

## Ambiente

L'explorer elenca oggetti, dataset e modelli. L'anteprima di un oggetto è in
sola lettura; le azioni rapide (riepilogo, `str`, grafico, salvataggio, rimozione)
generano comandi esistenti.

## Registro dei modelli

La dashboard confronta i modelli con AIC, BIC e differenze; le azioni aprono i
dialoghi o inseriscono i comandi nel report.

## Vedi anche

- `topic:report-studio`
- `topic:data-studio`
- `topic:chart-studio`
