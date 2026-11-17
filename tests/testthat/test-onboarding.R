test_that("the tour has four documented steps", {
  steps <- tour_steps()
  expect_length(steps, 4L)
  expect_equal(vapply(steps, function(step) step$id, character(1)),
               c("data", "charts", "report", "palette"))
  expect_true(all(vapply(steps, function(step) {
    nzchar(step$title) && nzchar(step$body) && nzchar(step$target)
  }, logical(1))))
  expect_null(tour_step(0L))
  expect_null(tour_step(99L))
  expect_equal(tour_step(2L)$id, "charts")
})

test_that("the tour modal exposes navigation and persistence actions", {
  html <- as.character(tour_modal(tour_step(2L), 2L, 4L))
  expect_match(html, "tour_next")
  expect_match(html, "tour_back")
  expect_match(html, "tour_skip")
  expect_match(html, "tour_dismiss")
  expect_match(html, "Step 2 of 4")
})

test_that("the checklist starts empty and tracks the session", {
  env <- new.env()
  state <- AppState(env)
  checks <- onboarding_checklist(state)
  expect_length(checks, 5L)
  expect_false(any(vapply(checks, function(check) check$done, logical(1))))

  assign("df", data.frame(y = 1:5), envir = env)
  active_dataset(state, "df")
  state$history <- list(list(command = "summary(df)"))
  state$plots <- list(list(id = "p1"))
  state$documents <- list(list(id = "d1", mode = "rmd"))

  checks <- onboarding_checklist(state)
  done <- vapply(checks, function(check) check$done, logical(1))
  names(done) <- vapply(checks, function(check) check$id, character(1))
  expect_true(done[["import"]])
  expect_true(done[["summary"]])
  expect_true(done[["chart"]])
  expect_true(done[["report"]])
  expect_false(done[["project"]])

  progress <- onboarding_progress(state)
  expect_equal(progress$done, 4L)
  expect_equal(progress$total, 5L)
  expect_equal(progress$percent, 80L)
})

test_that("the checklist card shows completed and unavailable items", {
  state <- AppState(new.env())
  html <- as.character(onboarding_checklist_ui(state))
  expect_match(html, "First steps")
  expect_match(html, "home_check_import")
  expect_match(html, "home_check_project")
  expect_match(html, "progress-bar")

  set_feature(state, "project", FALSE)
  disabled <- as.character(onboarding_checklist_ui(state))
  expect_match(disabled, "unavailable")
  expect_false(grepl("home_check_project", disabled, fixed = TRUE))
})

test_that("the checklist card uses the card head and the note component", {
  html <- as.character(onboarding_checklist_ui(AppState(new.env())))
  expect_match(html, "rcmdr-card-head", fixed = TRUE)
  expect_match(html, "rcmdr-badge", fixed = TRUE)
  expect_match(html, "rcmdr-checklist-action", fixed = TRUE)
  expect_match(html, "rcmdr-note", fixed = TRUE)
  expect_false(grepl("ms-auto", html, fixed = TRUE))
  expect_false(grepl("text-bg-", html, fixed = TRUE))
})
