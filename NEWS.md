# RcmdrShiny Studio 3.1.0

## Orientation

- **One truth for the grid.** With a filter on, the status bar, the data info
  line and the grid all describe the visible frame ("12 of 5,000 x 5"), and a
  neutral funnel chip names the filter. Clearing the filter restores the
  totals; the filter remains a view, never a change to the data.
- **A visual grammar.** Four meanings, always colour plus icon plus text:
  accent for "you are here", warning for a limit, danger for a failure and
  selection for the current selection. `context_chip()` is a thin wrapper over
  the existing badge, so there is one badge system.
- **A context line in every Studio view.** View, data set, filter and
  Rows/Cells mode in one static line; it is text, not another control, so it
  adds no tab stop. Classic keeps its tabs and `data-value` attributes.
- **A status bar with priorities.** Identity (data set, visible shape, filter),
  selection and last action, in three named groups. The version moved to
  **Help > About**, the counts to Console, History and Chart Studio, and the
  compact bar drops only the shape, which stays in the data info line.
- **Labeled slots.** When the workspace is split, each slot names its role and
  its view (`Primary · Data Studio`) and carries an accent or strong border.
  The accessible name is `Primary view: <view>` / `Secondary view: <view>`;
  `F6` is unchanged.
- **Predictable return.** `Esc` closes one layer per press: an inner layer
  (tooltip, menu, cell selection) that claims the key wins; a dialog closes
  before the modeless panel underneath. Button and `Esc` share the same
  focus-return path; **Reset layout** closes the modeless panel and leaves the
  focus on the workspace.
- **A start page that tells the truth.** With no data set, no open project and
  no recent project, Home shows four doors: import a file, create a new data
  set, open a project, or continue without data. It is a Home state, not a
  modal, and the normal Home returns as soon as there is something to
  continue.
- **No dead ends.** The six empty states (Data Studio, Environment, Charts,
  Report, Console, Help) each name the next action with the existing dialog.
  Filters and their visible shape are announced politely; the status bar keeps
  a long error to one readable line, with the full text in Output and in the
  `title`.

# RcmdrShiny Studio 3.0.0

## Desktop workspace

- **One navigation.** Studio has a single horizontal menubar with `Alt`/`F10`
  access, and the workspace shows one view at a time instead of a tabset of
  every view. `input$main_tabs` stays the navigation contract. Classic keeps
  its original tabs, labels and `data-value` attributes.
- **Two slots.** A primary view and an optional secondary view render as two
  distinct slots with their own outputs; a saved layout chooses the split.
  The same view cannot be shown twice, and switching slots loses no state.
- **Panels.** The Data Studio Inspector and the Chart Studio Preview can be
  hidden without losing data or output; the hidden panel's output is not
  built. Help, Console and Output can open in a modeless panel with a title
  and a *Back to workspace* button.
- **Undo and redo.** `Ctrl+Z` and `Ctrl+Shift+Z` work outside text entry for
  data changes and gallery pins, with an Edit menu entry and a status-bar
  message. The stack keeps 20 entries or 50 MB, a project load clears it, and
  a gallery undo restores the metadata, not the deleted PNG.
- **Rows and Cells.** Data Studio selects rows as before, or a rectangular
  cell range copied as TSV with `Ctrl+C`; the status bar reports the range,
  its size and the non-empty cells. `Esc` clears.
- **Resizable windows.** Dialogs remember their size per dialog id and expose
  a keyboard-accessible grip. Sizes are preference data, never statistical
  state.

## Desktop chrome and geometry

- Topbar 40 px, menubar 28 px, view bar and toolbar 40 px, radii 4/6/8 px,
  flat cards with a 1 px border. Every rule is scoped to
  `body.rcmdr-mode-studio`, so Classic keeps its spacing.
- Home is a two-column start page (actions and keyboard on the left,
  Continue/Recent/Projects on the right); the hero and its gradient are gone.
- Theme, language and density moved from the topbar to **View >
  Preferences...** (the Options dialog). Hidden `theme` and `language`
  inputs keep the existing observers for Ace, menus and help alive.
- A versioned `geometry` object remembers the last view, the sidebar, the DT
  column widths per data set and the dialog sizes. An old or corrupt file
  falls back to the default. **View > Reset layout** restores the layout
  without touching the data, the history, the log or the undo stack.
- The status bar names the data set, its shape, the model, the selection and
  the last action; `F6`/`Shift+F6` cycle primary, secondary, inner panel,
  modeless panel and status bar. Selection and undo are announced through a
  polite live region.

## Large data

- The grid switches to server-side paging above **5,000 rows** and to the
  browser editor below **10,000 cells**, decided in one place
  (`data_grid_plan()`). A visible notice names the limit that applies and
  what still works (reading, selection, copy).
- The thresholds are measured, not guessed: the client payload grows from
  474 KB at 10,000 rows to 4.9 MB at 100,000 rows, while a server page stays
  1.3 KB. The method, the table and the memory figures are in
  `docs/upgrades/QA-DATA.md`.
- No new table engine: if 100,000 rows are not enough, the documented
  `rtabulator`/`toastui` gate is the next step.

## Accessibility

- The data grid is a keyboard tab stop: arrows move a row cursor,
  `Enter`/`Space` select, `Shift`+arrows extend a cell range, `Esc` clears.
- The DT column grip is a focusable `separator`: arrows change the width by
  16 px and `Home` returns to the automatic width.
- At 200% zoom the CSS viewport falls below the breakpoint, so the shell
  becomes one column and the stacked sidebar stays within 40vh. Reduced
  motion still zeroes animations and transitions.
- A new browser e2e file covers F6 focus, the 640 px reflow and the theme
  classes; it is skipped, like the rest of the suite, where Chrome cannot
  navigate to `http(s)`.

No statistical command, dialog id, generated R command or existing i18n
string changed.

# RcmdrShiny Studio 2.9.0

## Desktop completion

- **Help where it is needed**: `help_tip()` adds a focusable question-mark
  trigger with a themed tooltip to the densest parameters; `Esc` closes the
  bubble without closing the dialog.
- **Dates**: `date_input()` and `date_range_input()` wrap the packaged
  air-datepicker, and the Data Studio filters a `Date`/`POSIXct` column by an
  inclusive calendar range. The filter is a view: it writes neither the data
  nor a command.
- **Feedback**: notifications use the Studio tokens and keep the newest
  three; long operations set `aria-busy` and announce themselves in a polite
  live region.
- **Split panes**: `split_pane()` gives Data Studio, Chart Builder and Report
  Studio a keyboard-accessible separator (arrows, Home/End, reset). Sizes are
  versioned preferences and survive a restart; below the breakpoints the panes
  stack and the separator leaves the layout.
- **Context menus**: `context_menu()` opens from the context-menu key or
  `Shift`+`F10`, keeps one panel open, stays inside the viewport and returns
  the focus. Items click the existing controls or send the existing payload,
  so no action is implemented twice.
- **Drag and drop**: pinned charts reorder in the gallery, grid headers
  reorder the view columns, and a dropped text file opens the normal Read Text
  Data dialog. Every gesture has a keyboard alternative, and neither the data
  nor the commands change.
- **Read-only tables**: the `reactable` gate stayed closed (about 3.6 MB of
  front-end for four tables); native tables gained sticky headers, the DT row
  rhythm and a focusable scroll region.
- **Plugin dialogs**: `settings_accordion()` and `settings_panel()` are part
  of the plugin API. ROC, UCA, Export, PcaRobust and sos group their fields;
  the ten short dialogs stay flat and are listed in
  `docs/upgrades/PLUGIN-DIALOGS.md`.
- **Help and palette**: the Help source filter is a searchable picker with a
  live result count; the palette keeps the query focus and announces the
  active option through `aria-activedescendant`, with Home/End added.
