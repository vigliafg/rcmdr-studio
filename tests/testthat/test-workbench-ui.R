# Workbench integration ------------------------------------------------------

test_that("the Workbench server drives Script, Console, Output and Environment", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(
    y = c(2, 1, 4, 3, 7, 6, 9, 8),
    x = c(2, 4, 6, 8, 10, 12, 14, 16),
    g = factor(rep(c("a", "b"), 4))
  )
  env$fit <- stats::lm(y ~ x, data = env$D)

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(
      menu_search = "", main_tabs = "Script", document_mode = "r",
      console_tabs = "Console", environment_tabs = "Objects"
    )
    session$flushReact()

    tabs <- htmltools::renderTags(output$script_tabs_ui)$html
    expect_match(tabs, "rcmdr-doc-tabs")
    expect_match(htmltools::renderTags(output$script_outline)$html,
                 "No headings")
    expect_match(htmltools::renderTags(output$script_diagnostics)$html,
                 "parses correctly")

    # Run a cell from the Script tab.
    session$setInputs(script = "x <- mean(D$y)\nx\n")
    session$flushReact()
    session$setInputs(run_cell_request = list(row = 0, column = 0))
    session$flushReact()
    expect_equal(length(state$script_outputs), 1L)
    expect_equal(state$script_outputs[[1L]]$status, "ok")
    expect_match(htmltools::renderTags(output$script_cell_output)$html,
                 "rcmdr-script-output")

    # Console command.
    session$setInputs(console_input = "mean(D$y)", console_run = 1)
    session$flushReact()
    expect_equal(state$console_last$status, "ok")
    expect_equal(length(state$console_history), 1L)
    expect_match(htmltools::renderTags(output$console_log)$html, "mean")
    expect_match(htmltools::renderTags(output$console_status_ui)$html, "OK")

    # Output cards and filters.
    session$setInputs(
      console_tabs = "Output", output_filter = "mean", output_status = "all",
      output_source = "all"
    )
    session$flushReact()
    expect_match(htmltools::renderTags(output$output_cards)$html,
                 "rcmdr-history-card")
    expect_equal(length(history_filter_entries(
      state$history, "mean", "all", "ok"
    )) >= 1L, TRUE)

    # Messages.
    session$setInputs(
      console_tabs = "Messages", messages_filter = "",
      messages_severity = "all"
    )
    run_command(state, "warning('careful')")
    session$flushReact()
    expect_match(htmltools::renderTags(output$messages_cards)$html, "careful")

    # Environment.
    session$setInputs(main_tabs = "Environment", environment_tabs = "Objects")
    session$flushReact()
    expect_match(htmltools::renderTags(output$environment_objects)$html, "fit")
    session$setInputs(environment_action = list(name = "D", action = "preview"))
    session$flushReact()
    expect_match(htmltools::renderTags(output$environment_preview)$html,
                 "data.frame")

    session$setInputs(environment_tabs = "Data sets")
    session$flushReact()
    expect_match(htmltools::renderTags(output$environment_datasets)$html,
                 "8 x 3")

    # Models.
    session$setInputs(environment_tabs = "Models")
    session$flushReact()
    expect_match(htmltools::renderTags(output$models_dashboard)$html, "fit")
    session$setInputs(model_action = list(name = "fit", action = "select"))
    session$flushReact()
    session$flushReact()
    dashboard <- htmltools::renderTags(output$models_dashboard)$html
    expect_match(dashboard, "Summary")
    expect_match(dashboard, "Set active")

    session$setInputs(model_action = list(name = "fit", action = "summary"))
    session$flushReact()
    expect_equal(tail(state$log, 1L), "summary(fit)")
  })
})

test_that("the Workbench UI renders inside the Studio shell", {
  html <- htmltools::renderTags(main_tabs_ui("studio"))$html
  expect_match(html, "Script")
  expect_match(html, "Console")
  expect_match(html, "Environment")
  expect_match(html, "script_editor_ui")
  expect_match(html, "console_input")
  expect_match(html, "environment_tabs")
})
