# Extra chart types -----------------------------------------------------------

test_that("the no-dependency extra types produce their own ggplot layers", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()
  specs <- list(
    lollipop = chart_spec("lollipop", "D", list(x = "g", y = "y")),
    dumbbell = chart_spec("dumbbell", "D",
                          list(x = "g", y = "y", y2 = "x")),
    doughnut = chart_spec("doughnut", "D", list(x = "g", y = "y")),
    stacked_area = chart_spec("stacked_area", "D",
                              list(x = "x", y = "y", group = "g"))
  )
  expected <- c(
    lollipop = "ggplot2::geom_segment",
    dumbbell = "ggplot2::geom_segment",
    doughnut = "ggplot2::coord_polar",
    stacked_area = "ggplot2::geom_area\\(position = \"stack\""
  )
  for (id in names(specs)) {
    expect_equal(chart_spec_validate(specs[[id]], state), character(),
                 info = id)
    command <- chart_spec_command(specs[[id]])
    expect_match(command, expected[[id]], info = id)
    expect_match(command, "^print\\(ggplot2::ggplot\\(D", info = id)
  }
})

test_that("doughnut draws a hole and hides the polar axis", {
  spec <- chart_spec("doughnut", "D", list(x = "g", y = "y"),
                     options = list(inner_radius = 0.6, width = 1))
  command <- chart_spec_command(spec)
  expect_match(command, "ggplot2::xlim\\(0.6, 2.5\\)")
  expect_match(command, "ggplot2::coord_polar\\(theta = \"y\"\\)")
  expect_match(command, "axis.text.y = ggplot2::element_blank\\(\\)")
})

test_that("optional extra types are gated by their package", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()
  if (chart_ext_available("ggridges")) {
    spec <- chart_spec("ridgeline", "D", list(x = "y", y = "g"))
    expect_equal(chart_spec_validate(spec, state), character())
    expect_match(chart_spec_command(spec),
                 "ggridges::geom_density_ridges")
  }
  if (chart_ext_available("ggbeeswarm")) {
    spec <- chart_spec("beeswarm", "D", list(x = "g", y = "y"))
    expect_equal(chart_spec_validate(spec, state), character())
    expect_match(chart_spec_command(spec),
                 "ggbeeswarm::geom_beeswarm")
  }
})
