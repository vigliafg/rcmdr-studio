# Optional chart extensions -------------------------------------------------
#
# ggstatsplot, patchwork, hrbrthemes and Quarto are optional.  The Studio
# detects them at runtime, hides what is not installed and never fails when an
# extension is missing: every helper below returns a plain value and the UI
# layer decides what to show.

#' Optional extensions known to the Chart Studio
#'
#' Each entry records the role of the package and the packages it needs.  The
#' registry is a plain list so that the same information feeds the type
#' registry, the models gallery and the options panel.
#' @keywords internal
chart_ext_registry <- function() {
  list(
    patchwork = list(
      label = "patchwork",
      role = tr("Chart composition"),
      description = tr(
        "Combines several charts into a single figure with shared tags and legends."
      ),
      packages = "patchwork",
      cli = FALSE
    ),
    ggstatsplot = list(
      label = "ggstatsplot",
      role = tr("Statistical charts"),
      description = tr(
        "Charts that carry the result of the statistical test in the subtitle."
      ),
      packages = "ggstatsplot",
      cli = FALSE
    ),
    hrbrthemes = list(
      label = "hrbrthemes",
      role = tr("Typography and themes"),
      description = tr(
        "Editorial themes and axis formats; missing fonts fall back to the system sans."
      ),
      packages = "hrbrthemes",
      cli = FALSE
    ),
    quarto = list(
      label = "Quarto",
      role = tr("Publishing"),
      description = tr(
        "Writes reproducible .qmd documents and renders them when the Quarto CLI is available."
      ),
      packages = "quarto",
      cli = TRUE
    )
  )
}

#' Packages that back the optional extensions
#' @keywords internal
chart_ext_packages <- function() {
  unique(unlist(lapply(chart_ext_registry(), function(entry) entry$packages),
                 use.names = FALSE))
}

#' Whether optional packages are installed
#'
#' `NULL` or an empty vector means "nothing extra needed" and returns `TRUE`.
#' @param packages Character vector of package names.
#' @keywords internal
chart_ext_available <- function(packages = NULL) {
  packages <- as.character(packages %||% character())
  packages <- packages[!is.na(packages) & nzchar(packages)]
  if (length(packages) == 0L) return(TRUE)
  all(vapply(packages, function(package) {
    requireNamespace(package, quietly = TRUE)
  }, logical(1)))
}

#' Version of an installed package
#' @keywords internal
chart_ext_version <- function(package) {
  if (!chart_ext_available(package)) return(NA_character_)
  as.character(utils::packageVersion(package))
}

#' Whether the Quarto command line tool is available
#' @keywords internal
quarto_cli_available <- function() {
  if (!requireNamespace("quarto", quietly = TRUE)) return(FALSE)
  isTRUE(tryCatch(quarto::quarto_available(), error = function(e) FALSE))
}

#' Status of every optional extension
#'
#' @return A data frame with one row per extension.
#' @keywords internal
chart_ext_status <- function() {
  registry <- chart_ext_registry()
  rows <- lapply(names(registry), function(id) {
    entry <- registry[[id]]
    installed <- chart_ext_available(entry$packages)
    cli_ok <- if (isTRUE(entry$cli)) quarto_cli_available() else TRUE
    version <- if (installed) {
      paste(vapply(entry$packages, chart_ext_version, character(1)),
            collapse = ", ")
    } else {
      ""
    }
    data.frame(
      id = id,
      label = entry$label,
      role = entry$role,
      installed = installed,
      version = version,
      ready = installed && cli_ok,
      cli = isTRUE(entry$cli),
      cli_available = cli_ok,
      packages = paste(entry$packages, collapse = ", "),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Packages missing for a set of requirements
#' @keywords internal
chart_ext_missing <- function(packages = NULL) {
  packages <- as.character(packages %||% character())
  packages <- packages[!is.na(packages) & nzchar(packages)]
  Filter(function(package) !requireNamespace(package, quietly = TRUE), packages)
}

#' Message explaining how to enable an extension
#' @keywords internal
chart_ext_hint <- function(packages = NULL, cli = FALSE) {
  packages <- as.character(packages %||% character())
  packages <- packages[!is.na(packages) & nzchar(packages)]
  parts <- character()
  if (length(packages) > 0L) {
    parts <- c(parts, sprintf(
      "install.packages(c(%s))",
      paste(sprintf("\"%s\"", packages), collapse = ", ")
    ))
  }
  if (isTRUE(cli)) parts <- c(parts, "https://quarto.org/docs/get-started/")
  paste(parts, collapse = " - ")
}

#' Badges for the extensions panel
#' @keywords internal
chart_ext_badges <- function() {
  status <- chart_ext_status()
  lapply(seq_len(nrow(status)), function(i) {
    row <- status[i, , drop = FALSE]
    installed <- isTRUE(row$installed)
    if (installed && isTRUE(row$ready)) {
      badge <- htmltools::span(class = "badge bg-success", tr("ready"))
    } else if (installed) {
      badge <- htmltools::span(class = "badge bg-warning text-dark",
                               tr("CLI missing"))
    } else {
      badge <- htmltools::span(class = "badge bg-secondary",
                               tr("not installed"))
    }
    htmltools::div(
      class = "rcmdr-checklist-item",
      htmltools::div(
        class = "flex-grow-1",
        htmltools::tags$strong(row$label),
        htmltools::tags$span(class = "text-muted small",
                             paste0(" - ", row$role)),
        htmltools::tags$p(class = "mb-0 small",
                          registry_description(row$id)),
        if (!isTRUE(row$ready)) {
          htmltools::tags$code(
            class = "small",
            chart_ext_hint(strsplit(row$packages, ", ", fixed = TRUE)[[1L]],
                           cli = isTRUE(row$cli) && !isTRUE(row$cli_available))
          )
        }
      ),
      badge
    )
  })
}

registry_description <- function(id) {
  entry <- chart_ext_registry()[[id]]
  entry$description %||% ""
}

#' Options panel section listing the optional extensions
#' @keywords internal
chart_ext_ui <- function() {
  htmltools::tagList(
    htmltools::tags$h6(tr("Optional extensions")),
    help_text(tr(
      "The Studio detects these packages at run time. Charts that need a missing package are hidden instead of failing."
    )),
    htmltools::div(class = "rcmdr-checklist-list", chart_ext_badges())
  )
}
