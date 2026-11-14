---
id: help-center
title: Using the help centre
type: concept
category: help
keywords: [help, search, topics, documentation, find, guide]
aliases: [help, documentation, search-help]
dialogs: []
commands: [help_search, help_topic, help_index]
packages: [RcmdrShiny]
related: [keyboard-shortcuts, glossary, navigation-workflows, writing-help-topics]
language: en
status: documented
---

# Using the help centre

The **Help** tab combines the task-oriented topics shipped with the core and
with the loaded plugins.  It works offline and needs no internet connection.

## Open the help centre

- Click the **Help** tab.
- Use **Help > Help centre** in the sidebar.
- Press the **Help** button in any dialog to jump straight to that dialog's
  topic.

## Search

Type one or more words in the search box.  Results come from a full-text index
that weighs titles highest, then keywords and aliases, then headings and
finally the body.  An exact title match is always ranked first.  Partial words
work: `summar` finds "Numerical summaries".

Each result shows its type, its source (core or plugin), its category and a
snippet with the matched words highlighted.  Click it to open the topic.

The **type** filter limits results to guides, references, tutorials or
troubleshooting notes; the **source** filter chooses the core or a single
plugin.  Filters and the category list can be combined.  **Clear filters**
resets them.

## Browse by category

The left column lists categories: Getting started, Data, Statistics, Models,
Graphs, Distributions, Reports, Tools, Workbench, Plugins, Using the help and
Troubleshooting.  Plugin topics appear under **Plugins**, prefixed with the
plugin name.

## Inside a topic

- The table of contents links to the headings on the page.
- Links to other topics (`topic:...`) open in place.
- **Related dialogs** opens the existing dialog without leaving the help.
- **Commands cited** lists the R functions the topic talks about.
- **Examples** shows the documented code.  Examples marked as runnable have a
  **Run** button; the command is shown for confirmation and then executed
  through the normal command engine, so it appears in the history and the
  output.
- **Insert into script** adds an example to the current script without running
  it.
- The **R reference** link at the bottom opens the underlying Rd page when one
  exists.
- **Report an issue** opens a diagnostics report that can be copied into a bug
  report.
- **Copy link** copies the stable `topic:<id>` reference.

## Contextual help

Every dialog knows its topic.  When a dialog is open, the help centre can jump
to "Help on this window", and the dialog's **Help** button opens the same
content in a modal.

When a command fails, the error card offers the help topic that most likely
explains it: missing objects point to data import, missing functions to package
loading, factor errors to the conversion dialog, and knit failures to report
authoring.

## Glossary and tour

The [glossary](topic:glossary) defines the statistical and interface terms used
throughout the application.  The guided tour is shown on first use and can be
restarted from **Help > Guided tour**.

## From R

```r
RcmdrShiny::help_search("logistic regression")
RcmdrShiny::help_topic("linear-model")
RcmdrShiny::help_index()
```

## See also

- `topic:keyboard-shortcuts`
- `topic:getting-started`
