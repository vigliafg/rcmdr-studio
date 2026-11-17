---
id: workbench
title: Workbench
type: task
category: workbench
keywords: [script, console, output, messages, environment, objects, models, cells, diagnostics, rerun, format, autosave, AIC, BIC]
aliases: [script-studio, console-studio, environment-studio, model-registry, models-dashboard]
dialogs: [environmentSave, modelExport]
commands: [summary, str, plot, rm, saveRDS, save, AIC, BIC]
packages: [styler]
related: [report-studio, data-studio, chart-studio, exporting-results]
language: en
status: documented
---

# Workbench

The Workbench is the set of Studio tabs that let you work **outside the
dialogs**: Script, Console, Output, Messages and Environment. Every execution
shares the same command log, structured history, output, messages and object
environment as the dialogs.

## Script

The **Script** tab edits a plain R script, an R Markdown document or a knitr
document. The document registry is shared with the Report Studio, so the same
buffers appear in both tabs.

| Control | Effect |
|---|---|
| Document tabs | Activate or close a buffer; `*` marks unsaved changes |
| Run selection | Run the selected lines, or the whole buffer when nothing is selected |
| Run all | Run the whole script |
| Run cell | Run the top-level expression at the cursor |
| Run above / Run below | Run the cells entirely above or below the cursor |
| Run chunk at cursor | Run the R Markdown or knitr chunk at the cursor |
| Format | Format with `styler`, when installed |

### Cells

In a plain R script the cells follow the top-level expressions found by
`parse()`, so a multi-line call stays in one cell. When the script does not
parse, the tab falls back to blank-line separated blocks. In R Markdown and
knitr mode the cells are the code chunks.

Cell output appears inline, under the editor; the document text is never
modified by running a cell.

### Outline and diagnostics

- The **Outline** lists `# Section`, `# %%`, `# ---- Section ----`, `##`
  sub-headings and function definitions. Click an entry to move the cursor.
- **Diagnostics** shows the parse error position. A script that parses shows a
  positive message.

### Find and replace

Use the find bar above the editor. **Find** moves to the next match,
**Replace** replaces the current match, **Replace all** replaces every match.
Search is case-insensitive and does not use regular expressions.

### Autosave

Dirty scripts are saved to a recovery file every 30 seconds; the Report Studio
shares the same autosave directory and recovery banner.

## Console

The **Console** is a direct entry point to the command engine.

- `Enter` runs the command, `Shift+Enter` adds a new line.
- `Arrow Up` and `Arrow Down` recall previous commands.
- Every command is logged, added to the structured history and captured like a
  dialog command.
- Plots are captured and added to the gallery.
- Errors appear as cards and in the Messages tab.

### Interactive commands

R is single threaded, so a command that waits for input would block the whole
session. The console detects `readline()`, `readLines()`, `menu()`,
`browser()`, `scan()`, `file.choose()` and `select.list()` and refuses to run
them. There is no real cancellation: the guard prevents the block instead of
pretending to interrupt it.

## Output

Every execution becomes a card with:

- status, source, time and duration;
- the command;
- a collapsible output;
- **Pin**, **Rerun**, **Open dialog**, **To script**, **To report** and
  **Copy**.

Search the output, filter by status (OK, error, empty), by source (dialogs,
script, console, menus, Data Studio, Chart Studio, Report, Environment,
Models) and show pinned cards only. The raw text output remains available
below the cards for compatibility with the historical Output pane.

## Messages

Messages are stored with their severity, the command and the history step.
Filter by severity (errors, warnings, notes) or search the text. A message card
can rerun the command that produced it.

## Environment

The **Environment** tab has three views.

### Objects

Name, class, type, size and actions:

| Action | Reproducible? |
|---|---|
| Preview | No; `str()`/`summary()` outside the engine |
| View | No; activates the data set and opens the Data Studio |
| Summary | Yes; `summary(name)` |
| str | Yes; `str(name)` |
| Plot | Yes; `plot(name)` |
| Save | Yes; `saveRDS(name, file)` or `save(name, file)` |
| Remove | Yes; `rm(name)` |
| Set active data set/model | No; session state |

### Data sets

The registry view shows name, size, source, modification time and the active
mark.

### Models

The dashboard lists every recognised model (`lm`, `glm`, `aov`, `coxph`,
`survreg`, `lmer`/`glmer`, `polr`, `multinom`, `nls`, `loess` and similar) with
formula, family, data, n, AIC, BIC, R squared and the delta AIC against the
best model.

Actions run existing commands: Summary, ANOVA, Effects, Diagnostics,
Influence, VIF, AIC, BIC, Stepwise, Export. **Set active** and **Reopen
dialog** are session operations. The dialog is reopened with the memory
recorded when the model was fitted; when no memory exists, the dialog for the
model class opens with the model name prefilled.

## Reproducibility

| Action | Command? |
|---|---|
| Console input | Yes |
| Run cell / above / below | Yes |
| Rerun from a card | Yes, the same command |
| Open dialog / Set active | No, session state |
| Environment preview | No |
| Environment summary, str, plot, remove | Yes |
| Environment save | Yes |
| Model summary, ANOVA, diagnostics and the rest | Yes |
| Model export | Yes |

## Troubleshooting

- **The console reports a blocked command**: the command needs input. Use a
  data set or a dialog parameter instead.
- **Format does nothing**: install `styler`. The button reports the missing
  package instead of changing the script.
- **The outline is empty**: add `# Section` comments or `# %%` cell markers.
- **A model is missing from the dashboard**: only recognised model classes are
  listed; assign the object and refresh.
- **Reopen dialog opens an empty dialog**: the session has no memory for that
  model. The class dialog opens with the model name prefilled.
- **Inline cell output disappears after an edit**: cell ids are positional, so
  editing the script clears the old output on purpose.

## See also

- `topic:report-studio`
- `topic:data-studio`
- `topic:chart-studio`
- `topic:exporting-results`
