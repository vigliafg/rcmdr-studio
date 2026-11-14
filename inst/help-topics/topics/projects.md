---
id: projects
title: Projects
type: task
category: workbench
keywords: [project, rcmdrproj, save, open, autosave, recovery, bundle, checkpoint, recent]
aliases: [project, project-file, rcmdrproj]
dialogs: [projectNew, projectOpen, projectSaveAs, projectBundle, sessionCheckpoint]
commands: [projectSave]
packages: [RcmdrShiny]
related: [workbench, report-studio, data-studio, menu-structure]
language: en
status: documented
examples:
  - code: "RcmdrShiny:::project_summary(AppState())"
    title: "Inspect the project summary"
    runnable: true
---

# Projects

A project is a portable `.rcmdrproj` file that describes a working session:
the data sets, the documents, the plots and the preferences. It never changes
the statistical commands: every analysis still produces the same R code.

## Save and open

- **File > New > Project...** creates a project and writes its first file.
- **File > Open > Project...** restores data sets, documents, plots, presets,
  favourites and options.
- **File > Save > Project...** saves to the current path; if the project has no
  path yet it opens **Save project as**.
- **File > Export > Project bundle...** creates a `.tar.gz` (or `.zip`) with the
  project, its included data and its plots.

Data sets that came from a file keep a relative source. Data sets created in
the session are written to `data/<name>.csv` inside the project folder. Plots
are copied to `assets/`.

## Autosave and recovery

While a project is open, the application writes `<project>.autosave` at the
configured interval. At start-up, if the autosave is newer than the project,
RcmdrShiny offers three choices:

- **Recover** loads the autosave and keeps the original project path;
- **Ignore** leaves the autosave for later;
- **Delete autosave** removes it.

The next explicit save replaces the project and removes the autosave.

## Recent projects

The Home card lists the most recent projects and the last project is checked at
start-up for recovery. The list lives in `projects.rds` under the user
configuration directory; set `options(RcmdrShiny.projects = "path.rds")` to
override it.

## Session checkpoints

**Utilities > Session checkpoints...** stores the active data set, the active
model and the open documents. A session checkpoint does not copy the data:
data checkpoints in the Data tab remain the tool for undoing structural
changes. Restoring a session checkpoint never runs a command.

## See also

- [Workbench](topic:workbench)
- [Report Studio](topic:report-studio)
- [Data Studio](topic:data-studio)