- **Lazy views**: Gallery, Models, Help, Report and Environment outputs are
  built on first open and rebuilt from current state; no hidden view keeps a
  stale copy. `app_ui()` and the command engine are unchanged.

No statistical command, dialog id, generated R command or existing i18n
string changed. The browser e2e suite remains skipped where Chrome cannot
navigate to `http(s)`; `tools/check_browser.R` records the limit.

## Data editor hardening

- The cell editor is bound to the data set and the view that rendered it: a
  stale editor left over from another data set or from View mode cannot be
  applied. Apply reports why instead of writing cells.
- Row insertion/removal and column sorting are disabled in the grid until
  they have a reproducible command; column resizing remains.
- Factors keep their ordered flag and gain a declared new level, dates and
  `NA` keep their type, and date-time/list columns are read-only in the
  editor. Invalid numeric, logical or date edits are refused before a command
  is generated.
- Edits in one column become one R command (`D[c(2, 4), "a"] <- c(...)`)
  instead of one command per cell; the checkpoint is unchanged.

# RcmdrShiny Studio 2.8.0

## Parameter panels and one widget family

- **Accordions for parameter-dense screens**: `settings_accordion()`,
  `settings_panel()` and `settings_group()` wrap bslib's accordion and add the
  Studio's heading semantics, chevron, density and focus ring. The *Options*
  dialog is five panels; the Chart Builder keeps *Chart and data* always
  visible and puts its remaining options into *Options*, *Style*, *Axes*,
  *Text*, *Theme* and *Output*. Import, Frequency Distributions, model and
  test dialogs group their fields by task. Every input id, default and
  generated R command is unchanged.
- **One control per list role**: a short single list stays a native
  `<select>`, a list that must stay visible is a native `<select multiple>`,
  and a long list opens the searchable virtual select. `var_input()` routes
  all 106 call sites by length (threshold 12); the server reads the same
  string or character vector as before.
- **Bounded numbers and colours**: `slider_input()` draws alpha, jitter, base
  size and notch width on a local noUiSlider, and `color_input()` replaces
  the free-text background field with the packaged Spectrum picker. The
  values and the commands they produce are unchanged.
- **Errors reach the field**: validation still returns the historical `error`
  and now adds `field_errors`. A rejected dialog opens every closed panel,
  marks the field with `aria-invalid`, focuses the first invalid field that
  has a box, and leaves hidden conditional fields alone.
- **Keyboard and names**: accordion headers are headings with `aria-level`;
  Up/Down, Home and End move between the headers of the same accordion. The
  virtual select is named by its visible label, noUiSlider handles expose
  `role="slider"`, and the Spectrum replacer is a button reachable with
  `Tab`, `Enter` and `Space`. `Esc` remains Bootstrap's modal contract.
- **Desktop chrome**: DT rows use 32 px in Compact and 40 px in Comfortable
  with a sticky header, hover and selection on every palette; rhandsontable
  uses the same height. Alerts, progress bars and scrollbars read the status
  and surface tokens instead of Bootstrap's stock palette. The code and report
  editors choose a packaged light or dark Ace theme from the selected palette.
- **What remains ours**: cards, notes, toolbars, tabs, badges, segmented
  controls, switches, icons and the dialog chrome are still the Studio's own
  components. No statistical parameter, dialog id or i18n string changed, and
  no remote asset was added.

## Interface refresh — one component vocabulary

- **Shared components in every view**: the shell, Home, Data Studio, Chart
  Studio, Report Studio, Script, Help and the workflow panel now build their
  headings, notes, action rows, toolbars, tab strips, badges and dialog chrome
  from `card_head()`, `note()`, `action_row()`, `toolbar()`, `tabs_strip()`,
  `badge()`, `modal_header()`, `modal_footer()` and `modal_shell()`. Every
  dialog keeps its ids, its six footer actions and their order; only the
  markup around them changed.
- **Forms read in one vocabulary**: `field()`, `field_grid()`,
  `segmented_input()`, `switch_input()` and `number_input()` replaced the
  hand-written Bootstrap columns and rows in the dialogs and studios. Numeric
  options are still `type=number` inputs with the same `min`, `max` and `step`;
  the server reads the same values.
- **Layout without layout utilities**: the Studio shell and the views use
  named `.rcmdr-*` grids and flex rows instead of `d-flex`, `gap-*`, `col-*`
  and `row g-*`. The responsive breakpoints live in `10-shell.css`,
  `20-components.css` and `60-views.css`; Classic mode keeps its own tabset
  and values untouched.
- **One type and spacing scale**: four text steps, two display steps, two
  control heights and a single focus ring are tokens in `00-tokens.css` and
  documented in `docs/upgrades/UI-TOKENS.md`. Density selects spacing only;
  the colours never change between Compact and Comfortable.
- **Eight themes by two densities**: the matrix is walked by
  `tests/testthat/test-theme-matrix.R`; text, muted text, primary text and
  control borders clear WCAG AA / 3:1 at every combination, and every theme
  resolves to a palette block and a body class the client applies.
- **Accessibility**: one `:focus-visible` outline on every control, a
  `prefers-reduced-motion` block, a labelled command palette, `Esc` and the
  static backdrop left to Bootstrap's modal contract, and the
  `visually-hidden` class kept for screen-reader labels.
- **Secondary dialogs**: the command palette, keyboard shortcuts, tour and
  project recovery use the same header and footer as the catalogue dialogs;
  the tour step is the header category, and the palette is named by its
  heading.

## Navigation — the tabs are windows, not a second menu

- **Compact interface by default**: dialogs and panels use a denser form
  layout. Fields sit in an automatic 2–4 column grid instead of one per row,
  labels and controls are smaller, and the spacing between blocks is a token
  (`--rcmdr-field-gap`, `--rcmdr-label-size`, `--rcmdr-control-min`, …) rather
  than a hard-coded number. On the same 1280 px screen the *Read text data*
  dialog went from 945 px of content to 608 px (−36%) and fits without
  scrolling; the Chart Studio form gains a second column in its narrow panel.
- **Density switch**: **Options > Density** offers *Compact* (default) and
  *Comfortable* (the previous spacing). It is stored in `preferences.rds` and
  applied through the `rcmdr-theme` message together with the theme, so it
  survives a restart.

- **Draggable dialogs**: every modal can be moved by dragging its header, so
  the data or the plot underneath stays usable while a dialog is open. A double
  click on the header puts it back where it opened, the offset is clamped so the
  header never leaves the window, and buttons, inputs and links in the header
  keep their normal behaviour. Touch and pen work through pointer events; the
  position is a CSS transform, so Bootstrap keeps its own centring.

- **Stable view ids**: every main tab carries a `value` (`data`, `charts`,
  `report`, `console`, `environment`, `help`, …). `state$show_tab()` resolves a
  view id, an English label or a translated label to the tab through
  `main_view_aliases()`, and the browser handler selects the tab by
  `data-value`. Renaming a tab or switching language can no longer break
  navigation silently, and the Console sub-tabs gained ids too.
- **Window names instead of menu verbs**: in Studio mode the tabs read
  **Data Studio**, **Chart Studio**, **Report Studio**, **Output (Console)** and
  **Help centre**, so they are no longer confused with the *Data*, *Graphs*,
  *Reports* and *Help* menus. Classic mode keeps the R Commander window names
  unchanged.
- **The tab strip is a segmented control**, visually distinct from the
  menubar, so the two horizontal bars are no longer read as a menu and a
  submenu.
- **Result hint**: after a dialog command the interface says where the result
  landed, for example *Analyze › Summaries › Numerical summaries → Result in:
  Output (Console) ▸ Output*, with **Show result**, an **Open automatically**
  switch (persisted in the preferences) and a dismiss button. A classic
  interface opened the result window; this one now offers to.

