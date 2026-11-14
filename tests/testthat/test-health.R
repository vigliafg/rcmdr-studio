# P7.17 and P7.18: health panel and extended diagnostics.

test_that("health_status reports the environment", {
  state <- AppState(new.env())
  state$options$features$project <- TRUE
  status <- health_status(state)
  expect_true(nzchar(status$rcmdrshiny))
  expect_true(nzchar(status$r_version))
  expect_true(is.logical(status$pandoc))
  expect_true(is.character(status$plugins))
  expect_true(is.data.frame(status$caches))
  expect_equal(status$project$title, "Untitled project")
  expect_true("project" %in% status$features)
})

test_that("health_table and health_panel_ui render the main sections", {
  state <- AppState(new.env())
  table <- health_table(state)
  expect_true(all(c("RcmdrShiny", "R", "pandoc", "Plugins", "Help topics",
                    "Caches", "Project") %in% table$item))
  html <- as.character(health_panel_ui(state))
  expect_match(html, "health_refresh")
  expect_match(html, "health_diagnostics")
  expect_match(html, "data-rcmdr-copy")
  expect_match(html, "Health")
})

test_that("the diagnostic report includes the project and caches", {
  state <- AppState(new.env())
  state$project_title <- "Analysis"
  state$project_path <- "/tmp/analysis.rcmdrproj"
  state$project_dirty <- TRUE
  state$history <- list(history_entry(NULL, Sys.time(), "script", "1 + 1"))
  state$last_error <- "boom"
  cache_stats()

  report <- diagnostics_report(state)
  expect_equal(report$ui_mode, "studio")
  expect_equal(report$project$title, "Analysis")
  expect_equal(report$history, 1L)
  expect_equal(report$last_error, "boom")
  expect_true(is.data.frame(report$caches))

  text <- format_diagnostics(report)
  expect_true(any(grepl("Project:", text)))
  expect_true(any(grepl("title: Analysis", text)))
  expect_true(any(grepl("Caches:", text)))
  expect_true(any(grepl("Last error: boom", text)))
  expect_match(diagnostics_report_text(state), "RcmdrShiny diagnostic")
})

test_that("the issue URL is pre-filled and encoded", {
  report <- diagnostics_report()
  url <- diagnostics_issue_url(report)
  expect_match(url, "^https://github\\.com/")
  expect_match(url, "title=")
  expect_match(url, "body=")
  expect_true(grepl("Diagnostic%20report", url, fixed = TRUE) ||
                grepl("Diagnostic+report", url, fixed = TRUE) ||
                grepl("Diagnostic%20report", url))
})
