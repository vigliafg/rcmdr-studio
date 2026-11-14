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

# -- P7.2 to P7.5: persistence, recent projects, autosave and bundle --------

test_project_state <- function() {
  state <- AppState(new.env())
  state$project_recent_file <- tempfile(fileext = ".rds")
  state$env$iris <- datasets::iris
  dataset_register(state, "iris", source = "session")
  state$active_dataset <- "iris"
  state$data_dictionary$iris <- list(
    Sepal.Length = list(label = "Lunghezza sepalo", units = "cm")
  )
  state$documents <- list(
    `document-0001` = list(
      id = "document-0001", title = "Report", path = NULL, mode = "rmd",
      text = "# Report\n", dirty = FALSE, last_saved = NULL,
      autosave_path = NULL, autosave_time = NULL
    )
  )
  state$active_document <- "document-0001"
  state$document <- state$documents[[1L]]
  plot_file <- tempfile(fileext = ".png")
  writeLines("not-a-real-png", plot_file)
  state$plots <- list(list(
    id = "plot-0001", index = 1L, file = plot_file, url = NULL,
    code = "hist(iris$Sepal.Length)", recorded = NULL, time = Sys.time(),
    spec = list(type = "histogram"), title = "Istogramma",
    tags = character(), pinned = TRUE, interactive_code = NULL
  ))
  state$plot_counter <- 1L
  state$dialog_presets <- list(numericalSummaries = list(
    Default = list(mean = TRUE)
  ))
  state$menu_favorites <- c("numericalSummaries", "Histogram")
  state$options$theme <- "dark"
  state
}

test_that("a project saves, reopens and restores the session", {
  state <- test_project_state()
  root <- tempfile("rcmdr-project-save-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  path <- file.path(root, "analysis.rcmdrproj")

  expect_equal(project_save(state, path), project_normalize_path(path))
  expect_true(file.exists(path))
  expect_true(file.exists(file.path(root, "data", "iris.csv")))
  expect_true(file.exists(file.path(root, "assets", "plot-0001.png")))
  expect_false(state$project_dirty)
  state_touch(state)
  expect_true(state$project_dirty)
  project_save(state, path)
  expect_false(state$project_dirty)

  project <- project_open(path)
  expect_equal(project$version, project_schema_version())
  expect_equal(project$datasets[[1L]]$source, "data/iris.csv")
  expect_true(project$datasets[[1L]]$include)
  expect_equal(project$documents[[1L]]$mode, "rmd")
  expect_equal(project$plots[[1L]]$file, "assets/plot-0001.png")
  expect_equal(project$options$theme, "dark")

  restored <- AppState(new.env())
  project_load(restored, path)
  expect_equal(restored$active_dataset, "iris")
  expect_equal(nrow(restored$env$iris), 150L)
  expect_equal(attr(restored$env$iris$Sepal.Length, "label"),
               "Lunghezza sepalo")
  expect_equal(restored$documents[[1L]]$text, "# Report\n")
  expect_equal(restored$active_document, "document-0001")
  expect_equal(restored$plot_counter, 1L)
  expect_true(file.exists(restored$plots[[1L]]$file))
  expect_equal(restored$menu_favorites,
               c("numericalSummaries", "Histogram"))
  expect_equal(restored$dialog_presets$numericalSummaries$Default$mean, TRUE)
  expect_equal(restored$options$theme, "dark")
  expect_equal(restored$project_path, project_normalize_path(path))
})

test_that("save as changes the project path and title", {
  state <- test_project_state()
  root <- tempfile("rcmdr-project-as-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  first <- project_save(state, file.path(root, "first"))
  expect_true(grepl("\\.rcmdrproj$", first))
  second <- project_save_as(state, file.path(root, "second.rcmdrproj"))
  expect_equal(state$project_path, project_normalize_path(second))
  expect_equal(state$project_title, "second")
  expect_true(file.exists(first))
  expect_true(file.exists(second))
})

test_that("history is included only when requested", {
  state <- test_project_state()
  state$history <- list(history_entry("hist-0001", Sys.time(), "script",
                                      "summary(iris)"))
  state$history_counter <- 1L
  root <- tempfile("rcmdr-project-history-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  plain <- project_open(project_save(state, file.path(root, "plain.rcmdrproj")))
  expect_false(isTRUE(plain$history$include))
  expect_null(plain$history$entries)

  full_path <- project_save(state, file.path(root, "full.rcmdrproj"),
                            include_history = TRUE)
  full <- project_open(full_path)
  expect_true(isTRUE(full$history$include))
  expect_equal(full$history$entries[[1L]]$command, "summary(iris)")

  restored <- AppState(new.env())
  project_load(restored, full_path)
  expect_true(any(vapply(restored$history, function(entry) {
    identical(entry$command, "summary(iris)")
  }, logical(1))))
})

test_that("recent projects are ordered, deduplicated and removable", {
  file <- tempfile(fileext = ".rds")
  on.exit(unlink(file), add = TRUE)
  root <- tempfile("rcmdr-recent-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  first <- file.path(root, "first.rcmdrproj")
  second <- file.path(root, "second.rcmdrproj")
  writeLines("version: 1", first)
  writeLines("version: 1", second)

  project_recent_add(first, "First", file = file)
  project_recent_add(second, "Second", file = file)
  project_recent_add(first, "First again", file = file)
  table <- project_recent(file = file)
  expect_equal(nrow(table), 2L)
  expect_equal(table$path[[1L]], project_normalize_path(first))
  expect_true(all(table$exists))

  project_recent_remove(first, file = file)
  expect_equal(project_recent(file = file)$path, project_normalize_path(second))
})

test_that("autosave and recovery keep the original project path", {
  state <- test_project_state()
  root <- tempfile("rcmdr-project-recovery-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  path <- project_save(state, file.path(root, "work.rcmdrproj"))
  autosave <- paste0(path, ".autosave")

  state$project_dirty <- TRUE
  expect_true(project_autosave(state))
  expect_true(file.exists(autosave))
  info <- project_recovery_info(path)
  expect_true(info$available)
  expect_true(file.exists(info$autosave))

  Sys.setFileTime(autosave, Sys.time() + 10)
  expect_true(project_recovery_info(path)$newer)

  recovered <- AppState(new.env())
  project_recover(recovered, path)
  expect_equal(recovered$project_path, project_normalize_path(path))
  expect_true(recovered$project_dirty)
  expect_equal(recovered$active_dataset, "iris")

  project_remove_autosave(recovered)
  expect_false(file.exists(autosave))
})

test_that("a bundle contains the project, its data and its plots", {
  state <- test_project_state()
  root <- tempfile("rcmdr-project-bundle-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  archive <- file.path(root, "bundle.tar.gz")

  expect_equal(project_export_bundle(state, archive),
               project_normalize_path(archive))
  expect_true(file.exists(archive))
  listing <- utils::untar(archive, list = TRUE)
  expect_true(any(grepl("project\\.rcmdrproj$", listing)))
  expect_true(any(grepl("README\\.txt$", listing)))
  expect_true(any(grepl("data/iris\\.csv$", listing)))
  expect_true(any(grepl("assets/plot-0001\\.png$", listing)))
})

test_that("a project can be reset without touching the session data", {
  state <- test_project_state()
  title <- project_reset(state, title = "New analysis")
  expect_equal(title, "New analysis")
  expect_true(state$project_dirty)
  expect_null(state$project_path)
  expect_true(exists("iris", envir = state$env, inherits = FALSE))
  summary <- project_summary(state)
  expect_equal(summary$title, "New analysis")
  expect_equal(summary$datasets, length(state$datasets))
})
