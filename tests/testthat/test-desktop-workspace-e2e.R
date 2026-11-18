# Desktop workspace in a browser (Wave 18, S11).
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
#     'testthat::test_file("tests/testthat/test-desktop-workspace-e2e.R")'
#
# The audit that runs here is the one the static tests cannot prove: F6 moves
# the real focus, the shell reflows at 200% zoom and the theme classes reach
# the real body.

desktop_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

desktop_app <- function() {
  env <- new.env(parent = globalenv())
  env$D <- data.frame(
    y = 1:12,
    x = 2 * (1:12),
    g = factor(rep(c("a", "b"), 6))
  )
  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "desktop-workspace",
    width = 1280,
    height = 1000,
    load_timeout = 90000
  )
  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menu-item').length > 0",
    timeout = 60000
  )
  app
}

test_that("F6 reaches the workspace regions without a mouse", {
  desktop_ready()
  app <- desktop_app()
  on.exit(app$stop(), add = TRUE)

  # The shell starts at Home, so the primary region is rendered.
  app$wait_for_js(
    "document.querySelector('[data-rcmdr-focus-region=\"primary\"]') !== null",
    timeout = 60000
  )
  app$run_js(
    "document.dispatchEvent(new KeyboardEvent('keydown', {key: 'F6'}));"
  )
  app$wait_for_idle()
  primary <- app$get_js(
    "document.activeElement.getAttribute('data-rcmdr-focus-region')"
  )
  expect_equal(primary, "primary")

  # Keep going until the status bar: the cycle is primary, secondary, panel,
  # modeless, status.  Some of the middle stops may be absent.
  reached <- FALSE
  for (i in seq_len(6L)) {
    app$run_js(
      "document.dispatchEvent(new KeyboardEvent('keydown', {key: 'F6'}));"
    )
    app$wait_for_idle()
    region <- app$get_js(
      "document.activeElement.getAttribute('data-rcmdr-focus-region')"
    )
    if (identical(region, "status")) {
      reached <- TRUE
      break
    }
  }
  expect_true(reached)
})

test_that("the shell reflows at 200% zoom without horizontal overflow", {
  desktop_ready()
  app <- desktop_app()
  on.exit(app$stop(), add = TRUE)

  # 200% of a 1280 px window is a 640 px CSS viewport.
  app$set_window_size(640, 1000)
  app$wait_for_idle()
  app$run_js("window.dispatchEvent(new Event('resize'));")
  app$wait_for_idle()

  overflow <- app$get_js(
    "document.documentElement.scrollWidth - window.innerWidth"
  )
  expect_lte(as.numeric(overflow), 1)

  sidebar <- app$get_js(
    paste0("(function(){var el=document.querySelector('.rcmdr-sidebar');",
           "if(!el)return 0;",
           "return el.getBoundingClientRect().height / window.innerHeight;})()")
  )
  expect_lte(as.numeric(sidebar), 0.41)
})

test_that("theme and density classes reach the real body", {
  desktop_ready()
  app <- desktop_app()
  on.exit(app$stop(), add = TRUE)

  expect_true(app$get_js(
    "document.body.classList.contains('rcmdr-mode-studio')"
  ))

  app$set_inputs(theme = "dark", wait_ = FALSE)
  app$wait_for_idle()
  app$wait_for_js(
    "document.body.classList.contains('rcmdr-dark')",
    timeout = 30000
  )
  expect_true(app$get_js(
    "document.body.classList.contains('rcmdr-dark')"
  ))

  app$set_inputs(theme = "contrast", wait_ = FALSE)
  app$wait_for_idle()
  app$wait_for_js(
    "document.body.classList.contains('rcmdr-contrast')",
    timeout = 30000
  )
  expect_true(app$get_js(
    "document.body.classList.contains('rcmdr-contrast')"
  ))
})
