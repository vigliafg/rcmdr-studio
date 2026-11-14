# Shared UI components -------------------------------------------------------
#
# Small, dependency-free components used by the Studio shell.  They are kept
# deliberately thin: the visual identity lives in app_css(), the components
# wrap the markup and the Bootstrap classes.

#' A compact status pill
#' @keywords internal
status_pill <- function(label, status = c("ok", "warning", "error", "muted")) {
  status <- match.arg(status)
  htmltools::tags$span(class = paste0("rcmdr-status-pill rcmdr-status-", status),
                       label)
}

#' An empty-state block
#' @keywords internal
empty_state <- function(title, message = NULL, action = NULL) {
  htmltools::tags$div(
    class = "rcmdr-empty",
    htmltools::tags$div(class = "rcmdr-empty-title", title),
    if (!is.null(message)) htmltools::tags$p(class = "rcmdr-empty-text", message),
    action
  )
}

#' A metric card
#' @keywords internal
metric_card <- function(label, value, help = NULL) {
  htmltools::tags$div(
    class = "rcmdr-metric",
    htmltools::tags$div(class = "rcmdr-metric-label", label),
    htmltools::tags$div(class = "rcmdr-metric-value", value),
    if (!is.null(help)) htmltools::tags$div(class = "rcmdr-metric-help", help)
  )
}

#' A section card
#' @keywords internal
section_card <- function(title, body, collapsed = FALSE) {
  htmltools::tags$details(
    class = "rcmdr-section-card",
    open = if (isTRUE(collapsed)) NULL else "open",
    htmltools::tags$summary(title),
    htmltools::tags$div(class = "rcmdr-section-body", body)
  )
}

#' A read-only code preview
#' @keywords internal
code_preview <- function(code, language = "r", copy = TRUE) {
  code <- paste(code %||% "", collapse = "\n")
  htmltools::tags$div(
    class = "rcmdr-code-preview",
    htmltools::tags$pre(
      class = "rcmdr-code",
      htmltools::tags$code(`data-language` = language, code)
    ),
    if (isTRUE(copy) && nzchar(code)) {
      htmltools::tags$button(
        type = "button", class = "btn btn-sm btn-outline-secondary rcmdr-copy",
        `data-rcmdr-copy` = code,
        onclick = "rcmdrCopy(this.getAttribute('data-rcmdr-copy')); return false;",
        tr("Copy")
      )
    }
  )
}

#' A two-column split view
#' @keywords internal
split_view <- function(left, right, proportions = c(2, 3)) {
  proportions <- rep_len(proportions, 2L)
  total <- sum(proportions)
  widths <- round(12 * proportions / total)
  htmltools::tags$div(
    class = "row g-3 rcmdr-split",
    htmltools::tags$div(class = paste0("col-lg-", widths[[1L]]), left),
    htmltools::tags$div(class = paste0("col-lg-", widths[[2L]]), right)
  )
}

#' A studio toolbar
#' @keywords internal
studio_toolbar <- function(..., left = NULL, right = NULL) {
  htmltools::tags$div(
    class = "rcmdr-toolbar d-flex gap-2 align-items-center flex-wrap",
    left,
    ...,
    if (!is.null(right)) htmltools::tags$div(class = "ms-auto d-flex gap-2", right)
  )
}

#' A compact breadcrumb
#' @keywords internal
studio_breadcrumb <- function(parts) {
  parts <- parts[nzchar(parts)]
  if (length(parts) == 0L) return(NULL)
  htmltools::tags$nav(
    class = "rcmdr-breadcrumb", `aria-label` = tr("Breadcrumb"),
    htmltools::tags$ol(
      class = "breadcrumb mb-0",
      lapply(seq_along(parts), function(i) {
        htmltools::tags$li(
          class = paste("breadcrumb-item", if (i == length(parts)) "active"),
          parts[[i]]
        )
      })
    )
  )
}
