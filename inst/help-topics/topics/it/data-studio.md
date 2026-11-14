---
id: data-studio
title: Data Studio
type: task
category: data
keywords: [dati, studio, griglia, inspector, filtro, selezione, checkpoint, dizionario, annulla, colonna, riga]
aliases: [data-studio, data-grid, inspector, checkpoint, dictionary]
dialogs: [dataImportWizard, dataAddColumn, dataDuplicateColumn, dataColumnType, dataCreateSubset, dataDeleteRows, dataCheckpoints, dataDictionary]
commands: [subset, rbind, attr, read.table]
packages: [DT, rhandsontable, utils]
related: [data-import, data-editing, exporting-results]
language: it
status: documented
---

# Data Studio

La scheda **Data** mostra il dataset attivo in una griglia con ricerca, filtri,
selezione e inspector di colonna. Ogni modifica strutturale produce un comando R
e un checkpoint di sessione.

## Griglia e selezione

- Cercare nelle colonne o filtrare la vista senza modificare i dati.
- Selezionare righe e colonne; la selezione mantiene gli indici originali.
- Trasformare la selezione in un subset con un comando registrato.

## Inspector

L'inspector riepiloga tipo, valori mancanti, valori unici, livelli e statistiche
descrittive. I suggerimenti contestuali aprono i dialoghi esistenti con le
variabili già selezionate.

## Operazioni

Le operazioni su colonne e righe usano i dialoghi del catalogo: aggiungi,
duplica, converti, rinomina, elimina, filtra e crea subset. Non esiste una
seconda implementazione delle stesse trasformazioni.

## Checkpoint e annulla

Ogni mutazione registra un checkpoint con nome, comando e dimensione. **Ripristina**
riporta il dataset a quel punto; il ripristino è una sessione, non un comando
statistico.

## Dizionario dei dati

Il dizionario raccoglie etichette, descrizioni e attributi delle colonne. Può
essere esportato in CSV o YAML e ricaricato in un secondo momento.

## Dataset grandi

Quando la griglia supera la soglia di editing, la modifica nel browser è
disattivata ma filtri, profili e dialoghi statistici continuano a funzionare.

## Vedi anche

- `topic:data-import`
- `topic:data-editing`
- `topic:exporting-results`
