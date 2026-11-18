test_that("Options dialog updates the state and R options", {
  state <- AppState(env = new.env())
  spec <- get_dialog_spec("Options")
  old_digits <- getOption("digits")
  old_width <- getOption("width")
  on.exit(options(digits = old_digits, width = old_width), add = TRUE)

  result <- spec$on_ok(list(
    Options_digits = 5,
    Options_width = 120,
    Options_edit_threshold = 500,
    Options_stringsAsFactors = FALSE
  ), state)

  expect_null(result$error)
  expect_equal(state$options$digits, 5L)
  expect_equal(state$options$width, 120L)
  expect_equal(state$options$edit_threshold, 500)
  expect_false(state$options$stringsAsFactors)
  expect_equal(getOption("digits"), 5)
  expect_equal(getOption("width"), 120)

  invalid <- spec$on_ok(list(
    Options_digits = 50, Options_width = 80,
    Options_edit_threshold = 1000, Options_stringsAsFactors = TRUE
  ), state)
  expect_match(dialog_field_errors(invalid)$digits, "between 1 and 22")
})

test_that("Setwd dialog validates the directory and generates setwd()", {
  state <- AppState(env = new.env())
  spec <- get_dialog_spec("Setwd")

  expect_match(spec$on_ok(list(Setwd_path = "/does/not/exist"), state)$error,
               "Directory not found")

  directory <- tempfile("rcmdr-setwd-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  old <- getwd()
  on.exit(setwd(old), add = TRUE)

  result <- spec$on_ok(list(Setwd_path = directory), state)
  expect_null(result$error)
  expect_match(result$commands, "^setwd\\(")
  expect_true(apply_dialog_result(state, result))
  expect_equal(normalizePath(getwd()), normalizePath(directory))
})

test_that("Load Data Set dialog loads RData and RDS files", {
  state <- AppState(env = new.env())
  spec <- get_dialog_spec("loadDataSet")

  # RData with a data frame
  path <- tempfile(fileext = ".RData")
  saved <- data.frame(y = 1:4)
  save(saved, file = path)
  on.exit(unlink(path), add = TRUE)

  result <- spec$on_ok(list(loadDataSet_path = path, loadDataSet_name = ""), state)
  expect_null(result$error)
  expect_match(result$commands, "^load\\(")
  expect_true(apply_dialog_result(state, result))
  expect_true(exists("saved", envir = state$env, inherits = FALSE))
  expect_equal(active_dataset(state), "saved")

  # RDS with an explicit name
  path_rds <- tempfile(fileext = ".rds")
  saveRDS(data.frame(x = 1:3), path_rds)
  on.exit(unlink(path_rds), add = TRUE)

  result <- spec$on_ok(
    list(loadDataSet_path = path_rds, loadDataSet_name = "MyData"),
    state
  )
  expect_null(result$error)
  expect_equal(result$commands, sprintf('MyData <- readRDS("%s")', path_rds))
  expect_true(apply_dialog_result(state, result))
  expect_equal(active_dataset(state), "MyData")
})

test_that("Load Data Set dialog rejects files without data frames", {
  state <- AppState(env = new.env())
  spec <- get_dialog_spec("loadDataSet")
  path <- tempfile(fileext = ".RData")
  value <- 1:3
  save(value, file = path)
  on.exit(unlink(path), add = TRUE)

  expect_match(
    spec$on_ok(list(loadDataSet_path = path, loadDataSet_name = ""), state)$error,
    "does not contain a data frame"
  )
})

test_that("help topics are rendered as plain text", {
  text <- help_topic_text("lm", package = "stats")
  expect_type(text, "character")
  expect_match(text, "lm")
  expect_null(help_topic_text("this-topic-does-not-exist-12345"))
})

test_that("Open Script File replaces the script contents", {
  state <- AppState(env = new.env())
  observed <- NULL
  state$set_script <- function(value) observed <<- value
  spec <- get_dialog_spec("loadLog")

  path <- tempfile(fileext = ".R")
  writeLines(c("x <- 1", "summary(x)"), path)
  on.exit(unlink(path), add = TRUE)

  result <- spec$on_ok(list(loadLog_path = path), state)
  expect_null(result$error)
  expect_true(apply_dialog_result(state, result))
  expect_equal(observed, "x <- 1\nsummary(x)")
})

test_that("widget library renders the documented widgets", {
  html <- function(x) htmltools::renderTags(x)$html

  expect_match(html(var_input("v", "Variables", c("a", "b"), multiple = TRUE)),
               "v")
  expect_match(html(checkboxes_input("p", c(a = "A", b = "B"), selected = "b")),
               "p_b")
  expect_match(html(model_formula_input("m", c("y", "x"))), "m_rhs")
  expect_match(html(model_formula_input("m", c("y", "x"))), "m_op_plus")
  expect_match(html(file_input("f", "File")), "f_browse")
  expect_match(html(dir_input("d", "Directory")), "d_browse")
  expect_match(html(slider_input("s", "Slider", 1, 10, 5)), "s")
})

test_that("update_dataset replaces the active data set", {
  env <- new.env()
  env$Dataset <- data.frame(x = 1:3)
  state <- AppState(env = env)
  active_dataset(state, "Dataset")

  expect_true(editable_dataset(state))
  update_dataset(state, data.frame(x = 4:6))
  expect_equal(env$Dataset$x, 4:6)
})

test_that("the editing threshold disables the editor", {
  env <- new.env()
  env$Dataset <- data.frame(matrix(1:100, nrow = 10))
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  state$options$edit_threshold <- 50

  expect_false(editable_dataset(state))
})

test_that("plot history copies plots to the session directory and exports PDF", {
  state <- AppState(env = new.env())
  state$plot_dir <- tempfile("rcmdr-plots-")
  dir.create(state$plot_dir)
  state$plot_prefix <- "test-plots"
  on.exit(unlink(state$plot_dir, recursive = TRUE), add = TRUE)

  run_command(state, "plot(1:10)")
  expect_equal(length(state$plots), 1L)
  plot <- state$plots[[1L]]
  expect_equal(plot$url, "test-plots/plot-0001.png")
  expect_true(file.exists(file.path(state$plot_dir, "plot-0001.png")))

  pdf_file <- tempfile(fileext = ".pdf")
  on.exit(unlink(pdf_file), add = TRUE)
  grDevices::pdf(pdf_file)
  grDevices::replayPlot(plot$recorded)
  grDevices::dev.off()
  expect_gt(file.info(pdf_file)$size, 100)
})

test_that("rgl commands populate the 3D widget", {
  skip_if_not_installed("rgl")
  state <- AppState(env = new.env())
  result <- run_command(state, "rgl::plot3d(1:10, 1:10, 1:10)")

  expect_equal(result$status, "ok")
  expect_false(is.null(state$rgl_widget))
})

test_that("the Options dialog dresses its controls without changing their values", {
  spec <- get_dialog_spec("Options")
  html <- htmltools::renderTags(spec$ui(AppState(env = new.env()), NULL))$html

  # Interface mode and density are two-choice questions: segmented controls.
  expect_equal(lengths(regmatches(html, gregexpr("rcmdr-segmented", html))), 2L)
  expect_match(html, 'name="Options_ui_mode"', fixed = TRUE)
  expect_match(html, 'name="Options_density"', fixed = TRUE)
  expect_match(html, 'value="classic"', fixed = TRUE)
  expect_match(html, 'value="comfortable"', fixed = TRUE)

  # The three preferences are switches; the numbers are number fields.
  expect_equal(lengths(regmatches(html, gregexpr("rcmdr-switch", html))), 3L)
  for (id in c("Options_stringsAsFactors", "Options_use_markdown",
               "Options_use_knitr")) {
    expect_match(html, paste0('id="', id, '"'), fixed = TRUE)
  }
  expect_match(html, 'id="Options_digits"', fixed = TRUE)
  expect_match(html, 'type="number"', fixed = TRUE)
  expect_false(grepl("rcmdr-switch\"[^>]*id=\"Options_digits", html))
})
