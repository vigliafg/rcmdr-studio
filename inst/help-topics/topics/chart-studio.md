---
id: chart-studio
title: Chart Studio
type: task
category: graphs
keywords: [chart, graph, plot, builder, preview, gallery, theme, palette, export, plotly, ggplot2]
aliases: [chart-studio, chart-builder, chart-gallery]
dialogs: [chartRename, chartDelete, chartExport]
commands: [Hist, Boxplot, scatterplot, lineplot, Barplot, plotMeans]
packages: [graphics, RcmdrMisc, car, plotly, ggplot2]
related: [histogram, scatterplot, boxPlot, exporting-results]
language: en
status: documented
---

# Chart Studio

The **Charts** tab in Studio mode is a builder, a live preview, a gallery and an
offline example catalogue. It uses a single ggplot2 engine: every applied chart
is a reproducible `print(ggplot(...))` command. The classic Rcmdr dialogs remain
available through **Advanced...** for the types that have one.

## Build, Models, Examples and Gallery

- **Build** creates a chart: choose a type, a data set, the mappings and the
  options. The preview and the generated command update as you change them.
- **Models** opens a ready-made recipe by analysis family; the mapping stays
  with the user.
- **Examples** is a curated, offline gallery adapted from the R Graph Gallery.
  Choose a card, inspect the description and the code, then **Open in builder**.
  The example fills the recipe; it does not load data into the session and it
  does not run a command.
- **Gallery** lists every plot of the session, including plots created by a
  dialog or by a script.

The **Advanced...** button opens the full Rcmdr dialog with the current
mappings prefilled. Use it when a type exposes options that the builder does
not.

## Chart types

| Type | Requires | Command |
|---|---|---|
| Histogram | numeric variable, optional groups | `Hist()` |
| Density plot | numeric variable, optional groups | `densityPlot()` |
| Boxplot | numeric variable, optional groups | `Boxplot()` |
| Scatterplot | two numeric variables, optional groups | `scatterplot()` |
| Line graph | index variable and one or more numeric series | `lineplot()` |
| Bar graph | factor | `Barplot()` |
| Dot plot | numeric variable, optional groups | `Dotplot()` |
| Strip chart | numeric variable, optional groups | `stripchart()` |
| Quantile-comparison plot | numeric variable, optional groups | `qqPlot()` |
| Plot of means | numeric response and factor | `plotMeans()` |
| XY conditioning plot | x, y and optional conditioning factor | `xyplot()` |

The mapping fields are generated from the type: numeric slots list numeric
variables, factor slots list factors and characters, and optional slots include
`<none>`.

## Boxplot options

The boxplot exposes notched boxes, notch width, variable box width and box
width. **Horizontal** uses `coord_flip()`; outliers can be hidden and the common
jitter control overlays the points.

## Histogram and scatter options

The histogram scale selector (frequency, density, percent) is mapped to
`after_stat()`; the number of bins and an optional bin width control the
histogram.

The scatterplot exposes a regression line, a confidence ellipse, a grid and
jitter. The “Smooth” choice and the “Confidence band” option produce
`geom_smooth(method = "lm" | "loess", se = TRUE/FALSE)`; the ellipse is
`stat_ellipse()`.

## Extended types

The builder also exposes types without a classic Rcmdr dialog:

| Type | Mapping | Main options |
|---|---|---|
| Violin plot | numeric, group? | trim, area/count/width scale, bandwidth adjust, boxplot overlay |
| Empirical CDF | numeric, group? | padding, line style |
| 2D density | two numerics | contour bins, bandwidth, points |
| Heatmap | x, y, numeric value | low/high gradient, value labels |
| Lollipop | category, value | point size, stem width |
| Dumbbell | category, start, end | point size, segment width |
| Doughnut | category, value | hole and ring width |
| Stacked area | x, value, series | alpha, stacked position |
| Ridgeline | numeric, group | overlap scale, alpha (needs `ggridges`) |
| Beeswarm | group, numeric | point size, alpha (needs `ggbeeswarm`) |
| Radar | category, value, profile? | closed profile, point/line size, fill alpha |
| Parallel coordinates | two or more numerics, group? | line alpha, scale (needs `GGally`) |

The statistical types (`stat_*`) use ggstatsplot and the composition type uses
patchwork. Optional types appear only when their package is installed; the
round-trip keeps the type and its mapping.

## Other chart options

- **Density**: bandwidth, adjust and rug; the kernel is not exposed because
  `geom_density()` uses a Gaussian kernel.
