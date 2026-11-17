# Form helpers ----------------------------------------------------------------

test_that("field() keeps label, control and help in one field container", {
  html <- as.character(field(
    htmltools::tags$input(id = "demo", type = "text"),
    label = "Demo",
    help = "Pick a value",
    class = "demo-field",
    for_id = "demo"
  ))
  expect_match(html, 'class="rcmdr-field demo-field"', fixed = TRUE)
  expect_match(html, '<label class="form-label" for="demo">Demo</label>',
               fixed = TRUE)
  expect_match(html, 'id="demo"', fixed = TRUE)
  expect_match(html, 'class="form-text">Pick a value', fixed = TRUE)
})

test_that("field() omits the optional parts instead of emitting empties", {
  html <- as.character(field(htmltools::tags$input(id = "bare")))
  expect_match(html, 'class="rcmdr-field"', fixed = TRUE)
  expect_false(grepl("form-label", html, fixed = TRUE))
  expect_false(grepl("form-text", html, fixed = TRUE))
})

test_that("field_grid() emits the class the dialog bodies already use", {
  html <- as.character(field_grid(htmltools::tags$div("x"), class = "wide"))
  expect_match(html, 'class="rcmdr-field-grid wide"', fixed = TRUE)
  expect_match(html, ">x<", fixed = TRUE)
})

test_that("switch_input() is the checkbox Shiny binds, only wrapped", {
  html <- as.character(switch_input("pref", "Prefer", TRUE))
  expect_match(html, 'class="rcmdr-switch"', fixed = TRUE)
  # Same id, same type, same Shiny class, same submitted value.
  expect_match(html, 'id="pref"', fixed = TRUE)
  expect_match(html, 'type="checkbox"', fixed = TRUE)
  expect_match(html, 'class="shiny-input-checkbox"', fixed = TRUE)
  expect_match(html, 'checked="checked"', fixed = TRUE)

  bare <- as.character(shiny::checkboxInput("pref", "Prefer", TRUE))
  expect_equal(gsub("^.*?(<input[^>]*>).*$", "\\1", html),
               gsub("^.*?(<input[^>]*>).*$", "\\1", bare))
})

test_that("segmented_input() keeps the radio ids, names and values", {
  html <- as.character(segmented_input(
    "mode", "Mode", c("Studio" = "studio", "Classic" = "classic"), "classic"
  ))
  expect_match(html, 'class="rcmdr-segmented"', fixed = TRUE)
  expect_match(html, 'id="mode"', fixed = TRUE)
  expect_match(html, 'name="mode"', fixed = TRUE)
  expect_match(html, 'value="studio"', fixed = TRUE)
  expect_match(html, 'value="classic"', fixed = TRUE)
  # The second option is the selected one.
  classic <- regmatches(html, regexpr('<input[^>]*value="classic"[^>]*>', html))
  expect_match(classic, 'checked="checked"', fixed = TRUE)

  radios <- regmatches(html, gregexpr('<input[^>]*type="radio"[^>]*>', html))[[1]]
  expect_length(radios, 2L)
})

test_that("number_input() and spin_input() build the same number field", {
  a <- as.character(number_input("n", "N", 5, min = 1, max = 9, step = 2))
  b <- as.character(spin_input("n", "N", 5, min = 1, max = 9, step = 2))
  expect_identical(a, b)
  expect_match(a, 'type="number"', fixed = TRUE)
  expect_match(a, 'id="n"', fixed = TRUE)
  expect_match(a, 'min="1"', fixed = TRUE)
  expect_match(a, 'max="9"', fixed = TRUE)
  expect_match(a, 'step="2"', fixed = TRUE)
})

test_that("the helpers are styled by tokens and keep a visible focus ring", {
  css <- as.character(app_css())
  expect_match(css, ".rcmdr-field {", fixed = TRUE)
  expect_match(css, ".rcmdr-switch input[type=\"checkbox\"]:checked", fixed = TRUE)
  expect_match(css, ".rcmdr-segmented .shiny-options-group label:has(input:checked)",
               fixed = TRUE)
  # The segmented control hides the radio but keeps it focusable, and the ring
  # moves to the visible label.
  expect_match(css,
               ".rcmdr-segmented .shiny-options-group label:has(input:focus-visible)",
               fixed = TRUE)
  expect_match(css,
               "outline: var(--rcmdr-focus-width) solid var(--rcmdr-focus);",
               fixed = TRUE)
  # A checked segment is a guaranteed pair, not white on the accent.
  expect_match(css,
               "background: var(--rcmdr-primary);\n      color: var(--rcmdr-on-primary);",
               fixed = TRUE)
})

test_that("the switch is used for preferences, not for command parameters", {
  script <- as.character(script_pane_ui())
  expect_match(script, 'class="rcmdr-switch"', fixed = TRUE)
  expect_match(script, 'id="auto_append"', fixed = TRUE)
  expect_match(script, 'type="checkbox"', fixed = TRUE)

  hint <- as.character(result_hint_ui(
    list(tab = "data", command = "Data > Active data set"), auto = TRUE
  ))
  expect_match(hint, 'class="rcmdr-switch"', fixed = TRUE)
  expect_match(hint, 'id="result_hint_auto"', fixed = TRUE)

  # A command parameter is a value that ends up in a command: flipping it does
  # not change the application, so it keeps the square checkbox.
  controls <- as.character(chart_stat_controls(list(options = list())))
  expect_match(controls, 'class="shiny-input-checkbox"', fixed = TRUE)
  expect_false(grepl("rcmdr-switch", controls, fixed = TRUE))
})
