# Script registry and tabs ---------------------------------------------------

test_that("the registry exposes the shared document buffers", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  table <- script_registry(state)
  expect_equal(nrow(table), 1L)
  expect_true(table$active[[1L]])
  expect_equal(table$mode[[1L]], "r")
  expect_equal(table$label[[1L]], table$title[[1L]])
})

test_that("a new script reuses an empty buffer", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  id <- document_id(state)
  script_create(state)
  expect_equal(document_id(state), id)
  expect_equal(document_mode(state), "r")
  expect_equal(document_text(state), "")
})

test_that("a new script creates a second buffer when the first is used", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  first <- document_id(state)
  document_set_text(state, "x <- 1")
  second <- script_create(state, "Analysis")
  expect_false(identical(first, second))
  expect_equal(document_id(state), second)
  expect_equal(document_mode(state), "r")
  expect_equal(document_text(state), "")

  script_activate(state, first)
  expect_equal(document_id(state), first)
  expect_match(document_text(state), "x <- 1")
})

test_that("closing tabs falls back to the remaining document", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  first <- document_id(state)
  document_set_text(state, "x <- 1")
  second <- script_create(state, "Second")
  script_activate(state, first)
  expect_true(script_close(state, second))
  expect_equal(nrow(script_registry(state)), 1L)
  script_close(state, first)
  expect_equal(nrow(script_registry(state)), 0L)
  expect_null(document_id(state))
})

test_that("dirty documents are marked in the tab label", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  document_set_text(state, "changed")
  table <- script_registry(state)
  expect_match(table$label[[1L]], "\\*$")
})

test_that("the tab bar renders the documents", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  document_set_text(state, "x <- 1")
  html <- htmltools::renderTags(script_document_tabs_ui(state))$html
  expect_match(html, "rcmdr-doc-tabs")
  expect_match(html, "script_tab_action")
  expect_match(html, "script_new")
})

test_that("the Script Studio UI keeps the historical editor ids", {
  html <- htmltools::renderTags(script_studio_ui())$html
  expect_match(html, "script_editor_ui")
  expect_match(html, "run_selection")
  expect_match(html, "run_all")
  expect_match(html, "run_chunk")
  expect_match(html, "document_mode")
  expect_match(html, "document_save")
  expect_match(html, "document_knit")
  expect_match(html, "script_find")
  expect_match(html, "script_outline")
  expect_match(html, "script_diagnostics")
})

test_that("the document strip is the shared tab strip", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  document_set_text(state, "x <- 1")
  html <- htmltools::renderTags(script_document_tabs_ui(state))$html
  expect_match(html, "rcmdr-tabs", fixed = TRUE)
  expect_match(html, "rcmdr-tabs-button", fixed = TRUE)
  expect_match(html, "rcmdr-doc-close", fixed = TRUE)
  expect_match(html, "action: &#39;close&#39;", fixed = TRUE)
  expect_match(html, "action: &#39;activate&#39;", fixed = TRUE)
  expect_false(grepl("rcmdr-doc-tab ", html, fixed = TRUE))
})
