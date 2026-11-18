plugin_dialog_env <- function(pkg) {
  env <- new.env(parent = asNamespace("RcmdrShiny"))
  sys.source(test_path("..", "..", "plugins", pkg, "R", "dialogs.R"),
             envir = env)
  env
}

test_that("the ROC options are grouped without renaming a field", {
  env <- plugin_dialog_env("RcmdrShinyPlugin.ROC")
  html <- as.character(env$roc_options_ui(
    function(x) paste0("fncvpROC_", x), list(), dialog_id = "fncvpROC"
  ))
  expect_match(html, "rcmdr-accordion", fixed = TRUE)
  expect_match(html, 'id="fncvpROC_settings"', fixed = TRUE)
  for (panel in c("Data options", "AUC", "Confidence interval", "Plot",
                  "Smoothing")) {
    expect_match(html, sprintf('data-value="%s"', panel), fixed = TRUE)
  }
  # The form field ids are exactly the ones the handlers read.
  for (field in c("direction", "ci_level", "partial_auc",
                  "print_thresholds", "smooth", "bandwidth")) {
    expect_match(html, paste0("fncvpROC_", field), fixed = TRUE)
  }
})

test_that("the UCA phases are panels, not a flat list", {
  env <- plugin_dialog_env("RcmdrShinyPlugin.UCA")
  state <- AppState(env = new.env())
  state$env$D <- data.frame(x = 1:3, y = 4:6)
  active_dataset(state, "D")
  spec <- env$uca_qcc_dialog("pchart2Menu", "p-chart phase II", "p", "2")
  html <- as.character(spec$ui(state, list()))
  expect_match(html, "rcmdr-accordion", fixed = TRUE)
  expect_match(html, 'id="pchart2Menu_settings"', fixed = TRUE)
  for (panel in c("Phase I", "Phase II", "Options")) {
    expect_match(html, sprintf('data-value="%s"', panel), fixed = TRUE)
  }
  expect_match(html, "pchart2Menu_x1", fixed = TRUE)
  expect_match(html, "pchart2Menu_x2", fixed = TRUE)
  expect_match(html, "pchart2Menu_plot_all", fixed = TRUE)
})

test_that("the sos search and filter are two panels", {
  env <- plugin_dialog_env("RcmdrShinyPlugin.sos")
  spec <- env$sos_dialog()
  html <- as.character(spec$ui(AppState(env = new.env()), list()))
  expect_match(html, "rcmdr-accordion", fixed = TRUE)
  expect_match(html, 'data-value="Search"', fixed = TRUE)
  expect_match(html, 'data-value="Filter"', fixed = TRUE)
  expect_match(html, "sosInit_search", fixed = TRUE)
  expect_match(html, "sosInit_filter", fixed = TRUE)
  expect_match(html, "sosInit_max_page", fixed = TRUE)
})

test_that("the Export dialogs group their options and keep the ids", {
  env <- plugin_dialog_env("RcmdrShinyPlugin.Export")
  env$export_last_object <- function() NULL
  env$export_object_class <- function(object) "none"
  env$export_object_available <- function(object) FALSE
  env$export_tables <- function(state) c(D = "D")

  xtable <- env$export_xtable_dialog()
  html <- as.character(xtable$ui(AppState(env = new.env()), list()))
  expect_match(html, "rcmdr-accordion", fixed = TRUE)
  for (panel in c("Content", "Typesetting", "File")) {
    expect_match(html, sprintf('data-value="%s"', panel), fixed = TRUE)
  }
  for (field in c("xtableExport_type", "xtableExport_tab_env",
                  "xtableExport_file")) {
    expect_match(html, field, fixed = TRUE)
  }

  latex <- env$export_latex_dialog()
  html <- as.character(latex$ui(AppState(env = new.env()), list()))
  for (field in c("latexExport_center", "latexExport_longtable",
                  "latexExport_blank_na")) {
    expect_match(html, field, fixed = TRUE)
  }

  format <- env$export_formatdf_dialog()
  html <- as.character(format$ui(AppState(env = new.env()), list()))
  expect_match(html, 'data-value="Numbers"', fixed = TRUE)
  expect_match(html, "formatdfExport_scientific", fixed = TRUE)
  expect_match(html, "formatdfExport_object", fixed = TRUE)
})

test_that("the plugin API exposes the accordion helpers", {
  exports <- readLines(test_path("..", "..", "NAMESPACE"))
  expect_true(any(grepl("export(settings_accordion)", exports, fixed = TRUE)))
  expect_true(any(grepl("export(settings_panel)", exports, fixed = TRUE)))
})

test_that("the robust PCA dialog separates variables, output and plots", {
  env <- plugin_dialog_env("RcmdrShinyPlugin.PcaRobust")
  state <- AppState(env = new.env())
  state$env$D <- data.frame(x = 1:3, y = 4:6)
  active_dataset(state, "D")
  spec <- env$pca_robust_dialog_full()
  html <- as.character(spec$ui(state, list()))
  expect_match(html, "rcmdr-accordion", fixed = TRUE)
  expect_match(html, 'id="pcaRobust_settings"', fixed = TRUE)
  for (panel in c("Variables", "Output", "Plots")) {
    expect_match(html, sprintf('data-value="%s"', panel), fixed = TRUE)
  }
  expect_match(html, "pcaRobust_variables", fixed = TRUE)
  expect_match(html, "pcaRobust_diagnostic", fixed = TRUE)
})
