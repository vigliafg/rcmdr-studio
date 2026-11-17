---
id: navigation-workflows
title: Navigation and guided workflows
type: task
category: workbench
keywords: [palette, favourites, favorites, recents, menu search, breadcrumb, shortcuts, presets, validation, workflow, guided, suggestions, inspector]
aliases: [navigation, workflows, command-palette, dialog-presets]
dialogs: []
commands: []
packages: [RcmdrMisc]
related: [menu-structure, workbench, report-studio, data-studio, keyboard-shortcuts]
language: en
status: documented
---

# Navigation and guided workflows

The navigation layer makes the catalogue usable without memorising the menu:
the command palette, favourites, recents, menu search and breadcrumbs all point
to the same existing dialogs and commands. Guided workflows only orchestrate
those dialogs; they never add a statistical procedure.

## Command palette

Press `Ctrl` + `K` (or `Ctrl` + `Shift` + `P`) to open the palette. It searches:

- menu commands and dialogs;
- help topics;
- data sets and variables;
- structured history;
- guided workflows.

The type filter and **Favourites only** switch narrow the list. Favourites and
recent commands are ranked first. Each row offers the relevant action:
**Run** a menu command, **Open** a dialog, **Activate** a data set, **Suggest**
for a variable, **Rerun**/**Insert**/**Copy** for a history step and **Start**
for a workflow. A disabled row explains why it cannot run.

Use the arrow keys to move and `Enter` to act; `Esc` closes the palette.

## Menubar, favourites and search

The main navigation is the horizontal menubar: **File**, **Edit**, **Data**,
**Transform**, **Analyze**, **Graphs**, **Reports**, **Utilities** and
**Help**. Each top-level entry opens a dropdown with nested submenus, grouped
by workflow. For example, **File > Save** contains one item per format (data
set, script, R Markdown report, knitr report, workspace) instead of a flat list
of near-duplicate Save commands. See [Menu structure](topic:menu-structure).

Every menu row has a star. A starred command appears under **Favourites** at the
top of the sidebar, and the last commands appear under **Recent**. The sidebar
search box filters the whole menu, including translated labels, and
highlights the matching text.

## Commands and windows

The two bars answer two different questions.

- The **menubar** holds the commands: the Rcmdr catalogue of statistical
  procedures, file operations and utilities. It is the only bar that runs
  something.
- The **tabs** are windows on the workspace: Home, Workflows, Data Studio,
  Chart Studio, Report Studio, Script, Output (Console), Environment and
  Help centre. They never run a command, they show what a command produced.
  Classic mode uses the R Commander window names instead (Script, Output,
  Messages, Plots, Report, Data, Environment, Help).

The names differ on purpose: **Data** in the menubar is a command group, while
**Data Studio** is the window where the data set is shown. The same holds for
**Graphs**/**Chart Studio**, **Reports**/**Report Studio** and
**Help**/**Help centre**.

A command runs where it always ran; the interface then says where the result
landed. After a dialog command a bar appears above the tabs:

> Analyze › Summaries › Numerical summaries → Result in: Output (Console) ▸ Output

**Show result** opens that window, **Open automatically** makes the switch
happen without asking (the choice is stored with the other preferences) and
**Dismiss** hides the bar. Plots point at Chart Studio; text output points at
the Output pane of the Console workspace.

Favourites, recents, expanded groups, dialog presets, language and theme are
stored in a small `preferences.rds` file under the user configuration
directory. Set `options(RcmdrShiny.preferences = "path/to/preferences.rds")` to
override it. Nothing is written when the directory is not writable.

## Breadcrumbs

A dialog and the palette show the menu path of the command, for example
**Statistics > Summaries > Numerical summaries**, so it is always clear where
the command comes from.

## Dialog presets and validation

The preset bar above a dialog can save the current inputs under a name, apply a
saved preset, delete it, and export or import a preset file. Presets are data,
not commands; applying one only pre-fills the dialog.

A dialog can return field-level errors. The modal stays open, the summary lists
every invalid field and focus moves to the first one. The error is attached to
the field with `aria-invalid`, not only shown in a toast.

Selectors show the variable type, missing count and unique values. Use the
search box inside a select to filter long variable lists. **Reset** restores the
values used when the dialog opened.

## Guided workflows

The **Workflows** tab lists the five built-in workflows:

| Workflow | Steps |
|---|---|
| Describe the data | Summary, missing values, histogram, boxplot |
| Compare groups | Summary by group, t-test, ANOVA, boxplot |
| Linear model | Fit, summary, diagnostics, effect plots |
| Survival analysis | Kaplan-Meier, log-rank, Cox model |
| Prepare the report | New Rmd, data profile, latest plot, knit |

Start a workflow, open a step and complete the usual dialog. The step is marked
**Done** when the dialog applies its commands. Optional steps can be **Skipped**;
required steps cannot. **Back**, **Cancel** and the draft report section are
always available. **Insert into report** adds a Markdown section with one
executable chunk per completed step, using exactly the commands the dialogs
generated.

Availability depends on the active data set and on loaded plugins. A blocked
step explains what is missing; it never runs a partial command.

## Variable suggestions

The Data Studio inspector answers "what can I do with this variable?" using the
variable type, missing values and the active data set. A numeric variable
suggests summary, histogram, density, boxplot, scatterplot, correlation and
transformation; a factor suggests frequency table, bar graph, boxplot, two-way
table, recode and reorder; a character or logical variable suggests conversion
to a factor. Each button opens the existing dialog with the variable already
selected.

Suggestions are rules, not statistical advice: they never recommend a model.

## Reproducibility

| Action | Command? |
|---|---|
| Palette: run a menu command | Yes, the same command |
| Palette: open a dialog | No, only opens it |
| Favourite or recent | No, preference |
| Preset | No, saved inputs |
| Workflow step | Yes, the dialog or command |
| Workflow report section | No, editable Markdown text |
| Variable suggestion | Depends on the chosen action |

## See also

- `topic:workbench`
- `topic:report-studio`
- `topic:keyboard-shortcuts`
