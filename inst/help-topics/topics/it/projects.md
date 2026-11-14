---
id: projects
title: Progetti
type: task
category: workbench
keywords: [progetto, rcmdrproj, salva, apri, autosave, recupero, bundle, checkpoint, recenti]
aliases: [project, project-file, rcmdrproj]
dialogs: [projectNew, projectOpen, projectSaveAs, projectBundle, sessionCheckpoint]
commands: [projectSave]
packages: [RcmdrShiny]
related: [workbench, report-studio, data-studio, menu-structure]
language: it
status: documented
---

# Progetti

Un progetto è un file portabile `.rcmdrproj` che descrive una sessione di
lavoro: dataset, documenti, grafici e preferenze. Non cambia i comandi
statistici: ogni analisi continua a produrre lo stesso codice R.

## Salva e apri

- **File > Nuovo > Progetto...** crea un progetto e scrive il primo file.
- **File > Apri > Progetto...** ripristina dataset, documenti, grafici, preset,
  preferiti e opzioni.
- **File > Salva > Progetto...** salva nel percorso corrente; se il progetto non
  ha ancora un percorso apre **Salva progetto come**.
- **File > Esporta > Bundle progetto...** crea un `.tar.gz` (o `.zip`) con il
  progetto, i dati inclusi e i grafici.

I dataset che provengono da un file mantengono un percorso relativo. I dataset
creati nella sessione vengono scritti in `data/<nome>.csv` nella cartella del
progetto. I grafici vengono copiati in `assets/`.

## Autosave e recupero

Mentre un progetto è aperto, l'applicazione scrive `<progetto>.autosave`
all'intervallo configurato. All'avvio, se l'autosave è più recente del progetto,
RcmdrShiny propone tre scelte:

- **Recupera** carica l'autosave e mantiene il percorso originale;
- **Ignora** lascia l'autosave per dopo;
- **Elimina autosave** lo rimuove.

Il successivo salvataggio esplicito sostituisce il progetto e rimuove
l'autosave.

## Progetti recenti

La scheda Home elenca i progetti recenti e all'avvio controlla l'ultimo per il
recupero. L'elenco vive in `projects.rds` nella cartella di configurazione
utente; usa `options(RcmdrShiny.projects = "percorso.rds")` per cambiarlo.

## Checkpoint di sessione

**Strumenti > Checkpoint di sessione...** memorizza dataset attivo, modello
attivo e documenti aperti. Un checkpoint di sessione non copia i dati: per
annullare modifiche strutturali restano i checkpoint della scheda Dati.
Ripristinare un checkpoint di sessione non esegue mai un comando.

## Vedi anche

- [Workbench](topic:workbench)
- [Report Studio](topic:report-studio)
- [Data Studio](topic:data-studio)
