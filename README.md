# RcmdrShiny Studio

[![R-CMD-check](https://github.com/vigliafg/rcmdr-studio/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/vigliafg/rcmdr-studio/actions/workflows/R-CMD-check.yaml)
[![Browser E2E](https://github.com/vigliafg/rcmdr-studio/actions/workflows/e2e.yaml/badge.svg)](https://github.com/vigliafg/rcmdr-studio/actions/workflows/e2e.yaml)

A local, browser-based statistical workbench **inspired by** the
[R Commander](https://www.r-commander.com/) (Rcmdr), rebuilt on
[Shiny](https://shiny.posit.co/) and free of Tcl/Tk.

RcmdrShiny Studio is not a pixel-for-pixel clone of R Commander. It keeps the
engine and the reproducible command semantics of Rcmdr 2.15.0 — every action
still produces a visible R command — but replaces the desktop/Tk metaphor with
a browser-native Studio: command palette, structured history, data, chart and
report workspaces, and a Classic mode for compatibility.

> **Status: 3.2 Wave 20 (Examples and extra charts).** The Studio shell is
> menu-first: one horizontal menubar (`Alt`/`F10`), one workspace view at a
> time with an optional second slot, hideable Inspector/Preview panels,
> application undo and redo, row and cell-range selection with TSV copy,
> resizable dialogs and modeless Help/Console/Output. The Chart Studio has a
> single ggplot2 engine and an offline **Examples** gallery of 28 recipes
> adapted from the R Graph Gallery; eight additional types — lollipop,
> dumbbell, doughnut, stacked area, ridgeline, beeswarm, radar and parallel
> coordinates — extend the builder.
> Orientation remains the through-line: every Studio view carries a context
> line, the status bar has three priority groups, split slots name their role
> and view, and the filter describes the visible frame rather than the total.
> With nothing to continue, Home starts from four doors and every empty state
> names its next action. `Esc` closes one layer per press. The desktop chrome is
> denser (40/28/40 px, 4/6/8 px radii, flat cards), and theme, language and
> density live in **View > Preferences...**. The layout — last view, sidebar,
> DT column widths, dialog sizes — survives a restart and resets without
> touching the data. Large data is honest: above 5,000 rows the grid pages on
> the server (measured in `docs/upgrades/QA-DATA.md`), above 10,000 cells the
> browser editor is disabled, and both limits say why. Classic keeps its
> original tabbed layout. Commands, dialog ids, generated R code and existing
> i18n strings are unchanged.


## Requirements

- R >= 4.1
- A modern browser
- Packages: `shiny`, `bslib`, `DT`, `shinyAce`, `shinyFiles`,
  `rhandsontable`, `RcmdrMisc`, `ggplot2`, `plotly` (plus their dependencies)
- Optional: `rgl` for the 3D plot pane, `svglite` for SVG export, `rmarkdown`,
  `knitr` and Pandoc for report previews and knits, `commonmark` for the fast
  Markdown preview, `yaml` for front matter parsing, `styler` for script
  formatting, `ggridges` for ridgelines, `ggbeeswarm` for beeswarms and
  `GGally` for parallel coordinates

## Install

```r
# from a local clone
install.packages(".", repos = NULL, type = "source")

# development dependencies
install.packages(c("testthat", "shinytest2", "pkgdown"))
```

## Run

```r
RcmdrShiny::run()
```

This starts a local Shiny application and opens it in the browser.  Commands
are evaluated in `.GlobalEnv`, mirroring Rcmdr's single-user desktop model.
Pass a different environment for tests or embedding:

```r
env <- new.env()
RcmdrShiny::run(env = env)
```

## What works

| Area | Status |
|---|---|
| Menu sidebar generated from `Rcmdr-menus.txt` | done |
| Reactive activation from Rcmdr predicates (`numericP()`, `modelCapability()`, ...) | done |
| Command runner (`run_command`) with output, messages, warnings and errors | done |
| Script pane (Ace), run selection / run all, open and download `.R` | done |
| Output and Messages panes (clear, download) | done |
| Data view (`DT`, server-side paging above 5,000 rows) and interactive editor (`rhandsontable`, 10,000-cell threshold) | done |
| Data set registry and active-data selector | done |
| Data grid with global search, column filter and original-row selection | done |
| Column inspector with statistics, levels and distribution preview | done |
| Reproducible column and row operations (add, duplicate, rename, reorder, delete, type, subset) | done |
| Session checkpoints with restore | done |
| Data dictionary with labels, units and CSV/YAML export | done |
| Import wizard with preview, delimiter detection and type proposal | done |
| Targeted mode for data sets above the editing threshold | done |
| Chart builder with per-type mappings and options | done |
| Isolated live preview with debounce and cache | done |
| Typed chart specification and thirty-three chart types | done |
| Theme/palette panel and single ggplot2 engine | done |
| Gallery with search, type filter, pin, rename, detail and compare | done |
| Round-trip: reopen a chart in the builder | done |
| Offline example gallery adapted from the R Graph Gallery | done |
| PNG/PDF/SVG export, HTML export for interactive plots | done |
| Plotly selection and subset from selected points | done |
| Report document registry with multiple open documents | done |
| Clickable outline and chunk list synchronized with the editor | done |
| Fast Markdown preview that never executes code | done |
| Executable cells with inline, collapsible output | done |
| Five report templates and dataset substitution | done |
| Contextual insertion of output, plots, tables, profiles and models | done |
| Conservative YAML front matter form and bibliography | done |
| Knit manager with formats, history, errors and downloads | done |
| Autosave, recovery copies and `.bak` backups | done |
| Multi-document script tabs shared with the Report Studio | done |
| Executable script cells with run cell, above and below | done |
| R outline, parse diagnostics and find/replace | done |
| Console with command recall, history and interactive guard | done |
| Filterable output cards with pin, rerun and rerun from messages | done |
| Structured messages by severity with command context | done |
| Object explorer with preview and reproducible actions | done |
| Data set registry and model list in the Environment tab | done |
| Models dashboard with AIC/BIC comparison and existing commands | done |
| Reopen a model dialog with its recorded memory | done |
| Plot capture, history gallery, PNG/PDF export | done |
| rgl 3D scene rendered with `rglwidget()` | done |
| Studio shell with Home, Charts and Console workspaces | done |
| Menu-first desktop workspace with two slots, hideable panels and modeless views | done |
| Application undo/redo, row and cell-range selection, TSV copy | done |
| Persistent geometry: last view, sidebar, column widths, dialog sizes, reset | done |
| Classic mode preserving the 1.13 layout | done |
| Horizontal menubar with hierarchical, workflow-grouped menus | done |
| Stable `menu_id` / `item_id` registry and first-party module fragments | done |
| One File > Save with sub-items per format | done |
| Versioned `.rcmdrproj` projects, autosave and recovery | done |
| Project bundle export and session checkpoints | done |
| Plugin SDK v2 with components, presets, workflows and templates | done |
| Health panel, extended diagnostics and benchmark suite | done |
| Command palette (`Ctrl+K`) over menus, help, data, variables and history | done |
| Structured command history with rerun, dialog reopening and script/report insertion | done |
| Live R-command preview, "To script" and named dialog presets | done |
| Isolated preview engine for base plots, plotly and Markdown | done |
| Minimal browser console with Output, Messages and History | done |
| Light, dark, high-contrast and system themes; keyboard shortcuts | done |
| Dialog runtime (tabs, OK/Apply/Reset/Cancel/Help, memory, validation, retry) | done |
| Read Text Data (file, clipboard, URL) | done |
| Numerical Summaries (statistics, groups, counts) | done |
| Linear Model (formula builder, subset, weights, row removal) | done |
| Options, Setwd, Load Data Set, Open Script File | done |
| Environment view, workspace download, dark mode, language selector | done |
| File/Data: imports (text/Excel/SPSS/Stata/SAS/Minitab) | done |
| Data: compute, recode, factors, binning, standardize | done |
| Data: missing values, subset, case names, rename, contrasts, stack | done |
| Data: remove/select rows, merge, aggregate, drop levels, sort, reshape | done |
| Data: export, save `.RData`, workspace, editor | done |
| Statistics: summaries, correlations, normality, tables | done |
| Statistics: t-tests, ANOVA (incl. repeated measures) | done |
| Statistics: variance, proportion and nonparametric tests | done |
| Statistics: PCA, factor analysis, reliability, clustering | done |
| Statistics: linear, GLM, multinomial, ordinal and mixed models | done |
| Graphs: base, RcmdrMisc, car and lattice dialogs | done |
| Distributions: quantiles, probabilities, plots and samples | done |
| 3D graphs with rgl and plot export/snapshot | done |
| Models: diagnostics, influence, hypotheses, model selection, effect plots | done |
| Tools and Help menus | done |
| Help tab: full-text search, filters, categories, TOC, related dialogs and contextual help | done |
| Markdown help topics for the core and every plugin (644 documented topics) | done |
| Runnable help examples with confirmation, logging and script insertion | done |
| Error-to-topic mapping and contextual help links in error cards | done |
| Glossary, updated shortcut reference and first-run tour/checklist | done |
| Italian translations for 27 core topics and live language switching | done |
| Interactive plots (plotly) for histogram, boxplot, scatterplot and line graph | done |
| Session report export (R Markdown, HTML when rmarkdown is installed) | done |
| Plugin command aliases (`aliases = c(new = "core")`) | done |
| R Markdown and knitr document mode, chunks, sections and knit | done |
| Knit to HTML/PDF/Word with preview in the Report tab | done |
| Run current chunk, document templates and options | done |
| Help API: `help_search()`, `help_topic()`, `help_index()` and plugin registration | done |
| Help inventory and link checker in CI | done |
| Plugin API: menus, direct commands, Shiny dialogs | done |
| Plugin packages (`RcmdrShinyPlugin.*`), predicates, menu merge and tooling | done |
| Legacy Tk plugin detection and warning | done |
| Accessibility landmarks and keyboard pass | done |
| Vignettes, pkgdown and release checklist | done |
| Help authoring guide and diagnostic report | done |
| Remaining 4 internal utilities (no user-facing dialog) | backlog |
| Wave 1 plugins: Export, sos, PcaRobust, ROC, UCA | done |
| Wave 2 plugins: TeachingDemos, HH, KMggplot2, TeachStat | done |
| Wave 3 plugins: survival, aRnova, NMBU, DoE | done |
| Wave 4 plugins: FactoMineR, EZR | done |
| Plugin hardening and release preparation | done |

The inventory is regenerated from an Rcmdr source tree with:

```sh
Rscript tools/inventory_dialogs.R /path/to/Rcmdr
```

## Help and documentation

The **Help** tab is an offline documentation browser: full-text search with
type/source/category filters, highlighted snippets, recent topics, a table of
contents, related dialogs and commands, runnable examples and a topic pane.
Every dialog has a **Help** button that opens its topic inside the dialog, with
a link to the R reference and to the full help centre. Failed commands offer
the topic that most likely explains the error.

Help topics are Markdown files with a YAML front matter, shipped in
`inst/help-topics/` and in each plugin's `inst/help-topics/`. The same API is available from
R:

```r
RcmdrShiny::help_search("logistic regression")
RcmdrShiny::help_topic("linear-model")
RcmdrShiny::help_index()
RcmdrShiny::help_catalog()
```

Plugins are discovered automatically, and can also register help explicitly:

```r
RcmdrShiny::RcmdrShiny.plugin(
  name = "RcmdrShinyPlugin.Example",
  dialogs = my_dialogs(),
  help = system.file("help", package = "RcmdrShinyPlugin.Example")
)
```

Rendering uses `commonmark` when installed and falls back to a plain `<pre>`
block otherwise, so the help works with no optional dependency. Topics can be
translated by adding `topics/<language>/<id>.md`; missing translations fall back
to English.

Tools:

```sh
Rscript tools/new_help_topic.R my-topic --title "My topic" --category statistics
Rscript tools/generate_help_topics.R --core
Rscript tools/inventory_help.R
Rscript tools/check_help_links.R --strict
Rscript tools/audit_i18n.R --language it
```

`audit_i18n.R` compares the literal `tr()` messages in `R/` and the menu labels
with the PO catalogue and the Studio TSV overlay, reporting the untranslated
strings. The first-run tour is dismissible, can be hidden permanently in the
browser's local storage, and can be restarted from **Help > Guided tour**.

`inventory_help.R` writes `inst/etc/help-inventory.csv` with one row per dialog
(`documented`, `draft`, `fallback` or `missing`) and the continuous integration
job fails when a dialog has neither a topic nor an Rd fallback.

`RcmdrShiny::format_diagnostics()` produces the report shown by
**Help > Diagnostics**, ready to paste into an issue.

## Test

```r
testthat::test_local()
```

The browser end-to-end test is opt-in:

```sh
RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_local(filter = "shinytest2")'
```

It drives the full flow in headless Chrome: import a CSV, compute numerical
summaries, fit a linear model, and verify the generated script and output.

## Architecture

| File | Responsibility |
|---|---|
| `R/app.R` | Shiny UI, Studio/Classic shell, server and status bar |
| `R/state.R` | `AppState`: environment, active data set/model, logs, history, memory |
| `R/commands.R` | `run_command()`: evaluation, capture, plot capture, history hooks |
| `R/history.R` | Structured command history and rerun/insert helpers |
| `R/preview.R` | Isolated preview engine for plots, plotly and Markdown |
| `R/command-palette.R` | Search index and palette over menus, help, data and history |
| `R/features.R` | Feature flags, Studio/Classic mode and theme settings |
| `R/ui-components.R` | Shared Studio components and status/empty/metric widgets |
| `R/history-ui.R` | History cards and filters |
| `R/data-studio.R` | Data registry, dictionary, checkpoints, selection, inspector and dialogs |
| `R/chart-spec.R` | Chart specification, validation, theme and command generation |
| `R/chart-types.R` | Chart type registry, mappings, controls and dialog memory |
| `R/chart-studio.R` | Chart builder UI, preview, gallery, export and dialogs |
| `R/report-studio.R` | Report Studio UI, preview, cells, insertion and knit manager |
| `R/report-templates.R` | Five report templates and the template gallery |
| `R/script-studio.R` | Script tabs, cells, outline, diagnostics and formatting |
| `R/console-studio.R` | Console UI, recall history and structured execution |
| `R/environment-studio.R` | Object explorer, data set registry and save dialog |
| `R/models-studio.R` | Model registry, dashboard, actions and export dialog |
| `R/console.R` | Interactive-command guard |
| `R/menus.R` | Parser for `Rcmdr-menus.txt` and sidebar renderer |
| `R/dialogs.R` | Dialog runtime, command preview and presets |
| `R/widgets.R` | Shiny equivalents of Rcmdr widgets |
| `R/command-builders.R` | Pure functions that generate Rcmdr-compatible commands |
| `R/dialogs-*.R` | Dialog specifications and validation |
| `R/i18n.R` | gettext helpers and language discovery |
| `inst/etc/Rcmdr-menus.txt` | Menu source of truth, copied from Rcmdr |
| `inst/po/` | Rcmdr translation catalogues |

Adding a dialog means:

1. write a `dialog_spec()` with `ui`, `on_ok` and optional `observers`;
2. keep command generation in a pure function and test it;
3. register the dialog in `dialog_catalog()`;
4. add the dialog to the inventory status list in
   `tools/inventory_dialogs.R`;
5. add unit and integration tests.

## Plugins

A minimal plugin API allows adding Rcmdr-style menus, direct commands and
Shiny dialogs:

```r
RcmdrShiny::RcmdrShiny.plugin(
  name = "demo",
  menus = "etc/menus.txt",
  commands = list(hello = function(state) {
    RcmdrShiny::run_command(state, 'cat("Hello\n")')
  }),
  dialogs = list(demo = RcmdrShiny::plugin_dialog(
    "demo", "Demo",
    ui = function(state, memory) htmltools::tags$p("Hello"),
    on_ok = function(input, state) list(commands = "1 + 1")
  ))
)
```

Load a plugin before starting the app:

```r
RcmdrShiny::run(plugins = "path/to/plugin.R")
```

Package plugins follow the `RcmdrShinyPlugin.*` protocol and export
`rcmdrshiny_plugin()`:

```r
RcmdrShiny::run(plugins = c(
  "RcmdrShinyPlugin.Export",
  "RcmdrShinyPlugin.sos"
))
```

They live under `plugins/` in this repository and are distributed on GitHub;
see `plugins/README.md`.  `tools/new_plugin.R` creates a new package skeleton
and `tools/inventory_plugin.R` inventories an upstream plugin.

See `inst/examples/demo-plugin.R` and `inst/examples/demo-menus.txt` for a
script plugin.  Legacy Tk plugins are detected and disabled with a warning.

## License and attribution

RcmdrShiny is distributed under the GNU General Public License, version 2 or
later (GPL-2+).  It is derived from Rcmdr 2.15.0, Copyright (C) 2001-2026
John Fox, Milan Bouchet-Valat and contributors.  See `NOTICE` and `UPSTREAM.md`
for details.
