---
id: keyboard-shortcuts
title: Keyboard shortcuts and accessibility
type: reference
category: help
keywords: [keyboard, shortcut, accessibility, focus, tab, screen reader]
aliases: [shortcuts, accessibility]
dialogs: []
commands: []
packages: [RcmdrShiny]
related: [help-center, troubleshooting]
language: en
status: documented
---

# Keyboard shortcuts and accessibility

RcmdrShiny is a browser application, so the browser's own shortcuts apply in
addition to the ones listed here.

## Navigation

| Action | Shortcut |
|---|---|
| Move to the next control | `Tab` |
| Move to the previous control | `Shift` + `Tab` |
| Activate the focused button or link | `Enter` or `Space` |
| Close a dialog | `Esc` when the dialog allows it, otherwise **Cancel** |
| Skip to the main content | `Tab` from the top of the page, then `Enter` on "Skip to main content" |

## Studio shortcuts

| Action | Shortcut |
|---|---|
| Open the command palette | `Ctrl` + `K` or `Ctrl` + `Shift` + `P` (`Cmd` on macOS) |
| Run the selection or the current chunk | `Ctrl` + `Enter` |
| Run the whole script | `Ctrl` + `Shift` + `Enter` |
| Save the current document | `Ctrl` + `S` |
| Save the document as | `Ctrl` + `Shift` + `S` |
| Switch to the nth Studio tab | `Alt` + `1` ... `Alt` + `9` |
| Open the Help tab | `F1` |
| Show the shortcut list | `Ctrl` + `/` |
| Close the palette or a modal | `Esc` |
| Move through palette results | `ArrowUp` / `ArrowDown`, then `Enter` |

## Dialog fields

- Variable lists support `Ctrl`-click and `Shift`-click for multiple selection.
- `Enter` in a single-line field submits the dialog when the field is the last
  control.
- **Reset** restores the values the dialog had when it opened.
- The **R command** panel shows the command that will be executed; **To
  script** inserts it without running it.
- The preset bar can save and reapply the current dialog values.

## Help tab

| Action | Shortcut |
|---|---|
| Focus the search box | `Tab` until the box is focused |
| Open the first result | `Enter` in the search box |
| Move between categories | `Tab` and arrow keys |

Search results are announced through an `aria-live` region, and each category
link has a descriptive label.

Search filters (`type` and `source`) and the category list combine with the
query. **Clear filters** resets them without clearing the topic pane.

## Help and learning

| Action | Where |
|---|---|
| Open the help centre | Help tab, or **Help > Help centre** |
| Search the help | **Help > Search help...** |
| Open the guided tour again | **Help > Guided tour** |
| Open the glossary | **Help > Glossary** |
| Open the shortcut list | `Ctrl` + `/` |
| Run a documented example | **Run** in the topic's Examples section |
| Insert an example in the script | **Insert into script** in the topic |
| Report a problem | **Report an issue** at the end of a topic |

## Language and theme

The language and theme selectors are in the top bar. Menus, help topics,
notifications and newly rendered panels use the new language immediately;
static chrome (for example the top-bar brand) is refreshed when the page is
reloaded. The choice is saved in the session preferences.

## Accessibility features

- Landmarks: the sidebar has `role="navigation"` and the content area
  `role="main"`.
- A "Skip to main content" link is the first focusable element.
- Dialog titles are announced by the browser's modal implementation.
- The light, dark and high-contrast themes keep readable contrast ratios.
- Text scales with the browser zoom without breaking the layout.
- The command palette and the history cards are keyboard reachable.

## Reporting a problem

If a control cannot be reached with the keyboard, open **Help > Diagnostics**,
copy the report and include it in the issue.

## See also

- `topic:help-center`
- `topic:troubleshooting`
