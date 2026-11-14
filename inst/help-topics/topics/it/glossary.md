---
id: glossary
title: Glossario
type: reference
category: help
order: 20
keywords: [glossario, definizioni, termini, terminologia, statistica, interfaccia]
aliases: [definizioni]
dialogs: []
commands: []
packages: [RcmdrShiny]
related: [getting-started, help-center, keyboard-shortcuts, navigation-workflows]
language: it
status: documented
---

# Glossario

Definizioni brevi dei termini statistici e dell'interfaccia usati in RcmdrShiny
Studio. Ogni termine rimanda all'argomento che lo spiega nel contesto.

## Termini dell'interfaccia

### Dataset attivo

Il data frame letto dai dialoghi, dai menu e dall'inspector. Compare nella barra
superiore e nella barra di stato. Scegliere un altro dataset cambia il dataset
attivo, non i dati. Vedi [Data Studio](topic:data-studio).

### Modello attivo

Il modello usato dai menu dei modelli e dai grafici diagnostici. Di solito un
modello fittato da un dialogo diventa attivo. Vedi
[Modello lineare](topic:linear-model).

### Registro dei comandi

L'elenco ordinato dei comandi R generati dall'interfaccia. È il contratto di
riproducibilità: ogni azione produce una o più righe nel registro, che possono
essere copiate nello script o in un report.

### Palette dei comandi

La casella di ricerca aperta con `Ctrl` + `K`. Cerca menu, dialoghi, argomenti
di aiuto, dataset, variabili, workflow e comandi recenti. Vedi
[Palette e workflow](topic:navigation-workflows).

### Memoria del dialogo

I valori che un dialogo ricorda alla riapertura successiva. È stato di sessione,
non un comando, e si cancella con **Reimposta**.

### Preset

Un insieme nominato di valori salvato dall'utente. Applicare un preset riempie
il dialogo ma esegue comunque il dialogo e registra il comando.

### Anteprima

La valutazione isolata di un comando prima della registrazione. Le anteprime non
toccano registro, output o galleria. Vedi [Chart Studio](topic:chart-studio).

### Workflow

Una sequenza guidata che apre dialoghi esistenti e registra i comandi prodotti.
Un workflow non contiene logica statistica propria.

## Termini statistici

### Coefficiente

L'effetto stimato di un predittore in un modello, di solito sulla scala del
predittore lineare. Vedi [Modello lineare](topic:linear-model).

### Intervallo di confidenza

Un intervallo di valori plausibili per un parametro, calcolato a un livello di
confidenza dichiarato. L'interpretazione è frequentista.

### Contrasto

Una combinazione lineare dei livelli di un fattore usata per confrontare i
gruppi. R usa i contrasti treatment per impostazione predefinita; **Dati >
Gestisci variabili > Imposta contrasti...** li cambia per un fattore.

### Gradi di libertà

La quantità di informazione indipendente disponibile per stimare una grandezza.
Compare in test, intervalli e riepiloghi dei modelli.

### Fattore

Un vettore R con un insieme fisso di livelli, usato per le variabili
categoriche. Una colonna di testo non è automaticamente un fattore: usare i
dialoghi di conversione quando una procedura richiede fattori. Vedi
[Conversione delle variabili di testo](topic:converting-character-variables).

### Valore mancante

`NA` in R. La maggior parte dei riepiloghi riporta il numero di valori mancanti;
molti modelli eliminano le righe incomplete. Vedi
[Diagnostica](topic:troubleshooting).

### p-value

La probabilità, assumendo vera l'ipotesi nulla, di osservare un risultato almeno
così estremo. Non è la probabilità che l'ipotesi nulla sia vera.

### Residuo

La differenza tra un valore osservato e il valore previsto da un modello. I
grafici dei residui sono il controllo più rapido delle assunzioni.

### Deviazione standard

La radice quadrata della varianza: una misura di dispersione sulla stessa scala
della variabile.

### Somma dei quadrati

La somma delle deviazioni al quadrato usata dall'analisi della varianza e dalla
regressione. Vedi [ANOVA a una via](topic:one-way-anova).

## Termini di R

### Data frame

L'oggetto tabellare di R, con colonne nominate che possono avere tipi diversi.
Il dataset attivo è sempre un data frame.

### Formula

La sintassi `risposta ~ predittori` usata da modelli e grafici.

### Pacchetto

Una raccolta di funzioni e dati R. Un dialogo che richiede un pacchetto lo
segnala come non disponibile finché il pacchetto non viene installato. Vedi
[Caricamento dei pacchetti](topic:loadPackages).

### Workspace

Gli oggetti R della sessione corrente. Salvare il workspace non equivale a
salvare un report o uno script: il registro dei comandi e lo script sono gli
artefatti riproducibili.

## Vedi anche

- [La prima analisi](topic:getting-started)
- [Usare il centro assistenza](topic:help-center)
- [Scorciatoie da tastiera](topic:keyboard-shortcuts)
- [Diagnostica](topic:troubleshooting)
