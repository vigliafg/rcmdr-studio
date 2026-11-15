# Chart gallery --------------------------------------------------------------

gallery_state <- function() {
  state <- chart_test_state()
  state$plot_dir <- tempfile("rcmdr-charts-")
  dir.create(state$plot_dir)
  state$plot_prefix <- "charts"
  chart_apply(state, chart_spec("histogram", "D", list(x = "y"),
                                labels = list(title = "Distribution")))
  chart_apply(state, chart_spec("scatter", "D", list(x = "x", y = "y"),
                                labels = list(title = "Relationship")))
  chart_apply(state, chart_spec("bar", "D", list(x = "g"),
                                labels = list(title = "Groups")))
  state
}

test_that("the gallery lists plots with metadata", {
  state <- gallery_state()
  table <- plot_list(state)
  expect_equal(nrow(table), 3L)
  expect_equal(table$title, c("Groups", "Relationship", "Distribution"))
  expect_equal(table$type, c("bar", "scatter", "histogram"))
  expect_true(all(table$dataset == "D"))
  expect_true(all(nzchar(table$url)))
  expect_false(any(table$pinned))
})

test_that("the gallery can be searched and filtered", {
  state <- gallery_state()
  expect_equal(plot_list(state, query = "relationship")$title,
               "Relationship")
  expect_equal(plot_list(state, query = "D")$type,
               c("bar", "scatter", "histogram"))
  expect_equal(plot_list(state, type = "scatter")$title, "Relationship")
  expect_equal(nrow(plot_list(state, type = "all")), 3L)
})

test_that("plots can be pinned, renamed and compared", {
  state <- gallery_state()
  expect_true(plot_update(state, 1L, pinned = TRUE))
  table <- plot_list(state)
  expect_true(table$pinned[table$index == 1L])
  expect_equal(table$title[[1L]], "Distribution")

  expect_true(plot_update(state, 1L, title = "Pinned histogram"))
  expect_equal(plot_title(plot_entry(state, 1L)), "Pinned histogram")
  expect_equal(nrow(plot_list(state, pinned = TRUE)), 1L)

  comparison <- plot_compare(state, c(1L, 2L))
  expect_equal(length(comparison), 2L)
  expect_equal(plot_title(comparison[[1L]]), "Pinned histogram")
})

test_that("plots can be reopened and deleted", {
  state <- gallery_state()
  spec <- plot_reopen(state, 2L)
  expect_equal(spec$type, "scatter")
  expect_equal(spec$mapping$x, "x")

  file <- state$plots[[2L]]$file
  expect_true(file.exists(file))
  expect_true(plot_delete(state, 2L))
  expect_equal(length(state$plots), 2L)
  expect_false(file.exists(file))
  expect_null(plot_reopen(state, "missing"))
  expect_false(plot_delete(state, 99L))
})

test_that("legacy plots without a spec still enter the gallery", {
  state <- chart_test_state()
  run_command(state, "plot(D$x, D$y)")
  table <- plot_list(state)
  expect_equal(nrow(table), 1L)
  expect_equal(table$type, "")
  expect_equal(table$title, "Plot")
  expect_null(plot_reopen(state, 1L))
})

test_that("ids are stable and locate plots by name", {
  state <- gallery_state()
  id <- state$plots[[1L]]$id
  expect_equal(plot_locate(state, id), 1L)
  expect_equal(plot_title(plot_entry(state, id)), "Distribution")
  expect_true(is.na(plot_locate(state, "missing")))
})

test_that("selected points create a reproducible data set", {
  state <- chart_test_state()
  spec <- chart_spec("scatter", "D", list(x = "x", y = "y"))
  selected <- data.frame(pointNumber = c(0L, 2L))

  result <- chart_subset_selected(state, spec, selected)
  expect_true(result$ok)
  expect_identical(result$name, "DSelected")
  expect_identical(result$rows, 2L)
  expect_true(exists("DSelected", envir = state$env, inherits = FALSE))
  expect_equal(nrow(state$env$DSelected), 2L)
  expect_identical(active_dataset(state), "DSelected")
  expect_match(result$command, "DSelected <- D\\[c\\(1, 3\\), , drop = FALSE\\]")
})

test_that("subsetting rejects grouped or non-scatter charts", {
  state <- chart_test_state()
  grouped <- chart_spec("scatter", "D", list(x = "x", y = "y", group = "g"))
  expect_false(chart_subset_selected(
    state, grouped, data.frame(pointNumber = 0L)
  )$ok)
  histogram <- chart_spec("histogram", "D", list(x = "y"))
  expect_false(chart_subset_selected(
    state, histogram, data.frame(pointNumber = 0L)
  )$ok)
  expect_false(chart_subset_selected(
    state, grouped, data.frame(pointNumber = integer())
  )$ok)
})
