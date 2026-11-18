# Home pane -------------------------------------------------------------------

test_that("the Home pane is a two-column start page", {
  html <- as.character(home_pane_ui())
  expect_match(html, 'class="rcmdr-home-start"', fixed = TRUE)
  expect_match(html, "rcmdr-home-column", fixed = TRUE)
  expect_match(html, "rcmdr-home-status", fixed = TRUE)
  expect_false(grepl("rcmdr-home-hero", html, fixed = TRUE))
  expect_match(html, "rcmdr-home-title", fixed = TRUE)
  expect_match(html, 'class="rcmdr-actions"', fixed = TRUE)
  expect_match(html, "rcmdr-card-head", fixed = TRUE)
  expect_match(html, "rcmdr-note", fixed = TRUE)
  for (id in c("home_import", "home_report", "home_workflows",
               "home_palette", "home_help", "home_shortcuts")) {
    expect_match(html, sprintf('id="%s"', id), fixed = TRUE)
  }
  # The start page and its cards carry only named classes.
  for (utility in c("d-flex", "gap-2", "flex-wrap", "mb-1", "mb-2",
                    "small text-muted")) {
    expect_false(grepl(utility, html, fixed = TRUE),
                 label = paste("Home still writes", utility))
  }
})

test_that("the Home cards render with the shared frame", {
  skip_if_not_installed("shiny")
  shiny::testServer(app_server(new.env(parent = globalenv())), {
    session$setInputs(menu_search = "")
    for (id in c("home_continue", "home_recent", "home_health",
                 "home_checklist", "home_projects")) {
      html <- htmltools::renderTags(output[[id]])$html
      expect_match(html, "rcmdr-home-card", fixed = TRUE,
                   label = sprintf("%s is a Home card", id))
      expect_match(html, "rcmdr-card-head", fixed = TRUE,
                   label = sprintf("%s has a card head", id))
      expect_false(grepl("d-flex", html, fixed = TRUE),
                   label = sprintf("%s writes no utility", id))
    }
  })
})

test_that("the home and workflow styles live with the views", {
  dialogs <- app_asset_text("css", "40-dialogs.css")
  views <- app_asset_text("css", "60-views.css")
  expect_false(any(grepl("rcmdr-home-", dialogs, fixed = TRUE)))
  expect_false(any(grepl("rcmdr-workflow-", dialogs, fixed = TRUE)))
  for (rule in c(".rcmdr-home-start", ".rcmdr-home-column",
                 ".rcmdr-home-status", ".rcmdr-home-card",
                 ".rcmdr-workflow-grid", ".rcmdr-workflow-step")) {
    expect_true(any(grepl(rule, views, fixed = TRUE)),
                label = sprintf("%s is in the views stylesheet", rule))
  }
})
