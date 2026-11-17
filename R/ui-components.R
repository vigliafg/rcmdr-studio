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
#'
#' A single row of filters and actions.  `left` and `right` are the two ends of
#' the bar; unnamed children go in the middle.  Named, it is announced as a
#' toolbar; unnamed, it is a plain group of controls.
#' @keywords internal
toolbar <- function(..., left = NULL, right = NULL, label = NULL) {
  htmltools::tags$div(
    class = "rcmdr-toolbar d-flex gap-2 align-items-center flex-wrap",
    role = if (is.null(label)) NULL else "toolbar",
    `aria-label` = label,
    left,
    ...,
    if (!is.null(right)) {
      htmltools::tags$div(class = "ms-auto d-flex gap-2 align-items-center", right)
    }
  )
}

#' @keywords internal
studio_toolbar <- function(..., left = NULL, right = NULL, label = NULL) {
  toolbar(..., left = left, right = right, label = label)
}

#' A status badge
#'
#' A short label with a semantic colour.  The colour is never the only signal:
#' the label itself says what the state is, and the icon is decorative.
#'
#' @param label Visible text.
#' @param status One of `neutral`, `ok`, `warning`, `error`, `info`.
#' @param icon Optional icon name from [rcmdr_icon_paths()].
#' @param title Optional tooltip.
#' @return A `<span>` tag.
#' @keywords internal
badge <- function(label, status = c("neutral", "ok", "warning", "error", "info"),
                  icon = NULL, title = NULL) {
  status <- match.arg(status)
  htmltools::tags$span(
    class = paste0("rcmdr-badge rcmdr-badge-", status),
    title = title,
    if (!is.null(icon)) rcmdr_icon(icon, size = 12),
    label
  )
}

#' Dialog header
#'
#' The full `.modal-header` of a dialog: icon chip, title, category and the
#' close button.  It belongs to a modal skeleton built with
#' `.modal-dialog`/`.modal-content`; [shiny::modalDialog()] keeps its own
#' header, so this component is for the dialogs that build their chrome.
#' @keywords internal
modal_header <- function(title, category = NULL, icon = NULL, close = TRUE,
                         close_label = tr("Close"), id = NULL) {
  htmltools::tags$div(
    class = "modal-header rcmdr-modal-header",
    if (!is.null(icon)) {
      htmltools::tags$span(class = "rcmdr-dialog-icon", rcmdr_icon(icon, 18))
    },
    htmltools::tags$div(
      class = "rcmdr-modal-heading",
      htmltools::tags$h4(class = "modal-title", id = id, title),
      if (!is.null(category) && nzchar(category)) {
        htmltools::tags$div(class = "rcmdr-dialog-category", category)
      }
    ),
    if (isTRUE(close)) {
      htmltools::tags$button(
        type = "button", class = "btn-close",
        `data-bs-dismiss` = "modal", `aria-label` = close_label
      )
    }
  )
}

#' Dialog footer
#'
#' The actions of a dialog.  The primary action is passed separately and
#' lands on the right, the way the eye reads a form: decide, then apply.
#' @keywords internal
modal_footer <- function(..., primary = NULL) {
  htmltools::tags$div(
    class = "modal-footer rcmdr-modal-footer",
    ...,
    if (!is.null(primary)) {
      htmltools::tags$div(class = "rcmdr-modal-primary", primary)
    }
  )
}

