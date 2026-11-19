# Chart example gallery -------------------------------------------------------

test_that("the example registry is complete and reproducible", {
  examples <- chart_examples()
  expect_gte(length(examples), 20L)
  expect_equal(length(unique(names(examples))), length(examples))
  for (example in examples) {
    expect_true(nzchar(example$id), info = example$id)
    expect_true(!is.null(chart_type(example$type)), info = example$id)
    expect_true(example$family %in% chart_type_analysis(chart_type(example$type)),
                info = example$id)
    expect_true(example$level %in% c("basic", "custom"), info = example$id)
    expect_match(example$source_url, "^https://r-graph-gallery\\.com/",
                 info = example$id)
    if (chart_example_available(example)) {
      expect_true(file.exists(testthat::test_path(
        "..", "..", "inst", "www", chart_example_thumbnail(example$id)
      )), info = example$id)
    }
  }
})

test_that("example specs validate on their sample data", {
  for (example in chart_examples()) {
    if (!chart_example_available(example)) next
    state <- AppState(new.env(parent = globalenv()))
    data <- chart_example_data(example)
    expect_true(is.data.frame(data), info = example$id)
    assign(example$data_name, data, envir = state$env)
    active_dataset(state, example$data_name)
    spec <- chart_example_spec(example)
    expect_equal(chart_spec_validate(spec, state), character(0),
                 info = example$id)
    code <- chart_example_code(example)
    expect_true(nzchar(code), info = example$id)
    expect_match(code, "^(print\\(ggplot2::|print\\(ggstatsplot::|print\\(ggridges::)",
                 info = example$id)
  }
})

test_that("the example filters combine family, level and query", {
  available <- sum(vapply(chart_examples(), chart_example_available,
                          logical(1)))
  expect_equal(nrow(chart_example_table()), available)
  expect_lt(nrow(chart_example_table(family = "time")), 26L)
  expect_true(all(chart_example_table(level = "basic")$level == "basic"))
  expect_true(all(chart_example_table(query = "density")$family %in%
                    c("univariate", "relationship")))
  expect_equal(nrow(chart_example_table(query = "zzzznomatch")), 0L)
})

test_that("an example maps only compatible columns", {
  state <- AppState(new.env(parent = globalenv()))
  assign("D", datasets::iris, envir = state$env)
  active_dataset(state, "D")
  example <- chart_example("scatter_group_ellipse")
  mapping <- chart_example_mapping_for(example, state)
  expect_equal(mapping$x, "Sepal.Length")
  expect_equal(mapping$y, "Sepal.Width")
  expect_equal(mapping$group, "Species")

  assign("E", datasets::mtcars, envir = state$env)
  active_dataset(state, "E")
  expect_equal(chart_example_mapping_for(example, state), list())
})

test_that("the gallery renders local cards with actions and a detail", {
  html <- htmltools::renderTags(chart_examples_ui())$html
  expect_match(html, "chart_examples_family", fixed = TRUE)
  expect_match(html, "chart_examples_level", fixed = TRUE)
  expect_match(html, "chart_examples_query", fixed = TRUE)
  expect_match(html, "chart_examples_grid", fixed = TRUE)
  expect_match(html, "chart_example_detail", fixed = TRUE)

  table <- chart_example_table()
  cards <- htmltools::renderTags(chart_examples_cards(table, selected = table$id[[1L]]))$html
  expect_match(cards, "rcmdr-example-grid", fixed = TRUE)
  expect_match(cards, "<button", fixed = TRUE)
  expect_match(cards, 'aria-pressed="true"', fixed = TRUE)
  expect_match(cards, "chart-examples/", fixed = TRUE)
  expect_false(grepl('src="http', cards, fixed = TRUE))

  detail <- htmltools::renderTags(
    chart_example_detail_ui(chart_example(table$id[[1L]]))
  )$html
  expect_match(detail, "Open in builder", fixed = TRUE)
  expect_match(detail, "Copy code", fixed = TRUE)
  expect_match(detail, "Source: R Graph Gallery", fixed = TRUE)
  expect_match(detail, 'target="_blank"', fixed = TRUE)
  expect_match(detail, 'rel="noopener noreferrer"', fixed = TRUE)
})

test_that("opening an example fills the builder without side effects", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- datasets::iris
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    state$log <- c("summary(D)")
    state$history <- list(list(id = "1"))
    session$setInputs(
      main_tabs = "charts", menu_search = "", chart_mode = "examples",
      chart_examples_family = "all", chart_examples_level = "all",
      chart_examples_query = ""
    )
    session$flushReact()

    grid <- htmltools::renderTags(output$chart_examples_grid)$html
    expect_match(grid, "chart_example_select", fixed = TRUE)
    expect_match(grid, "rcmdr-example-card", fixed = TRUE)

    session$setInputs(chart_example_select = "scatter_group_ellipse")
    session$flushReact()
    detail <- htmltools::renderTags(output$chart_example_detail)$html
    expect_match(detail, "Scatter by group with ellipse", fixed = TRUE)

    session$setInputs(chart_example_open = 1)
    session$flushReact()
    expect_equal(state$chart_recipe_pending$type, "scatter")
    expect_equal(state$chart_recipe_pending$mapping$x, "Sepal.Length")
    expect_equal(length(state$plots), 0L)
    expect_equal(state$log, "summary(D)")
    expect_length(state$history, 1L)
  })
})
