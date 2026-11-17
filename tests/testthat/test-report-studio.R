# Report Studio UI and server ------------------------------------------------

test_that("the Report Studio UI exposes the workspace", {
  html <- htmltools::renderTags(report_studio_ui())$html
  expect_match(html, "rcmdr-report-toolbar")
  expect_match(html, "report_document_ui")
  expect_match(html, "report_new")
  expect_match(html, "report_template")
  expect_match(html, "report_save")
  expect_match(html, "report_yaml")
  expect_match(html, "report_knit")
  expect_match(html, "report_outline")
  expect_match(html, "report_chunks")
  expect_match(html, "report_editor_ui")
  expect_match(html, "report_preview")
  expect_match(html, "report_template_action")
  expect_match(html, "report_download_knit")
})

test_that("the cell card renders status, output and actions", {
  chunk <- data.frame(
    id = "chunk-summary", label = "summary", engine = "r",
    start = 8L, end = 10L, code = "summary(D)", header = "```{r summary}",
    stringsAsFactors = FALSE
  )
  output <- list(status = "ok", output = c("Min. 1", "Max. 6"),
                 messages = character(), warnings = character(),
                 error = NULL, plot_url = NULL)
  html <- htmltools::renderTags(report_cell_card(chunk, output))$html
  expect_match(html, "chunk-summary")
  expect_match(html, "summary")
  expect_match(html, "Run")
  expect_match(html, "Run to here")
  expect_match(html, "Min. 1")

  empty <- htmltools::renderTags(report_cell_card(chunk, NULL))$html
  expect_match(empty, "not run")
})

test_that("document choices mark dirty documents", {
  state <- report_test_state()
  document_create(state, "rmd", "One", text = "a")
  document_set_text(state, "b")
  choices <- report_document_choices(state)
  expect_equal(length(choices), 1L)
  expect_match(names(choices)[[1L]], "\\*$")
})

test_that("history and plot choices are readable", {
  state <- report_test_state()
  run_command(state, "summary(D)")
  expect_equal(length(report_history_choices(state)), 1L)
  expect_match(names(report_history_choices(state))[[1L]], "summary")
  expect_equal(unname(report_history_choices(state)),
               state$history[[1L]]$id)

  expect_equal(unname(report_plot_choices(state)), "")
  expect_equal(names(report_plot_choices(state)), "<none>")
  report_fake_plot(state)
  expect_equal(length(report_plot_choices(state)), 1L)
})

test_that("the Report Studio server drives templates, cells and preview", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:6, x = c(2, 4, 6, 8, 10, 12),
                      g = factor(rep(c("a", "b"), 3)))

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(menu_search = "", main_tabs = "report",
                      report_preview_mode = "markdown")
    session$flushReact()

    documents <- htmltools::renderTags(output$report_document_ui)$html
    expect_match(documents, "document-")
    editor <- htmltools::renderTags(output$report_editor_ui)$html
    expect_match(editor, "report_editor")

    session$setInputs(report_template_action = "analysis")
    session$flushReact()
    expect_equal(document_mode(state), "rmd")
    expect_match(document_text(state), "## Context")
    expect_gt(nrow(document_chunks(document_text(state), "rmd")), 0L)

    session$setInputs(report_preview_mode = "markdown")
    preview <- htmltools::renderTags(output$report_preview)$html
    expect_match(preview, "Context")
    expect_match(preview, "rcmdr-report-chunk")

    chunks <- document_chunks(document_text(state), "rmd")
    session$setInputs(report_chunk_action = list(id = chunks$id[[1L]],
                                                 action = "run"))
    session$flushReact()
    expect_equal(state$cell_outputs[[chunks$id[[1L]]]]$status, "ok")

    history <- htmltools::renderTags(output$report_knit_history)$html
    expect_match(history, "No knit yet")
  })
})

test_that("the Report Studio knits and exposes the HTML preview", {
  skip_if_not_installed("shiny")
  skip_if_not(document_format_available("html", "rmd"),
              "Pandoc or rmarkdown not available")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:6, x = c(2, 4, 6, 8, 10, 12))

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(menu_search = "", main_tabs = "report",
                      report_preview_mode = "markdown")
    session$flushReact()
    session$setInputs(report_template_action = "analysis")
    session$flushReact()

    session$setInputs(report_knit_format = "html", report_knit = 1)
    session$flushReact()
    expect_false(is.null(state$knit_result))
    expect_equal(length(state$knit_history), 1L)

    session$setInputs(report_preview_mode = "html")
    preview <- htmltools::renderTags(output$report_preview)$html
    expect_match(preview, "<iframe")
  })
})
