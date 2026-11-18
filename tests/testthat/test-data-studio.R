
test_that("the date filter keeps the inclusive calendar range", {
  days <- as.Date(c("2026-11-10", "2026-11-15", "2026-11-20", NA))
  expect_equal(
    date_range_keep(days, c("2026-11-15", "2026-11-20")),
    c(FALSE, TRUE, TRUE, FALSE)
  )
  # One end keeps the range open; no range keeps every row.
  expect_equal(
    date_range_keep(days, "2026-11-18"),
    c(FALSE, FALSE, TRUE, FALSE)
  )
  expect_equal(date_range_keep(days, NULL), rep(TRUE, 4L))
  expect_true(date_column(days))
  expect_true(date_column(as.POSIXct("2026-11-18 12:00:00", tz = "UTC")))
  expect_false(date_column(1:3))
})
