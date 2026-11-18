---
id: about-studio
title: About RcmdrShiny Studio
type: reference
category: getting-started
keywords: [about, studio, identity, version, license, upstream, theme, density, accordion, picker, listbox, slider]
aliases: [about, version, license]
dialogs: [helpAboutCommander]
commands: []
packages: [RcmdrShiny]
related: [getting-started, help-center]
language: en
status: documented
---

# About RcmdrShiny Studio

**RcmdrShiny Studio** is a local, browser-native statistical workbench
**inspired by** the R Commander (Rcmdr). It is not a pixel-for-pixel clone of
R Commander.

The package keeps the engine and the reproducible command semantics of Rcmdr
2.15.0: every action in the interface produces a visible R command in the
script log, the output and the report.

## Studio and Classic

- **Studio mode** is the default interface: Home, Workflows, Data Studio,
  Chart Studio, Report Studio, Script, Output (Console), Environment and
  Help centre.
- **Classic mode** preserves the 1.13 layout with separate Script, Output,
  Messages, Plots, Report, Data, Environment and Help tabs.
- Switch mode from the top bar or from **Options**.

## What Studio adds

- a command palette (`Ctrl+K`);
- a structured command history with rerun, dialog reopening and insertion;
- live R-command preview in dialogs;
- isolated previews for plots and Markdown;
- eight themes — follow system, three light, three dark, high contrast — and
  two densities, Compact and Comfortable, from **Options**;
- one shared vocabulary of cards, notes, toolbars and dialogs, so every view
  and dialog reads the same way.
- a minimal console with Output, Messages and History.

## Parameter panels and widgets

Dialogs with many parameters group them into collapsible panels: *Options*,
*Import text data*, *Frequency Distributions*, the model dialogs and the test
dialogs. Click a panel header to open or close it; the chart builder keeps
*Chart and data* visible and puts the rest one click away. The per-type chart
options are the only nested group.

- **Variable lists** pick their control by length: a native listbox for a
  short multiple choice, a native drop-down for a short single choice, and a
  searchable picker above 12 entries. The value the server reads is the same.
- **Bounded numbers and colours** use the packaged slider and colour picker;
  the generated R command is the same as with a plain field.
- **Keyboard**: `Tab` moves through the fields, `Enter` or `Space` opens a
  panel, `Up` and `Down` move between the headers of one accordion, `Home` and
  `End` jump to its edges, and `Esc` still closes the dialog.
- **Validation**: when a dialog is rejected, every panel opens and the first
  invalid field is focused, so an error cannot stay hidden.

## Attribution

RcmdrShiny is derived from Rcmdr 2.15.0, Copyright (C) 2001-2026 John Fox,
Milan Bouchet-Valat and contributors, distributed under GPL-2+. See `NOTICE`
and `UPSTREAM.md` in the package sources.

## See also

- `topic:getting-started`
- `topic:help-center`
