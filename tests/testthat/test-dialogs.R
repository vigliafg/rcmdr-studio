summary_input <- function(...) {
  defaults <- list(
    numericalSummaries_x = "y",
    numericalSummaries_groups = "",
    numericalSummaries_mean = TRUE,
    numericalSummaries_sd = TRUE,
    numericalSummaries_se.mean = FALSE,
    numericalSummaries_var = FALSE,
    numericalSummaries_IQR = FALSE,
    numericalSummaries_cv = FALSE,
    numericalSummaries_counts = FALSE,
    numericalSummaries_skewness = FALSE,
    numericalSummaries_kurtosis = FALSE,
    numericalSummaries_quantiles = FALSE,
    numericalSummaries_quantiles_values = "0, .25, .5, .75, 1",
    numericalSummaries_type = "2"
  )
  modifyList(defaults, list(...))
}

model_input <- function(...) {
  defaults <- list(
    linearModel_model = "LinearModel.1",
    linearModel_lhs = "y",
    linearModel_rhs = "x",
    linearModel_subset = "",
    linearModel_weights = "",
    linearModel_remove = ""
  )
  modifyList(defaults, list(...))
}

import_input <- function(...) {
  defaults <- list(
    readDataSet_dsname = "Dataset",
    readDataSet_location = "local",
    readDataSet_path = "",
    readDataSet_url = "",
    readDataSet_header = TRUE,
    readDataSet_stringsAsFactors = TRUE,
    readDataSet_delimiter = "commas",
    readDataSet_other = "",
    readDataSet_missing = "NA",
    readDataSet_decimal = "period"
  )
  modifyList(defaults, list(...))
}

test_that("dialog UI builders render without a Shiny session", {
  env <- new.env()
  env$Dataset <- data.frame(y = 1:5, x = 1:5, g = factor(c("a", "b", "a", "b", "a")))
  state <- AppState(env = env)
  active_dataset(state, "Dataset")

  for (id in c("readDataSet", "numericalSummaries", "linearModel")) {
    spec <- get_dialog_spec(id)
    expect_equal(spec$id, id)
    ui <- spec$ui(state, NULL)
    rendered <- htmltools::renderTags(ui)
    expect_gt(nchar(rendered$html), 100)
  }
})

test_that("import dialog validates the data set name and source", {
  env <- new.env()
  state <- AppState(env = env)
  spec <- get_dialog_spec("readDataSet")

  expect_match(spec$on_ok(import_input(readDataSet_dsname = ""), state)$error,
               "name for the data set")
  expect_match(spec$on_ok(import_input(readDataSet_dsname = "my data"), state)$error,
               "not a valid name")
  expect_match(spec$on_ok(import_input(readDataSet_path = "/does/not/exist.csv"), state)$error,
               "File not found")
  expect_match(spec$on_ok(import_input(readDataSet_location = "url", readDataSet_url = ""), state)$error,
               "URL")

  env$Dataset <- data.frame(x = 1)
  expect_match(spec$on_ok(import_input(), state)$error, "already exists")
})

test_that("import dialog returns the read.table command and memory", {
  env <- new.env()
  state <- AppState(env = env)
  spec <- get_dialog_spec("readDataSet")
  csv <- tempfile(fileext = ".csv")
  writeLines(c("y,x", "1,2"), csv)
  on.exit(unlink(csv), add = TRUE)

  result <- spec$on_ok(import_input(readDataSet_path = csv), state)
  expect_null(result$error)
  expect_equal(result$activate_dataset, "Dataset")
  expect_match(result$commands, "^Dataset <- read\\.table\\(")
  expect_equal(result$memory$path, csv)
})

test_that("import dialog import works through the runtime", {
  env <- new.env()
  state <- AppState(env = env)
  spec <- get_dialog_spec("readDataSet")
  csv <- tempfile(fileext = ".csv")
  writeLines(c("y,x", "1,2", "3,4"), csv)
  on.exit(unlink(csv), add = TRUE)

  result <- spec$on_ok(import_input(readDataSet_path = csv), state)
  expect_true(apply_dialog_result(state, result))
  expect_equal(active_dataset(state), "Dataset")
  expect_equal(nrow(env$Dataset), 2L)
})

test_that("numerical summaries dialog validates its input", {
  env <- new.env()
  env$Dataset <- data.frame(y = 1:5, x = 1:5)
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  spec <- get_dialog_spec("numericalSummaries")

  expect_match(
    spec$on_ok(summary_input(numericalSummaries_x = character(0)), state)$error,
    "select a variable"
  )
  expect_match(
    spec$on_ok(summary_input(
      numericalSummaries_mean = FALSE, numericalSummaries_sd = FALSE,
      numericalSummaries_IQR = FALSE, numericalSummaries_quantiles = FALSE
    ), state)$error,
    "No statistics selected"
  )
})

test_that("numerical summaries dialog generates Rcmdr commands", {
  env <- new.env()
  env$Dataset <- data.frame(y = 1:5, x = 2 * (1:5))
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  spec <- get_dialog_spec("numericalSummaries")

  result <- spec$on_ok(summary_input(numericalSummaries_x = c("y", "x")), state)
  expect_null(result$error)
  expect_equal(
    result$commands,
    paste0(
      'numSummary(Dataset[,c("y", "x"), drop=FALSE], ',
      'statistics=c("mean", "sd"), quantiles=c(0,.25,.5,.75,1))'
    )
  )
  expect_equal(result$memory$x, c("y", "x"))
})

