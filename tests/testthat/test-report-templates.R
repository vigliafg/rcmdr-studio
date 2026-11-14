# Report templates -----------------------------------------------------------

test_that("the template catalogue is complete and labelled", {
  templates <- report_templates()
  expect_equal(sort(names(templates)),
               sort(c("analysis", "profile", "diagnostics", "teaching",
                      "survival")))
  for (template in templates) {
    expect_true(nzchar(template$title))
    expect_true(nzchar(template$description))
    expect_true(template$mode %in% c("rmd", "rnw"))
    expect_true(is.function(template$build))
  }
  expect_equal(unname(report_template_choices()), report_template_ids())
})

test_that("every template produces valid R Markdown", {
  for (id in report_template_ids()) {
    text <- report_template_text(id, "D", "A report")
    expect_equal(text[[1L]], "---")
    expect_true(any(grepl("^title: \"A report\"$", text)))
    expect_true(any(trimws(text) == "---"))
    expect_match(paste(text, collapse = "\n"), "## ")
    expect_false(grepl("{{dataset}}", paste(text, collapse = "\n"),
                       fixed = TRUE))
  }
})

test_that("the dataset placeholder is replaced safely", {
  text <- report_template_text("analysis", "D", "Report")
  expect_match(paste(text, collapse = "\n"), "summary\\(D\\)")
  fallback <- report_template_text("analysis", "", "Report")
  expect_match(paste(fallback, collapse = "\n"), "summary\\(Dataset\\)")
})

test_that("applying a template creates an active document", {
  state <- report_test_state()
  report_template_apply(state, "profile", "D", "Profile")
  expect_equal(document_mode(state), "rmd")
  expect_equal(document_title(state), "Profile")
  expect_true(document_dirty(state))
  expect_match(document_text(state), "## Structure")
  expect_match(document_text(state), "summary\\(D\\)")
  expect_equal(nrow(document_list(state)), 1L)
})

test_that("an unknown template is refused", {
  state <- report_test_state()
  expect_error(report_template_apply(state, "unknown", "D"), "Unknown template")
})

test_that("the template gallery renders cards", {
  html <- htmltools::renderTags(report_template_gallery_ui())$html
  expect_match(html, "rcmdr-template-card")
  expect_match(html, "report_template_action")
  expect_match(html, "Analysis report")
})
