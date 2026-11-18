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

test_that("the field family shares one chrome and one invalid state", {
  css <- as.character(app_css())
  expect_match(css, "body .form-control:hover:not(:disabled):not([readonly])",
               fixed = TRUE)
  expect_match(css, "body .form-control:disabled,", fixed = TRUE)
  expect_match(css, "body .form-control[readonly]", fixed = TRUE)
  expect_match(css, "body .form-control.is-invalid,", fixed = TRUE)
  expect_match(css, "border-color: var(--rcmdr-danger);", fixed = TRUE)

  # The select arrow is drawn in currentColor, not with Bootstrap's fixed
  # data URI, so it follows every palette.
  expect_match(
    css,
    "linear-gradient\\(45deg, transparent 50%, currentColor 50%\\)",
    perl = TRUE
  )
  expect_match(
    css,
    "linear-gradient\\(135deg, currentColor 50%, transparent 50%\\)",
    perl = TRUE
  )

  # A multiple select is a listbox: rows, no arrow, enough height.
  expect_match(css, "body select\\[multiple\\]\\.form-select", perl = TRUE)
  expect_match(css, "min-height: calc(var(--rcmdr-control-h) * 6);",
               fixed = TRUE)
})

test_that("checkbox and radio are 16 px controls with real states", {
  css <- as.character(app_css())
  check_rule <- regmatches(
    css,
    regexpr("body \\.form-check-input \\{[^}]*\\}", css, perl = TRUE)
  )
  expect_length(check_rule, 1L)
  expect_match(check_rule, "width: 1rem;", fixed = TRUE)
  expect_match(check_rule, "height: 1rem;", fixed = TRUE)
  expect_match(check_rule, "border-radius: var(--rcmdr-radius-xs);", fixed = TRUE)
  expect_match(css, 'body .form-check-input[type="radio"]', fixed = TRUE)
  expect_match(css, "border-radius: var(--rcmdr-radius-pill);", fixed = TRUE)
  expect_match(css, "body .form-check-input:disabled", fixed = TRUE)
  expect_match(css, "body .form-check-input.is-invalid:checked", fixed = TRUE)
  # Still the primary pair, never a light accent with a white glyph.
  checked <- regmatches(
    css,
    regexpr("body \\.form-check-input:checked,[^}]*\\}", css, perl = TRUE)
  )
  expect_match(checked, "var(--rcmdr-primary)", fixed = TRUE)
})

test_that("picker_input() keeps the id and the values of the choice", {
  html <- as.character(picker_input(
    "pick", "Pick", c("Alpha" = "a", "Beta" = "b"),
    selected = "b", multiple = FALSE
  ))
  expect_match(html, 'id="pick"', fixed = TRUE)
  expect_match(html, 'class="virtual-select"', fixed = TRUE)
  # The configuration is the widget contract: search on, first option not
  # auto-selected (so an explicit empty choice survives).
  config <- regmatches(html, regexpr('"config":\\{[^}]*\\}', html, perl = TRUE))
  expect_match(config, '"search":true', fixed = TRUE)
  expect_match(config, '"autoSelectFirstOption":false', fixed = TRUE)
  expect_match(config, '"selectedValue":"b"', fixed = TRUE)
  expect_match(config, '"multiple":false', fixed = TRUE)
})

test_that("picker_input() sends a character vector when multiple", {
  html <- as.character(picker_input(
    "pick", "Pick", c("a", "b", "c"), selected = c("a", "c"),
    multiple = TRUE
  ))
  config <- regmatches(html, regexpr('"config":\\{[^}]*\\}', html, perl = TRUE))
  expect_match(config, '"multiple":true', fixed = TRUE)
  expect_match(config, '"selectedValue":["a","c"]', fixed = TRUE)
  expect_match(config, '"showValueAsTags":true', fixed = TRUE)
  expect_match(config, '"disableSelectAll":false', fixed = TRUE)
})

test_that("listbox_input() is a native multiple select with rows", {
  html <- as.character(listbox_input(
    "list", "List", c("mpg", "cyl", "disp"), selected = c("mpg", "disp")
  ))
  expect_match(html, 'id="list"', fixed = TRUE)
  expect_match(html, 'multiple="multiple"', fixed = TRUE)
  expect_match(html, 'size="8"', fixed = TRUE)
  expect_false(grepl("selectize", html, fixed = TRUE))
})