## Chart Studio — one engine and four extensions

- The **base R engine is gone from the Chart Studio**: every chart is a ggplot2
  object. `chart_spec_engine()` normalises legacy `engine = "base"`
  specifications, and the Engine selector disappeared from the builder. The
  classic Graphs dialogs are untouched and keep emitting base R code; the
  builder button is now labelled *Open in the classic dialog (base R code)*.
- **patchwork**: new `compose` chart type that assembles two or more gallery
  charts with layout presets (side by side, stacked, 2x2, top + two below,
  automatic wrap), collected legends and panel tags.
- **ggstatsplot**: nine statistical types (`stat_compare`, `stat_within`,
  `stat_hist`, `stat_dot`, `stat_scatter`, `stat_corrmat`, `stat_pie`,
  `stat_bar`, `stat_coef`) that print the test result in the subtitle.
  `stat_coef` graphs a model already estimated in the session. The types are
  hidden when the package is missing; the Bayesian approach warns about
  `BayesFactor`.
- **hrbrthemes**: six editorial themes in the theme selector and axis formats
  (percent, thousands separator), with an automatic fallback to the system sans
  when the expected font is not installed.
- **Quarto**: the Report Studio can download the open document as `.qmd` with a
  format preset (HTML, Word, PDF via typst, GitHub Markdown). *Render with
  Quarto* appears only when the R package and the CLI answer. The chart
  chunk helper writes `#| label: fig-...` and `#| fig-cap:` for cross
  references.
- **Models view**: a new tab next to Build and Gallery groups ready-made chart
  recipes by analysis family and by chart type, with search, extension badges
  and a direct *Open* that loads the type, theme and options in the builder.
  The gallery gained an analysis filter.
- **Dependencies**: `patchwork`, `ggstatsplot`, `hrbrthemes`, `systemfonts`
  and `quarto` moved to `Imports`, so installing the package installs the whole
  ecosystem. The runtime checks remain, and every chart still degrades
  gracefully if a package is removed; only the Quarto CLI (a system tool, not
  an R package) is still optional.
- Options → *Optional extensions* reports what is installed, what is missing
  and the exact `install.packages()` call.
- The hrbrthemes entries in the theme selector sent their label instead of the
  theme id, so choosing *Ipsum RC* silently produced `theme_minimal()`; the
  selector now emits `theme_ipsum_rc` and friends.
- `tests/testthat/test-chart-extensions-e2e.R` drives the new structure in a
  real browser (ggstatsplot preview, axis formats, patchwork composition,
  Models view, `.qmd` download).

# RcmdrShiny Studio 2.7.0

## Dependencies — ggplot2 and plotly are now required

- `ggplot2` and `plotly` moved from `Suggests` to `Imports`: installing
  RcmdrShiny now installs both automatically.
- The ggplot2 engine is always offered; plotly interactivity and HTML export
  no longer depend on an optional install.
- The `ggplotly` capability probe remains, because a plotly/ggplot2 version
  mismatch can still prevent conversion.
- Documentation and the requirements list were updated; `svglite`,
  `htmlwidgets`, `rgl` and the reporting packages remain optional.

# RcmdrShiny Studio 2.6.0

## Wave 13 — Interactive preview in the builder

- The Build panel now shows a **plotly widget** when the preview has an
  interactive version: hover, zoom and point selection while editing.
- Falls back to the static PNG when plotly is unavailable or the chart has no
  interactive expression.
- The builder uses its own plotly source (`rcmdr-build`), so selection events
  never mix with the gallery detail (`rcmdr-chart`).
- Scatter selection shows the selected count and **Create data set from
  selection**, producing the same reproducible subset command as the gallery.
- Selection is cleared on Refresh, Reset and Apply.
- `chart_subset_selected()` is shared by the builder and the gallery.
- New tests: builder widget source, subset from selection and rejection of
  grouped/non-scatter charts.

# RcmdrShiny Studio 2.5.0

## Wave 12 — ggplot-only chart types

- **Violin plot**: numeric variable by group, with trim, area/count/width
  scaling, bandwidth adjust and an optional boxplot overlay.
- **Empirical CDF**: numeric variable by group, padding and line style.
- **2D density**: two numeric variables, contour bins, bandwidth and optional
  points.
- **Heatmap**: two variables and a numeric value, low/high gradient and
  optional value labels.
- These four types are available **only with the ggplot2 engine**: the type
  selector is filtered per engine, the base engine rejects them with an
  explicit message, and round-trip keeps the engine.
- New tests: engine gating, commands, validation, preview and apply for the
  four types.

# RcmdrShiny Studio 2.4.0

## Wave 11 — Remaining chart types completed

- **Density**: kernel, adjust, rug and grid in base; adjust in ggplot2.
- **Line graph**: line/step/area, line style, line width and an optional
  grouping variable for colour (ggplot2).
- **Bar graph**: bar width and count/percent statistic (ggplot2).
- **Dot plot**: binned dots in base; bin axis, stack direction, dot size and
  bin width in ggplot2.
- **Strip chart**: stack/jitter method plus jitter width/height and point
  shape (ggplot2).
- **QQ plot**: normal/uniform/exponential distribution, reference line,
  confidence envelope and grid; ggplot2 uses `stat_qq(distribution=)`.
- **Plot of means**: connect the means, error-bar width and point size;
  ggplot2 uses `stat_summary` for points, error bars and the connecting line.
- **XY conditioning plot**: points/lines/both plus an optional smooth and
  facet layout.
- All defaults are unchanged; new arguments appear only when the option is
  changed.

# RcmdrShiny Studio 2.3.0

## Wave 10 — Boxplot, histogram and scatter options

- **Boxplot (base and ggplot2)**: notch, notchwidth, variable width, horizontal
  layout, outlier visibility and box width. The horizontal base layout uses
  `boxplot()` because `car::Boxplot()` rejects `horizontal = TRUE`; defaults
  keep the exact `Boxplot(...)` command.
- **Boxplot points (ggplot2)**: optional jitter overlay from the jitter
  control.
- **Histogram (ggplot2)**: the frequency/density/percent selector now maps to
  `after_stat()` instead of being ignored.
- **Scatterplot (base and ggplot2)**: regression line, confidence ellipse,
  grid and jitter. Base emits `regLine`, `ellipse`, `grid` and
  `jitter = list(x =, y =)`; ggplot2 uses `geom_smooth(method = "lm")`,
  `stat_ellipse()` and `geom_jitter()`, with the confidence band controlled by
  the existing “Confidence band” option.
- **Loess vs regression**: the same checkbox pair chooses `lm` or `loess` in
  ggplot2 and `regLine` or `smooth` in base.
- Default commands are unchanged; new arguments appear only when the option is
  changed.

# RcmdrShiny Studio 2.2.0

## Wave 9 — ggplot2 as a first-class engine

- **All 11 chart types** now have a ggplot2 implementation: histogram,
  density, boxplot, scatterplot, line graph, bar graph, dot plot, strip chart,
  quantile-comparison plot, plot of means and XY conditioning plot.
- **Extended mappings** only for ggplot2: facet, size and label, on top of the
  base x/y/group slots. Base commands and specs are unchanged.
- **Shared ggplot2 options**: alpha, bar position, bin width, smooth method and
  confidence band, jitter, point shape, coordinate flip, facet scales and
  columns, ggplot2 theme (minimal, bw, classic, light, dark, void).
- **Labels**: title, subtitle, tag, axis labels and caption via `labs()`.
- **Scales**: log axes, manual fill/colour palettes, facets with free scales,
  multi-series lines with named colours.
- **Single command**: a ggplot2 spec emits one `print(ggplot(...))`; the base
  palette/par/title prefix is no longer added. This also fixes the duplicated
  labels and the malformed scatter + smooth expression.
