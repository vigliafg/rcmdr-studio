# Keyboard shortcuts ---------------------------------------------------------
#
# Shortcuts are navigation helpers.  They click the same buttons or links that
# the interface already exposes, so they never bypass the dialog runtime or the
# command engine.

#' Shortcut definitions
#'
#' @return A data frame with `keys`, `action` and `description`.
#' @keywords internal
shortcut_definitions <- function() {
  data.frame(
    keys = c(
      "Ctrl+K", "Ctrl+Shift+P", "Ctrl+S", "Ctrl+Shift+S", "Ctrl+Enter",
      "Ctrl+Shift+Enter", "Alt+1 ... Alt+9", "F1", "Ctrl+/", "Esc"
    ),
    action = c(
      "palette", "palette", "save", "save_as", "run_selection", "run_all",
      "tab", "help", "shortcuts", "close"
    ),
    description = c(
      tr("Open the command palette"),
      tr("Open the command palette"),
      tr("Save the current document"),
      tr("Save the current document as"),
      tr("Run the selection or the current chunk"),
      tr("Run the whole script"),
      tr("Switch to the nth Studio tab"),
      tr("Open Help"),
      tr("Show this shortcut list"),
      tr("Close the active dialog or palette")
    ),
    stringsAsFactors = FALSE
  )
}

#' Shortcut table
#' @keywords internal
shortcuts_table_ui <- function() {
  definitions <- shortcut_definitions()
  rows <- lapply(seq_len(nrow(definitions)), function(i) {
    htmltools::tags$tr(
      htmltools::tags$td(htmltools::tags$kbd(definitions$keys[[i]])),
      htmltools::tags$td(definitions$description[[i]])
    )
  })
  htmltools::tags$table(
    class = "table table-sm rcmdr-shortcuts-table",
    htmltools::tags$thead(
      htmltools::tags$tr(
        htmltools::tags$th(tr("Keys")),
        htmltools::tags$th(tr("Action"))
      )
    ),
    htmltools::tags$tbody(rows)
  )
}

#' Shortcut modal
#' @keywords internal
shortcuts_modal <- function() {
  modal_shell(
    tr("Keyboard shortcuts"),
    category = tr("Help"),
    icon = "help",
    size = "m",
    easyClose = TRUE,
    close = TRUE,
    htmltools::div(
      class = "rcmdr-shortcuts",
      shortcuts_table_ui(),
      note(tr("Shortcuts are also available from the Help tab and the Home card."))
    ),
    primary = modal_dismiss_button()
  )
}