test_that("the list controls explain an empty choice list", {
  html <- as.character(picker_input("pick", "Pick", character()))
  expect_match(html, "No variables available", fixed = TRUE)
  html <- as.character(listbox_input("list", "List", character()))
  expect_match(html, "No variables available", fixed = TRUE)
})

test_that("var_input() picks the control from the length of the list", {
  short <- as.character(var_input(
    "v", "Variables", c("y", "x"), selected = "x", multiple = TRUE
  ))
  expect_match(short, '<select id="v"', fixed = TRUE)
  expect_match(short, 'multiple="multiple"', fixed = TRUE)
  expect_match(short, 'class="shiny-input-select form-control form-select"',
               fixed = TRUE)
  # The value is the variable, not its description.
  expect_match(short, '<option value="x" selected>x</option>', fixed = TRUE)

  long <- as.character(var_input(
    "v", "Variables", letters[1:13], selected = c("a", "c"), multiple = TRUE
  ))
  expect_match(long, 'class="virtual-select"', fixed = TRUE)
  expect_match(long, '"multiple":true', fixed = TRUE)
  expect_match(long, '"selectedValue":["a","c"]', fixed = TRUE)
  expect_equal(var_input_picker_threshold(), 12L)
})

test_that("a single variable selector keeps an empty choice", {
  html <- as.character(var_input(
    "v", "Variable", c("y", "x"), selected = "",
    descriptions = c(y = "numeric", x = "numeric")
  ))
  # Native select, so the field is dressed by Bootstrap and by our tokens.
  expect_match(html, '<select id="v" class="shiny-input-select form-control form-select"',
               fixed = TRUE)
  expect_false(grepl('multiple="multiple"', html, fixed = TRUE))
  # Nothing selected stays a value the dialog can reject.
  expect_match(html, '<option value="" selected>&lt;no variable selected&gt;</option>',
               fixed = TRUE)
  expect_match(html, '<option value="y">y \u2014 numeric</option>', fixed = TRUE)
  expect_match(html, '<option value="x">x \u2014 numeric</option>', fixed = TRUE)

  selected <- as.character(var_input("v", "Variable", c("y", "x"),
                                     selected = "x"))
  expect_match(selected, '<option value="x" selected>x</option>',
               fixed = TRUE)
  # A long single list switches to the searchable picker.
  picker <- as.character(var_input("v", "Variable", letters[1:13],
                                   selected = "b"))
  expect_match(picker, 'class="virtual-select"', fixed = TRUE)
  expect_match(picker, '"multiple":false', fixed = TRUE)
  # An empty single choice is still no choice, not an empty array.
  empty <- as.character(var_input("v", "Variable", letters[1:13],
                                  selected = ""))
  expect_match(empty, '"selectedValue":""', fixed = TRUE)
})

test_that("the native select is the class the listbox CSS expects", {
  html <- as.character(native_select_input(
    "list", "List", c("mpg", "cyl"), selected = "cyl", multiple = TRUE
  ))
  expect_match(html, 'class="shiny-input-select form-control form-select"',
               fixed = TRUE)
  # The rule that turns a multiple select into a desktop listbox now matches
  # the markup Shiny actually emits.
  css <- as.character(app_css())
  expect_match(css, "body select\\[multiple\\]\\.form-select", perl = TRUE)
})

test_that("date_input() and date_range_input() keep a date value", {
  html <- as.character(date_input("d", "Date", value = "2026-11-18"))
  expect_match(html, 'id="d"', fixed = TRUE)
  expect_match(html, "sw-air-picker", fixed = TRUE)
  expect_match(html, '"value":["2026-11-18"]', fixed = TRUE)
  expect_match(html, '"clearButton":true', fixed = TRUE)

  range <- as.character(date_range_input(
    "r", "Range", value = c("2026-11-01", "2026-11-18")
  ))
  expect_match(range, 'id="r"', fixed = TRUE)
  expect_match(range, '"range":true', fixed = TRUE)
  expect_match(range, '"value":["2026-11-01","2026-11-18"]', fixed = TRUE)
  expect_match(range, "Any date", fixed = TRUE)
  expect_equal(date_widget_value(NULL), NULL)
  expect_equal(date_widget_value(c("2026-11-01", "")), "2026-11-01")
})

test_that("a date field without a visible label still has a name", {
  html <- as.character(date_range_input("dates", NULL))
  expect_match(html, "visually-hidden", fixed = TRUE)
  expect_match(html, "Date range", fixed = TRUE)
  one <- as.character(date_input("one_date", NULL))
  expect_match(one, ">Date</span>", fixed = TRUE)
})
