# Quarto --------------------------------------------------------------------

test_that("quarto status reports the package and the CLI separately", {
  status <- quarto_status()
  expect_named(status, c("package", "cli", "ready"))
  expect_equal(status$package, requireNamespace("quarto", quietly = TRUE))
  expect_equal(status$ready, status$package && status$cli)
})

test_that("the Quarto front matter carries the chosen format", {
  front <- quarto_front_matter("Report", format = "docx", author = "A",
                               date = "2026-01-01", toc = TRUE)
  expect_match(front, "^---", perl = TRUE)
  expect_match(front, 'title: "Report"', fixed = TRUE)
  expect_match(front, "format: docx", fixed = TRUE)
  expect_match(front, "author: A", fixed = TRUE)
  expect_match(front, "toc: true", fixed = TRUE)
  expect_match(front, "(?m)^---$", perl = TRUE)
  expect_equal(quarto_front_matter("x", format = "nope"),
               quarto_front_matter("x", format = "html"))
})

test_that("chunks carry labels, captions and sizes", {
  chunk <- quarto_chunk("plot(1)", label = "fig-a", caption = "A plot",
                        width = 8, height = 6)
  expect_match(chunk, "```{r}", fixed = TRUE)
  expect_match(chunk, "#| label: fig-a", fixed = TRUE)
  expect_match(chunk, '#| fig-cap: "A plot"', fixed = TRUE)
  expect_match(chunk, "#| fig-width: 8", fixed = TRUE)
  expect_match(chunk, "#| echo: true", fixed = TRUE)
  expect_match(chunk, "plot(1)", fixed = TRUE)
})

test_that("a chart becomes a labelled Quarto chunk", {
  spec <- chart_spec("histogram", "D", list(x = "y"),
                     labels = list(title = "Distribution"))
  chunk <- quarto_chart_chunk(spec, index = 3L)
  expect_match(chunk, "#| label: fig-chart-3", fixed = TRUE)
  expect_match(chunk, '#| fig-cap: "Distribution"', fixed = TRUE)
  expect_match(chunk, "ggplot2::ggplot", fixed = TRUE)
})

test_that("an R Markdown document is converted to Quarto", {
  text <- paste(
    "---", "title: Old", "output: html_document", "---", "",
    "## Heading", "", "```{r}", "1 + 1", "```", sep = "\n"
  )
  converted <- quarto_document(text, title = "New", format = "html")
  expect_match(converted, 'title: "New"', fixed = TRUE)
  expect_match(converted, "format: html", fixed = TRUE)
  expect_false(grepl("output: html_document", converted, fixed = TRUE))
  expect_match(converted, "## Heading", fixed = TRUE)
  expect_match(converted, "1 + 1", fixed = TRUE)
})

test_that("rendering is refused without the Quarto tool chain", {
  skip_if(isTRUE(quarto_status()$ready), "Quarto is available")
  result <- quarto_render(tempfile(fileext = ".qmd"))
  expect_false(result$ok)
  expect_match(result$error, "Quarto is not available")
})
