---
id: menu-structure
title: Menu structure and stable IDs
type: reference
category: workbench
keywords: [menu, menubar, hierarchy, save, module, plugin, id, stable, sdk]
aliases: [menus, menu-registry, stable-ids]
dialogs: []
commands: []
packages: [RcmdrShiny]
related: [navigation-workflows, writing-plugins, keyboard-shortcuts]
language: en
status: documented
examples:
  - code: "RcmdrShiny:::menu_leaves(RcmdrShiny::menu_tree())"
    title: "Inspect the menu leaves and their stable ids"
    runnable: true
---

# Menu structure and stable IDs

The application uses a horizontal menubar with nested submenus, grouped by
workflow in the style of SPSS and Minitab. The routines are unchanged: every
leaf still points to the same command the old flat menu used.

## Top level

```text
File  Edit  Data  Transform  Analyze  Graphs  Reports  Utilities  Help
```

- **File** — new/open/save, import, export and exit.
- **Edit** — editor actions, find and selection.
- **Data** — data sets, import, active data set and data dictionary.
- **Transform** — compute, recode, factors, missing values and variables.
- **Analyze** — summaries, tables, means, proportions, variances,
  nonparametric tests, models and distributions.
- **Graphs** — base, lattice, ggplot2, 3D and the chart gallery.
- **Reports** — document, authoring, knit and export.
- **Utilities** — modules, options, diagnostics and health.
- **Help** — help centre, search, glossary, shortcuts, tour and diagnostics.

## One Save, many formats

```text
File > Save
├─ Data set...
├─ Script...
├─ Report (R Markdown)...
├─ Report (knitr)...
├─ Workspace...
└─ Save as
   ├─ Script as...
   ├─ R Markdown as...
   ├─ knitr as...
   └─ Workspace as...
```

The item labels are the only thing a user sees; the command beneath them is
still `saveDataSet`, `saveLog`, `saveRmd`, `saveRnw` or `saveWorkspace`.
Reproducibility is therefore unchanged.

## Stable IDs

The menu registry separates four identifiers:

| Field | Example | Meaning |
|---|---|---|
| `module_id` | `core`, `survival` | First-party module |
| `menu_id` | `menu.file.save` | Group in the hierarchy |
| `item_id` | `file.save.script` | Leaf, immutable across reordering |
| `command_id` | `saveLog` | Engine command, unchanged |

The DOM id is derived from `item_id` (`menu_item_file_save_script`), not from a
row counter. Reordering or renaming a menu does not change it. The same
`command_id` may appear in two places, but each occurrence has its own
`item_id`.

## Registry files

```text
inst/menus/core.yml
plugins/<module>/inst/menus/module.yml
```

Each fragment declares `groups`, `items` and optional `removes`. A module can
remove an individual core command it replaces, but it does not delete a whole
core menu: the curated shell and its help entries stay available.

The loader validates unique IDs, existing parents, cycles and command
references. The test suite also checks that every command reachable in the
legacy menu is still reachable after the redesign.

## Inspect the registry from R

```r
registry <- RcmdrShiny:::menu_registry_cached()
RcmdrShiny:::menu_registry_validate(registry)
leaves <- RcmdrShiny::menu_leaves(RcmdrShiny::menu_tree())
leaves[, c("item_id", "menu_id", "command", "path")]
```

## See also

- [Navigation and guided workflows](topic:navigation-workflows)
- [Writing plugins](topic:writing-plugins)
- [Keyboard shortcuts](topic:keyboard-shortcuts)
