# Document registry ----------------------------------------------------------

test_that("the legacy buffer becomes the first registry document", {
  state <- report_test_state()
  document_registry_ensure(state)
  table <- document_list(state)
  expect_equal(nrow(table), 1L)
  expect_true(table$active[[1L]])
  expect_equal(table$mode[[1L]], "r")
  expect_equal(document_id(state), table$id[[1L]])
  expect_false(document_dirty(state))
})

test_that("documents can be created, activated and closed", {
  state <- report_test_state()
  document_registry_ensure(state)
  first <- document_id(state)

  second <- document_create(state, "rmd", "Second", text = "## A\n\ntext")
  expect_equal(document_id(state), second)
  expect_equal(document_title(state), "Second")
  expect_equal(nrow(document_list(state)), 2L)

  document_activate(state, first)
  expect_equal(document_id(state), first)
  expect_equal(document_mode(state), "r")

  expect_true(document_close(state, second))
  expect_equal(nrow(document_list(state)), 1L)
  expect_equal(document_id(state), first)

  expect_true(document_close(state, first))
  expect_equal(nrow(document_list(state)), 0L)
  expect_null(document_id(state))
  expect_equal(document_mode(state), "r")
})

test_that("text, path and mode stay in sync with the active document", {
  state <- report_test_state()
  id <- document_create(state, "rmd", "Sync", text = "one")
  document_set_text(state, "two")
  expect_equal(document_text(state), "two")
  expect_equal(state$documents[[id]]$text, "two")

  document_set_mode(state, "rnw")
  expect_equal(state$documents[[id]]$mode, "rnw")
  expect_equal(document_mode(state), "rnw")

  document_set_path(state, "/tmp/report.Rmd")
  expect_equal(state$documents[[id]]$path, "/tmp/report.Rmd")
  expect_equal(document_path(state), "/tmp/report.Rmd")
})

test_that("new documents reuse an empty buffer", {
  state <- report_test_state()
  document_registry_ensure(state)
  id <- document_id(state)
  document_new(state, "rmd", "Fresh")
  expect_equal(document_id(state), id)
  expect_equal(document_mode(state), "rmd")
  expect_match(document_text(state), "^---")
})

test_that("opening a file creates a document", {
  state <- report_test_state()
  path <- tempfile(fileext = ".Rmd")
  writeLines(c("---", "title: Open", "---", "", "## Section"), path)
  document_open(state, path)
  expect_equal(document_mode(state), "rmd")
  expect_equal(document_path(state), path)
  expect_equal(document_title(state), basename(path))
  expect_match(document_text(state), "## Section")
  expect_equal(nrow(document_list(state)), 1L)
})

test_that("dirty state follows edits and saves", {
  state <- report_test_state()
  document_create(state, "rmd", "Dirty", text = "a")
  expect_false(document_dirty(state))
  document_set_text(state, "b")
  expect_true(document_dirty(state))
  document_mark_clean(state)
  expect_false(document_dirty(state))
})