- **Interactivity**: ggplot2 plots can be converted with `plotly::ggplotly()`
  when the installed plotly and ggplot2 versions are compatible; the HTML
  export follows the same capability gate.
- **Validation** is engine-aware: extended slots are checked, unknown facet or
  size variables are reported, and missing ggplot2 is explained.
- New tests: 11/11 command generation, facets/themes/scales/labels, preview,
  apply and export, base engine regression.

# RcmdrShiny Studio 2.1.0

## Wave 8 — Plugin selection and diagnostics

- **Plugin selection is remembered**: the preferences file stores the chosen
  plugin packages and script paths. `app(plugins = NULL)` now uses that
  selection, `character()` starts with no plugins, and an explicit vector wins
  over the saved one.
- **Plugin manager**: *Utilities > Manage Rcmdr plug-ins...* lists the
  installed `RcmdrShinyPlugin.*` packages with checkboxes, accepts an
  additional script, saves the selection and reloads the registry. A plugin
  that cannot be loaded is reported instead of blocking the manager.
- **Conflicts are visible**: overrides between plugins and with the core are
  recorded in `plugin_conflicts()`, shown in Home > Health, in diagnostics and
  in a one-time notification. Core clashes still require `replace = TRUE`.
- **Deferred loading is measured**: health and diagnostics report how long the
  first catalogue took to materialise and how many plugins were queued.
- **Plugin benchmarks**: load one plugin, load all plugins, first catalogue
  after deferred loading and a warm menu tree, with documented budgets.
- **Dialog contract sweep**: every one of the 235 dialogs renders and returns a
  well-formed `on_ok()` result; explicit UI-to-command tests cover histogram,
  bar graph, scatterplot, correlations and export.
- **Correlation fix**: `cmd_correlation_matrix()` normalises `type`, so the
  Spearman choice now adds `method="spearman"` instead of silently generating
  a Pearson command.
- **Workflow traceability**: `workflow_step_trace()` records the dialog that
  completed each step and the commands it produced.
- **Strict memory mode**: `options(RcmdrShiny.strict_memory = TRUE)` warns when
  a preset or workflow passes memory keys the dialog does not consume.
- New tests: startup selection semantics, preferences roundtrip, plugin
  manager, conflict recording, deferred timing, the plugin benchmark, the
  dialog contract and the core dialog mappings.

# RcmdrShiny Studio 2.0.2

## Wave 8 — Menu availability and plugin robustness

- **Single availability source**: `command_availability()` reads the menu row
  and is used by the renderer, `launch()`, the history and the sidebar.
  `command_enabled()` is now a thin wrapper, so a command the menu disables
  cannot be opened through favourites, recents or the history.
- **Favourites and recents** mirror the menubar: unavailable commands are
  disabled with their reason, `hidden` commands are omitted, and the favourite
  star stays available so entries can still be removed. The stored preferences
  are never modified automatically.
- **Disabled menu items** expose `aria-disabled`, are focusable and announce
  their reason (`Not ported yet`, `Not available for the current data set`,
  `Not available in this environment`). Clicking one keeps the menu open.
- **Distinct messages**: a command that is not ported, one that needs a data
  set and one that is hidden by the environment now produce different
  notifications.
- **Plugin failures no longer abort startup**: each plugin load is isolated,
  failures are recorded and shown in Home > Health and in diagnostics, and the
  remaining plugins still load. Lazy queues record a failure instead of
  retrying it silently.
- **Runtime plugin loading** now asks to reload the page (the command palette
  sees new commands immediately) and states that restarting R removes the
  plugin. The `lazy_plugins` option is documented as deferred loading at the
  first catalogue lookup.
- New tests: availability matrix, disabled markup, favourites/recents, launch
  guard, history guard, plugin failure isolation and the reload message.

# RcmdrShiny Studio 2.0.1

## Menubar fixes (2026-11-15)

- **Wrapping menubar**: on narrow viewports the menubar wraps onto a second
  row instead of scrolling horizontally, so no top-level menu stays hidden
  off-screen. The mobile breakpoint no longer leaves a scroll container behind.
- **Anchored dropdowns**: the mobile dropdown stays attached to its group and
  is repositioned inside the viewport by `rcmdrAlignDropdown()`, replacing the
  fixed `top` that could overlap the page content.
- **Closing on selection**: choosing an item closes the dropdown, as a menubar
  is expected to do.
- **Stable open group**: re-rendering the menu tree no longer closes the open
  group or loops forever. The open group is remembered by `data-menu-group`
  and restored after the re-render; a close reported by a node that has been
  removed from the page is ignored, while the server drops toggle events that
  only echo the state it already has (`menu_toggle_is_echo()`).
- Unit tests pin the `data-menu-group` DOM contract and the echo detection.

# RcmdrShiny Studio 2.0.0

## Wave 7 — Platform, projects, plugins and quality

- **Projects**: versioned `.rcmdrproj` files save data set sources, documents,
  models, plots, presets, favourites and options. Save, open, save as, recent
  projects, atomic autosave and a recovery prompt on start-up.
- **Bundles**: `File > Export > Project bundle...` creates a self-contained
  `.tar.gz` (or `.zip`) with the project, included data and plots.
- **Session checkpoints**: store the active data set, active model and open
  documents; restoring never re-runs a command.
- **Project schema**: entry constructors, pure validation, normalisation,
  v0→v1 migration and path helpers that keep files inside the project folder.
- **Performance**: lazy plugin queues, menu/help/plugin catalogue caches,
  a benchmark suite and caps for cell outputs, knit history and plot gallery.
- **Plugin SDK v2**: versioned internal contract (`plugin_api_version()`,
  `plugin_contract()`), additive components, presets, workflows, chart types,
  report templates and help examples. The 15 first-party modules are covered by
  a contract test.
- **Health and diagnostics**: Home health panel with versions, optional
  packages, plugins, caches, project state and last error; diagnostics now
  include UI mode, feature flags, project, history and caches, with a
  pre-filled issue URL.
- **Quality**: test matrix, visual snapshot (optional), accessibility audit and
  a Studio release checklist.

# RcmdrShiny Studio 1.21.0

## Wave 6.5 — Menu platform and stable ids

- **Horizontal menubar**: File, Edit, Data, Transform, Analyze, Graphs,
  Reports, Utilities and Help, with hierarchical dropdowns and nested
  submenus. The routines and command ids are unchanged.
- **Curated grouping**: one File > Save with data set, script, R Markdown,
  knitr and workspace items, plus a nested Save as group; report authoring,
  models and distributions are grouped under Reports and Analyze.
- **Stable identifiers**: `module_id`, `menu_id`, `item_id` and `command_id`
  are separate. DOM keys derive from `item_id`, not from a row counter, so
  reordering does not break favourites, tests or palette links.
- **Registry files**: `inst/menus/core.yml` and
  `plugins/<module>/inst/menus/module.yml` replace the legacy menu file as the
  layout source. `Rcmdr-menus.txt` remains as the activation and migration
  reference.
- **Validation**: unique ids, existing parents, cycles and command references
  are checked; a golden test confirms every legacy command is still reachable.
- **First-party modules**: the 15 bundled plugins are maintained with the app,
  attach to core groups without redeclaring them, and can remove individual
  core commands they replace. They no longer delete whole core menus.
- **Migration**: expanded menu ids are mapped from the old names; favourites and
  recents keep the stable command ids.
- New `menu-structure` help topic, `menu-platform` vignette, registry tests and
  a browser flow for the menubar.

# RcmdrShiny Studio 1.20.0

## Wave 6 — Help, i18n and onboarding

- **Full-text help index**: cached per registry revision and language, with
  title/keyword/alias/heading/body weights, exact-title boost and prefix
  completion that does not over-match dialog ids.
