# Workspace -------------------------------------------------------------------
#
# Studio mode no longer renders every view at once.  One workspace slot renders
# the selected view, and the view switcher keeps `input$main_tabs` as the
# navigation contract used by `view_ready()`, `state$show_tab()` and the tests.
# Classic mode keeps its tabsetPanel unchanged.

#' Views available in the Studio workspace
#' @keywords internal
workspace_view_ids <- function() {
  c("home", "workflows", "data", "charts", "report", "script", "console",
    "environment", "help")
}

#' Render one Studio view
#'
#' The UI is built only for the visible view; this is what keeps the workspace
#' light and what makes two slots possible without duplicate output ids.
#'
#' @param view View id from [workspace_view_ids()].
#' @param mode UI mode; only `"studio"` uses the workspace views.
#' @return UI, or a safe Home fallback.
#' @keywords internal
workspace_view_ui <- function(view, mode = "studio", state = NULL,
                             show_inspector = NULL, show_preview = NULL) {
  view <- main_view_id(view) %||% "home"
  if (identical(mode, "classic")) return(home_pane_ui())
  inspector <- if (!is.null(show_inspector)) {
    isTRUE(show_inspector)
  } else {
    is.null(state) || !workspace_panel_hidden(state, "data", "inspector")
  }
  preview <- if (!is.null(show_preview)) {
    isTRUE(show_preview)
  } else {
    is.null(state) || !workspace_panel_hidden(state, "charts", "preview")
  }
  switch(
    view,
    home = home_pane_ui(state),
    workflows = uiOutput("workflow_panel"),
    data = data_pane_ui("studio", show_inspector = inspector),
    charts = plots_pane_ui("studio", show_preview = preview),
    report = report_pane_ui("studio"),
    script = script_studio_ui(),
    console = console_workspace_ui(),
    environment = environment_workspace_ui(),
    help = help_center_ui(),
    home_pane_ui()
  )
}

#' The Studio view switcher
#'
#' The buttons are the only visible navigation; `input$main_tabs` is the stable
#' value the server and the lazy-view gates read.
#' @keywords internal
workspace_view_switcher <- function(view = "home") {
  view <- main_view_id(view) %||% "home"
  labels <- main_tab_labels("studio")
  ids <- workspace_view_ids()
  htmltools::tags$div(
    class = "rcmdr-view-switcher",
    role = "tablist",
    `aria-label` = tr("Workspace"),
    lapply(ids, function(id) {
      htmltools::tags$button(
        type = "button",
        class = c("rcmdr-view-tab", if (identical(id, view)) "active"),
        role = "tab",
        `aria-selected` = if (identical(id, view)) "true" else "false",
        `data-value` = id,
        `data-rcmdr-view` = id,
        onclick = sprintf("rcmdrSetView('%s'); return false;", id),
        labels[[id]] %||% id
      )
    })
  )
}

#' Header of one workspace slot
#'
#' With two slots on screen, a title bar in each says which role the slot has
#' and which view it shows.  It is a label, not a control: the view switcher
#' remains the only navigation.
#'
#' @param role `"primary"` or `"secondary"`.
#' @param view View id shown in the slot.
#' @return A `<div>` with the role, a separator and the view name.
#' @keywords internal
workspace_slot_header <- function(role = c("primary", "secondary"), view) {
  role <- match.arg(role)
  role_label <- if (identical(role, "primary")) tr("Primary") else tr("Secondary")
  htmltools::div(
    class = paste("rcmdr-slot-header", paste0("rcmdr-slot-header-", role)),
    htmltools::tags$span(class = "rcmdr-slot-role", role_label),
    htmltools::tags$span(class = "rcmdr-slot-sep", "\u00b7",
                         `aria-hidden` = "true"),
    htmltools::tags$span(class = "rcmdr-slot-view", main_tab_label(view))
  )
}

