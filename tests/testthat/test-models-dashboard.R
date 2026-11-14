# Models dashboard and actions -----------------------------------------------

test_that("the dashboard shows an empty state without models", {
  state <- AppState(env = new.env())
  html <- htmltools::renderTags(models_dashboard_ui(state))$html
  expect_match(html, "No models yet")
})

test_that("the dashboard shows the registry and the delta AIC", {
  state <- workbench_test_state()
  html <- htmltools::renderTags(models_dashboard_ui(state))$html
  expect_match(html, "rcmdr-models-table")
  expect_match(html, "fit")
  expect_match(html, "gfit")
  expect_match(html, "AIC")
  expect_match(html, "model_action")
})

test_that("the action panel exposes the existing commands", {
  state <- workbench_test_state()
  html <- htmltools::renderTags(model_actions_ui(state, "fit"))$html
  for (label in c("Summary", "ANOVA", "Effects", "Diagnostics", "Influence",
                  "VIF", "Stepwise", "Export", "Reopen dialog", "Remove")) {
    expect_match(html, label)
  }
  expect_match(html, "Set active")
})

test_that("summary and AIC run existing commands", {
  state <- workbench_test_state()
  expect_true(model_action(state, "fit", "summary")$ok)
  expect_equal(tail(state$log, 1L), "summary(fit)")
  expect_equal(state$history[[1L]]$source, "model")
  expect_equal(state$model_selection, "fit")

  expect_true(model_action(state, "fit", "aic")$ok)
  expect_equal(tail(state$log, 1L), "AIC(fit)")
})

test_that("selecting and activating a model is a session operation", {
  state <- workbench_test_state()
  log_before <- length(state$log)
  expect_true(model_action(state, "gfit", "select")$ok)
  expect_equal(state$model_selection, "gfit")
  expect_equal(length(state$log), log_before)

  expect_true(model_action(state, "gfit", "active")$ok)
  expect_equal(state$active_model, "gfit")
  expect_equal(length(state$log), log_before)
})

test_that("diagnostics run the existing plot commands", {
  state <- workbench_test_state()
  expect_true(model_action(state, "fit", "diagnostics")$ok)
  expect_true(any(grepl("^plot\\(fit\\)$", state$log)))
})

test_that("actions on missing objects fail clearly", {
  state <- workbench_test_state()
  expect_false(model_action(state, "missing", "summary")$ok)
  expect_false(model_action(state, "D", "summary")$ok)
})

test_that("reopen uses the recorded dialog memory", {
  state <- workbench_test_state()
  opened <- NULL
  state$open_dialog <- function(id) opened <<- id
  run_command(state, "fit <- lm(y ~ x, data = D)", source = "dialog",
              dialog_id = "linearModel",
              dialog_memory = list(model_name = "fit"))
  expect_true(model_reopen_dialog(state, "fit"))
  expect_equal(opened, "linearModel")
  expect_equal(get_dialog_memory(state, "linearModel")$model_name, "fit")
})

test_that("reopen falls back to the class dialog when history is missing", {
  state <- workbench_test_state()
  opened <- NULL
  state$open_dialog <- function(id) opened <<- id
  expect_true(model_reopen_dialog(state, "gfit"))
  expect_equal(opened, "generalizedLinearModel")
  expect_equal(get_dialog_memory(state, "generalizedLinearModel")$model, "gfit")
})

test_that("reopen without an opener or a known class returns FALSE", {
  state <- workbench_test_state()
  expect_false(model_reopen_dialog(state, "fit"))
  state$env$plain <- data.frame(x = 1)
  expect_false(model_reopen_dialog(state, "plain"))
})

test_that("the export dialog builds a reproducible command", {
  state <- workbench_test_state()
  spec <- model_export_dialog()
  path <- tempfile(fileext = ".csv")
  result <- spec$on_ok(list(
    modelExport_model = "fit",
    modelExport_path = path,
    modelExport_what = "coefficients"
  ), state)
  expect_null(result$error)
  expect_match(result$commands, "write.csv")
  expect_match(result$commands, "summary\\(fit\\)")
  expect_match(result$commands, path, fixed = TRUE)

  expect_match(spec$on_ok(list(
    modelExport_model = "fit",
    modelExport_path = file.path(tempdir(), "missing-dir", "x.csv")
  ), state)$error, "Directory not found")
})

test_that("removing a model clears the selection", {
  state <- workbench_test_state()
  model_action(state, "gfit", "select")
  active_model(state, "gfit")
  expect_true(model_action(state, "gfit", "remove")$ok)
  expect_false(exists("gfit", envir = state$env, inherits = FALSE))
  expect_null(state$model_selection)
  expect_null(state$active_model)
})