- **Ranked search and filters**: filter by type, source (core or plugin) and
  category; results show type, source, category and a snippet with highlighted
  terms.
- **Richer topic pane**: on-page table of contents, related dialogs, cited
  commands, related topics, copy-link and report-an-issue actions.
- **Runnable examples**: examples are declared in the front matter; only
  `runnable: true` can run, after confirmation, through `run_command()`. They
  are logged in the history and can be inserted into the script. `{dataset}`
  and `Dataset` placeholders follow the selected data set.
- **Error-to-topic mapping**: missing objects, missing functions or packages,
  factor conversion, missing values, pandoc/knit, file, memory and singular-fit
  errors link to the relevant topic in error cards and dialogs.
- **Glossary and shortcuts**: new `glossary` topic and an updated
  `keyboard-shortcuts` reference covering filters, examples and the tour.
- **Onboarding**: four-step tour with highlight, Skip and Don't show again
  (browser local storage), restartable from Help > Guided tour; Home checklist
  for import, summary, chart, report and the future project step.
- **Live language switch**: in-process PO/TSV catalogue, top bar, menus, tabs,
  help and server messages re-render without restarting R; the language and
  theme persist in the preferences file.
- **Italian coverage**: new Italian translations for the glossary, Data Studio,
  Chart Studio, Report Studio, Workbench, navigation/workflows and the updated
  help centre and shortcut topics, plus a TSV overlay for Studio interface
  strings. `tools/audit_i18n.R` reports the remaining untranslated strings.
- New `help-index`, `help-errors` and `onboarding` modules, tests and CI audit
  step.

# RcmdrShiny Studio 1.19.0

## Wave 5 — Navigation, dialogs and guided workflows

- **Advanced command palette**: menus and dialogs, help, data sets, variables,
  history and workflows, with fuzzy search, type filter, favourites-first
  ordering, disabled reasons, cached index and per-row actions.
- **Favourites and recents**: starred menu rows, sidebar sections, recent
  commands and a small preferences file that survives a restart.
- **Menu search**: live filtering, match highlighting, expand/collapse all and
  persisted expansion.
- **Breadcrumbs**: dialogs and the palette show the menu path of the command.
- **Complete shortcuts**: `Ctrl+Shift+P`, `Ctrl+/`, `F1`, `Alt+1..9`, run-all
  and a shortcut modal.
- **Dialog platform 2.0**: complete command preview, named presets with
  export/import, inline field validation with focus and `aria-invalid`,
  richer selectors with type/missing/unique descriptions and responsive
  modals.
- **Guided workflows**: five workflows (describe, compare, linear model,
  survival, report), step statuses, skip/back/cancel, command recording and a
  draft report section generated from exactly the commands run.
- **Variable suggestions**: contextual actions in the Data Studio inspector,
  based on variable type and availability, opening existing dialogs.
- New `navigation-workflows` help topic and vignette.

# RcmdrShiny Studio 1.18.0

## Wave 4 — Workbench

- **Script Studio**: document tabs shared with the Report Studio, executable
  cells with Run cell/Run above/Run below, clickable outline, parse
  diagnostics, find/replace, formatting with `styler` and autosave.
- **Console**: direct R input with command recall, captured output, plots and
  structured history. Interactive prompts are detected and blocked.
- **Output cards**: search, status/source filters, pinned cards, rerun, open
  dialog, copy, and insertion into the script or report.
- **Structured messages**: severity (error/warning/note), the command and the
  history step, with filtering and rerun.
- **Environment explorer**: objects with class, type, size, read-only preview
  and reproducible Summary/str/Plot/Save/Remove actions, plus the data set
  registry and the model list.
- **Models dashboard**: recognise fitted models, show formula, family, n, AIC,
  BIC and R squared, compare delta AIC and run existing commands (summary,
  ANOVA, effects, diagnostics, influence, VIF, stepwise, export).
- **Reopen dialog with memory**: uses the dialog and memory recorded by the
  fitting command, with a class-based fallback.
- New `workbench` help topic and vignette.

# RcmdrShiny Studio 1.17.0

## Wave 3 — Report Studio

- **Document registry**: multiple open Rmd/Rnw documents with activation,
  closing, dirty tracking and a shared active buffer.
- **Report Studio UI**: toolbar, document selector, clickable outline, chunk
  list, Ace editor, preview tabs and a status bar. Classic mode keeps the
  historical Report iframe.
- **Fast Markdown preview** with `commonmark`: YAML becomes a title block and
  chunks become labelled placeholders. It never executes code.
- **Executable cells**: run one chunk or all chunks, inline collapsible output,
  captured plots and structured-history entries with source `report`.
- **Five templates**: analysis report, data profile, model diagnostics,
  teaching handout and survival report.
- **Contextual insertion**: output, plot, history step, table, data profile,
  model summary, section and chunk.
- **YAML form**: title, author, date, output, TOC, theme, bibliography and
  citation linking. Unknown fields are preserved on round-trip.
- **Knit manager**: format availability with reasons, progress feedback,
  structured errors, history, HTML preview and download.
- **Autosave and recovery**: periodic recovery copies, a recovery banner,
  `.bak` backup before saving and autosave cleanup after a save.
- New Report Studio help topic and vignette.

# RcmdrShiny Studio 1.16.0

## Wave 2 — Chart Studio

- **Chart specification**: a typed list with data set, mapping, options,
  theme, labels and size. The generated command delegates to the matching
  dialog builder, so it cannot drift from the historical engine.
- **Eleven chart types**: histogram, density, boxplot, scatterplot, line
  graph, bar graph, dot plot, strip chart, quantile-comparison plot, plot of
  means and XY conditioning plot.
- **Visual builder**: the mapping and option fields follow the type; the
  **Advanced...** button opens the full Rcmdr dialog with the current values.
- **Isolated live preview**: debounced, cached and never logged; the preview
  never adds a plot to the gallery.
- **Themed commands**: colour-blind-safe, Tableau, Viridis and greys palettes,
  base size, background, grid, legend, title and axis labels.
- **Opt-in ggplot2 engine** for histogram, density, boxplot, scatterplot,
  line graph and bar graph.
- **Gallery**: search, type filter, pinned-only view, detail with metadata,
  command and specification, pin, rename, delete, compare, copy code and
  insert into the report.
- **Round-trip**: the specification is attached to every applied plot and can
  be reopened in the builder.
- **Export**: PNG, PDF, SVG (with `svglite`) and HTML for interactive plots.
- **Interactive selection**: select points in an ungrouped scatterplot and
  create a reproducible subset.
- **Data Studio integration**: chart plots use the same gallery and report
  path as dialog plots.
- New Chart Studio help topic and vignette.

# RcmdrShiny Studio 1.15.0

## Wave 1 — Data Studio

- **Data set registry**: every data frame in the evaluation environment is
  registered with rows, columns, classes, source, modification time and
  editable status; the active data set can be switched from the Data toolbar.
- **Data grid**: client-side DT grid with global search and a server-side
  view of column filters that never modifies the data; row selection is
  mapped back to original row numbers.
- **Column inspector**: type, label, units, missingness, unique values,
  numeric statistics and a compact distribution plot.
- **Reproducible structural operations**: add, duplicate, rename, reorder and
  delete columns; add, duplicate and delete rows; change column type; create
  a subset from the current selection. Every operation is an R command.
- **Session checkpoints**: a checkpoint is created before data mutations and
  can be restored from the Data Studio. Restoring is a session operation and
  is recorded as a note in the structured history, not as a script command.
- **Data dictionary**: variable labels, units and descriptions stored as
  attributes and exported to CSV/YAML.
- **Import wizard** with a preview of the first rows, delimiter detection and
  proposed column types.
- **Targeted mode for large data sets**: above the interactive editing
  threshold the editable grid is replaced by targeted column and row actions.
