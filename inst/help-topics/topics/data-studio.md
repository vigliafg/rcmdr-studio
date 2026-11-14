---
id: data-studio
title: Data Studio
type: task
category: data
keywords: [data, studio, grid, inspector, filter, selection, checkpoint, dictionary, undo, column, row]
aliases: [data-studio, data-grid, inspector, checkpoint, dictionary]
dialogs: [dataImportWizard, dataAddColumn, dataDuplicateColumn, dataColumnType, dataCreateSubset, dataDeleteRows, dataCheckpoints, dataDictionary]
commands: [subset, rbind, attr, read.table]
packages: [DT, rhandsontable, utils]
related: [data-import, data-editing, exporting-results]
language: en
status: documented
---

# Data Studio

The **Data** tab in Studio mode is the data preparation workspace. It keeps
the same promise as the rest of RcmdrShiny Studio: every change that modifies
the data is an R command in the script log. View filters and checkpoints are
session operations and are labelled as such.

## Views and modes

- **View** shows a searchable grid. The global search box and the column
  filter change only what you see; they never modify the data set.
- **Edit** shows an editable `rhandsontable` grid while the data set is below
  the interactive editing threshold.
- **Targeted** appears automatically above that threshold. The grid stays
  read-only, but the inspector, filters and structural dialogs remain
  available.

## Data set registry

The toolbar selector lists every data frame in the evaluation environment,
with rows and columns. Switching the selector activates the chosen data set
for the menus, the inspector and the rest of the application. Data frames
created by a script or by the console are registered automatically.

## Grid and selection

The grid supports sorting, paging and global search. Click a row to select it;
use `Ctrl`-click (`Cmd`-click on macOS) to add or remove rows from the
selection. The selection bar shows the count and can be cleared. Selected rows
are original row numbers, not positions in the filtered view.

To subset by column values, choose a column filter and type a value. The grid
is filtered immediately, but the data set is unchanged.

## Inspector

The inspector describes the selected column:

- class and type;
- label, units and description;
- number of values, missing values and unique values;
- minimum, maximum, mean, median, standard deviation and quartiles for
  numeric variables;
- level counts for factors, characters and logicals;
- a compact histogram or bar chart.

The action buttons open the matching command dialog with the column already
selected.

## Structural operations

| Operation | Result |
|---|---|
| Add column | `Dataset$new <- with(Dataset, expression)` or a column of `NA` |
| Duplicate column | `Dataset$copy <- Dataset$source` |
| Rename column | `names(Dataset)[names(Dataset) == "old"] <- "new"` |
| Reorder columns | `Dataset <- Dataset[, c(...), drop = FALSE]` |
| Delete column | `Dataset <- within(Dataset, { column <- NULL })` |
| Change type | `as.numeric`, `as.factor`, `as.character`, `as.logical`, `as.Date` |
| Add row | `Dataset[nrow(Dataset) + 1L, ] <- NA` |
| Duplicate rows | `Dataset <- rbind(Dataset, Dataset[rows, , drop = FALSE])` |
| Delete rows | `Dataset <- Dataset[-rows, , drop = FALSE]` |
| Create subset | `subset()` or a bracketed row/column selection |

Each dialog previews its command before it runs. Structural operations create
a checkpoint first.

## Checkpoints

A checkpoint is a session snapshot created before a data mutation. Open
**Checkpoints** in the toolbar to see the list, its age, its size and the
data set it belongs to. Restoring a checkpoint:

- restores the data set and its dictionary;
- does **not** add a command to the script log;
- adds a note to the structured history.

Checkpoints are capped by count (20) and total memory (50 MB). Very large
data sets are not checkpointed; the application says so instead of failing.

## Data dictionary

The dictionary stores a label, units and description for each variable. The
values are written as attributes on the data frame, so they travel with the
data and appear in reports. Use **Dictionary** in the toolbar to edit a
variable and to export the dictionary as CSV or YAML.

## Import wizard

Use **Import...** in the toolbar to preview a CSV, TXT, XLSX or XLS file. The
wizard detects the delimiter, shows the first rows, proposes column types and
creates a reproducible `read.table()` or `readxl::read_excel()` command. The
uploaded file is copied to `~/.RcmdrShiny/files/` so the generated command
still works after the upload is gone.

## Reproducibility rules

| Action | Command? |
|---|---|
| Search or column filter | No, view only |
| Row selection | No, session state |
| Create subset | Yes |
| Add, duplicate, rename, reorder or delete column | Yes |
| Add, duplicate or delete row | Yes |
| Change column type | Yes |
| Label, units or description | Yes, `attr()` |
| Checkpoint or restore | No, session operation with a history note |
| Import or export | Yes |

## See also

- `topic:data-import`
- `topic:data-editing`
- `topic:exporting-results`
- `topic:keyboard-shortcuts`
