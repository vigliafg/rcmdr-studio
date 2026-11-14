test_that("common R errors map to the expected topics", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  expect_equal(error_help_topic("object 'Dataset' not found"), "data-import")
  expect_equal(error_help_topic("there is no package called 'car'"),
               "loadPackages")
  expect_equal(error_help_topic("could not find function \"foo\""),
               "loadPackages")
  expect_equal(
    error_help_topic("contrasts can be applied only to factors with 2 or more levels"),
    "converting-character-variables"
  )
  expect_equal(error_help_topic("NA/NaN/Inf in foreign function call"),
               "troubleshooting")
  expect_equal(error_help_topic("pandoc not found"), "document-authoring")
})

test_that("unknown errors do not produce a link", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  expect_null(error_help_topic("something completely unexpected"))
  expect_null(error_help_topic(""))
  expect_null(error_help_topic(NULL))
})

test_that("the suggestion includes the translated topic title", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  english <- error_help_suggestion("object 'x' not found", language = "en")
  expect_equal(english$id, "data-import")
  expect_match(english$title, "Import", ignore.case = TRUE)

  italian <- error_help_suggestion("object 'x' not found", language = "it")
  expect_equal(italian$id, "data-import")
  expect_match(italian$title, "Import", ignore.case = TRUE)
})

test_that("the error link carries the topic id", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  link <- error_help_link_ui("object 'x' not found")
  expect_equal(link$attribs$`data-help-topic`, "data-import")
  expect_match(as.character(link), "Open help")
  expect_null(error_help_link_ui("no known pattern"))
})
