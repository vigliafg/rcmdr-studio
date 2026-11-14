# Browser flow for project persistence (P7.6).
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
#     'testthat::test_file("tests/testthat/test-project-e2e.R")'

project_e2e_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

test_that("a project can be created from the Home card", {
  project_e2e_ready()

  root <- tempfile("rcmdr-project-e2e-")
  dir.create(root, recursive = TRUE)
  path <- file.path(root, "session.rcmdrproj")
  preferences <- file.path(root, "preferences.rds")
  projects <- file.path(root, "projects.rds")
  old <- list(
    preferences = Sys.getenv("RCMDRSHINY_PREFERENCES", unset = NA_character_),
    projects = Sys.getenv("RCMDRSHINY_PROJECTS", unset = NA_character_)
  )
  Sys.setenv(RCMDRSHINY_PREFERENCES = preferences,
             RCMDRSHINY_PROJECTS = projects)
  on.exit({
    unlink(root, recursive = TRUE)
    for (name in names(old)) {
      variable <- if (identical(name, "preferences")) {
        "RCMDRSHINY_PREFERENCES"
      } else {
        "RCMDRSHINY_PROJECTS"
      }
      if (is.na(old[[name]])) {
        Sys.unsetenv(variable)
      } else {
        do.call(Sys.setenv, stats::setNames(list(old[[name]]), variable))
      }
    }
  }, add = TRUE)

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = new.env()),
    name = "project-flow",
    width = 1400,
    height = 1000,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = 30000)
  app$run_js("Shiny.setInputValue('tour_skip', 1, {priority: 'event'});")
  app$wait_for_idle(timeout = 30000)

  app$wait_for_js(
    "document.getElementById('home_project_new') !== null",
    timeout = 60000
  )
  app$click("home_project_new")
  app$wait_for_js(
    "document.getElementById('projectNew_path') !== null",
    timeout = 60000
  )
  app$set_inputs(projectNew_title = "Session")
  app$set_inputs(projectNew_path = path)
  app$click("dialog_ok")
  app$wait_for_idle(timeout = 30000)

  expect_true(file.exists(path))
  project <- RcmdrShiny:::project_open(path)
  expect_equal(project$version, RcmdrShiny:::project_schema_version())
  expect_equal(project$title, "Session")
  expect_true(file.exists(projects))
})
