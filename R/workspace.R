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
    home = home_pane_ui(),
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
    uiOutput("workspace_layout")
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
