test_that("a view is ready only when it is the visible tab", {
  input <- list(main_tabs = "home", chart_mode = "build")
  expect_false(view_ready(input, "charts"))
  expect_true(view_ready(input, "home"))
  input$main_tabs <- "charts"
  expect_true(view_ready(input, "charts"))
  expect_true(subview_ready(input, "chart_mode", "build"))
  expect_false(subview_ready(input, "chart_mode", "gallery"))
  # A direct call or the first flush has no tab input yet: keep building.
  expect_true(view_ready(list(), "charts"))
  expect_true(subview_ready(list(), "chart_mode", "gallery"))
})

test_that("heavy outputs are empty until their view opens", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:20, x = 1:20, g = factor(rep(c("a", "b"), 10)))

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "home", menu_search = "", help_query = "")
    session$flushReact()

    hidden <- function(expr) {
      tryCatch(nzchar(as.character(expr)), error = function(e) FALSE)
    }
    expect_false(hidden(htmltools::renderTags(output$chart_gallery_grid)$html))
    expect_false(hidden(htmltools::renderTags(output$models_dashboard)$html))
    expect_false(hidden(htmltools::renderTags(output$help_results)$html))
    expect_false(hidden(htmltools::renderTags(output$report_preview)$html))
    expect_false(hidden(htmltools::renderTags(output$environment_objects)$html))

    session$setInputs(main_tabs = "help")
    session$flushReact()
    expect_true(hidden(htmltools::renderTags(output$help_results)$html))
  })
})

test_that("a lazy view is rebuilt from the current data, never from a stale copy", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:20, x = 1:20)

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "home", menu_search = "")
    session$flushReact()

    plot_register(state, list(title = "First chart", pinned = FALSE,
                              code = "plot(1)"))
    session$setInputs(main_tabs = "charts", chart_mode = "gallery")
    session$flushReact()
    first <- htmltools::renderTags(output$chart_gallery_grid)$html
    expect_match(first, "First chart", fixed = TRUE)

    # Hide the view, change the registry, then open it again.
    session$setInputs(main_tabs = "home")
    session$flushReact()
    plot_register(state, list(title = "Second chart", pinned = TRUE,
                              code = "plot(2)"))
    session$setInputs(main_tabs = "charts", chart_mode = "gallery")
    session$flushReact()
    second <- htmltools::renderTags(output$chart_gallery_grid)$html
    expect_match(second, "Second chart", fixed = TRUE)
    expect_match(second, "First chart", fixed = TRUE)
  })
})
