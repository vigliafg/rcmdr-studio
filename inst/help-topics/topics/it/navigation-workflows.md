---
id: navigation-workflows
title: Navigazione e workflow guidati
type: task
category: workbench
keywords: [palette, preferiti, recenti, ricerca menu, breadcrumb, scorciatoie, preset, validazione, workflow, guidato, suggerimenti, inspector]
aliases: [navigation, workflows, command-palette, dialog-presets]
dialogs: []
commands: []
packages: [RcmdrMisc]
related: [workbench, report-studio, data-studio, keyboard-shortcuts]
language: it
status: documented
---

# Navigazione e workflow guidati

La navigazione è un livello sopra il catalogo: non aggiunge procedure e non
cambia i comandi. Ogni voce continua a produrre lo stesso codice R.

## Palette dei comandi

`Ctrl` + `K` apre la palette. Cerca menu, dialoghi, argomenti di aiuto, dataset,
variabili, cronologia e workflow. Il filtro per tipo restringe i risultati.
Ogni riga mostra perché è disabilitata e offre l'azione pertinente: esegui, apri,
attiva, suggerisci, inserisci, copia.

## Preferiti e recenti

La stella accanto a una voce la aggiunge ai preferiti. Preferiti e recenti
compaiono in cima alla barra laterale e nella palette. Sono preferenze di
sessione, non comandi.

## Ricerca nei menu

La casella sopra i menu filtra etichette, percorso e nome del comando, evidenzia
le corrispondenze e può espandere o comprimere l'albero. Lo stato di espansione
viene ricordato.

## Workflow guidati

Un workflow orchestra dialoghi e comandi esistenti. Per ogni passo si può aprire
il dialogo, saltare, tornare indietro o annullare. I comandi completati sono
registrati nella cronologia e possono generare una bozza di sezione per il
report.

## Dialoghi

- Anteprima del comando prima dell'esecuzione.
- Preset nominati con esportazione e importazione.
- Validazione inline: il dialogo resta aperto e i campi non validi sono marcati.
- Selettori con tipo, valori mancanti e valori unici.
- Layout responsive e focus gestito.

## Vedi anche

- `topic:workbench`
- `topic:report-studio`
- `topic:keyboard-shortcuts`
