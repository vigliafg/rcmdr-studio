# P7.1 -- project schema, validation and migration.

test_that("a new project is a valid, versioned schema", {
  project <- project_new()
  expect_equal(project$version, project_schema_version())
  expect_true(project_is_timestamp(project$created))
  expect_true(project_is_timestamp(project$modified))
  expect_true(nzchar(project$package_version))
  expect_equal(project$datasets, list())
  expect_equal(project$models, list())
  expect_equal(project$documents, list())
  expect_equal(project$plots, list())
  expect_identical(project$favorites, character())
  expect_false(project$history$include)
  expect_true(project_validate(project)$ok)
  expect_false("path" %in% names(project_payload(project)))
})

test_that("the entry constructors build a project that validates", {
  project <- project_new()
  project$datasets <- list(project_dataset(
    "iris", source = "data/iris.csv", include = TRUE, active = TRUE,
    dictionary = list(
      Sepal.Length = list(label = "Lunghezza sepalo", units = "cm"),
      Species = list(description = "Specie")
    )
  ))
  project$models <- list(project_model_entry(
    "model.1", "lm", formula = "Sepal.Length ~ Species", data = "iris"
  ))
  project$active_model <- "model.1"
  project$documents <- list(project_document_entry(
    "report-1", path = "report.Rmd", mode = "rmd", text = "# Report",
    active = TRUE
  ))
  project$active_document <- "report-1"
  project$plots <- list(project_plot_entry(
    "plot-0001", file = "assets/plot-0001.png", title = "Istogramma",
    spec = list(type = "histogram"), pinned = TRUE
  ))
  project$presets <- list(numericalSummaries = list(
    Default = list(mean = TRUE, sd = TRUE)
  ))
  project$favorites <- c("numericalSummaries", "Histogram")

  result <- project_validate(project)
  expect_true(result$ok)
  expect_equal(result$problems, character())
  expect_equal(result$warnings, character())
})

test_that("the schema requires a version", {
  project <- project_new()
  project$version <- NULL
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "), "schema version")
})

test_that("the schema rejects an unknown future version", {
  project <- project_new()
  project$version <- project_schema_version() + 1L
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "), "newer")
})

test_that("the schema rejects malformed timestamps", {
  project <- project_new()
  project$created <- "yesterday"
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "), "ISO-8601")
})

test_that("duplicate data set names and multiple active data sets are errors", {
  project <- project_new()
  project$datasets <- list(
    project_dataset("iris", source = "a.csv", active = TRUE),
    project_dataset("iris", source = "b.csv", active = TRUE)
  )
  result <- project_validate(project)
  expect_false(result$ok)
  text <- paste(result$problems, collapse = " ")
  expect_match(text, "Duplicate data set name")
  expect_match(text, "At most one data set")
})

test_that("a data set entry needs a source path", {
  project <- project_new()
  project$datasets <- list(project_dataset("sessionOnly"))
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "), "source")
})

test_that("a model reference must exist", {
  project <- project_new()
  project$models <- list(project_model_entry("model.1", "lm"))
  project$active_model <- "model.2"
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "), "active model")
})

test_that("document modes and ids are validated", {
  project <- project_new()
  project$documents <- list(
    project_document_entry("report-1", mode = "xlsx", text = ""),
    project_document_entry("a/b", mode = "rmd", text = "")
  )
  project$active_document <- "missing"
  result <- project_validate(project)
  expect_false(result$ok)
  text <- paste(result$problems, collapse = " ")
  expect_match(text, "unknown document mode")
  expect_match(text, "path separators")
  expect_match(text, "active document")
})

test_that("only one document can be active", {
  project <- project_new()
  project$documents <- list(
    project_document_entry("d1", mode = "r", text = "", active = TRUE),
    project_document_entry("d2", mode = "r", text = "", active = TRUE)
  )
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "),
               "At most one document")
})

test_that("plot files must stay inside the project", {
  project <- project_new()
  project$plots <- list(
    project_plot_entry("p1", file = "../outside.png"),
    project_plot_entry("p2", file = "/tmp/absolute.png"),
    project_plot_entry("p1", file = "assets/ok.png")
  )
  result <- project_validate(project)
  expect_false(result$ok)
  text <- paste(result$problems, collapse = " ")
  expect_match(text, "must not leave the project")
  expect_match(text, "relative to the project")
  expect_match(text, "Duplicate plot id")
})

test_that("a plot outside assets is a warning, not an error", {
  project <- project_new()
  project$plots <- list(project_plot_entry("p1", file = "plots/p1.png"))
  result <- project_validate(project)
  expect_true(result$ok)
  expect_match(paste(result$warnings, collapse = " "), "outside 'assets/'")
})

test_that("favourites must be stable command ids", {
  project <- project_new()
  project$favorites <- list("numericalSummaries")
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "), "favorites")

  project$favorites <- c("numericalSummaries", "")
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "), "empty command id")
})

