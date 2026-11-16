# Optional chart extensions -------------------------------------------------

test_that("the extension registry lists every optional package", {
  status <- chart_ext_status()
  expect_true(all(c("patchwork", "ggstatsplot", "hrbrthemes", "quarto") %in%
                    status$id))
  expect_equal(nrow(status), 4L)
  expect_true(all(c("label", "role", "installed", "version", "ready", "cli")
                  %in% names(status)))
})

test_that("availability follows requireNamespace", {
  expect_true(chart_ext_available(NULL))
  expect_true(chart_ext_available(character()))
  expect_equal(chart_ext_available("patchwork"),
               requireNamespace("patchwork", quietly = TRUE))
  expect_false(chart_ext_available("rcmdrstudio.notapackage"))
  expect_equal(chart_ext_missing("rcmdrstudio.notapackage"),
               "rcmdrstudio.notapackage")
})

test_that("installation hints name the missing packages", {
  hint <- chart_ext_hint(c("ggstatsplot", "hrbrthemes"))
  expect_match(hint, "install.packages")
  expect_match(hint, "ggstatsplot")
  hint <- chart_ext_hint("quarto", cli = TRUE)
  expect_match(hint, "quarto.org")
})

test_that("the extensions panel renders one row per extension", {
  html <- htmltools::renderTags(chart_ext_ui())$html
  expect_match(html, "patchwork")
  expect_match(html, "ggstatsplot")
  expect_match(html, "Quarto")
})

test_that("the theme selector sends the hrbrthemes theme ids", {
  choices <- chart_gg_theme_choices()
  expect_equal(unname(choices[["Minimal"]]), "minimal")
  skip_if_not(chart_ext_available("hrbrthemes"), "hrbrthemes is not installed")
  expect_equal(unname(choices[["Ipsum RC"]]), "theme_ipsum_rc")
  expect_equal(unname(choices[["FT RC"]]), "theme_ft_rc")
  # The chosen value must reach the generated code as an hrbrthemes theme.
  code <- chart_gg_theme_code(list(ggplot_theme = "theme_ipsum_rc"))
  expect_match(code, "hrbrthemes::theme_ipsum_rc", fixed = TRUE)
})
