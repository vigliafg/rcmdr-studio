test_that("numeric profiles expose statistics and a histogram", {
  env <- new.env()
  env$D <- data.frame(
    y = c(1, 2, 3, 4, 5, NA),
    g = factor(c("a", "b", "a", "b", "a", NA)),
    s = c("x", "y", "x", "z", "y", NA),
    l = c(TRUE, FALSE, TRUE, FALSE, TRUE, NA),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")

  profile <- column_profile(state, "D", "y")
  expect_equal(profile$type, "numeric")
  expect_equal(profile$n, 6L)
  expect_equal(profile$missing, 1L)
  expect_equal(profile$unique, 5L)
  expect_equal(profile$stats$min, 1)
  expect_equal(profile$stats$max, 5)
  expect_equal(profile$stats$mean, 3)
  expect_equal(profile$stats$median, 3)
  expect_false(is.null(profile$histogram))
  expect_equal(sum(profile$histogram$counts), 5L)
})

test_that("factors, characters and logicals expose level counts", {
  env <- new.env()
  env$D <- data.frame(
    g = factor(c("a", "b", "a", "b", "a")),
    s = c("x", "y", "x", "z", "y"),
    l = c(TRUE, FALSE, TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")

  factor_profile <- column_profile(state, "D", "g")
  expect_equal(factor_profile$type, "factor")
  expect_equal(factor_profile$levels$value[[1L]], "a")
  expect_equal(factor_profile$levels$count[[1L]], 3L)

  character_profile <- column_profile(state, "D", "s")
  expect_equal(character_profile$type, "character")
  expect_equal(nrow(character_profile$levels), 3L)

  logical_profile <- column_profile(state, "D", "l")
  expect_equal(logical_profile$type, "logical")
  expect_equal(nrow(logical_profile$levels), 2L)
})

test_that("profiles handle empty, missing and unknown variables", {
  env <- new.env()
  env$D <- data.frame(
    empty = c(NA_real_, NA_real_, NA_real_),
    day = as.Date(c("2024-01-01", "2024-01-02", NA)),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")

  empty <- column_profile(state, "D", "empty")
  expect_equal(empty$missing, 3L)
  expect_true(is.na(empty$stats$mean))

  day <- column_profile(state, "D", "day")
  expect_equal(day$type, "date")
  expect_equal(day$missing, 1L)

  expect_null(column_profile(state, "D", "unknown"))
  expect_null(column_profile(state, "Missing", "day"))
})
