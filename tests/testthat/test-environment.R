# Environment explorer -------------------------------------------------------

test_that("the object list reports name, class, size and type", {
  state <- workbench_test_state()
  table <- object_list(state)
  expect_true(all(c("D", "fit", "gfit") %in% table$name))
  row <- table[table$name == "D", , drop = FALSE]
  expect_equal(row$class[[1L]], "data.frame")
  expect_equal(row$type[[1L]], "8 x 3")
  expect_true(nzchar(row$size[[1L]]))
})

test_that("an empty environment returns an empty table", {
  state <- AppState(env = new.env())
  table <- object_list(state)
  expect_equal(nrow(table), 0L)
  expect_true(all(c("name", "class", "size", "type", "preview") %in%
                    names(table)))
})

test_that("object previews are read-only text", {
  state <- workbench_test_state()
  preview <- object_preview(state, "D")
  expect_match(preview, "data.frame")
  expect_match(preview, "str\\(D\\)")
  expect_match(preview, "summary\\(D\\)")
  expect_equal(object_preview(state, "missing"), "")
})

test_that("preview is a session operation, summary is a command", {
  state <- workbench_test_state()
  log_before <- length(state$log)
  history_before <- length(state$history)
  result <- object_action(state, "D", "preview")
  expect_true(result$ok)
  expect_equal(state$environment_selection, "D")
  expect_equal(length(state$log), log_before)
  expect_equal(length(state$history), history_before)

  result <- object_action(state, "D", "summary")
  expect_true(result$ok)
  expect_equal(tail(state$log, 1L), "summary(D)")
  expect_equal(state$history[[1L]]$source, "environment")
})

test_that("view activates a data frame and opens the Data tab", {
  state <- workbench_test_state()
  tabs <- character()
  state$show_tab <- function(label) tabs <<- c(tabs, label)
  state$active_dataset <- NULL
  result <- object_action(state, "D", "view")
  expect_true(result$ok)
  expect_equal(state$active_dataset, "D")
  expect_equal(tabs, tr("Data"))
})

test_that("objects can be activated, plotted, inspected and removed", {
  state <- workbench_test_state()
  expect_true(object_action(state, "fit", "activate_model")$ok)
  expect_equal(state$active_model, "fit")

  expect_true(object_action(state, "fit", "str")$ok)
  expect_equal(tail(state$log, 1L), "str(fit)")

  expect_true(object_action(state, "fit", "remove")$ok)
  expect_false(exists("fit", envir = state$env, inherits = FALSE))
  expect_equal(tail(state$log, 1L), "rm(fit)")
})

test_that("actions on missing or mismatched objects fail clearly", {
  state <- workbench_test_state()
  expect_false(object_action(state, "missing", "preview")$ok)
  expect_false(object_action(state, "D", "activate_model")$ok)
  expect_false(object_action(state, "fit", "activate_dataset")$ok)
})

test_that("the object table renders actions", {
  state <- workbench_test_state()
  html <- htmltools::renderTags(environment_objects_ui(state))$html
  expect_match(html, "environment_action")
  expect_match(html, "Preview")
  expect_match(html, "Summary")
  expect_match(html, "Remove")
  expect_match(html, "Save")
})

test_that("the data set registry view shows provenance and size", {
  state <- workbench_test_state()
  html <- htmltools::renderTags(environment_datasets_ui(state))$html
  expect_match(html, "8 x 3")
  expect_match(html, "activate_dataset")
  expect_match(html, "Set active")
})

test_that("the save dialog writes a reproducible command", {
  state <- workbench_test_state()
  spec <- environment_save_dialog()
  path <- tempfile(fileext = ".rds")
  result <- spec$on_ok(list(
    environmentSave_object = "D",
    environmentSave_path = path,
    environmentSave_format = "rds"
  ), state)
  expect_null(result$error)
  expect_match(result$commands, "saveRDS\\(D")
  expect_match(result$commands, path, fixed = TRUE)

  expect_match(spec$on_ok(list(
    environmentSave_object = "missing",
    environmentSave_path = path
  ), state)$error, "existing object")
})

test_that("the environment workspace exposes the three views", {
  html <- htmltools::renderTags(environment_workspace_ui())$html
  expect_match(html, "environment_tabs")
  expect_match(html, "environment_objects")
  expect_match(html, "environment_datasets")
  expect_match(html, "models_dashboard")
})
