# Availability guards: a command the menu disables cannot be launched through
# favourites, recents or the history.

test_that("launch does not open a dialog for an unavailable command", {
  skip_if_not_installed("shiny")

  shiny::testServer(app_server(new.env()), {
    session$setInputs(menu_command = "oneWayAnova")
    session$flushReact()
    expect_error(as.character(output$dialog_body), class = "shiny.silent.error")
  })
})

test_that("reopening a dialog from history respects availability", {
  state <- AppState(env = new.env())
  state$history <- list(list(
    id = "hist-1",
    dialog_id = "oneWayAnova",
    dialog_memory = list()
  ))
  opened <- character()
  state$open_dialog <- function(id) {
    opened <<- c(opened, id)
    invisible(NULL)
  }
  state$session <- NULL

  expect_false(history_open_dialog(state, "hist-1"))
  expect_length(opened, 0L)

  state$env$Dataset <- data.frame(
    y = c(1, 2, 3, 4),
    g = factor(c("a", "b", "a", "b"))
  )
  active_dataset(state, "Dataset")

  expect_true(history_open_dialog(state, "hist-1"))
  expect_identical(opened, "oneWayAnova")
})
