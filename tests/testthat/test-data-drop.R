test_that("a dropped text file opens the Read Text Data dialog", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  shiny::testServer(app_server(env), {
    session$setInputs(menu_search = "")
    session$setInputs(data_drop_file = list(
      name = "dropped.csv", size = 24L, text = "a,b\n1,2\n3,4\n"
    ))
    session$flushReact()
    expect_equal(state$current_dialog, "readDataSet")
    memory <- get_dialog_memory(state, "readDataSet")
    expect_equal(memory$dsname, "dropped")
    expect_equal(memory$location, "local")
    expect_true(file.exists(memory$path))
    expect_equal(memory$delimiter, "commas")
    expect_equal(utils::head(readLines(memory$path), 3L),
                 c("a,b", "1,2", "3,4"))
  })
})

test_that("a binary or oversized drop is refused", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  shiny::testServer(app_server(env), {
    session$setInputs(menu_search = "")
    session$setInputs(data_drop_file = list(
      name = "book.xlsx", size = 100L, text = "not really a spreadsheet"
    ))
    session$flushReact()
    expect_null(state$current_dialog)
  })
})
