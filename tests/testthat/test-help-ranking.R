test_that("an exact title match ranks first", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  results <- help_search("numerical summaries")
  expect_equal(results$id[[1L]], "numerical-summaries")
})

test_that("title matches outrank body-only matches", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  results <- help_search("boxplot")
  expect_gt(nrow(results), 0L)
  expect_true(results$score[[1L]] >= results$score[[nrow(results)]])
})

test_that("aliases and command names are searchable", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  expect_true("numerical-summaries" %in% help_search("numSummary")$id)
  expect_true("linear-model" %in% help_search("lm")$id)
})

test_that("prefix search completes a word but does not over-match", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  expect_equal(help_search("summar")$id[[1L]], "numerical-summaries")
  expect_false("logistic-distribution" %in%
                 help_search("logistic regression", limit = 1L)$id)
})

test_that("the limit keeps the best results and scores descend", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  results <- help_search("model", limit = 5L)
  expect_lte(nrow(results), 5L)
  expect_true(all(diff(results$score) <= 0))
})

test_that("search results carry the snippet, type and language", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  result <- help_search("logistic regression", limit = 1L)
  expect_true(all(c("snippet", "snippet_html", "type", "language") %in%
                    names(result)))
  expect_match(result$snippet_html[[1L]], "<mark>")
})
