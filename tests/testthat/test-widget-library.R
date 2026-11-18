# External widget families and the token bridge ------------------------------

test_that("shinyWidgets is an Import with the verified floor", {
  desc <- read.dcf(test_path("..", "..", "DESCRIPTION"))
  imports <- desc[1L, "Imports"]
  expect_match(imports, "shinyWidgets (\\(>= 0\\.9\\.1\\))", perl = TRUE)
  expect_true(requireNamespace("shinyWidgets", quietly = TRUE))
  expect_gte(utils::packageVersion("shinyWidgets"), "0.9.1")
})

test_that("the widget library names only the adopted families", {
  lib <- widget_library()
  expect_named(lib, c("virtual_select", "slider", "colour"))
  expect_true(all(vapply(lib, is.function, logical(1))))
})

test_that("the bridge files load in the documented order", {
  expect_identical(
    app_css_files(),
    c("00-tokens.css", "10-shell.css", "15-bootstrap.css",
      "20-components.css", "30-forms.css", "40-dialogs.css",
      "50-widgets.css", "55-shinywidgets.css", "60-views.css",
      "70-refine.css")
  )
  css <- as.character(app_css())
  expect_match(css, "--bs-accordion-btn-color: var(--rcmdr-heading);",
               fixed = TRUE)
  expect_match(css, "--rcmdr-shadow-sm:", fixed = TRUE)
})

test_that("the bridge writes no literal colour", {
  for (file in c("15-bootstrap.css", "55-shinywidgets.css",
                 "50-widgets.css", "60-views.css", "70-refine.css")) {
    css <- app_asset_text("css", file)
    expect_false(grepl("#[0-9a-fA-F]{3,8}", css),
                 label = sprintf("%s has no hex colour", file))
    expect_false(grepl("rgba?\\(", css),
                 label = sprintf("%s has no rgb() literal", file))
  }
})

test_that("the virtual select reads the Studio tokens", {
  css <- app_asset_text("css", "55-shinywidgets.css")
  expect_match(css, "--vs-border-color: var(--rcmdr-border-strong);",
               fixed = TRUE)
  expect_match(css, "--vs-dropdown-box-shadow: var(--rcmdr-shadow-sm);",
               fixed = TRUE)
  expect_match(css, "--vs-selected-bg: var(--rcmdr-selection);",
               fixed = TRUE)
  expect_match(css, ".vs__dropdown-menu", fixed = TRUE)
  expect_match(css, "max-height: 20rem;", fixed = TRUE)
})

test_that("every palette defines the small elevation token", {
  palettes <- palette_tokens()
  for (name in names(palettes)) {
    expect_true("--rcmdr-shadow-sm" %in% names(palettes[[name]]),
                label = name)
  }
})

test_that("the candidate widgets keep their input ids", {
  virtual <- as.character(shinyWidgets::virtualSelectInput(
    "w_virtual", "Virtual", c("a", "b"), multiple = TRUE, search = TRUE
  ))
  expect_match(virtual, 'id="w_virtual"', fixed = TRUE)
  expect_match(virtual, 'class="virtual-select"', fixed = TRUE)

  slider <- as.character(shinyWidgets::noUiSliderInput(
    "w_slider", "Slider", 0, 1, 0.5
  ))
  expect_match(slider, 'id="w_slider"', fixed = TRUE)
  expect_match(slider, "sw-no-ui-slider", fixed = TRUE)

  colour <- as.character(shinyWidgets::spectrumInput(
    "w_colour", "Colour", "white"
  ))
  expect_match(colour, 'id="w_colour"', fixed = TRUE)
  expect_match(colour, "sw-spectrum", fixed = TRUE)

  date <- as.character(shinyWidgets::airDatepickerInput(
    "w_date", "Date"
  ))
  expect_match(date, 'id="w_date"', fixed = TRUE)
  expect_match(date, "sw-air-picker", fixed = TRUE)
})

