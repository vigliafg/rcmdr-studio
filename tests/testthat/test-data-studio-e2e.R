# Browser flow for the Data Studio.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-data-studio-e2e.R")'

data_studio_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

data_studio_switch_tab <- function(app, label) {
  switch_main_tab(app, label)
  app$wait_for_idle(timeout = 30000)
}

test_that("the Data Studio flow works in a browser", {
  data_studio_ready()

  env <- new.env()
  env$Dataset <- data.frame(
    y = 1:6,
    x = 2 * (1:6),
    g = factor(c("a", "b", "a", "b", "a", "b"))
  )

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "data-studio-flow",
    width = 1400,
    height = 1100,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menu-item').length > 0",
    timeout = 60000
  )

  leaves <- RcmdrShiny::menu_leaves(RcmdrShiny::menu_tree())
  key <- leaves$key[leaves$command == "selectActiveDataSet"][[1L]]
  app$run_js(sprintf("document.getElementById('%s').click();", key))
  app$wait_for_js(
    "document.getElementById('selectActiveDataSet_dataset') !== null",
    timeout = 60000
  )
  app$set_inputs(selectActiveDataSet_dataset = "Dataset", wait_ = FALSE)
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)
  app$wait_for_idle()

  data_studio_switch_tab(app, "Data")
  app$wait_for_js(
    "document.querySelectorAll('#data_studio_table tbody tr').length === 6",
    timeout = 60000
  )
  expect_match(app$get_text("#data_info"), "6 rows x 3 columns")
  expect_match(app$get_text("#data_inspector"), "integer - numeric")
  expect_true(app$get_js(
    "document.body.innerText.includes('Column actions')"
  ))

  # A view filter changes the grid only; it does not run an R command.
  app$set_inputs(data_filter_column = "g", data_filter_value = "a",
                 wait_ = FALSE)
  app$wait_for_js(
    "document.querySelectorAll('#data_studio_table tbody tr').length === 3",
    timeout = 30000
  )
  app$click("data_filter_clear")
  app$wait_for_js(
    "document.querySelectorAll('#data_studio_table tbody tr').length === 6",
    timeout = 30000
  )

  # Row selection is communicated by the grid callback.
  app$run_js(
    "document.querySelectorAll('#data_studio_table tbody tr')[0].querySelector('td').click();"
  )
  app$wait_for_idle()
  expect_match(app$get_text("#data_selection_bar"), "1 row")

  # Add a row: the command is logged and a checkpoint is created.
  app$click("data_add_row")
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('#data_info').innerText.includes('7 rows')",
    timeout = 30000
  )

  # Add a column through the dialog runtime.
  app$click("data_add_column")
  app$wait_for_js(
    "document.getElementById('dataAddColumn_name') !== null",
    timeout = 30000
  )
  app$set_inputs(
    dataAddColumn_name = "ratio",
    dataAddColumn_expression = "x / y",
    wait_ = FALSE
  )
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 30000)
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('#data_info').innerText.includes('4 columns')",
    timeout = 30000
  )

  # Restore the latest checkpoint (taken before the column was added).
  app$click("data_checkpoints")
  app$wait_for_js(
    "document.getElementById('dataCheckpoints_checkpoint') !== null",
    timeout = 30000
  )
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 30000)
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('#data_info').innerText.includes('3 columns')",
    timeout = 30000
  )

  # The export controls remain available.
  expect_true(app$get_js(
    "document.getElementById('download_dataset') !== null"
  ))
  expect_true(app$get_js(
    "document.getElementById('download_dataset_rdata') !== null"
  ))
})
