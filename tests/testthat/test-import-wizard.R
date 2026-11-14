test_that("delimiters are detected from the first line", {
  comma <- tempfile(fileext = ".csv")
  writeLines(c("a,b,c", "1,2,3"), comma)
  expect_equal(detect_delimiter(comma), ",")

  semicolon <- tempfile(fileext = ".csv")
  writeLines(c("a;b;c", "1;2;3"), semicolon)
  expect_equal(detect_delimiter(semicolon), ";")

  tab <- tempfile(fileext = ".tsv")
  writeLines(c("a\tb\tc", "1\t2\t3"), tab)
  expect_equal(detect_delimiter(tab), "\t")

  plain <- tempfile(fileext = ".txt")
  writeLines(c("a b c", "1 2 3"), plain)
  expect_equal(detect_delimiter(plain), ",")
})

test_that("column types are proposed conservatively", {
  df <- data.frame(
    integer = c("1", "2", "3"),
    numeric = c("1.5", "2.5", "3.5"),
    logical = c("TRUE", "FALSE", "TRUE"),
    date = c("2024-01-01", "2024-02-01", "2024-03-01"),
    text = c("a", "b", "c"),
    empty = c(NA, NA, NA),
    stringsAsFactors = FALSE
  )
  types <- suggest_column_types(df)
  expect_equal(unname(types), c("integer", "numeric", "logical", "date",
                                "character", "empty"))
})

test_that("CSV files are previewed without changing the environment", {
  path <- tempfile(fileext = ".csv")
  writeLines(c("a;b;c", "1;x;TRUE", "2;y;FALSE", "3;x;TRUE"), path)
  state <- AppState(env = new.env())

  preview <- preview_import_file(path, delimiter = ";", header = TRUE)
  expect_true(preview$ok)
  expect_equal(nrow(preview$data), 3L)
  expect_equal(names(preview$data), c("a", "b", "c"))
  expect_equal(preview$types[["a"]], "integer")
  expect_equal(length(ls(state$env)), 0L)

  missing <- preview_import_file(tempfile())
  expect_false(missing$ok)
})

test_that("the import wizard creates a reproducible read command", {
  path <- tempfile(fileext = ".csv")
  writeLines(c("a;b", "1;x", "2;y"), path)
  state <- AppState(env = new.env())

  spec <- get_dialog_spec("dataImportWizard")
  expect_false(is.null(spec))
  expect_false(isTRUE(spec$preview))

  input <- list(
    dataImportWizard_upload = list(datapath = path, name = "wizard.csv"),
    dataImportWizard_dsname = "WizardData",
    dataImportWizard_header = TRUE,
    dataImportWizard_delimiter = "semicolons",
    dataImportWizard_stringsAsFactors = FALSE
  )
  result <- spec$on_ok(input, state)
  expect_match(result$commands, "WizardData <- read.table\\(")
  expect_match(result$commands, 'sep=";"')
  expect_equal(result$activate_dataset, "WizardData")

  expect_equal(run_command(state, result$commands)$status, "ok")
  expect_equal(nrow(state$env$WizardData), 2L)
})

test_that("the import wizard validates its fields", {
  state <- AppState(env = new.env())
  spec <- get_dialog_spec("dataImportWizard")

  no_file <- spec$on_ok(list(dataImportWizard_dsname = "D"), state)
  expect_match(no_file$error, "choose a file")

  path <- tempfile(fileext = ".csv")
  writeLines(c("a", "1"), path)
  bad_name <- spec$on_ok(list(
    dataImportWizard_upload = list(datapath = path, name = "x.csv"),
    dataImportWizard_dsname = "1 bad name"
  ), state)
  expect_match(bad_name$error, "not a valid name")
})
