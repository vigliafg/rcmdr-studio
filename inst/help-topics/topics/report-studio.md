---
id: report-studio
title: Report Studio
type: task
category: report
keywords: [report, rmarkdown, rmd, knitr, document, preview, knit, template, yaml, bibliography, autosave, cell]
aliases: [report-studio, rmd-studio]
dialogs: [reportYaml, reportTemplate, newRmd, compileRmd, insertSection, insertChunk]
commands: [rmarkdown::render, knitr::kable, knitr::include_graphics]
packages: [rmarkdown, knitr, commonmark, yaml]
related: [document-authoring, exporting-results, data-studio, chart-studio]
language: en
status: documented
---

# Report Studio

The **Report** tab in Studio mode is an authoring environment for R Markdown
and knitr documents. The **Script** tab remains the low-level editor for R
code. Both share the same document buffer, so switching tabs never loses text.

## Preview versus knit

| Action | Runs code | Purpose |
|---|---|---|
| Markdown preview | No | Fast layout check; chunks appear as placeholders |
| Source view | No | The exact document text |
| HTML preview | — | The last knit of the document |
| Knit | Yes | Executes every chunk in the session and renders the output |

The fast preview is deliberately not a knit: you can edit a chunk that fails
without breaking the preview. The knit is the source of truth for the final
report.

## Layout

- **Outline**: every heading outside the code chunks. Click a heading to move
  the cursor in the editor.
- **Chunks**: each chunk with its label, status and **Run** action.
- **Editor**: an Ace editor with R Markdown syntax highlighting.
- **Preview**: Markdown, HTML or source.
- **Status bar**: saved/unsaved state, autosave time and the last knit.

## Documents

The document selector lists every open document; `*` marks unsaved changes.
**New** creates a document, **Template** creates one from a template and
**Close** removes the active document. Closing the last document leaves an
empty R script buffer.

## Templates

Five templates are available:

| Template | Contents |
|---|---|
| Analysis report | Context, data, descriptive statistics, graph, conclusions |
| Data profile | Structure, missing values, distributions, quality notes |
| Model diagnostics | Model summary, diagnostic plots, influence |
| Teaching handout | Objectives, worked example, exercises |
| Survival report | Kaplan-Meier and Cox scaffolding |

Templates only use commands that the dialogs already generate. A template
replaces `{{dataset}}` with the data set you select.

## Executable cells

**Run** on a chunk executes its code through the normal command engine:

- the command is recorded in the structured history with source `report`;
- the output appears inline, collapsible, under the chunk;
- plots are captured and shown under the output;
- the document itself is **not** modified.

**Run all** executes every chunk in order; **Run to here** executes the chunks
up to the selected one. The knit re-executes the chunks, so inline output is a
session preview, not a substitute for the knit.

## Insert

The **Insert** panel adds content to the document:

| Action | Result |
|---|---|
| Output | The captured output of a history step, as a literal block |
| Plot | A `knitr::include_graphics()` chunk for a session plot |
| History step | The command of a history step as a reproducible chunk |
| Table | A Markdown table rendered at authoring time |
| Data profile | A chunk with `dim()`, `str()` and missingness |
| Model summary | A `summary()` chunk for the active model |
| Section | A new heading |
| Chunk | A new empty code chunk |

Insertion is explicit. Editing the document, previewing it, or running a cell
does not silently change its content.

## YAML front matter

**YAML...** edits title, author, date, output format, table of contents, theme,
bibliography and citation linking. Fields that the form does not show are
preserved, so hand-written metadata is never lost. An empty value removes the
field.

## Knit manager

Choose HTML, PDF or Word and press **Knit**. The manager:

- disables nothing silently: an unavailable format explains what is missing;
- records every attempt in the knit history, with duration and errors;
- opens the result in the HTML preview;
- offers **Open** and **Download** for a successful knit.

HTML needs `rmarkdown`, `knitr` and Pandoc. PDF also needs a LaTeX
installation (`pdflatex`). Word needs Pandoc. An Rnw document knits to PDF.

## Autosave and recovery

When a document has unsaved changes, autosave writes a recovery copy every 30
seconds. A banner appears when a recovery file is found. **Save** writes the
document and creates a `.bak` backup of the previous version; saving removes
the recovery file.

## Reproducibility rules

| Action | Command? |
|---|---|
| Edit text | No |
| Markdown preview | No |
| Run a cell | Yes, through `run_command()` |
| Insert output or plot | No, document content |
| Knit | Yes, re-executes the chunks |
| YAML form | No, metadata |
| Template | No, initial text |
| Autosave | No, recovery file |

## Troubleshooting

- **HTML is unavailable**: install `rmarkdown` and `knitr` and make sure Pandoc
  is on the path (`rmarkdown::pandoc_available()`).
- **PDF is unavailable**: install a LaTeX distribution and check
  `Sys.which("pdflatex")`.
- **A chunk fails during knit**: the inline cell output shows the same error;
  fix the chunk and knit again. The knit history keeps the failure.
- **The preview differs from the knit**: the preview does not execute code and
  does not resolve chunk options; the knit does.
- **A recovered document is marked unsaved**: recovery creates a new document;
  save it to a file to clear the flag.

## See also

- `topic:document-authoring`
- `topic:exporting-results`
- `topic:data-studio`
- `topic:chart-studio`