test_that("project options are checked but unknown options only warn", {
  project <- project_new()
  project$options <- list(ui_mode = "kiosk", theme = "neon",
                          language = "xx", future_option = TRUE)
  result <- project_validate(project)
  expect_false(result$ok)
  text <- paste(result$problems, collapse = " ")
  expect_match(text, "ui_mode")
  expect_match(text, "theme")
  expect_match(text, "language")
  expect_match(paste(result$warnings, collapse = " "), "Unknown project option")

  project$options <- list(ui_mode = "classic", theme = "dark", language = "en")
  expect_true(project_validate(project)$ok)
})

test_that("unknown top-level and history fields only warn", {
  project <- project_new()
  project$future <- TRUE
  project$history <- list(include = TRUE, undo = 10L)
  result <- project_validate(project)
  expect_true(result$ok)
  text <- paste(result$warnings, collapse = " ")
  expect_match(text, "Unknown top-level field 'future'")
  expect_match(text, "Unknown history field 'undo'")
})

test_that("unknown dictionary fields warn instead of failing", {
  project <- project_new()
  project$datasets <- list(project_dataset(
    "iris", source = "data/iris.csv",
    dictionary = list(Sepal.Length = list(label = "L", colour = "red"))
  ))
  result <- project_validate(project)
  expect_true(result$ok)
  expect_match(paste(result$warnings, collapse = " "),
               "unknown dictionary field 'colour'")
})

test_that("a presets tree is validated", {
  project <- project_new()
  project$presets <- list(
    numericalSummaries = list(Default = list(mean = TRUE)),
    chart = "not a list"
  )
  result <- project_validate(project)
  expect_false(result$ok)
  expect_match(paste(result$problems, collapse = " "),
               "Presets for 'chart'")
})

test_that("project_validate_or_stop reports the problems", {
  project <- project_new()
  project$version <- NULL
  expect_error(project_validate_or_stop(project), "Invalid project")
  expect_invisible(project_validate_or_stop(project_new()))
})

test_that("pre-schema drafts migrate to version 1", {
  legacy <- list(
    data = list(list(name = "iris", source = "data/iris.csv")),
    active_dataset = "iris",
    docs = list(list(id = "report-1", mode = "rmd", text = "# Report")),
    favourites = c("numericalSummaries")
  )
  migrated <- project_migrate(legacy)

  expect_equal(migrated$version, 1L)
  expect_equal(attr(migrated, "migrated_from"), 0L)
  expect_null(migrated[["data"]])
  expect_null(migrated$active_dataset)
  expect_true(migrated$datasets[[1L]]$active)
  expect_equal(migrated$documents[[1L]]$id, "report-1")
  expect_equal(migrated$favorites, "numericalSummaries")
  expect_true(nzchar(migrated$created))
  expect_true(project_validate(migrated)$ok)
})

test_that("a current project passes through migration unchanged", {
  project <- project_new()
  migrated <- project_migrate(project)
  expect_null(attr(migrated, "migrated_from"))
  expect_equal(migrated$version, project_schema_version())
  expect_equal(migrated$created, project$created)
  expect_true(project_validate(migrated)$ok)
})

test_that("migration refuses a newer schema", {
  project <- project_new()
  project$version <- project_schema_version() + 1L
  expect_error(project_migrate(project), "supports up to")
})

test_that("named collections recover their identifiers", {
  project <- project_new()
  project$datasets <- list(iris = list(source = "data/iris.csv"))
  project$documents <- list(report = list(mode = "rmd", text = ""))
  project$plots <- list(first = list(file = "assets/first.png"))
  normalised <- project_normalize(project)
  expect_equal(normalised$datasets[[1L]]$name, "iris")
  expect_equal(normalised$documents[[1L]]$id, "report")
  expect_equal(normalised$plots[[1L]]$id, "first")
  expect_true(project_validate(normalised)$ok)
})

test_that("path helpers keep project paths relative and contained", {
  root <- tempfile("rcmdr-project-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  inside <- file.path(root, "assets", "plot-0001.png")
  expect_true(project_path_absolute("/tmp/x"))
  expect_true(project_path_absolute("C:/Users/x"))
  expect_false(project_path_absolute("assets/plot.png"))

  expect_equal(project_relative_path(inside, root), "assets/plot-0001.png")
  expect_equal(project_relative_path("assets/plotted.png", root),
               "assets/plotted.png")
  expect_equal(
    project_resolve_path("assets/plot-0001.png", root),
    project_normalize_path(inside)
  )

  expect_true(project_path_inside("assets/plot.png", root))
  expect_false(project_path_inside("../outside.png", root))
  expect_true(project_path_escapes("assets/../outside.png"))
  expect_false(project_path_escapes("assets/plot.png"))

  expect_equal(project_assets_dir(file.path(root, "work.rcmdrproj")),
               file.path(root, "assets"))
})
