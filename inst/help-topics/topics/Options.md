---
id: Options
title: Options
type: task
category: tools
order: 240
keywords: [options]
aliases: []
dialogs: [Options]
commands: [options]
packages: [RcmdrShiny]
related: []
language: en
status: documented
---

## What it does

The **Options** dialog is the menu entry `Tools > Options...`.

## Interface options

- **Interface mode** switches between the Studio workspaces and the Classic
  R Commander tabs.
- **Theme** picks a light, dark or high-contrast palette, or follows the
  system setting.
- **Density** controls how much space the fields take: **Compact** (default)
  keeps more fields on the screen and lays the dialog out in columns,
  **Comfortable** restores the wider Bootstrap spacing. The choice is saved
  with the other preferences and applies to every dialog and panel.

## How to fill it in

1. Choose the active data set if the dialog offers a selector.
2. Select the variables and options you need.
3. Press **OK**.

## What it produces

The generated command is written to the **Script** tab and evaluated in
the current session. Printed results appear in the **Output** tab; plots
appear in the **Plots** tab.

## R reference

`?options` (RcmdrShiny)

## See also

Browse the **Help** tab for related topics.