- **Line graph**: line/step/area, line style and width; an optional grouping
  variable colours the line in ggplot2.
- **Bar graph**: bar width and count/percent statistic in ggplot2.
- **Dot plot**: binned dots with bin axis, stack direction, dot size and bin
  width.
- **Strip chart**: stack or jitter, with jitter width/height and point shape in
  ggplot2.
- **QQ plot**: normal, uniform or exponential distribution, reference line and
  grid.
- **Plot of means**: connect the means, error-bar width and point size.
- **XY conditioning plot**: points, lines or both, optional layout and smooth.

## Preview

The preview is isolated. It runs in a child of the session environment, never
calls `run_command()`, never appends to the command log and never adds a plot to
the gallery. Previews are debounced and cached by specification and data set
shape.

When the chart has an interactive plotly version, the Build panel shows the
widget instead of the PNG: hover, zoom and point selection are available while
you edit. The builder uses a separate plotly source, so its selection does not
mix with the gallery detail. On an ungrouped scatterplot the selection offers
**Create data set from selection**, with the same reproducible command used by
the gallery.

If the chart cannot be produced, the preview panel shows the R error instead of
failing.

## Apply

**Apply** runs the generated command through the normal command engine:

- the command is appended to the log and to the structured history with source
  `chart`;
- the plot is captured in the gallery;
- the specification is attached to the plot so it can be reopened.

With the default theme and empty labels, the applied command is a single
`print(ggplot(...))` expression and does not mix base `par()` or `title()`.

## Theme and labels

The theme panel controls the palette, the base size, the background, the grid
and the legend position. Palette, theme and labels are part of the same ggplot
command: `scale_*_manual()`, `theme()` and `labs()`. With the default theme and
no labels, no extra layer is added.

Palettes include the R default, a colour-blind-safe palette, Tableau, Viridis
and greys.

## Single ggplot2 engine

`ggplot2` is a hard dependency and the Chart Studio has a **single engine**:
every type produces a `print(ggplot(...))` expression. The legacy base engine
selector was removed in 2.8.0; the classic Rcmdr commands remain available only
through the Classic mode and the **Advanced...** dialog.

Extra mappings:

- **Facet**: one conditioning variable, with fixed/free/free-x/free-y scales and
  an optional column count.
- **Size** and **Label** for scatterplots (numeric size and text label).

Shared options: alpha, bar position (identity/dodge/stack/fill), bin width,
smooth method (lm/loess/gam) with confidence band, jitter, point shape,
coordinate flip, ggplot2 theme (minimal, black and white, classic, light, dark,
void), grid, legend position and background. Labels include title, subtitle,
tag, axis labels and caption. Log axes and the five palettes are applied as
ggplot2 scales; multi-series line graphs get one layer per series with named
colours.

The preview evaluates the same command in the isolated preview device. When the
installed plotly and ggplot2 versions can convert ggplot objects, the gallery
also offers the interactive version and the HTML export; otherwise those
actions are hidden.



## Gallery

Each gallery card shows the title, the type, the data set and the time. Use the
search box, the type filter and the pinned-only switch to narrow the list.
Actions:

- **Detail**: large preview, metadata, command and specification.
- **Pin**: keep the chart at the top of the gallery.
- **Reopen in builder**: restore type, data set, mappings, options, theme and
  labels.
- **Rename** and **Delete** are metadata operations.
- **Copy code** copies the command.
- **Export...** writes PNG, PDF, SVG (when `svglite` is installed) or HTML
  (for interactive plots).
- **Add to report**: every session plot is already included in the report; use
  the Report tab to export it.

Renaming, pinning and deleting are session operations: they do not add commands
to the script. Deleting a chart never removes the command from the log.

## Interactive plots and selection

`plotly` is a hard dependency: supported charts always have an interactive
version. Select points in an ungrouped scatterplot and use **Subset selected
points** to create a new data set from the selection. The subset is a
reproducible R command and the new data set becomes active.

## Reproducibility rules

| Action | Command? |
|---|---|
| Change a mapping or an option | No, preview only |
| Preview | No |
| Apply | Yes |
| Theme or palette | Yes, in the applied command |
| Export | No, file only |
| Rename, pin, delete | No, session metadata |
| Reopen | No |
| Open an example in the builder | No |
| Subset selected points | Yes |

## See also

- `topic:histogram`
- `topic:scatterplot`
- `topic:boxPlot`
- `topic:exporting-results`
- `topic:data-studio`
