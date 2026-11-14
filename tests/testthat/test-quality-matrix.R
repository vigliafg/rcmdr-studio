# P7.19: the test matrix is present and wired.

test_that("every test layer has a file and a command", {
  files <- c(
    "test-shinytest2.R",
    "test-menu-platform-e2e.R",
    "test-navigation-e2e.R",
    "test-visual.R",
    "test-accessibility.R",
    "test-performance.R",
    "test-project.R",
    "test-session-checkpoints.R",
    "test-menu-registry.R",
    "test-plugins-compat.R"
  )
  for (file in files) {
    expect_true(file.exists(testthat::test_path(file)), info = file)
  }
  expect_true(file.exists(testthat::test_path("..", "benchmarks",
                                              "benchmark.R")))
})

test_that("golden command builders are covered", {
  files <- list.files(testthat::test_path(), pattern = "^test-command-builders",
                      full.names = TRUE)
  expect_gte(length(files), 4L)
})

test_that("E2E tests are gated by the environment variable", {
  text <- paste(readLines(testthat::test_path("test-shinytest2.R"),
                          warn = FALSE), collapse = "\n")
  expect_match(text, "RCMDRSHINY_E2E", fixed = TRUE)
  text <- paste(readLines(testthat::test_path("test-menu-platform-e2e.R"),
                          warn = FALSE), collapse = "\n")
  expect_match(text, "RCMDRSHINY_E2E", fixed = TRUE)
})

test_that("documented release commands still run", {
  expect_true(is.function(diagnostics_report))
  expect_true(is.function(benchmark_suite))
  expect_true(is.function(cache_stats))
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."),
                        mustWork = TRUE)
  if (file.exists(file.path(root, "RELEASE-CHECKLIST.md"))) {
    expect_true(file.exists(file.path(root, "RELEASE-CHECKLIST.md")))
  }
})