#' Tab strip
#'
#' A row of small tabs for hand-built views: each tab sets `id` to its value,
#' the same contract the script document tabs already use.  The items are
#' toggle buttons (`aria-pressed`), not ARIA tabs, because the component does
#' not implement the arrow-key navigation the tab pattern promises.
#'
#' @param id Shiny input to update.
#' @param tabs Named character vector: label = value.
#' @param selected Value of the active tab.  Defaults to the first.
#' @param label Accessible name for the strip.
#' @return A `<div>` tag, or `NULL` when `tabs` is empty.
#' @keywords internal
tabs_strip <- function(id, tabs, selected = NULL, label = NULL) {
  if (length(tabs) == 0L) return(NULL)
  if (is.null(names(tabs)) || any(!nzchar(names(tabs)))) {
    stop("tabs_strip() needs a named character vector: label = value.",
         call. = FALSE)
  }
  values <- unname(as.character(tabs))
  invalid <- !grepl("^[A-Za-z0-9_.-]+$", c(id, values))
  if (any(invalid)) {
    stop("tabs_strip() ids and values must be simple identifiers.",
         call. = FALSE)
  }
  selected <- selected %||% values[[1L]]
  htmltools::tags$div(
    class = "rcmdr-tabs", role = "group", `aria-label` = label,
    lapply(seq_along(values), function(i) {
      active <- identical(values[[i]], selected)
      htmltools::tags$button(
        type = "button",
        class = paste0("rcmdr-tabs-item", if (active) " active" else ""),
        `aria-pressed` = if (active) "true" else "false",
        `data-value` = values[[i]],
        onclick = sprintf(
          "Shiny.setInputValue('%s', '%s', {priority: 'event'});",
          id, values[[i]]
        ),
        names(tabs)[[i]]
      )
    })
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

# Icons ---------------------------------------------------------------------
#
# Dependency-free 24x24 stroke icons, drawn with the current text colour.  The
# names describe the role, not the drawing, so the set can be replaced without
# touching the callers.

#' Icon paths
#'
#' Named list of SVG children, one entry per icon. Each path is a string of
#' `<path>`, `<line>`, `<rect>` or `<circle>` elements in a 24x24 viewBox.
#'
#' @return A named list of character strings.
#' @keywords internal
rcmdr_icon_paths <- function() {
  list(
    sliders = paste0(
      '<line x1="4" y1="7" x2="20" y2="7"/>',
      '<line x1="4" y1="12" x2="20" y2="12"/>',
      '<line x1="4" y1="17" x2="20" y2="17"/>',
      '<circle cx="9" cy="7" r="2.1" fill="currentColor" stroke="none"/>',
      '<circle cx="15" cy="12" r="2.1" fill="currentColor" stroke="none"/>',
      '<circle cx="8" cy="17" r="2.1" fill="currentColor" stroke="none"/>'
    ),
    output = paste0(
      '<rect x="3" y="4" width="18" height="16" rx="2.5"/>',
      '<path d="M7 9h5M7 13h10M7 17h4"/>'
    ),
    table = paste0(
      '<rect x="3" y="4" width="18" height="16" rx="2.5"/>',
      '<path d="M3 10h18M9.5 10v10"/>'
    ),
    doc = paste0(
      '<path d="M6 3.5h7.5L18 8v12.5H6z"/>',
      '<path d="M13.5 3.5V8H18"/>',
      '<path d="M9 12.5h6M9 16h6"/>'
    ),
    sun = paste0(
      '<circle cx="12" cy="12" r="4"/>',
      '<path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2',
      'M5.2 5.2l1.4 1.4M17.4 17.4l1.4 1.4',
      'M18.8 5.2l-1.4 1.4M6.6 17.4l-1.4 1.4"/>'
    ),
    moon = '<path d="M20.5 14.2A8.7 8.7 0 0 1 9.8 3.5a8.7 8.7 0 1 0 10.7 10.7z"/>',
    close = '<path d="M6 6l12 12M18 6L6 18"/>',
    help = paste0(
      '<circle cx="12" cy="12" r="9"/>',
      '<path d="M9.6 9.4a2.5 2.5 0 1 1 3.6 2.3c-.8.5-1.2 1-1.2 1.9"/>',
      '<circle cx="12" cy="17" r=".9" fill="currentColor" stroke="none"/>'
    ),
    code = '<path d="M8.5 6.5L3 12l5.5 5.5M15.5 6.5L21 12l-5.5 5.5"/>',
    chevron = '<path d="M6 9.5l6 6 6-6"/>',
    check = '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    copy = paste0(
      '<rect x="8" y="8" width="12" height="12" rx="2"/>',
      '<path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>'
    ),
    refresh = '<path d="M20 11a8 8 0 1 0-.6 4"/><path d="M20 4.5V11h-6"/>',
    search = '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4 4"/>',
    plus = '<path d="M12 5v14M5 12h14"/>',
    minus = '<path d="M5 12h14"/>'
  )
}

#' Inline SVG icon
#'
#' @param name One of `names(rcmdr_icon_paths())`.
#' @param size Square size in pixels.
#' @param title Accessible name. When `NULL` the icon is decorative: it is
#'   hidden from assistive technology and the surrounding text carries the
#'   meaning.
#' @return An `<svg>` tag.
#' @keywords internal
rcmdr_icon <- function(name, size = 16, title = NULL) {
  paths <- rcmdr_icon_paths()
  name <- match.arg(name, names(paths))
  size <- as.integer(size %||% 16L)[[1L]]
  htmltools::tags$svg(
    xmlns = "http://www.w3.org/2000/svg",
    class = "rcmdr-icon",
    width = size, height = size, viewBox = "0 0 24 24",
    fill = "none", stroke = "currentColor", `stroke-width` = 1.7,
    `stroke-linecap` = "round", `stroke-linejoin` = "round",
    focusable = "false",
    role = if (is.null(title)) NULL else "img",
    `aria-hidden` = if (is.null(title)) "true" else NULL,
    `aria-label` = title,
    htmltools::HTML(paths[[name]])
  )
}
