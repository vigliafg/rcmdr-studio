---
id: help-center
title: Usare il centro assistenza
type: concept
category: help
keywords: [aiuto, ricerca, argomenti, documentazione, guida]
aliases: []
dialogs: []
commands: [help_search, help_topic, help_index]
packages: [RcmdrShiny]
related: [keyboard-shortcuts, glossary, navigation-workflows, writing-help-topics]
language: it
status: documented
---

La scheda **Help** raccoglie gli argomenti del nucleo e dei plugin caricati.
Funziona offline.

## Aprire il centro assistenza

- Fare clic sulla scheda **Help**.
- Usare **Aiuto > Centro assistenza** nella barra laterale.
- Premere **Aiuto** in una finestra di dialogo per aprire l'argomento
  corrispondente.

## Ricerca

Digitare una o più parole. I risultati provengono da un indice full-text che
pesa prima i titoli, poi parole chiave e alias, poi le intestazioni e infine il
corpo del testo. Una corrispondenza esatta del titolo è sempre in cima. Anche
le parole parziali funzionano: `riass` trova "Riassunti numerici".

Ogni risultato mostra tipo, origine (nucleo o plugin), categoria e uno stralcio
con le parole evidenziate. Il filtro **tipo** limita a guide, riferimenti,
tutorial o diagnostica; il filtro **origine** sceglie il nucleo o un singolo
plugin. I filtri si combinano con l'elenco delle categorie e **Cancella filtri**
li azzera.

## Dentro un argomento

- L'indice interno porta alle sezioni della pagina.
- **Dialoghi correlati** apre il dialogo esistente senza uscire dall'aiuto.
- **Comandi citati** elenca le funzioni R dell'argomento.
- **Esempi**: quelli marcati come eseguibili hanno **Esegui**. Il comando viene
  mostrato per conferma e poi eseguito dal normale motore dei comandi, quindi
  compare nella cronologia e nell'output.
- **Inserisci nello script** aggiunge un esempio senza eseguirlo.
- **Copia link** copia il riferimento stabile `topic:<id>`.
- **Segnala un problema** apre un report diagnostico copiabile.

## Errori contestuali

Quando un comando fallisce, la card di errore propone l'argomento più probabile:
oggetti mancanti rimandano all'importazione, funzioni mancanti al caricamento dei
pacchetti, errori sui fattori alla conversione, errori di knit alla creazione del
report.

## Glossario e tour

Il [glossario](topic:glossary) definisce i termini statistici e dell'interfaccia.
Il tour guidato compare al primo avvio e si riavvia da **Aiuto > Tour guidato**.

## Dalla riga di comando

```r
RcmdrShiny::help_search("regressione logistica")
RcmdrShiny::help_topic("linear-model")
RcmdrShiny::help_index()
```

## Vedi anche

- `topic:keyboard-shortcuts`
- `topic:getting-started`
