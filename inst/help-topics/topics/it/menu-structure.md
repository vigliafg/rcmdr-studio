---
id: menu-structure
title: Struttura dei menu e ID stabili
type: reference
category: workbench
keywords: [menu, menubar, gerarchia, salva, modulo, plugin, id, stabile, sdk]
aliases: [menus, menu-registry, stable-ids]
dialogs: []
commands: []
packages: [RcmdrShiny]
related: [navigation-workflows, writing-plugins, keyboard-shortcuts]
language: it
status: documented
---

# Struttura dei menu e ID stabili

L'applicazione usa una barra dei menu orizzontale con sottomenu annidati,
raggruppati per flusso di lavoro nello stile di SPSS e Minitab. Le routine non
cambiano: ogni voce punta allo stesso comando del vecchio menu piatto.

## Livello superiore

```text
File  Modifica  Dati  Trasforma  Analizza  Grafici  Report  Strumenti  Aiuto
```

- **File** — nuovo/apri/salva, importa, esporta ed esci.
- **Modifica** — azioni editor, ricerca e selezione.
- **Dati** — dataset, importazione, dataset attivo e dizionario.
- **Trasforma** — calcola, ricodifica, fattori, valori mancanti e variabili.
- **Analizza** — riassunti, tabelle, medie, proporzioni, varianze, test non
  parametrici, modelli e distribuzioni.
- **Grafici** — base, lattice, ggplot2, 3D e galleria.
- **Report** — documento, authoring, knit ed export.
- **Strumenti** — moduli, opzioni, diagnostica e health.
- **Aiuto** — centro assistenza, ricerca, glossario, scorciatoie e tour.

## Un solo Salva, molti formati

```text
File > Salva
├─ Dataset...
├─ Script...
├─ Report (R Markdown)...
├─ Report (knitr)...
├─ Workspace...
└─ Salva come
   ├─ Script come...
   ├─ R Markdown come...
   ├─ knitr come...
   └─ Workspace come...
```

Le etichette sono l'unica cosa visibile all'utente; il comando sottostante resta
`saveDataSet`, `saveLog`, `saveRmd`, `saveRnw` o `saveWorkspace`. La
riproducibilità non cambia.

## ID stabili

Il registro dei menu separa quattro identificatori:

| Campo | Esempio | Significato |
|---|---|---|
| `module_id` | `core`, `survival` | Modulo first-party |
| `menu_id` | `menu.file.save` | Gruppo nella gerarchia |
| `item_id` | `file.save.script` | Voce, immutabile al riordino |
| `command_id` | `saveLog` | Comando del motore, invariato |

L'ID DOM deriva da `item_id` (`menu_item_file_save_script`), non da un contatore
di riga. Lo stesso `command_id` può comparire in due punti, ma ogni occorrenza
ha il proprio `item_id`.

## File del registro

```text
inst/menus/core.yml
plugins/<modulo>/inst/menus/module.yml
```

Ogni frammento dichiara `groups`, `items` e `removes` opzionali. Un modulo può
rimuovere un singolo comando del nucleo che sostituisce, ma non elimina un intero
menu del nucleo: la shell curata e le voci di aiuto restano disponibili.

## Vedi anche

- [Navigazione e workflow guidati](topic:navigation-workflows)
- [Scrivere plugin](topic:writing-plugins)
- [Scorciatoie da tastiera](topic:keyboard-shortcuts)