#' Accessible name of a workspace slot
#' @keywords internal
workspace_slot_label <- function(role = c("primary", "secondary"), view) {
  role <- match.arg(role)
  if (identical(role, "primary")) {
    sprintf(tr("Primary view: %s"), main_tab_label(view))
  } else {
    sprintf(tr("Secondary view: %s"), main_tab_label(view))
  }
}

#' The Studio workspace shell
#'
#' `workspace_layout` is rendered on the server because it may become a split
#' between two views.
#' @keywords internal
workspace_shell_ui <- function(view = "home") {
  htmltools::tagList(
    # The hidden text input keeps `input$main_tabs` alive from the first flush
    # and binds it before the first view switch.  It is not a visible control.
    htmltools::tags$div(
      class = "rcmdr-view-state",
      shiny::textInput("main_tabs", NULL, value = view)
    ),
    htmltools::div(
      class = "rcmdr-view-bar",
      uiOutput("workspace_switcher_ui", inline = TRUE),
      uiOutput("workspace_secondary_ui", inline = TRUE),
      uiOutput("workspace_panel_toggles_ui", inline = TRUE),
      uiOutput("workspace_focus_ui", inline = TRUE)
    ),
    htmltools::div(
      class = "rcmdr-context-bar",
      uiOutput("workspace_context_ui")
    ),
    uiOutput("workspace_layout")
  )
}

#' The context line of a Studio view
#'
#' "Dove sono" and "su cosa sto lavorando" in one line: the place, the data
#' set, the filter and the selection mode.  It is text, not a control: the
#' only interactive parts stay where they already are (the toolbar).
#'
#' @param state Application state.
#' @param view View id ("home", "data", "charts", ...).
#' @param frame Visible data frame, or `NULL`.
#' @param filter A list with `column`, `value` and `dates`, or `NULL`.
#' @param selection_mode `"rows"`, `"cells"` or `NULL`.
#' @return A `<div>` with the place and its chips.
#' @keywords internal
workspace_context_line <- function(state, view, frame = NULL,
                                  filter = NULL, selection_mode = NULL) {
  view <- main_view_id(view) %||% "home"
  labels <- main_tab_labels("studio")
  place <- paste(tr("Studio"), labels[[view]] %||% view, sep = " \u00b7 ")
  chips <- list()

  data_name <- active_dataset(state)
  if (!is.null(data_name) && nzchar(data_name)) {
    chips <- c(chips, list(context_chip(data_name, icon = "table")))
  }

  if (identical(view, "data")) {
    filter <- filter %||% list()
    view_state <- data_view_state(state, frame, filter)
    if (!is.null(view_state) && isTRUE(view_state$filtered)) {
      chips <- c(chips, list(context_chip(
        sprintf(
          tr("filter: %s \u00b7 %d of %d rows"),
          view_state$filter_label,
          view_state$visible_rows,
          view_state$total_rows
        ),
        icon = "funnel"
      )))
    }
    mode <- as.character(selection_mode %||% "")
    if (mode %in% c("rows", "cells")) {
      chips <- c(chips, list(context_chip(
        if (identical(mode, "cells")) tr("Cells") else tr("Rows"),
        tone = "accent"
      )))
    }
  }

  htmltools::div(
    class = "rcmdr-context-line",
    htmltools::tags$span(class = "rcmdr-context-place", place),
    chips
  )
}

#' Is a view panel explicitly hidden?
#' @keywords internal
workspace_panel_hidden <- function(state, view, panel) {
  entry <- (state$options$workspace_panels %||% list())[[view]]
  if (is.null(entry) || is.null(entry[[panel]])) return(FALSE)
  !isTRUE(entry[[panel]])
}

#' Store the visibility of one view panel
#' @keywords internal
workspace_panel_set <- function(state, view, panel, visible) {
  panels <- state$options$workspace_panels %||% list()
  entry <- panels[[view]] %||% list()
  entry[[panel]] <- isTRUE(visible)
  panels[[view]] <- entry
  state$options$workspace_panels <- panels
  invisible(entry)
}
