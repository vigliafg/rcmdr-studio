# UI -> command mapping for the dialogs with the widest use.  The dialog
# input is built explicitly, not from the rendered defaults, so a renamed field
# or a wrong argument is caught here.

mapping_state <- function() {
  env <- new.env()
  env$Dataset <- data.frame(
    y = c(1, 2, 3, 4, 5, 6, 7, 8),
    x = c(2, 4, 6, 8, 10, 12, 14, 16),
    z = c(1, 1, 2, 2, 3, 3, 4, 4),
    g = factor(rep(c("a", "b"), 4L))
  )
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  state
}

test_that("the histogram dialog maps every option", {
  state <- mapping_state()
  spec <- get_dialog_spec("Histogram")

  result <- spec$on_ok(list(
    Histogram_variable = "y",
    Histogram_group = "g",
    Histogram_scale = "density",
    Histogram_breaks = "10"
  ), state)

  expect_identical(
    result$commands,
    cmd_histogram("Dataset", "y", "g", "density", "10")
  )
  expect_identical(result$memory$scale, "density")
  expect_identical(result$memory$group, "g")
})

test_that("the bar graph dialog maps the group", {
  state <- mapping_state()
  result <- get_dialog_spec("barGraph")$on_ok(list(
    barGraph_variable = "g",
    barGraph_group = ""
  ), state)

  expect_identical(result$commands, cmd_barplot("Dataset", "g", NULL))
})

test_that("the scatterplot dialog maps smooth, boxplots and log", {
  state <- mapping_state()
  result <- get_dialog_spec("scatterPlot")$on_ok(list(
    scatterPlot_x = "x",
    scatterPlot_y = "y",
    scatterPlot_group = "g",
    scatterPlot_smooth = TRUE,
    scatterPlot_boxplots = TRUE,
    scatterPlot_log = "xy"
  ), state)

  expect_identical(
    result$commands,
    cmd_scatterplot("Dataset", "x", "y", "g", TRUE, TRUE, "xy")
  )
})

test_that("the correlation dialog maps Pearson, Spearman and partial", {
  state <- mapping_state()
  spec <- get_dialog_spec("correlationMatrix")
  base <- list(
    correlationMatrix_variables = c("x", "y", "z"),
    correlationMatrix_use = "complete",
    correlationMatrix_pvalues = FALSE
  )

  pearson <- spec$on_ok(c(base, list(correlationMatrix_type = "Pearson")),
                        state)
  expect_identical(
    pearson$commands,
    cmd_correlation_matrix("Dataset", c("x", "y", "z"), "Pearson")
  )

  spearman <- spec$on_ok(c(base, list(correlationMatrix_type = "Spearman")),
                         state)
  expect_match(spearman$commands, 'method="spearman"', fixed = TRUE)
  expect_false(grepl("method=\"pearson\"", spearman$commands, fixed = TRUE))

  partial <- spec$on_ok(c(base, list(correlationMatrix_type = "partial")),
                        state)
  expect_match(partial$commands, "partial.cor", fixed = TRUE)
})

test_that("the export dialog maps the separator and flags", {
  state <- mapping_state()
  file <- tempfile(fileext = ".csv")
  on.exit(unlink(file), add = TRUE)

  result <- get_dialog_spec("exportDataSet")$on_ok(list(
    exportDataSet_file = file,
    exportDataSet_sep = "semicolons",
    exportDataSet_colnames = TRUE,
    exportDataSet_rownames = FALSE,
    exportDataSet_quotes = FALSE,
    exportDataSet_na = "."
  ), state)

  expect_identical(
    result$commands,
    cmd_export_data("Dataset", file, sep = ";", col_names = TRUE,
                    row_names = FALSE, quote = FALSE, na = ".")
  )
})

test_that("the mapped dialogs reject incomplete input", {
  state <- mapping_state()

  expect_match(get_dialog_spec("Histogram")$on_ok(
    list(Histogram_variable = ""), state
  )$error, "select a variable")

  expect_match(get_dialog_spec("scatterPlot")$on_ok(
    list(scatterPlot_x = "y", scatterPlot_y = "y"), state
  )$error, "different")

  expect_match(get_dialog_spec("correlationMatrix")$on_ok(list(
    correlationMatrix_variables = "x",
    correlationMatrix_type = "Pearson"
  ), state)$error, "Fewer than 2")

  expect_match(get_dialog_spec("exportDataSet")$on_ok(
    list(exportDataSet_file = ""), state
  )$error, "select a file")
})