- New Data Studio help topic and vignette.

# RcmdrShiny Studio 1.14.0

## Wave 0 — Studio foundations

- New product identity: **RcmdrShiny Studio**, a browser-native statistical
  workbench inspired by the R Commander. The package remains `RcmdrShiny` and
  the command-generation semantics are unchanged.
- **Studio mode** (default) and **Classic mode** (the 1.13 layout), switchable
  from the top bar and from **Options**.
- New **Home** tab with quick actions, active data/model, recent commands and
  environment health.
- New **command palette** (`Ctrl+K`) over menu entries, help topics, datasets,
  variables and the structured history.
- New **structured command history** (`state$history`) beside the existing
  `state$log`: every command records its source, dialog, memory, status,
  output, messages, plot and duration. History cards can rerun a command,
  reopen its dialog, or insert it into the script/report.
- New minimal **Console** workspace with Output, Messages and History
  sub-tabs. Interactive commands are detected and blocked with an explanation.
- **Live R-command preview** in every dialog, plus "To script" without
  executing and named dialog presets.
- New **isolated preview engine** for base plots, plotly and Markdown; previews
  never touch the log, output or plot gallery.
- New design tokens and components; light, dark, high-contrast and system
  themes; keyboard shortcuts and focus/ARIA improvements.
- Feature flags gate the Studio modules while the new workspaces land.

# RcmdrShiny 1.13.0

## Document authoring (D1-D5)

- The **Script** tab now edits three kinds of buffer: a plain R script, an
  **R Markdown** document and a **knitr** document.  Switching mode converts
  the buffer without losing code.
- Dialogs append their commands as code chunks in document mode; the new
  **Section**, **Remove block** and **Remove section** buttons edit the
  document structure.
- New commands and dialogs: `loadRmd`, `loadRnw`, `saveRmd`, `saveRnw`,
  `saveRmdAs`, `saveRnwAs`, `newRmd`, `newRnw`, `editMarkdown`, `editKnitr`,
  `removeLastRmdBlock`, `removeLastRmdSection`, `removeLastRnwBlock`,
  `insertSection` and `compileRmd`.
- **File > Knit document...** renders the document in the session environment
  to HTML, PDF or Word; a knitr document is converted with `knitr::knit()` and
  LaTeX.  The result opens in the new **Report** tab and can be downloaded.
- The **Run chunk** button executes the chunk under the cursor.
- **Options** exposes the R Markdown and knitr command visibility.
- New help topic `document-authoring`, new vignette *Writing reports with
  R Markdown and knitr*, and a screenshot of document mode.
- With document authoring implemented, the core has 13 disabled menu entries
  left: three lifecycle commands, the nine browser-delegated Edit actions and
  `Identify3D`.

# RcmdrShiny 1.12.0

## Residual features (plan F1-F12)

### Core

- **Gumbel distribution** family: quantiles, probabilities, plot and samples
  through `VGAM`; the menu entries are hidden when VGAM is missing.
- **Convert all character variables to factors** as a direct command.
- **Plugin command aliases**: `RcmdrShiny.plugin(aliases = c(new = "core"))`
  lets plugin menus reuse core dialogs and direct commands without duplicating
  them.  `get_dialog()` and `direct_commands()` resolve aliases, and the alias
  keeps its own id for dialog memory and help.
- **Interactive plots**: when `plotly` is installed, the histogram, boxplot,
  scatterplot and line graph dialogs also produce an interactive widget with
  hover, zoom and selection.  The PNG gallery and export are unchanged.
- **Session report**: `report_rmd()`, `write_report_rmd()` and
  `write_report_html()` back **File > Export report...**, which collects the
  command log, output and plots without re-running the analysis.
- Core menu coverage: 205 dialogs; with all plugins, 850 of 900 menu entries
  are implemented.  The remaining 50 are out of scope by design (R Markdown
  editor, close/restart, cut/copy/undo, `identify()`, `Identify3D`).

### EZR 0.2.0

- **Sample size and power**: 17 entries covering proportions, means, paired
  means, hazard ratios, non-inferiority, phase II and selection designs via
  `pwr` and `clinfun`.
- **Data and variables**: CP932 import, copy/rename/merge data sets, workspace
  load, renewal, Stata export, threshold binning, log transform, numeric
  conversion.
- **Graphs and tables**: violin, ordered chart, swimmer, Sankey, CONSORT,
  adjusted survival, adjusted and stacked cumulative incidence, graph settings
  and summary table.
- **Tests and accuracy**: proportion differences and ratios, Cochran Q,
  Cochran-Armitage trend, modified Poisson regression, Grubbs, Kolmogorov-
  Smirnov, variance F, ANCOVA, Jonckheere-Terpstra, predictive values, ROC
  comparison, time-dependent ROC and Cronbach's alpha.
- **Survival, matching and meta-analysis**: logrank trend, current survival,
  time-dependent Cox, competing risks (Gray test, Fine-Gray), `MatchIt`
  matching, Mantel-Haenszel, conditional logistic, stratified Cox, and
  proportion/mean/hazard/network meta-analysis.
- Every remaining EZR-specific menu entry is now implemented; the only
  disabled entries are the shared out-of-scope core commands.

### NMBU 0.2.0