test_that("the candidate widgets are served from the package, not a CDN", {
  widgets <- htmltools::tagList(
    shinyWidgets::virtualSelectInput("w_virtual", "Virtual", c("a", "b")),
    shinyWidgets::noUiSliderInput("w_slider", "Slider", 0, 1, 0.5),
    shinyWidgets::spectrumInput("w_colour", "Colour", "white"),
    shinyWidgets::airDatepickerInput("w_date", "Date")
  )
  deps <- htmltools::renderTags(widgets)$dependencies
  urls <- vapply(deps, function(dep) {
    href <- dep$src$href
    if (is.null(href)) "" else as.character(href)
  }, character(1))
  expect_false(any(grepl("^https?://", urls)))
})

test_that("the widget gallery covers every family and is not shipped", {
  root <- test_path("..", "..")
  gallery <- readLines(file.path(root, "tools", "widget_gallery.R"))
  text <- paste(gallery, collapse = "\n")
  for (marker in c("textInput", "selectInput", "checkboxInput",
                   "radioButtons", "switch_input", "segmented_input",
                   "virtualSelectInput", "picker_input", "listbox_input",
                   "var_input", "sliderInput", "slider_input", "color_input",
                   "airDatepickerInput", "accordion", "datatable")) {
    expect_match(text, marker, fixed = TRUE,
                 label = sprintf("gallery has %s", marker))
  }
  ignore <- readLines(file.path(root, ".Rbuildignore"))
  expect_true(any(grepl("^\\^tools\\$", ignore)))
})

test_that("the gallery renders in check mode", {
  root <- normalizePath(test_path("..", ".."))
  old <- setwd(root)
  on.exit(setwd(old), add = TRUE)
  out <- suppressWarnings(system2(
    "Rscript", c("--vanilla", "tools/widget_gallery.R"),
    env = c("RCMDRSHINY_GALLERY_CHECK=1"),
    stdout = TRUE, stderr = TRUE
  ))
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  expect_equal(status, 0L)
  expect_match(paste(out, collapse = "\n"), "gallery ok", fixed = TRUE)
})

test_that("slider_input() keeps the id and the number on a noUi handle", {
  html <- as.character(slider_input("w_alpha", "Alpha", 0, 1, 0.7, 0.05))
  expect_match(html, 'id="w_alpha"', fixed = TRUE)
  expect_match(html, "sw-no-ui-slider", fixed = TRUE)
  # The value is the only thing that changed from sliderInput(): the id and
  # the bound numbers are the ones the server already reads.
  expect_match(html, '"start":0.7', fixed = TRUE)
  expect_match(html, '"range":{"min":0,"max":1}', fixed = TRUE)
  expect_match(html, '"step":0.05', fixed = TRUE)
  # The tooltip shows the precision of the step.
  expect_match(html, '"decimals":2', fixed = TRUE)
  whole <- as.character(slider_input("w_size", "Size", 6, 32, 12, 1))
  expect_match(whole, '"decimals":0', fixed = TRUE)
  expect_equal(slider_decimals(1), 0L)
  expect_equal(slider_decimals(0.05), 2L)
  expect_equal(slider_decimals(0.5), 1L)
})

test_that("the server can move a slider handle", {
  # shinyWidgets changes the range but not the value, so the wrapper owns a
  # message; the browser handler is what makes update_number_input() work.
  js <- as.character(app_js())
  expect_match(js, "rcmdr-set-slider", fixed = TRUE)
  expect_match(js, "noUiSlider.set", fixed = TRUE)

  expect_true(all(c("chart_gg_alpha", "chart_gg_jitter", "chart_base_size",
                    "chart_opt_notchwidth") %in% slider_input_ids()))
  skip_if_not_installed("shiny")
  session <- shiny::MockShinySession$new()
  expect_error(update_number_input(session, "chart_gg_alpha", 0.35), NA)
  # A number field takes the ordinary Shiny message.
  expect_error(update_number_input(session, "chart_gg_binwidth", 0.2), NA)
})

test_that("color_input() is a spectrum field with a hex value", {
  html <- as.character(color_input("w_colour", "Background"))
  expect_match(html, 'id="w_colour"', fixed = TRUE)
  expect_match(html, "sw-spectrum", fixed = TRUE)
  expect_match(html, 'data-color="#ffffff"', fixed = TRUE)
  expect_match(html, 'data-update-on="change"', fixed = TRUE)
  # A named colour stays a colour string.
  named <- as.character(color_input("w_colour2", "Background", "white"))
  expect_match(named, 'data-color="white"', fixed = TRUE)
})
