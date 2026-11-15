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

The **Charts** tab in Studio mode is a builder, a live preview and a gallery on
top of the same plotting engine used by the Rcmdr dialogs. It never introduces a
new statistical procedure: every applied chart is a command produced by the
matching dialog builder.

## Build and Gallery

- **Build** creates a chart: choose a type, a data set, the mappings and the
  options. The preview and the generated command update as you change them.
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

For both engines the boxplot exposes notched boxes, notch width, variable box
width and box width. **Horizontal** works in both: the base engine switches to
`boxplot(..., horizontal = TRUE)` because `car::Boxplot()` rejects it, while
ggplot2 uses `coord_flip()`. Outliers can be hidden. In ggplot2 the common
jitter control overlays the points.

## Histogram and scatter options

The histogram scale selector (frequency, density, percent) is honoured by both
engines; ggplot2 maps it to `after_stat()`.

The scatterplot exposes a regression line, a confidence ellipse, a grid and
jitter in both engines. In ggplot2 the “Smooth” choice and the “Confidence
band” option produce `geom_smooth(method = "lm" | "loess", se = TRUE/FALSE)`;
the ellipse is `stat_ellipse()`.

## ggplot-only types

Four statistical types exist only with the ggplot2 engine and appear in the
chart type selector only after switching engine:

| Type | Mapping | Main options |
|---|---|---|
| Violin plot | numeric, group? | trim, area/count/width scale, bandwidth adjust, boxplot overlay |
| Empirical CDF | numeric, group? | padding, line style |
| 2D density | two numerics | contour bins, bandwidth, points |
| Heatmap | x, y, numeric value | low/high gradient, value labels |

With the base engine these types are rejected with an explicit message; the
round-trip keeps the engine and the type.

## Other chart options

- **Density**: kernel, adjust, rug and grid in the base engine; ggplot2 uses
  adjust.
- **Line graph**: line/step/area, line style and width; an optional grouping
  variable colours the line in ggplot2.
- **Bar graph**: bar width and count/percent statistic in ggplot2.
- **Dot plot**: binned dots in base; bin axis, stack direction, dot size and
  bin width in ggplot2.
- **Strip chart**: stack or jitter, with jitter width/height and point shape in
  ggplot2.
- **QQ plot**: normal, uniform or exponential distribution, reference line,
  confidence envelope and grid.
- **Plot of means**: connect the means, error-bar width and point size.
- **XY conditioning plot**: points, lines or both, optional layout and smooth.

## Preview

The preview is isolated. It runs in a child of the session environment, never
calls `run_command()`, never appends to the command log and never adds a plot to
the gallery. Previews are debounced and cached by specification and data set
shape.

If the chart cannot be produced, the preview panel shows the R error instead of
failing.

## Apply

**Apply** runs the generated command through the normal command engine:

- the command is appended to the log and to the structured history with source
  `chart`;
- the plot is captured in the gallery;
- the specification is attached to the plot so it can be reopened.

With the default theme and empty labels, the applied command is exactly the
command of the equivalent dialog.

## Theme and labels

The theme panel controls the palette, the base size, the background, the grid
and the legend position. Palette and device settings are emitted before the
plot; the title, axis labels and caption are emitted after it. With the default
theme and no labels, no extra command is added.

Palettes include the R default, a colour-blind-safe palette, Tableau, Viridis
and greys.

## ggplot2 engine

When `ggplot2` is installed, the engine selector offers a full ggplot2 engine
for **all 11 chart types**. The applied command is a single
`print(ggplot(...))` expression; the base palette, `par()` and `title()` are not
mixed in.

Extra mappings appear only with this engine:

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

The base engine remains the default and its commands are unchanged.

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

When `plotly` is installed, supported charts also have an interactive version.
Select points in an ungrouped scatterplot and use **Subset selected points** to
create a new data set from the selection. The subset is a reproducible R
command and the new data set becomes active.

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
| Subset selected points | Yes |

## See also

- `topic:histogram`
- `topic:scatterplot`
- `topic:boxPlot`
- `topic:exporting-results`
- `topic:data-studio`