- Clipboard import/export, data sequences, deletion and mean centering.
- Covariance/correlation matrix and summarized one- and two-sample z-tests.
- Relevant component analysis, variable clustering, simplex models, LDA/QDA,
  grand-mean CI, discriminant scores, hierarchical merging, contrasts,
  post-hoc tests, PRESS/R2pred/RMSEP, deviance tests, (X'X)^-1, PCA/PCR/PLS
  plots, discriminant and mixture plots, stepwise selection and fitted line
  plots.
- All NMBU-specific menu entries are implemented.

### DoE 0.2.0

- Import/export: workspace load, CSV re-import, design export, catalogue load.
- Candidate and Taguchi parameter designs, Latin hypercube augmentation.
- Tabulation, response selection, contrasts, long-to-wide reshape,
  aggregation, centre points, cube extraction, effect plots and steepest
  ascent.
- Sixteen **Info** entries now open the in-app DoE guide instead of being
  dead menu items.
- All DoE-specific menu entries are implemented.

### Help and documentation

- 442 help topics across the core (133) and the 15 plugins (309).  All 619
  dialog entries have a documented topic; no `draft` and no missing topic
  remain.  `tools/promote_help_topics.R` upgrades the
  template-generated topics after validation.
- Italian translations for 21 core topics (up from 3), with English fallback.
- `tools/help_screenshots.R` captures the main window, import and histogram
  dialogs, the Data/Plots/Help tabs; eight vignettes embed a screenshot.
- New `PLUGIN-ALIAS-MAP.md` documents every alias.

### Tests and CI

- Five browser flows for the plugin families (graphics, models,
  multivariate, clinical, teaching) in `test-plugins-e2e.R`.
- New unit tests for Gumbel, aliases, string conversion, plotly, report
  generation and every plugin extras module.
- `R CMD check` clean for the core and all 15 plugins.

# RcmdrShiny 1.6.0

## Help and documentation infrastructure

- New **Help** tab with offline search, categories, recent topics and a topic
  pane; every dialog's **Help** button opens its topic inline.
- Help topics are Markdown files with YAML front matter, shipped in
  `inst/help-topics/` and discovered automatically in plugin packages.
- New API: `help_search()`, `help_topic()`, `help_topics()`, `help_index()`,
  `help_catalog()`, `help_render()`, `help_topic_html()`, `help_register()`,
  `help_unregister()`, `help_registry()`, `help_topic_for_dialog()`,
  `help_topics_for_dialog()`, `register_plugin_help()`, `help_center_ui()` and
  `help_server()`.
- `dialog_spec()` and `plugin_dialog()` accept `help_topic`; the default is the
  dialog id, then a topic that declares the dialog, then the Rd fallback.
- 131 core topics and 297 plugin topics; the distribution dialogs are grouped
  by family (normal, t, chi-squared, F, ...).
- Italian translations for the pilot topics, with English fallback.
- New **Help** menu entries: Help centre, Search help, Tutorials, Keyboard
  shortcuts, Plugin help and Diagnostics.
- `diagnostics_report()` and `format_diagnostics()` back the Diagnostics entry.
- New tools: `tools/new_help_topic.R`, `tools/generate_help_topics.R`,
  `tools/inventory_help.R` and `tools/check_help_links.R`.
- New CI workflow `help.yaml`; `commonmark` and `yaml` are optional
  (Suggests) dependencies with internal fallbacks.
- New vignettes: data import, descriptive statistics, linear models, graphs,
  survival, design of experiments, FactoMineR, EZR, troubleshooting and
  contributing help topics.

# RcmdrShiny 1.5.0

## Plugin Wave 4 and completion

- Added `RcmdrShinyPlugin.FactoMineR`: PCA, CA, MCA, MFA, DMFA, FAMD, HCPC,
  GPA, category description and preference plots.
- Added `RcmdrShinyPlugin.EZR`: core EZR data preparation, descriptive
  statistics, t and proportion tests, ANOVA, correlation, regression,
  nonparametric tests, survival analysis, diagnostic accuracy and graphics.
- All 15 general-purpose plugins from the approved plan are now present in the
  monorepo and distributed on GitHub.
- Wave 5 hardening: all plugin packages are checked with `R CMD check`, the
  combined plugin set is smoke-tested, and the documentation/status files are
  synchronised.

# RcmdrShiny 1.4.0

## Plugin Wave 3

- Added `RcmdrShinyPlugin.survival`: survival functions, comparisons, Cox and
  parametric models, proportional-hazards tests and diagnostics, plus survival
  data definitions, wide-to-long conversion and date conversion.
- Added `RcmdrShinyPlugin.aRnova`: one-way, multi-way and repeated-measures
  ANOVA, with the generalized linear model dialog reused from the core.
- Added `RcmdrShinyPlugin.NMBU`: t and z tests, proportion tests, power,
  one-way and multi-way ANOVA, PLS regression, principal components, stepwise
  selection, predictions and model diagnostics.
- Added `RcmdrShinyPlugin.DoE`: screening, fractional and full factorial,
  orthogonal array, central composite, Box-Behnken, latin hypercube and
  D-optimal designs, with inspection, modification and analysis dialogs.
- Core: plugin `etc/model-capabilities.txt` files are merged into the model
  capability table.
- Core: `AOVModelsP()`, `coxphP()`, `survregP()` and `highOrderTermsP()`
  activation predicates.
- Core: plugin predicates can receive the application state plus their own
  arguments.
- Fourteen plugins now load together (616 menu leaves).

# RcmdrShiny 1.3.0

## Plugin Wave 2

- Added `RcmdrShinyPlugin.TeachingDemos`: central limit theorem, confidence
  interval simulation, power, coin and die simulations, regression and
  correlation demos, and distribution visualization.  The plugin removes the
  duplicated core distribution entries.
- Added `RcmdrShinyPlugin.KMggplot2`: ggplot2 histograms, Q-Q plots, box,
  violin and confidence-interval plots, scatter, line, pie, bar and contour
  plots, scatter matrices, Kaplan-Meier curves, factor conversion and 17
  distribution plots.
- Added `RcmdrShinyPlugin.HH`: two-way tables, best subsets, confidence
  interval plots, predictions, scatter and lattice plots, Likert plots,
  interaction plots, ANOVA tables, hypothesis plots, MMC and projector
  settings.
- Added `RcmdrShinyPlugin.TeachStat`: descriptive statistics, index numbers,
  random-variable dialogs, confidence intervals and hypothesis tests, plus the
  data-management menu using the core dialogs.
- Core: `nonFactorsP()`, `twoOrMoreLevelFactorsP()`, `aovModelsP()`,
  `AbscontDistrsP()` and `DiscreteDistrsP()` activation predicates.
- Core: `two_level_factors()` is now part of the plugin API.
- Core: plugin names that clash with another plugin now warn and override
  instead of blocking the session; clashes with core still fail.
- Ten plugins now load together (474 menu leaves).

# RcmdrShiny 1.2.0

## Plugin Wave 1

- Added `RcmdrShinyPlugin.Export`: xtable/HTML export, Hmisc LaTeX export and
  `format.df`, with a compatible last-output stack.
- Added `RcmdrShinyPlugin.sos`: R help search with multiple terms, union or
  intersection, column filtering and spreadsheet output.
- Added `RcmdrShinyPlugin.PcaRobust`: robust PCA with ROBPCA, loadings, scores
  and the five diagnostic plots.
- Added `RcmdrShinyPlugin.ROC`: single, paired and unpaired ROC curves,
  logistic-model ROC curves and Hosmer-Lemeshow tests.
- Added `RcmdrShinyPlugin.UCA`: variance and randomness tests, predictions,
  Pareto charts and 21 quality-control charts.
- Core additions for plugins: `popOutput()`, `get_dialog()`, `glmP()`/`lmP()`
  activation predicates, lazy attachment of optional plugin packages and plot
  capture for `screeplot`, `biplot`, `qcc` and `paretochart`.
- Plugin packages are versioned 0.1.0 and tested with `R CMD check`.

# RcmdrShiny 1.1.0

## Plugin infrastructure (Wave 0)

- New `RcmdrShinyPlugin.*` package protocol: `load_plugin_package()` loads the
  namespace and calls the exported `rcmdrshiny_plugin()`.
- Plugin packages can also return a plugin specification, or a list of
  specifications, instead of registering a plugin directly.
- Legacy `RcmdrPlugin.*` packages keep the menus-only compatibility path.
- `RcmdrShiny.plugin()` accepts `predicates` for plugin-specific activation
  expressions and `replace` for explicit overrides.
- Command, dialog and predicate name conflicts are detected when a plugin is
  registered.
- Plugin menus are merged with Rcmdr's insertion rules, including top-level
  placement before Tools/Help, insertion into existing menus and `remove` rows.
- Duplicate menu names after merging are rejected with a clear error.
- Exported plugin helpers: `variables()`, `numeric_variables()`,
  `factor_variables()`, `dataset()`, `plugin_formula()`, widget functions and
  translation helpers.
- Tooling: `tools/new_plugin.R` scaffolds a plugin package;
  `tools/inventory_plugin.R` reports menus, commands and Tk dialogs in an
  upstream plugin source tree.
- CI: the plugins workflow discovers every plugin package and checks each one.

# RcmdrShiny 1.0.0

## Phase 7 — Hardening, documentation and release

- Hardened long-running sessions: bounded output/message buffers and capped
  plot history with file cleanup.
- Large data sets use server-side `DT` rendering above a configurable
  threshold.
- Accessibility pass: skip link, main/navigation/banner landmarks, ARIA live
  status, focus-visible styles, icon labels, plot image alt text and document
  language.
- Documentation: Getting Started, Migrating from Rcmdr and Writing Plugins
  vignettes; pkgdown configuration and reference sections.
- Release engineering: CRAN comments, release checklist, citation file,
  desktop entry, coverage workflow and browser E2E workflow.
- Full suite of unit, golden, integration, plugin and opt-in browser tests.
- Version 1.0.0; 138 user-facing dialogs ported, four internal Tk utilities
  remain.

# RcmdrShiny 0.7.0

## Phase 6 — Plugin API

- Public plugin API: `RcmdrShiny.plugin()`, `plugin_dialog()`,
  `load_plugin()`, `load_plugin_package()`, `list_plugins()` and
  `unload_plugins()`.
- Plugins can add Rcmdr-style menus, direct commands (with or without a state
  argument) and Shiny dialogs.
- Menu definitions from plugin `menus.txt` files are merged with the standard
  Rcmdr menus at application start.
- Legacy Tk plugins are detected and registered with a warning; their Tk
  dialogs are not executed.
- `run()`/`app()` accept a `plugins` argument; the Tools menu can load a
  plugin script (menus appear after restart).
- Example plugin in `inst/examples/demo-plugin.R` and `demo-menus.txt`.
- Plugin tests for menus, commands, dialogs, script loading and legacy
  warnings.
- Inventory unchanged: 138 ported dialogs / 4 internal utilities; version
  0.7.0.

# RcmdrShiny 0.6.0

## Phase 5 — Models, Tools and Help

- Complete Models menu: model selection and summaries, coefficient
  comparison, observation statistics, AIC/BIC, stepwise and subset selection,
  confidence intervals, bootstrap, delta method, ANOVA tables, model
  comparison, linear hypotheses, VIF, Breusch-Pagan, Durbin-Watson, RESET,
  outlier tests, response transformation, basic model plots, residual QQ,
  component+residual and added-variable plots (including 3D), influence plots,
  effect plots and predictor-effect plots.
- Tools: load packages, options/save options, plugin notice, macOS App Nap
  notice and auxiliary-software notice.
- Help: quick help, about, manuals and website links, R Markdown link, R help
  system and dataset help.
- Lazy attachment of car, effects, leaps, lmtest, boot and RcmdrMisc for model
  commands.
- Golden-command and execution tests for the main model diagnostics.
- Rendering and validation tests for every Phase 5 dialog.
- Inventory: 138 ported / 4 internal utilities; version 0.6.0.

# RcmdrShiny 0.5.0

## Phase 4 — Graphs, Distributions and 3D

- Complete Graphs menu: index plot, histogram, stem-and-leaf, boxplot, dot
  plot, scatterplot and matrix, bar graph, pie chart, line graph,
  quantile-comparison plot, plot of means, 3D scatterplot, XY conditioning
  plot, strip chart, density estimate, discrete numeric plot, symmetry boxplot
  and color palette.
- Complete Distributions menu for the supported families (normal, t, chi-square,
  F, exponential, uniform, beta, Cauchy, logistic, lognormal, gamma, Weibull,
  binomial, Poisson, geometric, hypergeometric and negative binomial):
  quantiles, probabilities, mass for discrete families, density/CDF plots and
  random samples, plus random seed control.
- Plot capture from dialogs, plot history gallery, PNG/PDF export and 3D
  snapshot export.
- Lazy attachment of RcmdrMisc/car/lattice/rgl for graph commands.
- Command-builder golden tests and execution tests that verify plot capture.
- Rendering and validation tests for all graph and distribution dialogs.
- Browser E2E extended with a histogram dialog and plot-history assertions.
- Inventory: 107 ported / 35 todo; Phase 4 checklist; version 0.5.0.

# RcmdrShiny 0.4.0

## Phase 3 — Statistics

- Complete Statistics menu coverage: 42 dialogs ported.
- Summaries: frequency distributions with goodness-of-fit, table of
  statistics, correlation matrix/test, normality tests, power transforms.
- Contingency tables: two-way, two-way from counts, multi-way, entered table,
  percentages, chi-square components, expected counts and Fisher tests.
- Means: single, independent and paired t-tests; one-way and multi-way ANOVA;
  one- and two-factor repeated-measures ANOVA through `car::Anova`.
- Variances: F-test, Bartlett, Levene and single-sample variance test.
- Proportions: single- and two-sample proportion tests.
- Nonparametric: two-sample, paired and single-sample Wilcoxon,
  Kruskal-Wallis and Friedman tests.
- Dimensional analysis: reliability, principal components, factor analysis
  and a simplified SEM-based confirmatory factor analysis.
- Cluster analysis: k-means, hierarchical clustering and summaries/assignment.
- Models: linear regression, GLM, multinomial logit, ordinal regression,
  linear mixed models and generalized linear mixed models.
- Lazy attachment of car, lme4, MASS, nnet, multcomp, sem and TeachingDemos.
- Golden-command and execution tests for the main analyses; Statistics
  dialogs registered and rendered in tests.
- Inventory: 79 ported / 63 todo; version 0.4.0.

# RcmdrShiny 0.3.0

## Phase 2 — File and Data

- Complete Data menu coverage: 34 dialogs ported (new data set, select data
  set, package data, text/Excel/SPSS/Stata/SAS/Minitab imports, compute,
  delete, recode, factor conversions, binning, standardize, export, missing
  data, subset, case names, rename, contrasts, stack, remove/select rows,
  merge, aggregate, drop levels, sort, reshape long/wide, view data).
- Command builders reproduce the Rcmdr `data-menu.R` code, with unit and
  execution tests.
- Lazy attachment of RcmdrMisc/car/foreign so generated commands work
  without slowing application startup.
- New data set creates an editable data frame; Data tab remains the editor.
- Import dialogs accept a typed path or `shinyFiles` browsing and validate
  the data set name and file.
- Direct File/Data actions: view data, refresh, variables, add observation
  numbers, help, list data sets in packages, save `.RData`, export/workspace
  downloads.
- Phase 2 checklist and 36-dialog porting inventory.

# RcmdrShiny 0.2.0

## Phase 1 — shell and infrastructure

- Reactive menu activation and installation expressions evaluated from
  `Rcmdr-menus.txt` (Rcmdr predicates and model-capability table).
- Dialog runtime: OK, Apply, Reset, Cancel, Help, per-dialog memory,
  command-error notification with Retry, busy state.
- Full widget library: variable selector, checkbox groups, radio buttons,
  text/numeric/slider/combo inputs, file and directory choosers, subset entry,
  model-formula builder.
- Data pane: `DT` view plus `rhandsontable` editing with a configurable cell
  threshold and Apply-changes workflow.
- Plot pipeline: history gallery, thumbnail selection, PNG and PDF export.
- rgl integration: 3D scenes captured with `rgl.useNULL()` and rendered with
  `rglwidget()`.
- File utilities: `Setwd`, `Load Data Set` (RData/RDS), `Open Script File`,
  script/output/dataset/workspace downloads.
- Options dialog (digits, width, editing threshold, stringsAsFactors).
- Help menu: about, quick help, R help system and dataset help.
- Top bar: dataset/model badges, language selector, dark-mode toggle.
- Tests for activation predicates, widgets, options, data editing, plot
  history/export, rgl and workspace loading; browser test extended with plot,
  data editor, options and about flows.
- Version bumped to 0.2.0 (milestone "Shell").

# RcmdrShiny 0.1.0

## Phase 0 — vertical slice

- Package skeleton, GPL-2+ licensing and attribution notice.
- Shiny shell: top bar, menu sidebar, Script/Output/Messages/Plots/Data/
  Environment tabs, status bar.
- Menu sidebar generated from Rcmdr 2.15.0's `Rcmdr-menus.txt`; commands not
  yet ported are disabled with an "In porting" tooltip.
- `AppState` with active data set, active model, command log, output,
  messages, dialog memory and plot history.
- `run_command()` with capture of output, messages, warnings and errors,
  automatic active-object detection, and PNG plot capture.
- Dialog runtime with modal UI, validation, reset and per-dialog memory.
- Ported dialogs: *Read Text Data*, *Numerical Summaries*, *Linear Model*.
- Direct command *Summarize active data set*.
- `DT` data view, environment view and plot preview.
- Unit, golden-command and server integration tests; opt-in shinytest2
  browser end-to-end test.
- `tools/inventory_dialogs.R` generates the official backlog
  (`inst/etc/dialogs-inventory.csv`) from an Rcmdr source tree.
