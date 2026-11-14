test_that("the registry builds groups, items and separators", {
  registry <- menu_registry_new()
  registry <- menu_registry_add(registry, list(
    menu_group("menu.file", label = "File", order = 10L),
    menu_group("menu.file.save", parent = "menu.file", label = "Save",
               order = 20L),
    menu_item("file.save.data", "menu.file.save", "Data set...",
              "saveDataSet", order = 10L),
    menu_item("file.save.script", "menu.file.save", "Script...",
              "saveLog", order = 20L),
    menu_separator("menu.file", order = 90L)
  ))

  expect_equal(length(registry$groups), 2L)
  expect_equal(length(registry$items), 3L)
  validation <- menu_registry_validate(registry)
  expect_true(validation$ok)

  tree <- menu_registry_tree(registry)
  expect_equal(tree[[1L]]$id, "menu.file")
  expect_equal(tree[[1L]]$children[[1L]]$id, "menu.file.save")
  keys <- vapply(tree[[1L]]$children[[1L]]$children,
                 function(node) node$key %||% "", character(1))
  expect_true(all(startsWith(keys[nzchar(keys)], "menu_item_")))
})

test_that("stable DOM keys do not depend on order", {
  registry <- menu_registry_new()
  registry <- menu_registry_add(registry, list(
    menu_group("menu.file", label = "File"),
    menu_item("file.save.data", "menu.file", "Data", "saveDataSet", order = 10L),
    menu_item("file.save.script", "menu.file", "Script", "saveLog", order = 20L)
  ))
  before <- vapply(menu_registry_tree(registry)[[1L]]$children,
                   function(node) node$key, character(1))

  registry$items[["file.save.data"]]$order <- 99L
  after <- vapply(menu_registry_tree(registry)[[1L]]$children,
                  function(node) node$key, character(1))

  expect_setequal(unname(before), unname(after))
  expect_equal(menu_dom_id("file.save.data"),
               "menu_item_file_save_data")
})

test_that("the validator catches duplicate ids and unknown parents", {
  registry <- menu_registry_new()
  registry <- menu_registry_add(registry, list(
    menu_group("menu.file", label = "File"),
    menu_item("file.item", "menu.file", "One", "cmd1"),
    menu_item("file.item", "menu.file", "Two", "cmd2"),
    menu_item("orphan", "menu.missing", "Orphan", "cmd3")
  ))
  validation <- menu_registry_validate(registry)
  expect_false(validation$ok)
  expect_match(paste(validation$problems, collapse = " "), "Duplicate item")
  expect_match(paste(validation$problems, collapse = " "), "unknown parent")
})

test_that("the validator catches menu cycles", {
  registry <- menu_registry_new()
  registry <- menu_registry_add(registry, list(
    menu_group("menu.a", parent = "menu.b", label = "A"),
    menu_group("menu.b", parent = "menu.a", label = "B")
  ))
  validation <- menu_registry_validate(registry)
  expect_false(validation$ok)
  expect_match(paste(validation$problems, collapse = " "), "cycle")
})

test_that("the validator checks command ids when asked", {
  registry <- menu_registry_new()
  registry <- menu_registry_add(registry, list(
    menu_group("menu.file", label = "File"),
    menu_item("file.missing", "menu.file", "Missing", "notACommand")
  ))
  expect_true(menu_registry_validate(registry)$ok)
  validation <- menu_registry_validate(registry, commands = "saveLog")
  expect_false(validation$ok)
  expect_match(paste(validation$problems, collapse = " "), "notACommand")
})

test_that("the curated core registry keeps every legacy command", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  definitions <- read_rcmdr_menus()
  legacy <- definitions$command[definitions$type == "item" &
                                  definitions$kind == "command"]
  legacy <- unique(legacy[nzchar(legacy)])

  registry <- menu_registry_load(menu_registry_default_file(), module = "core")
  commands <- unique(menu_leaves(menu_registry_tree(registry))$command)
  expect_setequal(commands, legacy)
})

test_that("the core registry has the curated top-level groups", {
  registry <- menu_registry_load(menu_registry_default_file(), module = "core")
  tree <- menu_registry_tree(registry)
  labels <- vapply(tree, function(node) node$label, character(1))
  expect_equal(unname(labels[1:3]), c("File", "Edit", "Data"))
  expect_true(all(c("Transform", "Analyze", "Graphs", "Reports",
                    "Utilities", "Help") %in% labels))
})

test_that("the File Save submenu has stable semantic item ids", {
  registry <- menu_registry_load(menu_registry_default_file(), module = "core")
  leaves <- menu_leaves(menu_registry_tree(registry))
  save <- leaves[grepl("^File > Save", leaves$path), , drop = FALSE]
  expect_true(all(c("file.save.data", "file.save.script", "file.save.rmd",
                    "file.save.rnw", "file.save.workspace") %in%
                    save$item_id))
  expect_equal(save$command[save$item_id == "file.save.data"], "saveDataSet")
  expect_equal(save$command[save$item_id == "file.save.script"], "saveLog")
})

test_that("the registry survives a YAML round trip", {
  skip_if_not_installed("yaml")
  registry <- menu_registry_load(menu_registry_default_file(), module = "core")
  path <- tempfile(fileext = ".yml")
  on.exit(unlink(path), add = TRUE)
  writeLines(menu_registry_to_yaml(registry, module = "core"), path)
  reread <- menu_registry_load(path, module = "core")
  expect_equal(names(reread$groups), names(registry$groups))
  expect_equal(names(reread$items), names(registry$items))
  expect_true(menu_registry_validate(reread)$ok)
})

test_that("a module attaches to an existing core group without redeclaring it", {
  registry <- menu_registry_new()
  registry <- menu_registry_add(registry, list(
    menu_group("menu.file", label = "File", order = 10L),
    menu_item("core.item", "menu.file", "Core", "coreCommand")
  ))
  fragment <- list(
    module = "demo",
    groups = list(list(id = "menu.file", parent = "", label = "File")),
    items = list(list(id = "demo.item", parent = "menu.file",
                      label = "Demo", command = "demoCommand"))
  )
  merged <- menu_registry_merge(registry, fragment, module = "demo")
  expect_equal(length(merged$groups), 1L)
  expect_equal(merged$groups[["menu.file"]]$label, "File")
  expect_equal(length(merged$items), 2L)
  expect_equal(merged$items[["demo.item"]]$module, "demo")
})

test_that("removing a command only touches the declared source module", {
  registry <- menu_registry_new()
  registry <- menu_registry_add(registry, list(
    menu_group("menu.data", label = "Data"),
    menu_item("core.data.import", "menu.data", "Import", "readDataSet",
              module = "core"),
    menu_item("module.data.import", "menu.data", "Import",
              "readDataSet", module = "demo")
  ))
  registry$removes <- list(menu_remove("readDataSet", module = "demo",
                                       kind = "command",
                                       source_module = "core"))
  result <- menu_registry_apply_removes(registry)
  modules <- vapply(result$items, function(item) item$module %||% "",
                    character(1))
  expect_equal(unname(modules), "demo")
})
