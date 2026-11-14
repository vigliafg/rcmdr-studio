# P7.20: visual regression, optional.
#
# The snapshot is checked only when vdiffr is installed and the snapshot exists.
# The plot is deterministic: base graphics, fixed data and fixed theme colours.

visual_plot <- function() {
  graphics::par(mar = c(4, 4, 2, 1))
  graphics::plot(
    1:10, (1:10)^2, type = "b", pch = 19, col = "#1f3a5f",
    xlab = "x", ylab = "y", main = "Quadratic"
  )
}

test_that("the reference chart matches its snapshot", {
  skip_if_not_installed("vdiffr")
  skip_on_cran()
  snapshot <- testthat::test_path("_snaps", "visual", "quadratic-line.svg")
  skip_if_not(file.exists(snapshot),
              "The visual snapshot has not been generated on this platform.")
  vdiffr::expect_doppelganger("quadratic-line", visual_plot)
})
