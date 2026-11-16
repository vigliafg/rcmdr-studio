# Quarto --------------------------------------------------------------------
#
# The .qmd download always works: it is a plain text transformation of the
# document the Report Studio already holds.  Rendering needs the Quarto CLI and
# is offered only when the CLI answers.

#' Status of the Quarto tool chain
#' @keywords internal
quarto_status <- function() {
  package <- requireNamespace("quarto", quietly = TRUE)
  cli <- if (package) {
    isTRUE(tryCatch(quarto::quarto_available(), error = function(e) FALSE))
  } else {
    FALSE
  }
  list(package = package, cli = cli, ready = package && cli)
}

#' Formats offered for a Quarto document
#' @keywords internal
quarto_formats <- function() {
  stats::setNames(
    c("html", "docx", "pdf", "gfm"),
    c("HTML", "Word (docx)", "PDF (typst)", "GitHub Markdown")
  )
}

#' YAML front matter of a Quarto document
#' @keywords internal
quarto_front_matter <- function(title = "", format = "html",
                                author = "", date = "", toc = FALSE) {
  format <- format %||% "html"
  if (!format %in% unname(quarto_formats())) format <- "html"
  lines <- c("---", sprintf("title: %s", chart_quote(title %||% "")))
  if (nzchar(author %||% "")) lines <- c(lines, sprintf("author: %s", author))
  if (nzchar(date %||% "")) lines <- c(lines, sprintf("date: %s", date))
  lines <- c(lines, sprintf("format: %s", format))
  if (isTRUE(toc)) lines <- c(lines, "toc: true")
  lines <- c(lines, "execute:", "  echo: true", "  warning: false",
             "  message: false", "---", "")
  paste(lines, collapse = "\n")
}

#' Code chunk with Quarto options
#'
#' @param code R code of the chunk.
#' @param label Chunk label, used for cross references (`fig-...`).
#' @param caption Figure caption.
#' @param width,height Figure size in inches.
#' @keywords internal
quarto_chunk <- function(code, label = NULL, caption = NULL,
                         width = NULL, height = NULL, echo = TRUE) {
  options <- c("```{r}")
  if (nzchar(label %||% "")) {
    options <- c(options, sprintf("#| label: %s", label))
  }
  if (nzchar(caption %||% "")) {
    options <- c(options, sprintf("#| fig-cap: %s", chart_quote(caption)))
  }
  if (!is.null(width)) {
    options <- c(options, sprintf("#| fig-width: %s",
                                  format(as.numeric(width), digits = 3)))
  }
  if (!is.null(height)) {
    options <- c(options, sprintf("#| fig-height: %s",
                                  format(as.numeric(height), digits = 3)))
  }
  options <- c(options, sprintf("#| echo: %s",
                                if (isTRUE(echo)) "true" else "false"))
  paste(c(options, code, "```"), collapse = "\n")
}

#' Quarto chunk for a chart specification
#' @param spec A chart specification.
#' @param index Used to build a unique label.
#' @keywords internal
quarto_chart_chunk <- function(spec, index = 1L) {
  label <- sprintf("fig-chart-%d", as.integer(index))
  caption <- (spec$labels %||% list())$title %||% ""
  if (!nzchar(caption)) caption <- chart_spec_title(spec)
  size <- spec$size %||% chart_size_defaults()
  quarto_chunk(
    chart_spec_command(spec),
    label = label,
    caption = caption,
    width = (size$width %||% 800) / 96,
    height = (size$height %||% 600) / 96
  )
}

#' Turn an R Markdown document into a Quarto document
#'
#' The YAML block is replaced with a Quarto one; the body is kept verbatim
#' because the chunk syntax is the same.
#' @keywords internal
quarto_document <- function(text, title = "", format = "html",
                            author = "", date = "", toc = FALSE) {
  text <- text %||% ""
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  lines <- sub("^\\s+", "", lines)
  body <- text
  if (length(lines) > 0L && identical(lines[[1L]], "---")) {
    end <- which(grepl("^---$", lines) & seq_along(lines) > 1L)[1L]
    if (!is.na(end) && end < length(lines)) {
      body <- paste(lines[(end + 1L):length(lines)], collapse = "\n")
    }
  }
  paste(quarto_front_matter(title = title, format = format, author = author,
                            date = date, toc = toc),
        body, sep = "\n")
}

#' Render a Quarto document
#'
#' Only called when the CLI is available; the caller decides whether to offer
#' the action.
#' @keywords internal
quarto_render <- function(path, output_format = "html", timeout = 180) {
  status <- quarto_status()
  if (!isTRUE(status$ready)) {
    return(list(ok = FALSE, error = tr(
      "Quarto is not available. Install the quarto R package and the Quarto CLI."
    )))
  }
  old <- options(quarto.timeout = timeout)
  on.exit(options(old), add = TRUE)
  result <- tryCatch(
    quarto::quarto_render(input = path, output_format = output_format,
                          execute = TRUE),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    return(list(ok = FALSE, error = conditionMessage(result)))
  }
  output <- sub("\\.qmd$", paste0(".", output_format), path)
  list(ok = TRUE, output = output)
}
