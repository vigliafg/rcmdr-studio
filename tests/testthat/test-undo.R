# Application undo/redo: data and gallery snapshots ---------------------------

undo_test_state <- function() {
  state <- AppState(new.env(parent = globalenv()))
  assign("D", data.frame(y = 1:5, x = 1:5), envir = state$env)
  active_dataset(state, "D")
  state
}

test_that("a data command is undone and redone without re-running it", {
  state <- undo_test_state()
  run_command(state, "D$y <- D$y * 2", log = FALSE)
  expect_equal(state$env$D$y, c(2, 4, 6, 8, 10))
  expect_length(state$undo_stack, 1L)
  expect_equal(state$undo_stack[[1L]]$kind, "data")
  after_history <- length(state$history)

  expect_true(undo_apply(state))
  expect_equal(state$env$D$y, 1:5)
  expect_length(state$undo_stack, 0L)
  expect_length(state$redo_stack, 1L)
  # The restore is a snapshot: no command, history entry or log line is added.
  expect_equal(length(state$history), after_history)
  expect_length(state$log, 0L)

  expect_true(undo_redo(state))
  expect_equal(state$env$D$y, c(2, 4, 6, 8, 10))
  expect_length(state$undo_stack, 1L)
  expect_length(state$redo_stack, 0L)
})

test_that("read-only commands and no-op assignments do not fill the stack", {
  state <- undo_test_state()
  run_command(state, "summary(D)", log = FALSE)
  run_command(state, "D <- D", log = FALSE)
  expect_length(state$undo_stack, 0L)

  run_command(state, "D <- D[D$y > 2, , drop = FALSE]", log = FALSE)
  expect_length(state$undo_stack, 1L)
  expect_equal(nrow(state$env$D), 3L)
})

test_that("a new action empties the redo branch", {
  state <- undo_test_state()
  run_command(state, "D$y <- D$y + 1", log = FALSE)
  undo_apply(state)
  expect_length(state$redo_stack, 1L)

  run_command(state, "D$x <- D$x + 10", log = FALSE)
  expect_length(state$redo_stack, 0L)
  expect_length(state$undo_stack, 1L)
})

test_that("the stack is bounded by count and by memory", {
  state <- undo_test_state()
  state$options$undo_max <- 2L
  for (i in 1:3) {
    run_command(state, sprintf("D$y <- D$y + %d", i), log = FALSE)
  }
  expect_length(state$undo_stack, 2L)
  expect_equal(state$undo_stack[[2L]]$label, "D$y <- D$y + 3")

  tight <- undo_test_state()
  tight$options$undo_max_bytes <- 1
  run_command(tight, "D$y <- D$y + 1", log = FALSE)
  expect_length(tight$undo_stack, 0L)
  expect_false(is.null(tight$undo_skip))
})

test_that("gallery pins are undone and redone", {
  state <- undo_test_state()
  plot_register(state, list(id = "plot-0001", code = "plot(1)"))
  expect_false(state$plots[[1L]]$pinned)

  plot_update(state, "plot-0001", pinned = TRUE)
  expect_true(state$plots[[1L]]$pinned)
  expect_equal(state$undo_stack[[length(state$undo_stack)]]$kind, "gallery")

  expect_true(undo_apply(state))
  expect_false(state$plots[[1L]]$pinned)
  expect_true(undo_redo(state))
  expect_true(state$plots[[1L]]$pinned)
})

test_that("gallery delete and reorder are reversible metadata", {
  state <- undo_test_state()
  plot_register(state, list(id = "plot-0001", code = "plot(1)", pinned = TRUE))
  plot_register(state, list(id = "plot-0002", code = "plot(2)", pinned = TRUE))
  plot_register(state, list(id = "plot-0003", code = "plot(3)", pinned = TRUE))

  plot_reorder(state, 1L, 3L)
  expect_equal(state$plots[[1L]]$order, 2)
  expect_true(undo_apply(state))
  expect_equal(state$plots[[1L]]$order, 1)

  plot_delete(state, "plot-0001")
  expect_length(state$plots, 2L)
  expect_true(undo_apply(state))
  expect_length(state$plots, 3L)
})

test_that("Data Studio commands record one entry", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:5, x = 1:5)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(menu_search = "", data_mode = "view",
                      data_inspector_column = "y")
    session$flushReact()
    session$setInputs(data_add_row = 1)
    session$flushReact()
    expect_equal(nrow(state$env$D), 6L)
    expect_length(state$undo_stack, 1L)
    expect_equal(state$undo_stack[[1L]]$label, "Adding a row")

    expect_true(undo_apply(state))
    expect_equal(nrow(state$env$D), 5L)
  })
})

test_that("Edit availability, labels and menu status follow the stack", {
  state <- undo_test_state()
  expect_equal(command_status(state, "onUndo"), "disabled")
  expect_equal(command_status(state, "onRedo"), "disabled")

  run_command(state, "D$y <- D$y + 1", log = FALSE)
  expect_equal(command_status(state, "onUndo"), "enabled")
  expect_equal(command_availability(state, "onUndo")$status, "enabled")

  tree <- list(list(type = "menu", id = "menu.edit", label = "Edit",
                    children = list(
                      list(type = "item", command = "onUndo", label = "Undo"),
                      list(type = "item", command = "onRedo", label = "Redo")
                    )))
  labels <- vapply(undo_menu_tree(tree, state)[[1L]]$children,
                   function(node) node$label, character(1))
  expect_match(labels[[1L]], "^Undo: D\\$y <- D\\$y \\+ 1$")

  undo_apply(state)
  expect_equal(command_status(state, "onUndo"), "disabled")
  expect_equal(command_status(state, "onRedo"), "enabled")
})

test_that("a project load clears the undo stack", {
  state <- undo_test_state()
  run_command(state, "D$y <- D$y + 1", log = FALSE)
  expect_length(state$undo_stack, 1L)

  path <- tempfile(fileext = ".rcmdrproj")
  on.exit(unlink(path), add = TRUE)
  project_save(state, path)
  run_command(state, "D$y <- D$y + 1", log = FALSE)
  expect_length(state$undo_stack, 2L)

  project_load(state, path)
  expect_length(state$undo_stack, 0L)
  expect_length(state$redo_stack, 0L)
})

test_that("the keyboard shortcut ignores text entry", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "undo_shortcut", fixed = TRUE)
  expect_match(js, "redo_shortcut", fixed = TRUE)
  expect_match(js, "ace_editor", fixed = TRUE)
  expect_match(js, "isContentEditable", fixed = TRUE)
})
