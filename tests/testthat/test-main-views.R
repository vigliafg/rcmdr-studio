# Main views: stable ids, translated labels and the result hint ---------------

test_that("view ids resolve from ids, English and translated labels", {
  expect_equal(main_view_id("data"), "data")
  expect_equal(main_view_id("Data"), "data")
  expect_equal(main_view_id("Data Studio"), "data")
  expect_equal(main_view_id("Charts"), "charts")
  expect_equal(main_view_id("Chart Studio"), "charts")
  expect_equal(main_view_id("Plots"), "charts")
  expect_equal(main_view_id("Output"), "output")
  expect_equal(main_view_id("Messages"), "messages")
  expect_equal(main_view_id("Help centre"), "help")
  expect_null(main_view_id("Not a view"))
  expect_null(main_view_id(NULL))

  old <- getOption("RcmdrShiny.language")
  on.exit(options(RcmdrShiny.language = old), add = TRUE)
  i18n_set_language("it")
  expect_equal(main_view_id("Studio dati"), "data")
  expect_equal(main_view_id("Studio grafici"), "charts")
  i18n_set_language("en")
})

test_that("output and messages are panes of the Console workspace in Studio", {
  expect_equal(main_tab_target("Data", "studio"), list(tab = "data"))
  expect_equal(main_tab_target("Output", "studio"),
               list(tab = "console", sub = "output"))
  expect_equal(main_tab_target("Messages", "studio"),
               list(tab = "console", sub = "messages"))
  expect_equal(main_tab_target("History", "studio"),
               list(tab = "console", sub = "history"))
  expect_equal(main_tab_target("Console", "studio"), list(tab = "console"))
  # Classic mode has real tabs for the same panes.
  expect_equal(main_tab_target("Output", "classic"), list(tab = "console"))
  expect_equal(main_tab_target("History", "classic"), list(tab = "console"))
  expect_equal(main_tab_target("Charts", "classic"), list(tab = "charts"))
  expect_null(main_tab_target("nope", "studio"))
})

test_that("the tab titles are windows, not menu verbs", {
  expect_equal(main_tab_label("data", "studio"), tr("Data Studio"))
  expect_equal(main_tab_label("charts", "studio"), tr("Chart Studio"))
  expect_equal(main_tab_label("report", "studio"), tr("Report Studio"))
  expect_equal(main_tab_label("help", "studio"), tr("Help centre"))
  expect_equal(main_tab_label("charts", "classic"), tr("Plots"))
  expect_equal(main_tab_label("console", "classic"), tr("Output"))
})

test_that("the main tabs carry the stable view values", {
  html <- htmltools::renderTags(workspace_view_switcher("home"))$html
  expect_match(html, 'data-value="data"', fixed = TRUE)
  expect_match(html, 'data-value="charts"', fixed = TRUE)
  expect_match(html, 'data-value="report"', fixed = TRUE)
  expect_match(html, 'data-value="console"', fixed = TRUE)
  expect_match(html, 'data-value="help"', fixed = TRUE)

  classic <- htmltools::renderTags(main_tabs_ui("classic"))$html
  expect_match(classic, 'data-value="console"', fixed = TRUE)
  expect_match(classic, 'data-value="messages"', fixed = TRUE)
  expect_match(classic, 'data-value="charts"', fixed = TRUE)
})

test_that("a dialog command records where its result landed", {
  state <- AppState(env = new.env())
  ok <- apply_dialog_result(state, list(commands = "1 + 1"),
                            dialog_id = "numericalSummaries")
  expect_true(ok)
  expect_equal(state$last_result$tab, "console")
  expect_equal(state$last_result$sub, "output")
  expect_gt(length(state$last_result$command), 0L)
})

test_that("a plot command points at the chart window", {
  state <- AppState(env = new.env())
  state$options$max_plots <- 5L
  ok <- apply_dialog_result(state, list(commands = "plot(1:3)", plot = TRUE),
                            dialog_id = "scatterplot")
  expect_true(ok)
  expect_equal(state$last_result$tab, "charts")
  expect_null(state$last_result$sub)
})

test_that("a dialog that already switches tab leaves no hint", {
  state <- AppState(env = new.env())
  tabs <- character()
  state$show_tab <- function(view) tabs <<- c(tabs, view)
  apply_dialog_result(state, list(commands = "1 + 1", tab = "Data"))
  expect_null(state$last_result)
  expect_equal(tabs, tr("Data"))
})

test_that("the auto-switch preference moves to the result", {
  state <- AppState(env = new.env())
  tabs <- character()
  state$show_tab <- function(view) tabs <<- c(tabs, view)
  state$options$auto_switch_result <- TRUE
  apply_dialog_result(state, list(commands = "1 + 1"))
  expect_equal(tabs, "output")
})

test_that("the result hint names the window and offers to open it", {
  html <- htmltools::renderTags(result_hint_ui(
    list(tab = "console", sub = "output",
         command = c("Analyze", "Summaries", "Numerical summaries"))
  ))$html
  expect_match(html, "Numerical summaries")
  expect_match(html, "Result in:")
  expect_match(html, "Output (Console)", fixed = TRUE)
  expect_match(html, "Show result")
  expect_match(html, "result_hint_open")
  expect_match(html, "rcmdr-result-hint")

  charts <- htmltools::renderTags(result_hint_ui(list(tab = "charts")))$html
  expect_match(charts, "Chart Studio")
  expect_false(grepl("\u25b8", charts))

  expect_null(result_hint_ui(NULL))
})

test_that("the result hint output follows a dialog command", {
  env <- new.env()
  shiny::testServer(app_server(env), {
    session$setInputs(menu_search = "")
    expect_null(output$result_hint)
    expect_true(apply_dialog_result(state, list(commands = "1 + 1"),
                                    dialog_id = "numericalSummaries"))
    session$flushReact()
    html <- htmltools::renderTags(output$result_hint)$html
    expect_match(html, "Result in:")
    expect_match(html, "result_hint_open")
  })
})

test_that("the auto-switch preference is persisted", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  state <- AppState(env = new.env())
  state$options$auto_switch_result <- TRUE
  preferences_save(state, path)
  restored <- AppState(env = new.env())
  preferences_load(restored, path)
  expect_true(isTRUE(restored$options$auto_switch_result))
})