test_that("numerical summaries dialog supports groups", {
  env <- new.env()
  env$Dataset <- data.frame(
    y = 1:6,
    g = factor(rep(c("a", "b"), each = 3))
  )
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  spec <- get_dialog_spec("numericalSummaries")

  result <- spec$on_ok(summary_input(
    numericalSummaries_x = "y",
    numericalSummaries_groups = "g"
  ), state)
  expect_match(result$commands, "groups=Dataset\\$g")
})

test_that("linear model dialog validates and generates commands", {
  env <- new.env()
  env$Dataset <- data.frame(y = 1:5, x = 1:5, w = rep(1, 5))
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  spec <- get_dialog_spec("linearModel")

  expect_match(spec$on_ok(model_input(linearModel_model = "1bad"), state)$error,
               "not a valid name")
  expect_match(spec$on_ok(model_input(linearModel_lhs = ""), state)$error,
               "Left-hand side")
  expect_match(spec$on_ok(model_input(linearModel_rhs = ""), state)$error,
               "Right-hand side")
  expect_match(spec$on_ok(model_input(
    linearModel_subset = "x > 2", linearModel_remove = "1"
  ), state)$error, "both case removal and subset")

  result <- spec$on_ok(model_input(
    linearModel_model = "M", linearModel_rhs = "x + w",
    linearModel_weights = "w"
  ), state)
  expect_null(result$error)
  expect_equal(result$commands, c(
    "M <- lm(y ~ x + w, data=Dataset, weights=w)",
    "summary(M)"
  ))
  expect_equal(result$activate_model, "M")
})

test_that("linear model dialog validates row removal", {
  env <- new.env()
  env$Dataset <- data.frame(y = 1:3, x = 1:3)
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  spec <- get_dialog_spec("linearModel")

  expect_match(spec$on_ok(model_input(linearModel_remove = "99"), state)$error,
               "bad row numbers")
  result <- spec$on_ok(model_input(linearModel_remove = "2"), state)
  expect_match(result$commands[[1]], "subset =-c\\(2\\)")
})

# Dialog chrome --------------------------------------------------------------

test_that("a dialog takes the icon of the menu branch it lives in", {
  make <- function(id, icon = NULL) {
    dialog_spec(id = id, title = id,
                ui = function(state, memory) NULL,
                on_ok = function(input, state) list(),
                icon = icon)
  }
  expect_equal(dialog_icon_name(make("readDataSet")), "table")
  expect_equal(dialog_icon_name(make("numericalSummaries")), "output")
  expect_equal(dialog_icon_name(make("Scatter3D")), "chart")
  expect_equal(dialog_icon_name(make("projectNew")), "doc")
  expect_equal(dialog_icon_name(make("onCut")), "code")
  expect_equal(dialog_icon_name(make("Options")), "sliders")
  expect_equal(dialog_icon_name(make("helpCenter")), "help")
  # A dialog that is not in the menu, or names its own icon, still renders.
  expect_equal(dialog_icon_name(make("not-a-dialog")), "sliders")
  expect_equal(dialog_icon_name(make("readDataSet", icon = "search")), "search")
})

test_that("the dialog header is a titled, labelled modal header", {
  spec <- dialog_spec(
    id = "numericalSummaries", title = "Numerical summaries",
    ui = function(state, memory) NULL,
    on_ok = function(input, state) list()
  )
  html <- as.character(dialog_modal(spec))
  expect_match(html, 'class="modal-header rcmdr-modal-header"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-dialog-icon"', fixed = TRUE)
  expect_match(html, "<svg", fixed = TRUE)
  expect_match(
    html,
    '<h4 class="modal-title" id="rcmdr-dialog-title">Numerical summaries</h4>',
    fixed = TRUE
  )
  # The modal points at the title, so it has an accessible name.
  expect_match(html, 'aria-labelledby="rcmdr-dialog-title"', fixed = TRUE)
  # Still one `.modal-content`, and the body keeps its scroll area.
  expect_equal(lengths(regmatches(html, gregexpr("modal-content", html))), 1L)
  expect_match(html, 'class="modal-body"', fixed = TRUE)
})

test_that("the dialog footer keeps its six actions and the tab order", {
  spec <- get_dialog_spec("numericalSummaries")
  html <- as.character(dialog_modal(spec))
  ids <- c(
    "dialog_help", "dialog_insert_script", "dialog_reset",
    "dialog_cancel", "dialog_apply", "dialog_ok"
  )
  at <- vapply(ids, function(id) {
    regexpr(paste0('id="', id, '"'), html, fixed = TRUE)[[1L]]
  }, 0L)
  expect_true(all(at > 0L))
  expect_equal(order(at), seq_along(ids), info = "footer order")
  expect_match(html, 'class="modal-footer rcmdr-modal-footer"', fixed = TRUE)
  # The decision sits in its own group at the right end.
  expect_gt(
    regexpr('class="rcmdr-modal-primary"', html, fixed = TRUE)[[1L]],
    at[["dialog_reset"]]
  )
})

test_that("the dialog stays modal: no backdrop dismiss and no Esc", {
  spec <- get_dialog_spec("numericalSummaries")
  html <- as.character(dialog_modal(spec))
  expect_match(html, 'data-bs-backdrop="static"', fixed = TRUE)
  expect_match(html, 'data-bs-keyboard="false"', fixed = TRUE)
  # No X: it would bypass the Cancel handler that clears the dialog state.
  expect_false(grepl("btn-close", html, fixed = TRUE))
  # The Shiny bootstrapping script survives the chrome rewrite.
  expect_match(html, "new bootstrap.Modal", fixed = TRUE)
})
