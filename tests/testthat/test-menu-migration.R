test_that("legacy menu ids migrate to stable menu ids", {
  expect_equal(unname(menu_migrate_ids("fileMenu")), "menu.file")
  expect_equal(unname(menu_migrate_ids("statisticsMenu")), "menu.analyze")
  expect_equal(unname(menu_migrate_ids("modelsMenu")),
               "menu.analyze.models")
  expect_equal(unname(menu_migrate_ids("unknownMenu")), "unknownMenu")
  expect_equal(unname(menu_migrate_ids(character())), character())
})

test_that("the preferences loader migrates expanded menu ids", {
  state <- AppState(new.env())
  state$options$persist_preferences <- TRUE
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(list(expanded = c("fileMenu", "statisticsMenu")), path)

  expect_true(preferences_load(state, path = path))
  expect_equal(state$menu_expanded, c("menu.file", "menu.analyze"))
})

test_that("breadcrumbs use the new hierarchy", {
  path <- menu_command_path("numericalSummaries")
  expect_equal(path[[1L]], "Analyze")
  expect_true("Summaries" %in% path)
})

test_that("the palette sees stable item ids for menu leaves", {
  leaves <- menu_leaves(menu_tree())
  expect_true(all(c("item_id", "menu_id", "module_id") %in% names(leaves)))
  row <- leaves[leaves$command == "numericalSummaries", , drop = FALSE][1L, ]
  expect_true(nzchar(row$item_id))
  expect_equal(row$menu_id, "menu.analyze.summaries_menu")
  expect_equal(menu_dom_id(row$item_id), row$key)
})
