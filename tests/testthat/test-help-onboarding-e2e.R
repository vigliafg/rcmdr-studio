# Browser flow for the Wave 6 help centre and tour.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-help-onboarding-e2e.R")'

help_e2e_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

help_e2e_open_help <- function(app) {
  app$run_js(
    "var links = document.querySelectorAll('#main_tabs .nav-link');
     if (links.length) links[links.length - 1].click();"
  )
  app$wait_for_js("document.getElementById('help_query') !== null",
                  timeout = 60000)
}

test_that("search, examples and the tour work in a browser", {
  help_e2e_ready()

  preferences <- tempfile(fileext = ".rds")
  old_preferences <- Sys.getenv("RCMDRSHINY_PREFERENCES", unset = NA_character_)
  Sys.setenv(RCMDRSHINY_PREFERENCES = preferences)
  on.exit({
    unlink(preferences)
    if (is.na(old_preferences)) {
      Sys.unsetenv("RCMDRSHINY_PREFERENCES")
    } else {
      Sys.setenv(RCMDRSHINY_PREFERENCES = old_preferences)
    }
  }, add = TRUE)

  old_language <- getOption("RcmdrShiny.language")
  on.exit(options(RcmdrShiny.language = old_language), add = TRUE)
  RcmdrShiny::i18n_set_language("en")

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = new.env()),
    name = "help-onboarding-flow",
    width = 1400,
    height = 1100,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menu-item').length > 0",
    timeout = 60000
  )

  # First-run tour is dismissible.
  app$wait_for_js("document.querySelector('.modal-title') !== null",
                  timeout = 60000)
  expect_match(app$get_text(".modal-title"), "Tour")
  app$click("tour_skip")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 30000)

  help_e2e_open_help(app)

  app$set_inputs(help_query = "numerical summaries", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-help-result').length > 0",
    timeout = 60000
  )
  app$run_js("document.querySelector('.rcmdr-help-result').click();")
  app$wait_for_js(
    "document.querySelector('.rcmdr-help-examples') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-help-topic"), "Numerical summaries")

  # Filters reduce the result set without touching the topic.
  app$set_inputs(help_type = "tutorial", wait_ = FALSE)
  app$wait_for_idle(timeout = 30000)
  app$click("help_clear_filters")
  app$wait_for_idle(timeout = 30000)

  # A runnable example asks for confirmation and is logged.
  app$run_js(
    "Shiny.setInputValue('help_open', 'getting-started', {priority: 'event'});"
  )
  app$wait_for_js(
    "document.querySelector('.rcmdr-help-header h2') &&
      document.querySelector('.rcmdr-help-header h2').textContent.indexOf('first analysis') >= 0",
    timeout = 60000
  )
  app$wait_for_js(
    "document.querySelector('.rcmdr-help-examples [data-help-example]') !== null",
    timeout = 60000
  )
  app$run_js(
    "document.querySelector('.rcmdr-help-examples [data-help-example]').click();"
  )
  app$wait_for_js("document.getElementById('help_example_confirm') !== null",
                  timeout = 60000)
  app$wait_for_idle(timeout = 30000)
  app$click("help_example_confirm")
  app$wait_for_idle(timeout = 60000)
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)

  # The tour can be restarted from the Help menu equivalent.
  app$run_js("Shiny.setInputValue('tour_start', Date.now(), {priority: 'event'});")
  app$wait_for_js("document.getElementById('tour_next') !== null",
                  timeout = 60000)
  app$wait_for_idle(timeout = 30000)
  for (step in 1:4) {
    app$click("tour_next")
    app$wait_for_idle(timeout = 30000)
  }
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 30000)

  # Language switch re-renders the tabs without a restart.
  app$set_inputs(language = "it", wait_ = FALSE)
  app$wait_for_idle(timeout = 30000)
  expect_match(app$get_text("#main_tabs"), "Centro assistenza")
  expect_match(app$get_text("#main_tabs"), "Studio dati")
})
