# Wave 0 browser flow: Studio shell, palette, dialog preview, history, modes.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-wave0-e2e.R")'

wave0_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

wave0_switch_tab <- function(app, label) {
  switch_main_tab(app, label)
}

test_that("the Studio foundation flow works in a browser", {
  wave0_ready()

  env <- new.env()
  env$Dataset <- data.frame(
    y = 1:6,
    x = 2 * (1:6),
    g = factor(c("a", "b", "a", "b", "a", "b"))
  )

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "wave0-studio",
    width = 1280,
    height = 1000,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menu-item').length > 0",
    timeout = 60000
  )

  # Activate the data set so the summary dialog is enabled.
  leaves <- RcmdrShiny::menu_leaves(RcmdrShiny::menu_tree())
  key <- leaves$key[leaves$command == "selectActiveDataSet"][[1L]]
  app$run_js(sprintf("document.getElementById('%s').click();", key))
  app$wait_for_js("document.getElementById('selectActiveDataSet_dataset') !== null",
                  timeout = 60000)
  app$set_inputs(selectActiveDataSet_dataset = "Dataset", wait_ = FALSE)
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)
  app$wait_for_idle()

  # Home is the default Studio landing tab.
  app$wait_for_js("document.querySelector('#home_import') !== null",
                  timeout = 60000)
  expect_match(app$get_text(".rcmdr-home-hero"), "RcmdrShiny Studio")

  # Command palette: Ctrl+K opens it, a query finds the summary dialog.
  app$run_js(
    "document.dispatchEvent(new KeyboardEvent('keydown', {key: 'k', ctrlKey: true}));"
  )
  app$wait_for_js("document.querySelector('#palette_query') !== null",
                  timeout = 60000)
  app$set_inputs(palette_query = "numerical", wait_ = FALSE)
  app$wait_for_idle()
  app$wait_for_js("document.querySelector('.rcmdr-palette-result') !== null",
                  timeout = 30000)
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-palette-result')).find(function(el){return el.getAttribute('data-palette-id') === 'numericalSummaries';}).click();"
  )
  app$wait_for_js("document.querySelector('#numericalSummaries_x') !== null",
                  timeout = 60000)

  # The live command preview appears before OK.
  app$set_inputs(
    numericalSummaries_x = "y",
    numericalSummaries_groups = "",
    numericalSummaries_mean = TRUE,
    numericalSummaries_sd = TRUE,
    wait_ = FALSE
  )
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('.rcmdr-dialog-preview').innerText.includes('numSummary')",
    timeout = 30000
  )

  # "To script" inserts without executing.
  app$click("dialog_insert_script")
  app$wait_for_idle()
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 30000)
  app$wait_for_js(
    "ace.edit(document.querySelector('#script_editor_ui .ace_editor')).getValue().includes('numSummary')",
    timeout = 30000
  )

  # Execute the inserted script and verify the output.
  app$click("run_all")
  app$wait_for_idle()
  wave0_switch_tab(app, "Console")
  wave0_switch_tab(app, "Output")
  app$wait_for_js(
    "document.querySelector('#output_text').innerText.includes('mean')",
    timeout = 30000
  )

  # History cards expose rerun and dialog actions.
  wave0_switch_tab(app, "History")
  app$wait_for_js(
    "document.querySelector('.rcmdr-history-card') !== null",
    timeout = 30000
  )
  expect_match(app$get_text(".rcmdr-history-card"), "numSummary")
  app$run_js(
    "document.querySelector('[data-history-action=\"rerun\"]').click();"
  )
  app$wait_for_idle()

  # Studio/Classic switch.
  app$click("ui_mode_toggle")
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('#main_tabs .nav-link[data-value=\"charts\"]') !== null",
    timeout = 30000
  )
  app$click("ui_mode_toggle")
  app$wait_for_idle()
  app$wait_for_js(
    "Array.from(document.querySelectorAll('.nav-link')).some(function(a){return a.textContent.trim() === 'Home';})",
    timeout = 30000
  )

  # High-contrast theme is applied to the body.
  app$set_inputs(theme = "contrast", wait_ = FALSE)
  app$wait_for_idle()
  expect_true(app$get_js(
    "document.body.classList.contains('rcmdr-contrast')"
  ))
})
