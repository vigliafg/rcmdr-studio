# P7.6 to P7.8: project UI hooks, session checkpoints and recovery.

test_that("session checkpoints record and restore the active session", {
  state <- AppState(new.env())
  state$env$df <- data.frame(y = 1:5)
  active_dataset(state, "df")
  state$env$model.1 <- stats::lm(y ~ 1, data = state$env$df)
  state$active_model <- "model.1"
  state$documents <- list(
    `document-0001` = list(
      id = "document-0001", title = "Report", path = NULL, mode = "rmd",
      text = "# Report", dirty = FALSE, last_saved = NULL,
      autosave_path = NULL, autosave_time = NULL
    )
  )
  state$active_document <- "document-0001"
  state$document <- state$documents[[1L]]

  entry <- session_checkpoint_create(state, "Before change")
  expect_equal(entry$dataset, "df")
  expect_equal(entry$model, "model.1")
  expect_equal(entry$active_document, "document-0001")

  table <- session_checkpoint_list(state)
  expect_equal(nrow(table), 1L)
  expect_equal(table$label, "Before change")

  state$active_dataset <- NULL
  state$active_model <- NULL
  expect_true(session_checkpoint_restore(state, entry$id))
  expect_equal(state$active_dataset, "df")
  expect_equal(state$active_model, "model.1")
  expect_equal(state$active_document, "document-0001")
})

test_that("session checkpoints skip objects that no longer exist", {
  state <- AppState(new.env())
  state$env$df <- data.frame(y = 1:3)
  active_dataset(state, "df")
  state$env$model.1 <- stats::lm(y ~ 1, data = state$env$df)
  state$active_model <- "model.1"
  entry <- session_checkpoint_create(state)

  rm("df", envir = state$env)
  rm("model.1", envir = state$env)
  state$active_dataset <- NULL
  state$active_model <- NULL

  expect_true(session_checkpoint_restore(state, entry$id))
  expect_null(state$active_dataset)
  expect_null(state$active_model)
})

test_that("session checkpoints respect the configured cap", {
  state <- AppState(new.env())
  state$options$session_checkpoint_max <- 3L
  for (i in seq_len(5L)) session_checkpoint_create(state, paste("c", i))
  expect_equal(length(state$session_checkpoints), 3L)
  expect_equal(session_checkpoint_list(state)$label, c("c 5", "c 4", "c 3"))
})

test_that("deleting a session checkpoint is explicit", {
  state <- AppState(new.env())
  entry <- session_checkpoint_create(state, "one")
  expect_true(session_checkpoint_delete(state, entry$id))
  expect_false(session_checkpoint_delete(state, entry$id))
  expect_equal(nrow(session_checkpoint_list(state)), 0L)
})

test_that("project dialogs and commands are registered", {
  expect_true(all(c("projectNew", "projectOpen", "projectSaveAs",
                    "projectBundle", "sessionCheckpoint") %in% dialog_ids()))
  expect_true("projectSave" %in% names(direct_commands()))

  spec <- get_dialog("projectNew")
  expect_true(is.function(spec$ui))
  expect_true(is.function(spec$on_ok))

  expect_true("sessionCheckpoint" %in% dialog_ids())
})

test_that("projectSave writes the current project", {
  state <- AppState(new.env())
  state$project_recent_file <- tempfile(fileext = ".rds")
  root <- tempfile("rcmdr-command-save-")
  dir.create(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  state$project_path <- file.path(root, "work.rcmdrproj")
  state$project_title <- "work"

  direct_commands()[["projectSave"]](state)
  expect_true(file.exists(state$project_path))
  info <- project_open(state$project_path)
  expect_equal(info$version, project_schema_version())
})

test_that("the Home project card exposes the project actions", {
  state <- AppState(new.env())
  state$project_recent_file <- tempfile(fileext = ".rds")
  html <- as.character(project_home_ui(state))
  for (id in c("home_project_new", "home_project_open", "home_project_save",
               "home_project_bundle")) {
    expect_match(html, id, fixed = TRUE)
  }
  expect_match(html, "Project:")
})

test_that("the recovery modal offers recover, ignore and delete", {
  info <- list(
    path = "/tmp/example.rcmdrproj",
    autosave = "/tmp/example.rcmdrproj.autosave",
    available = TRUE,
    project_time = Sys.time() - 60,
    autosave_time = Sys.time(),
    newer = TRUE,
    project_size = 100,
    autosave_size = 120
  )
  html <- as.character(project_recovery_modal(info))
  expect_match(html, "project_recovery_recover")
  expect_match(html, "project_recovery_ignore")
  expect_match(html, "project_recovery_delete")
})

test_that("the recovery modal wears the shared chrome and keeps its actions", {
  info <- list(
    path = "/tmp/example.rcmdrproj",
    autosave = "/tmp/example.rcmdrproj.autosave",
    available = TRUE,
    project_time = Sys.time() - 60,
    autosave_time = Sys.time(),
    newer = TRUE,
    project_size = 100,
    autosave_size = 120
  )
  html <- as.character(project_recovery_modal(info))
  expect_match(html, 'class="modal-header rcmdr-modal-header"', fixed = TRUE)
  expect_match(html, 'id="rcmdr-modal-title">Recover unsaved project</h4>',
               fixed = TRUE)
  expect_match(html, 'class="modal-footer rcmdr-modal-footer"', fixed = TRUE)
  expect_match(html, "rcmdr-recovery-list", fixed = TRUE)
  # The three actions keep their ids; the decision is grouped on the right.
  primary <- sub(".*rcmdr-modal-primary", "", html)
  expect_match(primary, "project_recovery_recover", fixed = TRUE)
  expect_false(grepl("project_recovery_ignore", primary, fixed = TRUE))
  # No X: the backdrop is static and a button decides.
  expect_false(grepl("btn-close", html, fixed = TRUE))
  expect_false(grepl('class="small"', html, fixed = TRUE))
})
