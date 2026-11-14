test_that("filters restrict by topic type", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  results <- help_search("data", type = "tutorial")
  expect_true(all(results$type == "tutorial"))
})

test_that("filters restrict by category", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  results <- help_search("model", category = "models")
  expect_true(all(results$category == "models"))
})

test_that("the package filter separates core and plugin topics", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  core <- help_search("demo", package = "core")
  expect_equal(nrow(core), 0L)

  directory <- help_test_plugin_dir()
  help_register(list(
    version = 1,
    language = "en",
    categories = list(list(id = "plugins", title = "Plugins", order = 70)),
    topics = list(list(id = "demo-topic", file = "topics/demo-topic.md",
                       category = "plugins"))
  ), base_dir = directory, package = "RcmdrShinyPlugin.FilterDemo")

  plugin <- help_search("demo", package = "RcmdrShinyPlugin.FilterDemo")
  expect_equal(nrow(plugin), 1L)
  expect_equal(plugin$id[[1L]],
               "plugin:RcmdrShinyPlugin.FilterDemo:demo-topic")

  expect_equal(nrow(help_search("demo", package = "core")), 0L)
})

test_that("catalog filters match the search filters", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  catalog <- help_catalog(category = "models", type = "task")
  expect_true(all(catalog$category == "models"))
  expect_true(all(catalog$type == "task"))
  expect_gt(nrow(catalog), 0L)
})

test_that("filter choices expose all, core, types and categories", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  choices <- help_filter_choices()
  expect_equal(unname(choices$packages[1:2]), c("all", "core"))
  expect_true("all" %in% choices$types)
  expect_true("models" %in% choices$categories)
})
