test_that("the index records documents and weighted terms", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  index <- help_index_build()
  expect_true(all(c("terms", "docs", "titles", "title_tokens", "revision") %in%
                    names(index)))
  expect_gt(nrow(index$docs), 10L)
  expect_true("numerical-summaries" %in% index$docs$id)

  title <- index$terms[["numerical"]][["numerical-summaries"]]
  body <- index$terms[["numeric"]][["numerical-summaries"]]
  expect_gt(title, body)
  expect_equal(index$titles[["numerical-summaries"]], "Numerical summaries")
})

test_that("the cached index is reused until the registry changes", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)

  first <- help_index_cached()
  second <- help_index_cached()
  expect_identical(first, second)

  directory <- help_test_plugin_dir()
  help_register(list(
    version = 1,
    language = "en",
    categories = list(list(id = "plugins", title = "Plugins", order = 70)),
    topics = list(list(id = "demo-topic", file = "topics/demo-topic.md",
                       category = "plugins"))
  ), base_dir = directory, package = "RcmdrShinyPlugin.IndexDemo")

  third <- help_index_cached()
  expect_false(identical(first$revision, third$revision))
  expect_true("plugin:RcmdrShinyPlugin.IndexDemo:demo-topic" %in% third$docs$id)
})

test_that("the table of contents follows Markdown headings", {
  toc <- help_toc("# Title\n\n## First\n\n### Detail\n\n## First")
  expect_equal(toc$level, c(1L, 2L, 3L, 2L))
  expect_equal(toc$title, c("Title", "First", "Detail", "First"))
  expect_equal(anyDuplicated(toc$anchor), 0L)
})

test_that("headings inside code fences are ignored", {
  toc <- help_toc("# Title\n\n```r\n## not a heading\n```\n\n## Real")
  expect_equal(toc$title, c("Title", "Real"))
})

test_that("anchors are inserted before rendering", {
  markdown <- "# Title\n\n## First section\n\nText."
  toc <- help_toc(markdown)
  anchored <- help_markdown_with_anchors(markdown, toc)
  expect_match(anchored, "<a id=\"rcmdr-help-first-section-2\"></a>")
})

test_that("snippet highlighting escapes HTML and marks the query", {
  html <- help_snippet_highlight("Use summary() <unsafe>", c("summary"))
  expect_match(html, "<mark>summary</mark>")
  expect_false(grepl("<unsafe>", html, fixed = TRUE))
})
