---
id: report-studio
title: Report Studio
type: task
category: report
keywords: [report, rmarkdown, rmd, knitr, documento, anteprima, knit, modello, yaml, bibliografia, autosalvataggio, cella]
aliases: [report-studio, rmd-studio]
dialogs: [reportYaml, reportTemplate, newRmd, compileRmd, insertSection, insertChunk]
commands: [rmarkdown::render, knitr::kable, knitr::include_graphics]
packages: [rmarkdown, knitr, commonmark, yaml]
related: [document-authoring, exporting-results, data-studio, chart-studio]
language: it
status: documented
---

# Report Studio

La scheda **Report** gestisce documenti R Markdown con registro, outline,
anteprima veloce, celle eseguibili, template, knit e autosalvataggio.

## Ciclo di lavoro

1. Creare un documento da **File > Nuovo documento R Markdown...** o da un
   template della galleria.
2. Scrivere testo e chunk nell'editor; l'outline mostra le sezioni.
3. Usare **Inserisci** per aggiungere output, grafici, comandi della cronologia,
   tabelle, profili di colonna o modelli.
4. Controllare l'anteprima: non esegue il codice, quindi è veloce.
5. Eseguire una cella con il pulsante dedicato per vedere l'output inline.
6. Fare il knit e scaricare il risultato.

## Template

La galleria propone report generici, report di analisi, report di dati e
template per la didattica. Un template è un punto di partenza modificabile, non
un formato rigido.

## YAML e bibliografia

Il modulo YAML conserva titolo, autore, data, output e bibliografia. Le chiavi
non riconosciute restano nel documento, così il round-trip non perde opzioni.

## Knit

Il gestore del knit mostra formato, file prodotti, data e messaggi di errore.
Gli errori citano il chunk e la riga; se manca pandoc, il messaggio rimanda
all'argomento di diagnostica.

## Autosalvataggio e recupero

Il documento viene salvato periodicamente nella directory di sessione. Se
l'applicazione si chiude, il banner di recupero propone l'ultima copia. Il file
originale non viene sovrascritto senza conferma.

## Vedi anche

- `topic:document-authoring`
- `topic:exporting-results`
- `topic:chart-studio`
