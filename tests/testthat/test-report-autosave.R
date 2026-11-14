# Autosave and recovery ------------------------------------------------------

test_that("autosave writes only dirty documents", {
  state <- report_test_state()
  document_create(state, "rmd", "Auto", text = "one")
  expect_false(document_autosave(state))
  expect_equal(length(list.files(state$autosave_dir)), 0L)

  document_set_text(state, "two")
  expect_true(document_autosave(state))
  files <- list.files(state$autosave_dir, full.names = TRUE)
  expect_equal(length(files), 1L)
  expect_match(paste(readLines(files, warn = FALSE), collapse = "\n"), "two")
  expect_false(is.null(state$autosave_time))
})

test_that("recoveries are listed and can be loaded", {
  state <- report_test_state()
  document_create(state, "rmd", "Recover me", text = "draft")
  document_set_text(state, "unsaved draft")
  document_autosave(state)

  recoveries <- document_recoveries(state)
  expect_equal(nrow(recoveries), 1L)
  expect_match(recoveries$title[[1L]], "document-")

  document_recover(state, recoveries$path[[1L]])
  expect_equal(document_mode(state), "rmd")
  expect_true(document_dirty(state))
  expect_match(document_text(state), "unsaved draft")
})

test_that("saving creates a backup and removes the autosave file", {
  state <- report_test_state()
  path <- tempfile(fileext = ".Rmd")
  writeLines("old", path)
  document_create(state, "rmd", "Saved", text = "new")
  document_set_text(state, "newer")
  document_autosave(state)
  autosave <- document(state)$autosave_path
  expect_true(file.exists(autosave))

  document_save(state, path)
  expect_true(file.exists(paste0(path, ".bak")))
  expect_false(document_dirty(state))
  expect_false(file.exists(autosave))
  expect_match(paste(readLines(path, warn = FALSE), collapse = "\n"), "newer")
})

test_that("the autosave directory is configurable", {
  state <- report_test_state()
  directory <- tempfile("custom-autosave-")
  dir.create(directory)
  state$autosave_dir <- directory
  document_create(state, "rmd", "Custom", text = "x")
  document_set_text(state, "y")
  document_autosave(state)
  expect_equal(length(list.files(directory)), 1L)
})
