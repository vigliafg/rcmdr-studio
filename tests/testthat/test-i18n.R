test_that("language codes are normalized", {
  expect_equal(i18n_normalize("it_IT.UTF-8"), "it")
  expect_equal(i18n_normalize("en_US"), "en")
  expect_equal(i18n_normalize("C"), "en")
  expect_equal(i18n_normalize(NULL), "en")
  expect_equal(i18n_normalize(""), "en")
})

test_that("the PO parser joins lines, skips fuzzy entries and unescapes", {
  path <- tempfile(fileext = ".po")
  writeLines(c(
    "msgid \"\"",
    "msgstr \"\"",
    "\"Content-Type: text/plain; charset=UTF-8\\n\"",
    "",
    "msgid \"Number of clusters:\"",
    "msgstr \"Numero di cluster:\"",
    "",
    "#, fuzzy",
    "msgid \"Fuzzy text\"",
    "msgstr \"Testo incerto\"",
    "",
    "msgid \"A long \"",
    "\"message\"",
    "msgstr \"Un messaggio \"",
    "\"lungo\"",
    "",
    "msgid \"Quoted \\\"value\\\"\"",
    "msgstr \"Valore \\\"virgolettato\\\"\""
  ), path)
  on.exit(unlink(path), add = TRUE)

  catalogue <- i18n_parse_po(path)
  expect_equal(catalogue[["Number of clusters:"]], "Numero di cluster:")
  expect_false("Fuzzy text" %in% names(catalogue))
  expect_equal(catalogue[["A long message"]], "Un messaggio lungo")
  expect_equal(catalogue[["Quoted \"value\""]], "Valore \"virgolettato\"")
})

test_that("the TSV overlay is parsed", {
  path <- tempfile(fileext = ".tsv")
  writeLines(c(
    "msgid\tmsgstr",
    "# comment",
    "Home\tCasa",
    "Data\tDati"
  ), path)
  on.exit(unlink(path), add = TRUE)

  catalogue <- i18n_parse_tsv(path)
  expect_equal(catalogue[["Home"]], "Casa")
  expect_equal(catalogue[["Data"]], "Dati")
})

test_that("tr uses the live catalogue without restarting", {
  old <- getOption("RcmdrShiny.language")
  on.exit(options(RcmdrShiny.language = old), add = TRUE)

  i18n_set_language("it")
  expect_equal(current_language(), "it")
  expect_equal(tr("Home"), "Casa")
  expect_equal(tr("Run a summary"), "Esegui un riassunto")

  i18n_set_language("en")
  expect_equal(current_language(), "en")
  expect_equal(tr("Home"), "Home")
})

test_that("the saved language and theme are restored", {
  state <- AppState(new.env())
  state$options$persist_preferences <- TRUE
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(list(version = 1L, language = "it", theme = "dark"), path)

  expect_true(preferences_load(state, path = path))
  expect_equal(state$options$language, "it")
  expect_equal(state$options$theme, "dark")

  state$options$language <- "it"
  state$options$theme <- "dark"
  state$options$preferences_file <- path
  expect_true(preferences_save(state, path = path))
  saved <- readRDS(path)
  expect_equal(saved$language, "it")
  expect_equal(saved$theme, "dark")
})

test_that("the supported languages include Italian", {
  expect_true("it" %in% available_languages())
  expect_true(i18n_supported("it"))
  expect_true(i18n_supported("en"))
  expect_false(i18n_supported("zz"))
})
