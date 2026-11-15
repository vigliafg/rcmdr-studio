# Browser flow for the Wave 6.5 menubar and stable ids.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-menu-platform-e2e.R")'

menu_e2e_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

test_that("the menubar exposes hierarchical menus with stable ids", {
  menu_e2e_ready()

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

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = new.env()),
    name = "menu-platform-flow",
    width = 1400,
    height = 1000,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = 30000)
  app$run_js("Shiny.setInputValue('tour_skip', 1, {priority: 'event'});")
  app$wait_for_idle(timeout = 30000)

  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menubar-group').length >= 9",
    timeout = 60000
  )
  labels <- app$get_js(
    "Array.from(document.querySelectorAll('.rcmdr-menubar-group > summary')).map(function(el){return el.textContent.trim();}).join('|')"
  )
  for (label in c("File", "Edit", "Data", "Transform", "Analyze",
                  "Graphs", "Reports", "Utilities", "Help")) {
    expect_match(labels, label, fixed = TRUE)
  }

  # File > Save is one group with format sub-items, not three flat Saves.
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-menubar-group')).find(function(el){
       return el.querySelector('summary').textContent.trim() === 'File';
     }).open = true;"
  )
  app$wait_for_js(
    "document.querySelector('.rcmdr-menubar-dropdown details[data-menu-id=\"menu.file.save\"]') !== null",
    timeout = 30000
  )
  save_labels <- app$get_js(
    "Array.from(document.querySelectorAll('.rcmdr-menubar-dropdown details[data-menu-id=\"menu.file.save\"] .rcmdr-menu-item')).map(function(el){return el.textContent.trim();}).join('|')"
  )
  for (label in c("Data set", "Script", "Report", "Workspace")) {
    expect_match(save_labels, label, fixed = TRUE)
  }
  expect_false(grepl("Save script as", save_labels, fixed = TRUE))

  # The stable item id is present in the DOM.
  expect_match(
    app$get_html(".rcmdr-menubar-dropdown details[data-menu-id=\"menu.file.save\"]"),
    "menu_item_file_save_script",
    fixed = TRUE
  )

  # An item still opens the existing dialog.
  app$run_js(
    "document.getElementById('menu_item_item_core_menu_utilities_options').click();"
  )
  app$wait_for_js(
    "document.getElementById('Options_digits') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".modal-title"), "Options")
  app$click("dialog_cancel")
})

test_that("unavailable menu items explain themselves and keep the menu open", {
  menu_e2e_ready()

  preferences <- tempfile(fileext = ".rds")
  saveRDS(list(
    favorites = c("readDataSet", "oneWayAnova", "onCopy"),
    recents = character()
  ), preferences)
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

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = new.env()),
    name = "menu-unavailable-flow",
    width = 1400,
    height = 1000,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = 30000)
  app$run_js("Shiny.setInputValue('tour_skip', 1, {priority: 'event'});")
  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menubar-group').length >= 9",
    timeout = 60000
  )

  # Transform has only inactive entries without a data set.
  app$run_js(paste0(
    "(function(){",
    "var g=Array.from(document.querySelectorAll('.rcmdr-menubar-group'))",
    ".find(function(el){return el.querySelector('summary').textContent.trim()==='Transform';});",
    "if(g) g.open=true;",
    "})();"
  ))
  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menubar-group[open] .rcmdr-menu-item[aria-disabled=\"true\"]').length > 0",
    timeout = 30000
  )

  item <- paste0(
    "document.querySelector('.rcmdr-menubar-group[open] ",
    ".rcmdr-menu-item[aria-disabled=\"true\"]')"
  )
  expect_match(
    app$get_js(paste0(item, ".getAttribute('title')")),
    "Not available", fixed = TRUE
  )
  expect_identical(app$get_js(paste0(item, ".getAttribute('tabindex')")), "0")
  expect_match(
    app$get_js(paste0(item, ".textContent")),
    "Not available", fixed = TRUE
  )

  # Clicking a disabled item keeps the menu open and opens nothing.
  app$run_js(paste0(item, ".click();"))
  app$wait_for_idle(timeout = 30000)
  expect_true(app$get_js(
    "document.querySelector('.rcmdr-menubar-group[open]') !== null"
  ))
  expect_true(app$get_js("document.querySelector('.modal') === null"))

  # Favourites mirror the status: one link, two disabled entries.
  expect_equal(app$get_js(
    "document.querySelectorAll('#menus .rcmdr-menu-shortcuts a.rcmdr-menu-item').length"
  ), 1)
  expect_equal(app$get_js(
    "document.querySelectorAll('#menus .rcmdr-menu-shortcuts .rcmdr-menu-item[aria-disabled=\"true\"]').length"
  ), 2)
})
