# Interface density -----------------------------------------------------------

test_that("the density preference defaults to compact and is validated", {
  state <- AppState(env = new.env())
  expect_equal(ui_density(state), "compact")
  expect_equal(ui_densities(), c("compact", "comfortable"))

  state$options$density <- "comfortable"
  expect_equal(ui_density(state), "comfortable")

  state$options$density <- "enormous"
  expect_equal(ui_density(state), "compact")

  expect_equal(set_ui_density(state, "comfortable"), "comfortable")
  expect_equal(state$options$density, "comfortable")
  expect_equal(set_ui_density(state, "nope"), "compact")
})

test_that("the density is persisted with the other preferences", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  state <- AppState(env = new.env())
  state$options$density <- "comfortable"
  preferences_save(state, path)

  restored <- AppState(env = new.env())
  preferences_load(restored, path)
  expect_equal(restored$options$density, "comfortable")
})

test_that("the density tokens exist for both variants", {
  css <- as.character(app_css())
  expect_match(css, "--rcmdr-field-gap", fixed = TRUE)
  expect_match(css, "body.rcmdr-density-comfortable", fixed = TRUE)
  expect_match(css, "--rcmdr-control-min", fixed = TRUE)
  # Compact is the base: no class is needed for the default look.
  expect_match(css, "body .form-group,\n    body .shiny-input-container", fixed = TRUE)
})

test_that("dialog bodies are laid out in a field grid", {
  css <- as.character(app_css())
  expect_match(css, ".rcmdr-dialog-grid", fixed = TRUE)
  expect_match(css, "grid-column: 1 / -1", fixed = TRUE)

  env <- new.env()
  shiny::testServer(app_server(env), {
    session$setInputs(menu_search = "")
    state$current_dialog <- "Options"
    # The output caches the initial "no dialog" evaluation; invalidate it the
    # way the server does when a dialog opens.
    dialog_revision(dialog_revision() + 1L)
    session$flushReact()
    html <- htmltools::renderTags(output$dialog_body)$html
    expect_match(html, "rcmdr-dialog-grid", fixed = TRUE)
    expect_match(html, "rcmdr-field-grid", fixed = TRUE)
  })
})

test_that("the options dialog offers the density switch", {
  spec <- get_dialog_spec("Options")
  expect_true(!is.null(spec))
  html <- htmltools::renderTags(spec$ui(AppState(env = new.env()), NULL))$html
  expect_match(html, "Options_density", fixed = TRUE)
  expect_match(html, "Compact")
  expect_match(html, "Comfortable")
})

test_that("the options dialog applies and sends the density", {
  state <- AppState(env = new.env())
  sent <- list()
  state$session <- list(
    sendCustomMessage = function(type, message) {
      sent[[type]] <<- message
      invisible(NULL)
    }
  )
  persisted <- FALSE
  state$persist_preferences <- function() {
    persisted <<- TRUE
    invisible(NULL)
  }
  spec <- get_dialog_spec("Options")
  result <- spec$on_ok(
    list(Options_density = "comfortable", Options_digits = 7,
         Options_width = 80, Options_edit_threshold = 10000),
    state
  )
  expect_null(result$error)
  expect_equal(state$options$density, "comfortable")
  expect_equal(result$memory$density, "comfortable")
  expect_equal(sent[["rcmdr-theme"]]$density, "comfortable")
  expect_true(persisted)
})
