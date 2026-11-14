# YAML front matter ----------------------------------------------------------

test_that("front matter is parsed and located", {
  text <- c("---", 'title: "T"', "author: A", "toc: true", "---", "",
            "Body")
  front <- document_front_matter(paste(text, collapse = "\n"))
  expect_equal(front$values$title, "T")
  expect_equal(front$values$author, "A")
  expect_true(front$values$toc)
  expect_equal(front$bounds, c(1L, 5L))

  none <- document_front_matter("No front matter")
  expect_null(none$bounds)
  expect_equal(none$values, list())
})

test_that("setting fields preserves unknown fields", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Meta",
    text = c("---", 'title: "Old"', "custom: keep-me", "---", "", "Body")
  )
  document_set_front_matter(state, list(title = "New", toc = TRUE))
  values <- document_front_matter_values(state)
  expect_equal(values$title, "New")
  expect_equal(values$custom, "keep-me")
  expect_true(values$toc)
  expect_match(document_text(state), "custom: keep-me")
})

test_that("NULL removes a field", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Meta",
    text = c("---", 'title: "T"', "bibliography: refs.bib", "---", "", "Body")
  )
  document_set_front_matter(state, list(bibliography = NULL))
  expect_null(document_front_matter_values(state)$bibliography)
  expect_false(grepl("bibliography", document_text(state)))
})

test_that("a missing front matter is created", {
  state <- report_test_state()
  document_create(state, "rmd", "No header", text = "Body only")
  document_set_front_matter(state, list(title = "Added", author = "Ada"))
  text <- document_text(state)
  expect_match(text, "^---\\n")
  expect_match(text, 'title: Added')
  expect_match(text, "Body only")
})

test_that("YAML values round-trip through the form", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Round",
    text = c("---", 'title: "Round"', "output: html_document", "---", "", "Body")
  )
  spec <- report_yaml_dialog()
  result <- spec$on_ok(list(
    reportYaml_title = "Round trip",
    reportYaml_author = "Ada",
    reportYaml_date = "2026-11-14",
    reportYaml_output = "pdf_document",
    reportYaml_toc = TRUE,
    reportYaml_theme = "cosmo",
    reportYaml_bibliography = "",
    reportYaml_link_citations = TRUE
  ), state)
  expect_null(result$error)
  values <- document_front_matter_values(state)
  expect_equal(values$title, "Round trip")
  expect_equal(values$author, "Ada")
  expect_equal(values$output, "pdf_document")
  expect_true(values$toc)
  expect_equal(values$theme, "cosmo")
  expect_true(values[["link-citations"]])
})

test_that("the YAML dialog validates title and bibliography", {
  state <- report_test_state()
  document_create(state, "rmd", "Meta", text = "Body")
  spec <- report_yaml_dialog()
  result <- spec$on_ok(list(reportYaml_title = ""), state)
  expect_match(result$error, "title")

  result <- spec$on_ok(list(
    reportYaml_title = "T",
    reportYaml_bibliography = tempfile()
  ), state)
  expect_match(result$error, "not found")
})

test_that("the bibliography dialog still uses the quoted form", {
  state <- report_test_state()
  document_create(state, "rmd", "Bib", text = "Body")
  document_set_bibliography(state, "first.bib")
  expect_match(document_text(state), 'bibliography: "first.bib"')
  document_set_bibliography(state, "second.bib")
  expect_equal(length(grep("^bibliography:", document_lines(document_text(state)))),
               1L)
})
