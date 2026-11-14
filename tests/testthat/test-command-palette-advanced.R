palette_test_state <- function() {
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(
    x = c(1, 2, 3, NA, 5),
    y = c(2, 4, 6, 8, 10),
    g = factor(c("a", "a", "b", "b", "b"))
  )
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  state
}

test_that("the palette separates dialogs from menu commands", {
  state <- palette_test_state()
  index <- palette_index(state)

  expect_true(any(index$type == "dialog"))
  expect_true(any(index$type == "menu"))
  expect_true(all(index$type[index$id == "numericalSummaries"] == "dialog"))
  expect_setequal(
    unique(index$type[index$type == "workflow"]),
    "workflow"
  )
  expect_equal(sum(index$type == "workflow"), 5L)
})

test_that("favourites and recents are ranked first", {
  state <- palette_test_state()
  menu_recent_add(state, "readDataSet")
  menu_favorite_toggle(state, "linearModel")

  index <- palette_index(state)
  results <- palette_search("", index, limit = 10L)

  expect_true(results$favorite[[1L]] || results$recent[[1L]])
  expect_true(any(results$id == "linearModel"))
})

test_that("the palette filters by type and favourite", {
  state <- palette_test_state()
  menu_favorite_toggle(state, "numericalSummaries")

  index <- palette_index(state)
  dialogs <- palette_search("", index, limit = 1000L, type = "dialog")
  expect_true(nrow(dialogs) > 0L)
  expect_true(all(dialogs$type == "dialog"))

  favourites <- palette_search("", index, limit = 1000L, type = "favorite")
  expect_equal(favourites$id, "numericalSummaries")

  workflows <- palette_search("", index, limit = 1000L, type = "workflow")
  expect_equal(nrow(workflows), 5L)
})

test_that("the palette index is cached until the state changes", {
  state <- palette_test_state()
  first <- palette_index_cached(state)
  second <- palette_index_cached(state)
  expect_identical(first, second)

  menu_recent_add(state, "readDataSet")
  third <- palette_index_cached(state)
  expect_false(identical(first, third))
})

test_that("workflow rows do not duplicate when a step has several titles", {
  state <- palette_test_state()
  index <- palette_index(state)
  workflow <- index[index$type == "workflow", , drop = FALSE]
  expect_equal(nrow(workflow), length(workflow_registry()))
  expect_false(anyDuplicated(workflow$id) > 0L)
})

test_that("palette results expose action buttons and disabled reasons", {
  state <- palette_test_state()
  index <- palette_index(state)
  results <- palette_search("numerical", index)
  html <- as.character(palette_results_ui(results))
  expect_match(html, "rcmdr-palette-actions")
  expect_match(html, "rcmdr-palette-result")

  disabled <- palette_row(
    "unavailable", "dialog", "Unavailable", "Statistics", "unavailable",
    enabled = FALSE, reason = "Needs a package", command = "unavailable"
  )
  disabled_html <- as.character(palette_results_ui(disabled))
  expect_match(disabled_html, "aria-disabled")
  expect_match(disabled_html, "Needs a package")
})
