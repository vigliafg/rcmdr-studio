test_that("menu favourites and recents render in the sidebar", {
  state <- AppState(env = new.env())
  menu_favorite_toggle(state, "readDataSet")
  menu_recent_add(state, "numericalSummaries")

  html <- as.character(htmltools::tagList(
    menu_sections_ui(state),
    menu_ui(
      menu_tree(),
      function(node) command_status(state, node$command, node$activation,
                                    node$install),
      favorites = menu_favorite_ids(state),
      expanded = state$menu_expanded
    )
  ))

  expect_match(html, "Favourites")
  expect_match(html, "Recent")
  expect_match(html, "rcmdr-menu-star")
  expect_match(html, "readDataSet")
  expect_match(html, "numericalSummaries")
})

test_that("menu search highlights the matching text", {
  html <- as.character(menu_highlight("Numerical summaries", "numer"))
  expect_match(html, "<mark")
  expect_match(html, "Numer")
  expect_equal(menu_highlight("No match", "zzz"), "No match")
})

test_that("flat search rows keep the path and the favourite star", {
  leaves <- menu_leaves(menu_tree())
  row <- leaves[leaves$command == "numericalSummaries", , drop = FALSE]
  html <- as.character(menu_flat_item_ui(
    row, "enabled", "numer", favorite = TRUE
  ))
  expect_match(html, "rcmdr-menu-flat-path")
  expect_match(html, "rcmdr-menu-star active")
  expect_match(html, "<mark")
})

test_that("menu expansion persists in the state", {
  state <- AppState(env = new.env())
  ids <- menu_group_ids()

  expect_true(length(ids) > 0L)
  menu_set_expanded(state, ids[1:2], expand = TRUE)
  expect_true(all(ids[1:2] %in% state$menu_expanded))

  menu_toggle_expanded(state, ids[[1L]], open = FALSE)
  expect_false(ids[[1L]] %in% state$menu_expanded)

  menu_set_expanded(state, ids, expand = FALSE)
  expect_length(state$menu_expanded, 0L)
})

test_that("the command breadcrumb follows the menu tree", {
  path <- menu_command_path("numericalSummaries")
  expect_true(length(path) >= 2L)
  expect_true("Statistics" %in% path)
  expect_equal(menu_command_path("not-a-command"), character())
  expect_equal(dialog_breadcrumb_parts("numericalSummaries"), path)
})
