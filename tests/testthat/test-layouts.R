test_that("a split ratio is clamped and validated", {
  expect_equal(layout_ratio(0.4), 0.4)
  expect_equal(layout_ratio(0), layout_min_ratio)
  expect_equal(layout_ratio(2), layout_max_ratio)
  expect_null(layout_ratio("not a number"))
  expect_null(layout_ratio(c(0.2, 0.8)))
  expect_equal(layout_ratio(NULL, fallback = 0.5), 0.5)
  expect_equal(layout_initial("missing", default = 0.7), 0.7)
})

test_that("split sizes survive a preferences round trip", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  state <- AppState(env = new.env())
  expect_equal(layout_set(state, "chart_layout", 0.42), 0.42)
  expect_equal(layout_set(state, "data_layout", 0.66), 0.66)
  preferences_save(state, path)

  restored <- AppState(env = new.env())
  expect_true(preferences_load(restored, path))
  expect_equal(restored$options$layouts$chart_layout$first, 0.42)
  expect_equal(restored$options$layouts$data_layout$first, 0.66)
  expect_equal(restored$options$layouts$chart_layout$version, layout_version)
  expect_equal(layout_initial("chart_layout", layouts = restored$options$layouts),
               0.42)
  expect_null(layout_saved("unknown", restored$options$layouts))
})

test_that("a layout saved by another version is ignored", {
  layouts <- list(
    old = list(version = layout_version + 1L, first = 0.3),
    clean = list(version = layout_version, first = 0.25)
  )
  expect_null(layout_saved("old", layouts))
  expect_equal(layout_saved("clean", layouts), 0.25)
  expect_equal(layout_initial("old", default = 0.5, layouts = layouts), 0.5)
})

test_that("clearing preferences clears the split sizes", {
  state <- AppState(env = new.env())
  layout_set(state, "chart_layout", 0.4)
  preferences_clear(state)
  expect_equal(state$options$layouts, list())
})
