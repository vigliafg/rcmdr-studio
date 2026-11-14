---
id: keyboard-shortcuts
title: Scorciatoie da tastiera e accessibilità
type: reference
category: help
keywords: [tastiera, scorciatoie, accessibilità, focus, tab, screen reader]
aliases: []
dialogs: []
commands: []
packages: [RcmdrShiny]
related: [help-center, troubleshooting]
language: it
status: documented
---

# Scorciatoie da tastiera e accessibilità

RcmdrShiny è un'applicazione browser, quindi valgono anche le scorciatoie del
browser.

## Navigazione

| Azione | Scorciatoia |
|---|---|
| Controllo successivo | `Tab` |
| Controllo precedente | `Shift` + `Tab` |
| Attivare il pulsante o link con focus | `Invio` o `Spazio` |
| Chiudere un dialogo | `Esc` se consentito, altrimenti **Annulla** |
| Saltare al contenuto principale | `Tab` dall'inizio pagina, poi `Invio` su "Salta al contenuto" |

## Barra dei menu

| Azione | Tasto |
|---|---|
| Passare tra i menu di primo livello | `Tab` / `Shift` + `Tab` |
| Aprire o chiudere un menu | `Invio` o `Spazio` sulla sua etichetta |
| Entrare in un sottomenu | `Tab` fino al sottomenu, poi `Invio` |
| Chiudere il menu aperto | `Esc` o clic fuori dalla barra |
| Raggiungere una voce | `Tab` fino alla voce, poi `Invio` |

La barra dei menu è un albero nativo `<details>`: funziona senza mouse e su
schermi piccoli scorre in orizzontale. La palette dei comandi resta la via più
rapida da tastiera.

## Campi dei dialoghi

- Le liste di variabili supportano `Ctrl`+clic e `Shift`+clic.
- **Reimposta** riporta i valori iniziali del dialogo.

## Scheda Help

| Azione | Scorciatoia |
|---|---|
| Portare il focus sulla ricerca | `Tab` fino al campo |
| Aprire il primo risultato | `Invio` nel campo |
| Spostarsi tra le categorie | `Tab` e frecce |

I risultati sono annunciati tramite una regione `aria-live`. I filtri per tipo
e origine si combinano con la ricerca e con l'elenco delle categorie.

## Aiuto e apprendimento

| Azione | Dove |
|---|---|
| Aprire il centro assistenza | Scheda Help, oppure **Aiuto > Centro assistenza** |
| Cercare nell'aiuto | **Aiuto > Cerca nell'aiuto...** |
| Riavviare il tour guidato | **Aiuto > Tour guidato** |
| Aprire il glossario | **Aiuto > Glossario** |
| Mostrare l'elenco delle scorciatoie | `Ctrl` + `/` |
| Eseguire un esempio documentato | **Esegui** nella sezione Esempi |
| Inserire un esempio nello script | **Inserisci nello script** |
| Segnalare un problema | **Segnala un problema** in fondo all'argomento |

## Lingua e tema

I selettori di lingua e tema sono nella barra superiore. Menu, argomenti di
aiuto, notifiche e pannelli ridisegnati usano subito la nuova lingua; la
cornice statica viene aggiornata al ricaricamento della pagina. La scelta è
salvata nelle preferenze di sessione.

## Funzioni di accessibilità

- Landmark: la sidebar ha `role="navigation"` e l'area contenuti `role="main"`.
- Un link "Salta al contenuto principale" è il primo elemento focalizzabile.
- Il tema scuro mantiene i rapporti di contrasto del tema chiaro.
- Il testo si adatta allo zoom del browser senza rompere il layout.

## Vedi anche

- `topic:help-center`
- `topic:troubleshooting`
