# Resizable dialogs and modeless panels ---------------------------------------

geometry_spec <- function() {
  dialog_spec(
    id = "geometryTest", title = "Geometry test",
    ui = function(state, memory) NULL,
    on_ok = function(input, state) list()
  )
}

test_that("a dialog remembers its width and height by id", {
  state <- AppState(new.env())
  spec <- geometry_spec()
  plain <- as.character(dialog_modal(spec, state))
  expect_match(plain, 'data-rcmdr-dialog-id="geometryTest"', fixed = TRUE)
  expect_match(plain, 'role="separator"', fixed = TRUE)
  expect_match(plain, 'data-rcmdr-dialog-resize="1"', fixed = TRUE)
  expect_match(plain, 'tabindex="0"', fixed = TRUE)
  expect_false(grepl("data-rcmdr-dialog-width", plain, fixed = TRUE))

  dialog_size_store(state, "geometryTest", width = 760, height = 540)
  sized <- as.character(dialog_modal(spec, state))
  expect_match(sized, 'data-rcmdr-dialog-width="760"', fixed = TRUE)
  expect_match(sized, 'data-rcmdr-dialog-height="540"', fixed = TRUE)
  expect_match(sized, "width:760px", fixed = TRUE)
  expect_match(sized, "--rcmdr-dialog-height:540px", fixed = TRUE)
})

test_that("dialog size is clamped and survives preferences", {
  state <- AppState(new.env())
  dialog_size_store(state, "clamped", width = 10, height = 10000)
  expect_equal(dialog_size(state, "clamped")$width, 360)
  expect_equal(dialog_size(state, "clamped")$height, 3000)

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  dialog_size_store(state, "histogram", width = 700, height = 500)
  preferences_save(state, path)
  restored <- AppState(new.env())
  expect_true(preferences_load(restored, path))
  expect_equal(dialog_size(restored, "histogram")$width, 700)
  expect_equal(dialog_size(restored, "histogram")$height, 500)
  expect_null(dialog_size(restored, "not-a-dialog")$width)
})

test_that("the resize JS publishes the final geometry", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "dialog_geometry", fixed = TRUE)
  expect_match(js, "rcmdr-dialog-resize", fixed = TRUE)
  expect_match(js, "ArrowRight", fixed = TRUE)
  expect_match(js, "rcmdr-resizing", fixed = TRUE)
})

test_that("modeless Help renders without a modal and keeps view_ready", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:3)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "home", menu_search = "",
                      modeless_view = "help")
    session$flushReact()
    panel <- htmltools::renderTags(output$modeless_panel)$html
    expect_match(panel, "rcmdr-modeless-panel", fixed = TRUE)
    expect_match(panel, 'role="complementary"', fixed = TRUE)
    expect_match(panel, 'id="modeless_close"', fixed = TRUE)
    expect_false(grepl("modal fade", panel, fixed = TRUE))
    expect_true(view_ready(list(main_tabs = "home",
                                modeless_view = "help"), "help"))
    expect_false(view_ready(list(main_tabs = "home",
                                 modeless_view = "help"), "data"))
  })
})

test_that("the View menu opens the modeless panels", {
  leaves <- menu_leaves(menu_tree())
  panel <- leaves[grepl("panel$", leaves$label), , drop = FALSE]
  expect_setequal(panel$command,
                  c("openHelpPanel", "openConsolePanel", "openOutputPanel"))
  expect_true(all(grepl("^View > ", panel$path)))
})

test_that("opening a modeless panel refuses a view already in the workspace", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:3)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "console", menu_search = "",
                      workspace_secondary_view = "")
    session$flushReact()
    expect_false(isTRUE(state$open_modeless("output")))

    session$setInputs(main_tabs = "home")
    session$flushReact()
    expect_true(isTRUE(state$open_modeless("console")))
    session$setInputs(modeless_view = "console")
    session$flushReact()
    panel <- htmltools::renderTags(output$modeless_panel)$html
    expect_match(panel, "console_input", fixed = TRUE)
  })
})

test_that("closing the modeless panel clears it", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:3)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "home", menu_search = "",
                      modeless_view = "help")
    session$flushReact()
    expect_false(is.null(htmltools::renderTags(output$modeless_panel)$html))

    session$setInputs(modeless_close = 1)
    session$flushReact()
    session$setInputs(modeless_view = "")
    session$flushReact()
    expect_false(nzchar(as.character(
      htmltools::renderTags(output$modeless_panel)$html
    )))
  })
})

test_that("the modeless focus handler returns focus to the trigger", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "rcmdr-modeless", fixed = TRUE)
  expect_match(js, "modeless_close", fixed = TRUE)
  expect_match(js, "document.activeElement", fixed = TRUE)
})
