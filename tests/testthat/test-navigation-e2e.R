# Browser flow for navigation and guided workflows.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-navigation-e2e.R")'

navigation_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

navigation_switch_tab <- function(app, label) {
  switch_main_tab(app, label)
  app$wait_for_idle(timeout = 30000)
}

test_that("the navigation and workflow flows work in a browser", {
  navigation_ready()

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

  env <- new.env()
  env$D <- data.frame(
    y = c(2, 1, 4, 3, 7, 6, 9, 8),
    x = c(2, 4, 6, 8, 10, 12, 14, 16),
    g = factor(rep(c("a", "b"), 4))
  )

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "navigation-flow",
    width = 1500,
    height = 1200,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menu-item').length > 0",
    timeout = 60000
  )

  # Activate the data set through the existing dialog.
  leaves <- RcmdrShiny::menu_leaves(RcmdrShiny::menu_tree())
  key <- leaves$key[leaves$command == "selectActiveDataSet"][[1L]]
  app$run_js(sprintf("document.getElementById('%s').click();", key))
  app$wait_for_js(
    "document.getElementById('selectActiveDataSet_dataset') !== null",
    timeout = 60000
  )
  app$set_inputs(selectActiveDataSet_dataset = "D", wait_ = FALSE)
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)

  # Palette: search and open a dialog.
  app$click("palette_open")
  app$wait_for_js("document.getElementById('palette_query') !== null",
                  timeout = 60000)
  app$set_inputs(palette_query = "numerical", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelector(\"#palette_results .rcmdr-palette-result[data-palette-id='numericalSummaries']\") !== null",
    timeout = 60000
  )
  app$run_js(
    "document.querySelector(\"#palette_results .rcmdr-palette-result[data-palette-id='numericalSummaries']\").click();"
  )
  app$wait_for_js(
    "document.getElementById('numericalSummaries_x') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".modal-title"), "Numerical Summaries")
  app$click("dialog_cancel")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)

  # Favourite a menu command and verify the sidebar section.
  app$run_js("document.querySelector('.rcmdr-menu-star').click();")
  app$wait_for_js(
    "document.querySelector('.rcmdr-menu-shortcuts') &&
       document.querySelector('.rcmdr-menu-shortcuts').innerText.indexOf('Favourites') >= 0",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-menu-shortcuts"), "Favourites")

  # Save a preset from the dialog.
  app$click("palette_open")
  app$wait_for_js("document.getElementById('palette_query') !== null",
                  timeout = 60000)
  app$set_inputs(palette_query = "numerical", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelector(\"#palette_results .rcmdr-palette-result[data-palette-id='numericalSummaries']\") !== null",
    timeout = 60000
  )
  app$run_js(
    "document.querySelector(\"#palette_results .rcmdr-palette-result[data-palette-id='numericalSummaries']\").click();"
  )
  app$wait_for_js(
    "document.getElementById('dialog_preset_name') !== null",
    timeout = 60000
  )
  app$set_inputs(dialog_preset_name = "Teaching", wait_ = FALSE)
  app$wait_for_js(
    "document.getElementById('dialog_preset_name').value === 'Teaching'",
    timeout = 60000
  )
  app$click("dialog_preset_save")
  app$wait_for_js(
    "Array.from(document.querySelectorAll('option')).some(function(o){return o.textContent.trim() === 'Teaching';})",
    timeout = 60000
  )
  app$click("dialog_cancel")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)

  # Guided workflow: start, open the first step and complete it.
  navigation_switch_tab(app, "Workflows")
  app$wait_for_js(
    "document.querySelectorAll('#workflow_panel button').length > 0",
    timeout = 60000
  )
  app$run_js(
    "Array.from(document.querySelectorAll('#workflow_panel button')).find(function(b){return b.textContent.trim() === 'Start';}).click();"
  )
  app$wait_for_js(
    "Array.from(document.querySelectorAll('#workflow_panel button')).some(function(b){return b.textContent.trim() === 'Open step';})",
    timeout = 60000
  )
  app$run_js(
    "Array.from(document.querySelectorAll('#workflow_panel button')).find(function(b){return b.textContent.trim() === 'Open step';}).click();"
  )
  app$wait_for_js(
    "document.getElementById('numericalSummaries_x') !== null",
    timeout = 60000
  )
  app$set_inputs(numericalSummaries_x = "x", wait_ = FALSE)
  app$wait_for_idle(timeout = 60000)
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)
  app$wait_for_js(
    "document.getElementById('workflow_panel').innerText.indexOf('Done') >= 0",
    timeout = 60000
  )
  expect_match(app$get_text("#workflow_panel"), "Done")

  # Variable suggestions in the Data Studio inspector.
  navigation_switch_tab(app, "Data")
  app$wait_for_js(
    "document.querySelector('.rcmdr-variable-suggestions') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-variable-suggestions"),
               "What can I do with this variable")
})
