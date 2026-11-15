workflow_test_state <- function() {
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(
    x = c(1, 2, 3, 4, 5, 6),
    y = c(2, 4, 6, 8, 10, 12),
    g = factor(c("a", "a", "b", "b", "c", "c"))
  )
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  state
}

test_that("the workflow registry exposes the five planned workflows", {
  workflows <- workflow_registry()
  expect_setequal(
    names(workflows),
    c("describe", "compare", "linear", "report", "survival")
  )
  for (workflow in workflows) {
    expect_s3_class(workflow, "RcmdrShinyWorkflow")
    expect_true(length(workflow$steps) > 0L)
    expect_true(nzchar(workflow$report_section))
  }
})

test_that("a workflow starts with the first step pending", {
  state <- workflow_test_state()
  started <- workflow_start(state, "describe")
  expect_true(started$ok)

  current <- workflow_current_step(state)
  expect_equal(current$index, 1L)
  expect_equal(current$status, "pending")

  progress <- workflow_progress(state)
  expect_equal(nrow(progress), 4L)
  expect_true(progress$current[[1L]])
  expect_true(all(progress$status == "pending"))
})

test_that("dialog steps return memory without running anything", {
  state <- workflow_test_state()
  workflow_start(state, "describe")

  result <- workflow_step_open(state, "summary")
  expect_true(result$ok)
  expect_equal(result$dialog, "numericalSummaries")
  expect_equal(result$memory$x, c("x", "y"))
  expect_true(result$memory$mean)
  expect_length(state$log, 0L)
})

test_that("a completed dialog marks the step and advances", {
  state <- workflow_test_state()
  workflow_start(state, "describe")

  workflow_mark_step(
    state, "numericalSummaries",
    list(commands = "numSummary(Dataset[, c(\"x\")], statistics=c(\"mean\"))"),
    history_ids = "hist-0001"
  )

  progress <- workflow_progress(state)
  expect_equal(progress$status[[1L]], "done")
  expect_equal(workflow_current_step(state)$step$id, "missing")
  expect_equal(state$workflow$history_ids, "hist-0001")

  section <- workflow_report_section(state)
  expect_match(section, "Description of the data")
  expect_match(section, "numSummary")
})

test_that("direct command steps run and record their command", {
  state <- workflow_test_state()
  workflow_start(state, "describe")
  workflow_mark_step(state, "numericalSummaries", list(commands = "x <- 1"))

  result <- workflow_step_open(state, "missing")
  expect_true(result$ok)
  expect_true(result$ran)
  expect_length(state$log, 1L)
  expect_match(state$log[[1L]], "is.na")

  progress <- workflow_progress(state)
  expect_equal(progress$status[[2L]], "done")
})

test_that("optional steps can be skipped while required steps cannot", {
  state <- workflow_test_state()
  workflow_start(state, "describe")

  expect_false(workflow_skip_step(state, "summary")$ok)

  workflow_mark_step(state, "numericalSummaries", list(commands = "x <- 1"))
  expect_true(workflow_skip_step(state, "missing")$ok)
  expect_equal(
    workflow_progress(state)$status[[2L]],
    "skipped"
  )
})

test_that("model and data commands explain why they are blocked", {
  state <- AppState(env = new.env())
  workflow_start(state, "linear")
  progress <- workflow_progress(state)
  expect_false(progress$available[progress$id == "summary"])
  expect_match(progress$reason[progress$id == "summary"], "Fit a model")

  workflow_start(state, "describe")
  progress <- workflow_progress(state)
  expect_false(progress$available[progress$id == "missing"])
  expect_match(progress$reason[progress$id == "missing"], "Select a data set")
})

test_that("back, cancel and unknown steps are handled", {
  state <- workflow_test_state()
  expect_false(workflow_step_open(state)$ok)

  workflow_start(state, "describe")
  workflow_mark_step(state, "numericalSummaries", list(commands = "x <- 1"))
  expect_true(workflow_back(state)$ok)
  expect_equal(workflow_current_step(state)$index, 1L)

  expect_false(workflow_step_open(state, "unknown-step")$ok)
  expect_true(workflow_cancel(state))
  expect_null(workflow_active(state))
  expect_false(workflow_cancel(state))
})

test_that("the workflow draft is inserted into a new report", {
  state <- workflow_test_state()
  workflow_start(state, "describe")
  workflow_mark_step(state, "numericalSummaries",
                     list(commands = "summary(Dataset$x)"))

  result <- workflow_insert_report(state)
  expect_true(result$ok)
  expect_equal(document_mode(state), "rmd")
  expect_match(document_text(state), "Description of the data")
  expect_match(document_text(state), "summary\\(Dataset\\$x\\)")
})

test_that("the workflow panel renders the registry and the active steps", {
  state <- workflow_test_state()
  html <- as.character(workflow_panel_ui(state))
  expect_match(html, "rcmdr-workflow-grid")
  expect_match(html, "Describe the data")

  workflow_start(state, "describe")
  html <- as.character(workflow_panel_ui(state))
  expect_match(html, "rcmdr-workflow-step")
  expect_match(html, "Numerical summaries")
  expect_match(html, "Skip")
})

test_that("the step trace records the dialog that completed it", {
  state <- workflow_test_state()
  workflow_start(state, "describe")

  workflow_mark_step(
    state, "numericalSummaries",
    list(commands = "numSummary(Dataset[, c(\"x\")], statistics=c(\"mean\"))"),
    history_ids = "hist-0001"
  )

  trace <- workflow_step_trace(state)
  expect_equal(nrow(trace), 4L)
  summary <- trace[trace$step == "summary", , drop = FALSE]
  expect_identical(summary$dialog, "numericalSummaries")
  expect_identical(summary$traced_dialog, "numericalSummaries")
  expect_identical(summary$status, "done")
  expect_match(summary$commands, "numSummary")

  pending <- trace[trace$step != "summary", , drop = FALSE]
  expect_true(all(pending$status == "pending"))
  expect_true(all(pending$traced_dialog == ""))
})
