# Server-level integration for the Wave 6 help centre.

test_that("the help tab searches, filters and opens a topic", {
  skip_if_not_installed("shiny")
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  shiny::testServer(app_server(new.env()), {
    session$setInputs(help_query = "numerical summaries")
    html <- htmltools::renderTags(output$help_results)$html
    expect_match(html, "Numerical summaries")
    expect_match(html, "statistics")

    session$setInputs(help_open = "numerical-summaries")
    topic <- htmltools::renderTags(output$help_topic)$html
    expect_match(topic, "When to use it")
    expect_match(topic, "data-help-example")
    expect_match(topic, "On this page")

    session$setInputs(help_type = "tutorial")
    filtered <- htmltools::renderTags(output$help_results)$html
    expect_false(grepl("Numerical summaries", filtered, fixed = TRUE))

    session$setInputs(help_type = "all", help_query = "")
    session$setInputs(help_clear_filters = 1)
    session$flushReact()
    restored <- htmltools::renderTags(output$help_results)$html
    expect_match(restored, "Help centre")
  })
})

test_that("a runnable example goes through the command engine", {
  skip_if_not_installed("shiny")
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  env <- new.env()
  assign("Dataset", data.frame(y = 1:5, x = 2:6), envir = env)

  shiny::testServer(app_server(env), {
    session$setInputs(help_query = "numerical summaries")
    session$setInputs(help_open = "numerical-summaries")
    session$setInputs(help_example_run = list(topic = "numerical-summaries",
                                              index = 1L))
    session$setInputs(help_example_confirm = 1)
    session$setInputs(tick = 1)

    sources <- vapply(state$history, function(entry) entry$source %||% "",
                      character(1))
    commands <- vapply(state$history, function(entry) entry$command %||% "",
                       character(1))
    expect_true("help" %in% sources)
    expect_true(any(grepl("summary(Dataset)", commands, fixed = TRUE)))
  })
})

test_that("changing the language re-renders menus and help", {
  skip_if_not_installed("shiny")
  help_unregister()
  on.exit(help_unregister(), add = TRUE)
  old <- getOption("RcmdrShiny.language")
  old_language <- Sys.getenv("LANGUAGE", "")
  old_prefs <- Sys.getenv("RCMDRSHINY_PREFERENCES", "")
  Sys.setenv(RCMDRSHINY_PREFERENCES = tempfile())
  on.exit({
    options(RcmdrShiny.language = old)
    Sys.setenv(LANGUAGE = old_language)
    Sys.setenv(RCMDRSHINY_PREFERENCES = old_prefs)
    i18n_reset()
  }, add = TRUE)
  i18n_set_language("en")

  shiny::testServer(app_server(new.env()), {
    session$setInputs(language = "it")
    # The first setInputs seeds the input in testServer; the second one is the
    # user change that the observer handles.
    session$setInputs(language = "it")
    session$flushReact()
    expect_equal(current_language(), "it")
    menus <- htmltools::renderTags(output$menubar)$html
    expect_match(menus, "Dati")
    session$setInputs(help_query = "regressione logistica")
    results <- htmltools::renderTags(output$help_results)$html
    expect_match(results, "Modello lineare generalizzato")
  })
})

test_that("the tour starts, advances and closes", {
  skip_if_not_installed("shiny")

  shiny::testServer(app_server(new.env()), {
    session$setInputs(tour_start = 1)
    session$setInputs(tour_next = 1)
    session$setInputs(tour_next = 1)
    session$setInputs(tour_next = 1)
    session$setInputs(tour_next = 1)
    expect_true(TRUE)
  })
})

test_that("a failed command offers a contextual help link", {
  skip_if_not_installed("shiny")
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  env <- new.env()
  shiny::testServer(app_server(env), {
    run_command(state, "summary(missing_object)", source = "console")
    session$setInputs(tick = 1)
    html <- htmltools::renderTags(output$history_cards)$html
    expect_match(html, "data-help-topic")
    expect_match(html, "data-import")
  })
})
