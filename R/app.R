# Shiny application ---------------------------------------------------------

# Assets ---------------------------------------------------------------
#
# CSS and JavaScript live in inst/www and are inlined as text.  That keeps the
# application identical under pkgload::load_all() and from an installed
# package, with no addResourcePath() and no URL that could break.

app_asset <- function(...) {
  path <- system.file("www", ..., package = "RcmdrShiny")
  if (!nzchar(path)) {
    # Working copy loaded without pkgload: fall back to the source tree.
    path <- file.path("inst", "www", ...)
  }
  if (!file.exists(path)) {
    stop("Missing application asset: ", path, call. = FALSE)
  }
  path
}

app_asset_text <- function(...) {
  paste(
    readLines(app_asset(...), warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

app_css_files <- function() {
  c(
    "00-tokens.css",
    "10-shell.css",
    "15-bootstrap.css",
    "20-components.css",
    "30-forms.css",
    "40-dialogs.css",
    "50-widgets.css",
    "55-shinywidgets.css",
    "60-views.css",
    "70-refine.css"
  )
}

app_css <- function() {
  htmltools::HTML(paste(
    vapply(
      app_css_files(),
      function(file) app_asset_text("css", file),
      character(1)
    ),
    collapse = "\n"
  ))
}


app_js_files <- function() {
  c(
    "00-boot.js",
    "10-dialogs.js",
    "20-theme.js",
    "30-script.js",
    "40-interactions.js",
    "50-menubar.js",
    "60-help.js",
    "65-data-selection.js",
    "70-keyboard.js"
  )
}

app_js <- function(lang = current_language()) {
  body <- vapply(
    app_js_files(),
    function(file) app_asset_text("js", file),
    character(1)
  )
  htmltools::HTML(paste0(
    "document.documentElement.lang = '", lang, "';\n",
    paste(body, collapse = "\n")
  ))
}

script_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      selectInput(
        "document_mode", NULL,
        choices = stats::setNames(
          c("r", "rmd", "rnw"),
          c(tr("R script"), tr("R Markdown"), tr("knitr"))
        ),
        selected = "r", width = "140px"
      ),
      actionButton("document_new", tr("New"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_open", tr("Open"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_save", tr("Save"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_save_as", tr("Save as"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_section", tr("Section"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_chunk", tr("Chunk"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_remove_block", tr("Remove block"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("document_remove_section", tr("Remove section"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("document_knit", tr("Knit"), class = "btn-sm btn-primary")
    ),
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      actionButton("run_selection", tr("Run selection"), class = "btn-sm btn-primary"),
      actionButton("run_all", tr("Run all"), class = "btn-sm btn-outline-primary"),
      actionButton("run_chunk", tr("Run chunk"), class = "btn-sm btn-outline-primary",
                   onclick = "rcmdrRunChunk();"),
      actionButton("clear_script", tr("Clear"), class = "btn-sm btn-outline-secondary"),
      downloadButton("download_script", tr("Download"),
                     class = "btn-sm btn-outline-secondary"),
      switch_input("auto_append", tr("Append generated commands"), value = TRUE)
    ),
    uiOutput("script_editor_ui")
  )
}

classic_report_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2 flex-wrap",
      downloadButton("download_knit", tr("Download report"),
                     class = "btn-sm btn-outline-secondary"),
      actionButton("knit_refresh", tr("Refresh"), class = "btn-sm btn-outline-secondary")
    ),
    uiOutput("report_pane")
  )
}

report_pane_ui <- function(mode = "studio") {
  if (identical(mode, "classic")) {
    classic_report_pane_ui()
  } else {
    report_studio_ui()
  }
}

output_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2",
      downloadButton("download_output", tr("Download output"),
                     class = "btn-sm btn-outline-secondary"),
      actionButton("clear_output", tr("Clear"), class = "btn-sm btn-outline-secondary")
    ),
    verbatimTextOutput("output_text")
  )
}

messages_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2",
      actionButton("clear_messages", tr("Clear"), class = "btn-sm btn-outline-secondary")
    ),
    verbatimTextOutput("messages_text")
  )
}

classic_data_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      radioButtons(
        "data_mode", NULL,
        choices = stats::setNames(c("view", "edit"), c(tr("View"), tr("Edit"))),
        inline = TRUE
      ),
      actionButton("data_refresh", tr("Refresh"), class = "btn-sm btn-outline-secondary"),
      actionButton("data_apply", tr("Apply changes"), class = "btn-sm btn-primary"),
      downloadButton("download_dataset", tr("Download CSV"),
                     class = "btn-sm btn-outline-secondary"),
      downloadButton("download_dataset_rdata", tr("Save .RData"),
                     class = "btn-sm btn-outline-secondary"),
      uiOutput("data_info", inline = TRUE)
    ),
    uiOutput("data_pane")
  )
}

data_pane_ui <- function(mode = "studio", show_inspector = TRUE) {
  if (identical(mode, "classic")) {
    classic_data_pane_ui()
  } else {
    data_studio_ui(show_inspector = show_inspector)
  }
}

classic_plots_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2 flex-wrap",
      downloadButton("download_plot_png", tr("Save PNG"),
                     class = "btn-sm btn-outline-secondary"),
      downloadButton("download_plot_pdf", tr("Save PDF"),
                     class = "btn-sm btn-outline-secondary"),
      if (requireNamespace("rgl", quietly = TRUE)) {
        downloadButton("download_rgl", tr("Save 3D PNG"),
                       class = "btn-sm btn-outline-secondary")
      }
    ),
    uiOutput("plotly_pane"),
    uiOutput("plot_gallery"),
    uiOutput("plot_header"),
    htmltools::div(
      class = "rcmdr-plot",
      imageOutput("plot_image", height = "auto")
    ),
    uiOutput("rgl_pane")
  )
}

plots_pane_ui <- function(mode = "studio", show_preview = TRUE) {
  if (identical(mode, "classic")) {
    classic_plots_pane_ui()
  } else {
    chart_studio_ui(show_preview = show_preview)
  }
}

home_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "rcmdr-home-hero",
      htmltools::tags$h2(tr("RcmdrShiny Studio")),
      htmltools::tags$p(tr(
        "A browser-native statistical workbench inspired by the R Commander. Every action still produces reproducible R code."
      )),
      action_row(
        actionButton("home_import", tr("Import data"), class = "btn-light btn-sm"),
        actionButton("home_report", tr("New report"), class = "btn-light btn-sm"),
        actionButton("home_workflows", tr("Guided workflows"),
                     class = "btn-light btn-sm"),
        actionButton("home_palette", tr("Command palette"), class = "btn-light btn-sm"),
        actionButton("home_help", tr("Getting started"), class = "btn-light btn-sm")
      )
    ),
    htmltools::div(
      class = "rcmdr-home-grid",
      uiOutput("home_continue"),
      uiOutput("home_projects"),
      uiOutput("home_checklist"),
      uiOutput("home_recent"),
      uiOutput("home_health"),
      htmltools::div(
        class = "rcmdr-home-card",
        card_head(htmltools::tags$h5(tr("Keyboard"))),
        note(tr("Ctrl+K opens the command palette.")),
        note(tr("Ctrl+Enter runs the selection or the current chunk.")),
        note(tr("Ctrl+S saves the current document.")),
        action_row(
          actionButton("home_shortcuts", tr("All keyboard shortcuts"),
                       class = "btn-sm btn-outline-secondary")
        )
      )
    )
  )
}

console_workspace_ui <- function() {
  tabsetPanel(
    id = "console_tabs",
    tabPanel(tr("Console"), console_studio_ui(), value = "console"),
    tabPanel(tr("Output"), output_studio_ui(), value = "output"),
    tabPanel(tr("Messages"), messages_studio_ui(), value = "messages"),
    tabPanel(tr("History"), history_pane_ui(), value = "history")
  )
}

main_tabs_ui <- function(mode = "studio", view = "home") {
  if (identical(mode, "classic")) {
    return(tabsetPanel(
      id = "main_tabs",
      tabPanel(tr("Script"), script_pane_ui(), value = "script"),
      tabPanel(tr("Output"), output_pane_ui(), value = "console"),
      tabPanel(tr("Messages"), messages_pane_ui(), value = "messages"),
      tabPanel(tr("Plots"), plots_pane_ui("classic"), value = "charts"),
      tabPanel(tr("Report"), report_pane_ui("classic"), value = "report"),
      tabPanel(tr("Data"), data_pane_ui("classic"), value = "data"),
      tabPanel(tr("Environment"), uiOutput("environment_pane"),
               value = "environment"),
      tabPanel(tr("Help"), help_center_ui(), value = "help")
    ))
  }
  # Studio renders one view at a time.  `input$main_tabs` stays the contract,
  # but there is no tabsetPanel holding every view in the DOM.
  workspace_shell_ui(view)
}

#' Stable identifiers for the main views
#'
#' The tabs are windows onto the same state, their labels are translated and
#' the Studio and Classic modes show different windows. Navigation therefore
#' uses a stable view id: renaming a tab or switching language can never break
#' `state$show_tab()` silently.
#'
#' @return A named character vector mapping labels to view ids.
#' @keywords internal
main_view_aliases <- function() {
  c(
    "Home" = "home",
    "Workflows" = "workflows",
    "Data" = "data",
    "Data Studio" = "data",
    "Charts" = "charts",
    "Chart Studio" = "charts",
    "Plots" = "charts",
    "Report" = "report",
    "Report Studio" = "report",
    "Script" = "script",
    "Console" = "console",
    "Output (Console)" = "console",
    "Output" = "output",
    "Messages" = "messages",
    "History" = "history",
    "Environment" = "environment",
    "Help" = "help",
    "Help centre" = "help",
    "Help center" = "help"
  )
}

#' @keywords internal
main_view_ids <- function() unique(unname(main_view_aliases()))

#' Resolve a view label or id to a view id
#'
#' @param x A view id ("data"), an English label ("Data Studio") or a
#'   translated label ("Studio dati").
#' @return A single view id, or `NULL` when `x` is not a known view.
#' @keywords internal
main_view_id <- function(x) {
  if (is.null(x) || length(x) == 0L) return(NULL)
  value <- trimws(as.character(x[[1L]]))
  if (!nzchar(value)) return(NULL)
  if (value %in% main_view_ids()) return(value)
  aliases <- main_view_aliases()
  if (value %in% names(aliases)) return(unname(aliases[[value]]))
  for (msgid in names(aliases)) {
    if (identical(value, tr(msgid))) return(unname(aliases[[msgid]]))
  }
  NULL
}

#' Where a view id lives in the current tab layout
#'
#' Output, messages and history are panes of the Console workspace in Studio
#' mode but real tabs in Classic mode.
#'
#' @param x View id or label.
#' @param mode UI mode, "studio" or "classic".
#' @return `list(tab = <tab value>, sub = <sub-tab value or NULL>)`, or `NULL`.
#' @keywords internal
main_tab_target <- function(x, mode = "studio") {
  view <- main_view_id(x)
  if (is.null(view)) return(NULL)
  if (!identical(mode, "classic")) {
    if (identical(view, "output")) return(list(tab = "console", sub = "output"))
    if (identical(view, "messages")) {
      return(list(tab = "console", sub = "messages"))
    }
    if (identical(view, "history")) {
      return(list(tab = "console", sub = "history"))
    }
    return(list(tab = view))
  }
  if (view %in% c("output", "history")) return(list(tab = "console"))
  list(tab = view)
}

#' Labels of the main views in the current mode and language
#'
#' @param mode UI mode, "studio" or "classic".
#' @return A named character vector of labels, keyed by view id.
#' @keywords internal
main_tab_labels <- function(mode = "studio") {
  if (identical(mode, "classic")) {
    return(c(
      home = tr("Home"),
      workflows = tr("Workflows"),
      data = tr("Data"),
      charts = tr("Plots"),
      report = tr("Report"),
      script = tr("Script"),
      console = tr("Output"),
      messages = tr("Messages"),
      environment = tr("Environment"),
      help = tr("Help")
    ))
  }
  c(
    home = tr("Home"),
    workflows = tr("Workflows"),
    data = tr("Data Studio"),
    charts = tr("Chart Studio"),
    report = tr("Report Studio"),
    script = tr("Script"),
    console = tr("Output (Console)"),
    messages = tr("Messages"),
    environment = tr("Environment"),
    help = tr("Help centre")
  )
}

#' @keywords internal
main_tab_label <- function(view, mode = "studio") {
  labels <- main_tab_labels(mode)
  value <- labels[[as.character(view)[[1L]]]]
  if (is.null(value)) as.character(view)[[1L]] else unname(value)
}

#' @keywords internal
main_subtab_labels <- function() {
  c(console = tr("Console"), output = tr("Output"),
    messages = tr("Messages"), history = tr("History"))
}

#' The "where did my result go" bar
#'
#' A classic interface opened the result window after a command; this one keeps
#' the user where they are, so it says where the result landed and offers to
#' open it.
#'
#' @param info A `list(tab = , sub = , command = )` recorded by
#'   `apply_dialog_result()`, or `NULL`.
#' @param mode UI mode, "studio" or "classic".
#' @param auto Whether the auto-switch preference is on.
#' @return UI, or `NULL` when there is no result to show.
#' @keywords internal
result_hint_ui <- function(info, mode = "studio", auto = FALSE) {
  if (is.null(info)) return(NULL)
  target_label <- main_tab_label(info$tab, mode)
  sub_labels <- main_subtab_labels()
  sub_label <- if (!is.null(info$sub)) {
    unname(sub_labels[[info$sub]] %||% info$sub)
  } else {
    NULL
  }
  path <- info$command %||% character()
  command_label <- if (length(path) > 0L) {
    paste(vapply(path, menu_label, character(1)), collapse = " \u203a ")
  } else {
    NULL
  }
  htmltools::div(
    class = "rcmdr-result-hint",
    role = "status",
    `aria-live` = "polite",
    htmltools::div(
      class = "rcmdr-result-hint-text",
      if (!is.null(command_label)) htmltools::tags$strong(command_label),
      " \u2192 ",
      tr("Result in:"),
      " ",
      htmltools::tags$strong(
        paste(c(target_label, sub_label), collapse = " \u25b8 ")
      )
    ),
    htmltools::div(
      class = "d-flex align-items-center gap-2 flex-wrap",
      actionButton("result_hint_open", tr("Show result"),
                   class = "btn-sm btn-primary"),
      switch_input("result_hint_auto", tr("Open automatically"),
                   value = isTRUE(auto)),
      actionButton("result_hint_close", tr("Dismiss"),
                   class = "btn-sm btn-outline-secondary")
    )
  )
}

app_topbar_ui <- function(theme = "system") {
  languages <- available_languages()
  current <- current_language()
  if (!current %in% languages) languages <- c(current, languages)
  htmltools::div(
    class = "rcmdr-topbar",
    role = "banner",
    htmltools::div(
      class = "rcmdr-brand",
      htmltools::tags$span(class = "rcmdr-brand-mark",
                           rcmdr_icon("sliders", 18)),
      htmltools::tags$strong(tr("RcmdrShiny Studio"),
                             class = "rcmdr-brand-title"),
      htmltools::tags$small(tr("Inspired by R Commander"),
                            class = "rcmdr-brand-sub")
    ),
    htmltools::div(
      class = "rcmdr-topbar-controls",
      htmltools::tags$button(
        type = "button",
        class = "rcmdr-topbar-icon",
        `data-rcmdr-sidebar-toggle` = "1",
        `aria-expanded` = "true",
        `aria-label` = tr("Menus"),
        onclick = "return rcmdrToggleSidebar(this);",
        rcmdr_icon("menu", 18)
      ),
      actionButton(
        "palette_open", tr("Search"),
        class = "btn-sm btn-outline-light",
        title = tr("Command palette (Ctrl+K)")
      ),
      uiOutput("dataset_badge", inline = TRUE),
      uiOutput("model_badge", inline = TRUE),
      # The two selects carry no visible label: the bar is dense and the
      # current value is the label.  A visually hidden one keeps the control
      # named for a screen reader.
      selectInput(
        "language",
        htmltools::tags$span(class = "visually-hidden", tr("Language")),
        choices = stats::setNames(languages, toupper(languages)),
        selected = current, width = "90px"
      ),
      selectInput(
        "theme",
        htmltools::tags$span(class = "visually-hidden", tr("Theme")),
        choices = theme_choices(),
        selected = theme,
        width = "160px"
      ),
      uiOutput("ui_mode_toggle_ui", inline = TRUE),
      actionLink("about_open", tr("About"), class = "rcmdr-topbar-link")
    )
  )
}

app_ui <- function() {
  bslib::page_fluid(
    theme = bslib::bs_theme(version = 5, primary = "#1f3a5f"),
    htmltools::tags$head(
      htmltools::tags$style(app_css()),
      htmltools::tags$script(app_js())
    ),
    htmltools::tags$a(
      class = "visually-hidden-focusable rcmdr-skip-link",
      href = "#main-content", tr("Skip to main content")
    ),
    # Busy and outcome announcements: the status bar is visual, this region
    # is what a screen reader hears while a command runs.
    htmltools::tags$div(
      id = "rcmdr-live-status",
      class = "visually-hidden",
      role = "status", `aria-live` = "polite", `aria-atomic` = "true"
    ),
    uiOutput("app_topbar"),
    uiOutput("menubar"),
    htmltools::div(
      class = "rcmdr-shell",
      htmltools::div(
        class = "rcmdr-shell-body",
        htmltools::div(
          class = "rcmdr-sidebar",
          role = "navigation", `aria-label` = tr("Application menus"),
          htmltools::div(
            class = "rcmdr-menu-search",
            textInput(
              "menu_search",
              htmltools::tags$span(class = "visually-hidden",
                                   tr("Search menus")),
              placeholder = tr("Search menus..."), width = "100%"
            ),
            htmltools::div(
              class = "rcmdr-menu-actions",
              actionLink("menu_expand_all", tr("Expand all")),
              actionLink("menu_collapse_all", tr("Collapse all"))
            )
          ),
          uiOutput("menus")
        ),
        htmltools::div(
          class = "rcmdr-main",
          id = "main-content", role = "main", tabindex = "-1",
          uiOutput("result_hint"),
          uiOutput("main_tabs_ui")
        )
      )
    ),
    htmltools::div(
      class = "rcmdr-statusbar", role = "status", `aria-live` = "polite",
      uiOutput("statusbar", inline = TRUE)
    ),
    # Report downloads are triggered from the Export report dialog; the
    # buttons are invisible but must exist for Shiny to bind the outputs.
    htmltools::div(
      class = "visually-hidden",
      actionButton("shortcuts_open", tr("Keyboard shortcuts")),
      actionButton("undo_shortcut", tr("Undo")),
      actionButton("redo_shortcut", tr("Redo")),
      actionButton("copy_selection_shortcut", tr("Copy selection")),
      actionButton("help_shortcut", tr("Help")),
      downloadButton("download_report_rmd", tr("Download report (.Rmd)")),
      downloadButton("download_report_html", tr("Download report (.html)"))
    )
  )
}

#' Is a view the one the user is looking at?
#'
#' The heavy outputs are computed on first open, not on the initial flush.  A
#' missing input means a direct call (tests, a scripted render), which keeps
#' the historical behaviour: the output is built.
#' @keywords internal
view_ready <- function(input, view) {
  primary <- input$main_tabs %||% ""
  secondary <- input$workspace_secondary_view %||% ""
  if (!nzchar(primary) && !nzchar(secondary)) return(TRUE)
  identical(primary, view) || identical(secondary, view)
}

#' Is a sub-view the active one?
#' @inheritParams view_ready
#' @keywords internal
subview_ready <- function(input, id, value) {
  current <- input[[id]] %||% ""
  if (!nzchar(current)) return(TRUE)
  identical(current, value)
}

#' Application server
#'
#' @param env Evaluation environment for commands.
#' @return A Shiny server function.
#' @keywords internal
app_server <- function(env = globalenv()) {
  force(env)

  function(input, output, session) {
    state <- AppState(env)
    state$session <- session
    try(preferences_load(state), silent = TRUE)
    if (!is.null(state$options$language) && nzchar(state$options$language)) {
      i18n_set_language(state$options$language)
    }
    persist_preferences <- function() {
      try(preferences_save(state), silent = TRUE)
      invisible(NULL)
    }
    # Split sizes are preferences: the divider sends a ratio on release and the
    # server stores it without making the project dirty.
    for (split_id in split_pane_ids()) {
      split_pane_server(split_id, input, state, persist_preferences)
    }
    split_pane_server("workspace_split", input, state, persist_preferences)
    document_registry_ensure(state)
    tick <- reactiveVal(0L)
    menu_revision <- reactiveVal(0L)
    language_revision <- reactiveVal(0L)
    state$language_revision <- language_revision
    dialog_revision <- reactiveVal(0L)
    script_value <- reactiveVal("")
    editor_mode <- reactiveVal(state$document$mode %||% "r")
    plot_selected <- reactiveVal(NULL)
    last_plot_count <- reactiveVal(0L)
    main_tabs_mode <- reactiveVal(ui_mode(state))
    workspace_secondary <- reactiveVal(state$options$workspace_secondary %||% "")
    workspace_focus <- reactiveVal(state$options$workspace_focus %||% "split")
    workspace_revision <- reactiveVal(0L)
    history_revision <- reactiveVal(0L)
    data_grid_revision <- reactiveVal(0L)
    data_selection_revision <- reactiveVal(0L)
    chart_revision <- reactiveVal(0L)
    # The cell editor is tied to one render of one data set.  The token changes
    # when the data set, its shape or the grid revision changes; Apply refuses
    # an editor that survived a view switch or a data change.
    editor_context <- reactiveVal(NULL)
    editor_token <- reactive({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df)) return("")
      paste(
        "ed",
        state$revision %||% 0L,
        data_grid_revision(),
        gsub("[^A-Za-z0-9_.-]", "_", active_dataset(state) %||% ""),
        nrow(df), ncol(df),
        sep = "-"
      )
    })
    observeEvent(list(input$data_mode, editor_token()), {
      mode <- input$data_mode %||% "view"
      df <- dataset(state)
      token <- if (identical(mode, "edit") && !is.null(df) &&
                   editable_dataset(state)) {
        editor_token()
      } else {
        ""
      }
      session$sendCustomMessage("rcmdr-editor-stamp", list(token = token))
    }, ignoreInit = FALSE)
    # The Ace editor is rebuilt only when the palette changes, not on every
    # tick: a theme swap must not discard the undo history mid-sentence.
    ace_theme <- reactiveVal(ui_ace_theme(ui_theme(state)))
    # Long commands set aria-busy and announce themselves in a polite live
    # region; the status bar badge is only the visual half of the state.
    set_busy <- function(value, message = NULL) {
      state$busy <- isTRUE(value)
      session$sendCustomMessage("rcmdr-busy", list(
        busy = isTRUE(value),
        message = message %||% ""
      ))
      invisible(NULL)
    }
    state$notify <- function() tick(tick() + 1L)
    state$script_consumed <- 0L
    state$set_script <- function(value) {
      script_value(value)
      shinyAce::updateAceEditor(session, "script", value = value)
    }

    sync_editor <- function() {
      value <- document_text(state)
      script_value(value)
      shinyAce::updateAceEditor(session, "script", value = value)
      invisible(value)
    }
    state$sync_document <- sync_editor

    # Project autosave.  The timer is cheap: it writes only when a project is
    # open or has unsaved metadata, and project_autosave() is atomic.
    project_autosave_timer <- shiny::reactiveTimer(
      as.integer(state$options$autosave_interval %||% 30000L)
    )
    shiny::observeEvent(project_autosave_timer(), {
      if (!is.null(state$project_path) || isTRUE(state$project_dirty)) {
        project_autosave(state)
      }
    }, ignoreInit = TRUE)

    # Offer recovery once, when the most recent project has a newer autosave.
    if (isTRUE(getOption("RcmdrShiny.recovery_prompt", TRUE))) {
      session$onFlushed(function() {
        recent <- tryCatch(project_recent(limit = 1L), error = function(e) NULL)
        if (is.null(recent) || nrow(recent) == 0L) return(invisible(NULL))
        info <- tryCatch(
          project_recovery_info(recent$path[[1L]]),
          error = function(e) NULL
        )
        if (is.null(info) || !isTRUE(info$available) ||
            !isTRUE(info$newer)) {
          return(invisible(NULL))
        }
        state$project_recovery_path <- info$path
        shiny::showModal(project_recovery_modal(info))
        invisible(NULL)
      }, once = TRUE)
    }

    # Read the editor content even when a tick-driven observer runs before the
    # input binding has propagated the latest keystrokes.
    current_document_text <- function() {
      value <- isolate(input$script)
      if (!is.null(value) && nzchar(value)) document_set_text(state, value)
      document_text(state)
    }
    state$current_document_text <- current_document_text
    state$persist_preferences <- function() persist_preferences()
    state$show_tab <- function(view) {
      target <- main_tab_target(view, main_tabs_mode())
      if (is.null(target)) return(invisible(FALSE))
      session$sendCustomMessage("rcmdr-tab", target)
      invisible(TRUE)
    }

    output$app_topbar <- renderUI({
      language_revision()
      app_topbar_ui(ui_theme(state))
    })

    tour_index <- reactiveVal(1L)
    show_tour_step <- function(index = 1L) {
      steps <- tour_steps()
      index <- max(1L, min(length(steps), as.integer(index)))
      tour_index(index)
      step <- steps[[index]]
      if (nzchar(step$tab %||% "")) state$show_tab(tr(step$tab))
      session$sendCustomMessage(
        "rcmdr-tour-highlight", list(selector = step$target)
      )
      showModal(tour_modal(step, index, length(steps)))
    }
    state$start_tour <- function() show_tour_step(1L)

    session$onFlushed(function() {
      session$sendCustomMessage("rcmdr-theme", list(
        theme = ui_theme(state),
        density = ui_density(state)
      ))
    }, once = TRUE)

    open_palette <- function() {
      showModal(palette_modal())
      session$sendCustomMessage("rcmdr-focus", "palette_query")
    }

    output$ui_mode_toggle_ui <- renderUI({
      language_revision()
      actionLink(
        "ui_mode_toggle",
        if (identical(main_tabs_mode(), "studio")) tr("Classic") else tr("Studio"),
        class = "rcmdr-topbar-link"
      )
    })

    # Result hint ------------------------------------------------------------
    # A command runs where it always ran, but the user coming from a classic
    # interface expects the result window to open.  The hint says where the
    # result landed and offers to open it, like the classic window did.
    output$result_hint <- renderUI({
      tick()
      language_revision()
      result_hint_ui(
        state$last_result,
        mode = main_tabs_mode(),
        auto = isTRUE(state$options$auto_switch_result)
      )
    })

    observeEvent(input$result_hint_open, {
      info <- isolate(state$last_result)
      if (is.null(info)) return()
      state$show_tab(info$sub %||% info$tab)
    }, ignoreInit = TRUE)

    observeEvent(input$result_hint_close, {
      state$last_result <- NULL
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$result_hint_auto, {
      state$options$auto_switch_result <- isTRUE(input$result_hint_auto)
      persist_preferences()
      if (isTRUE(state$options$auto_switch_result)) {
        info <- isolate(state$last_result)
        if (!is.null(info)) state$show_tab(info$sub %||% info$tab)
      }
    }, ignoreInit = TRUE)

    help_server(input, output, session, state)

    # Per-session directory for plot thumbnails and downloads.
    plot_dir <- file.path(tempdir(), paste0("rcmdrshiny-", session$token))
    dir.create(plot_dir, showWarnings = FALSE, recursive = TRUE)
    state$plot_dir <- plot_dir
    state$plot_prefix <- paste0("rcmdr-plots-", session$token)
    try(addResourcePath(state$plot_prefix, plot_dir), silent = TRUE)

    knit_dir <- file.path(tempdir(), paste0("rcmdrshiny-knit-", session$token))
    dir.create(knit_dir, showWarnings = FALSE, recursive = TRUE)
    state$knit_dir <- knit_dir
    state$knit_prefix <- paste0("rcmdr-knit-", session$token)
    try(addResourcePath(state$knit_prefix, knit_dir), silent = TRUE)

    report_dir <- file.path(tempdir(), paste0("rcmdrshiny-report-", session$token))
    dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)
    state$report_dir <- report_dir
    state$autosave_dir <- file.path(tempdir(), "rcmdrshiny-autosave")

    tree <- menu_tree()
    leaves <- menu_leaves(tree)

    failures <- plugin_failures()
    if (nrow(failures) > 0L) {
      showNotification(
        sprintf(tr("%d plugin(s) could not be loaded. See Home > Health."),
                nrow(failures)),
        type = "warning", duration = 10
      )
    }
    conflicts <- plugin_conflicts()
    if (nrow(conflicts) > 0L) {
      showNotification(
        sprintf(tr("%d plugin conflict(s) recorded. See Home > Health."),
                nrow(conflicts)),
        type = "warning", duration = 10
      )
    }

    # -- menus --------------------------------------------------------------

    output$menubar <- renderUI({
      menu_revision()
      language_revision()
      tick()
      menubar_ui(
        undo_menu_tree(tree, state),
        function(node) {
          command_status(state, node$command, node$activation, node$install)
        },
        favorites = menu_favorite_ids(state),
        expanded = state$menu_expanded %||% character()
      )
    })

    output$menus <- renderUI({
      menu_revision()
      language_revision()
      tick()
      query <- trimws(input$menu_search %||% "")
      favorites <- menu_favorite_ids(state)
      if (!nzchar(query)) {
        return(menu_sections_ui(state, leaves))
      }
      translated <- vapply(leaves$label, menu_label, character(1))
      matches <- leaves[
        grepl(query, paste(leaves$label, translated, leaves$path,
                           leaves$command),
              ignore.case = TRUE, fixed = TRUE),
        , drop = FALSE
      ]
      if (nrow(matches) == 0L) {
        return(empty_state(
          tr("No menu entries"),
          tr("Try a different search term.")
        ))
      }
      htmltools::tagList(lapply(seq_len(nrow(matches)), function(i) {
        row <- matches[i, , drop = FALSE]
        status <- command_status(state, row$command, row$activation, row$install)
        if (identical(status, "hidden")) return(NULL)
        menu_flat_item_ui(row, status, query,
                          row$command[[1L]] %in% favorites)
      }))
    })

    observeEvent(input$menu_favorite, {
      action <- input$menu_favorite
      if (is.null(action) || is.null(action$command)) return()
      menu_favorite_toggle(state, action$command)
      persist_preferences()
      menu_revision(menu_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$menu_group_toggle, {
      action <- input$menu_group_toggle
      if (is.null(action) || is.null(action$id)) return()
      # Re-rendering the menu tree recreates the open <details> elements, which
      # makes the browser report a toggle for a state the session already has.
      # Touching the state for those echoes re-renders the tree again (tick())
      # and the UI loops forever, so only real changes are applied.
      if (menu_toggle_is_echo(isolate(state$menu_expanded), action$id,
                              action$open)) {
        return()
      }
      menu_toggle_expanded(state, action$id, isTRUE(action$open))
      persist_preferences()
    }, ignoreInit = TRUE)

    observeEvent(input$menu_expand_all, {
      menu_set_expanded(state, menu_group_ids(tree), expand = TRUE)
      persist_preferences()
      menu_revision(menu_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$menu_collapse_all, {
      menu_set_expanded(state, menu_group_ids(tree), expand = FALSE)
      persist_preferences()
      menu_revision(menu_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$shortcuts_open, {
      showModal(shortcuts_modal())
    }, ignoreInit = TRUE)

    observeEvent(input$home_shortcuts, {
      showModal(shortcuts_modal())
    }, ignoreInit = TRUE)

    finish_tour <- function(dismiss = FALSE) {
      removeModal()
      session$sendCustomMessage("rcmdr-tour-clear", list())
      if (isTRUE(dismiss)) {
        session$sendCustomMessage("rcmdr-tour-dismissed", list())
      }
      invisible(NULL)
    }

    observeEvent(input$tour_start, {
      show_tour_step(1L)
    })

    observeEvent(input$tour_next, {
      index <- tour_index()
      steps <- tour_steps()
      if (index >= length(steps)) {
        finish_tour(dismiss = TRUE)
        showNotification(tr("Tour completed. You can restart it from Help > Tour."),
                         type = "message", duration = 4)
      } else {
        show_tour_step(index + 1L)
      }
    })

    observeEvent(input$tour_back, {
      show_tour_step(tour_index() - 1L)
    })

    observeEvent(input$tour_skip, {
      finish_tour(dismiss = FALSE)
    })

    observeEvent(input$tour_dismiss, {
      finish_tour(dismiss = TRUE)
    })

    observeEvent(input$help_shortcut, {
      if (is.function(state$help_show)) state$help_show("getting-started")
      state$show_tab(tr("Help"))
    }, ignoreInit = TRUE)

    observeEvent(input$home_workflows, {
      state$show_tab(tr("Workflows"))
    }, ignoreInit = TRUE)

    observeEvent(tick(), {
      mode <- ui_mode(state)
      if (!identical(mode, isolate(main_tabs_mode()))) {
        main_tabs_mode(mode)
      }
    }, ignoreInit = TRUE)

    output$main_tabs_ui <- renderUI({
      language_revision()
      main_tabs_ui(main_tabs_mode(),
                   view = isolate(input$main_tabs) %||% "home")
    })

    render_workspace_view <- function(view, primary = FALSE) {
      show_inspector <- if (isTRUE(primary) && identical(view, "data") &&
                            !is.null(input$workspace_show_inspector)) {
        isTRUE(input$workspace_show_inspector)
      } else {
        NULL
      }
      show_preview <- if (isTRUE(primary) && identical(view, "charts") &&
                          !is.null(input$workspace_show_preview)) {
        isTRUE(input$workspace_show_preview)
      } else {
        NULL
      }
      workspace_view_ui(
        view, "studio", state,
        show_inspector = show_inspector,
        show_preview = show_preview
      )
    }

    output$workspace_switcher_ui <- renderUI({
      language_revision()
      workspace_view_switcher(input$main_tabs %||% "home")
    })

    output$workspace_secondary_ui <- renderUI({
      language_revision()
      primary <- input$main_tabs %||% "home"
      ids <- setdiff(workspace_view_ids(), primary)
      labels <- main_tab_labels("studio")
      choices <- stats::setNames(
        c("", ids),
        c(tr("Single view"), vapply(ids, function(id) labels[[id]] %||% id,
                                    character(1)))
      )
      selected <- input$workspace_secondary_view %||% workspace_secondary()
      if (!selected %in% ids) selected <- ""
      selectInput(
        "workspace_secondary_view",
        htmltools::tags$span(class = "visually-hidden", tr("Second view")),
        choices = choices,
        selected = selected,
        width = "190px"
      )
    })

    output$workspace_panel_toggles_ui <- renderUI({
      language_revision()
      workspace_revision()
      view <- input$main_tabs %||% "home"
      if (identical(view, "data")) {
        return(checkboxInput(
          "workspace_show_inspector", tr("Inspector"),
          value = !workspace_panel_hidden(state, "data", "inspector")
        ))
      }
      if (identical(view, "charts")) {
        return(checkboxInput(
          "workspace_show_preview", tr("Preview"),
          value = !workspace_panel_hidden(state, "charts", "preview")
        ))
      }
      NULL
    })

    output$workspace_focus_ui <- renderUI({
      language_revision()
      secondary <- input$workspace_secondary_view %||% workspace_secondary()
      if (!nzchar(secondary)) return(NULL)
      htmltools::div(
        class = "rcmdr-workspace-focus",
        segmented_input(
          "workspace_focus", NULL,
          c(Split = "split", Primary = "primary", Secondary = "secondary"),
          selected = input$workspace_focus %||% workspace_focus()
        ),
        actionButton("workspace_swap", tr("Swap sides"),
                     class = "btn-sm btn-outline-secondary")
      )
    })

    output$workspace_layout <- renderUI({
      language_revision()
      workspace_revision()
      primary <- input$main_tabs %||% "home"
      secondary <- input$workspace_secondary_view %||% workspace_secondary()
      if (!nzchar(secondary) || identical(secondary, primary)) {
        return(render_workspace_view(primary, primary = TRUE))
      }
      focus <- input$workspace_focus %||% workspace_focus()
      if (identical(focus, "primary")) {
        return(render_workspace_view(primary, primary = TRUE))
      }
      if (identical(focus, "secondary")) {
        return(render_workspace_view(secondary, primary = FALSE))
      }
      split_pane(
        "workspace_split",
        uiOutput("workspace_primary"),
        uiOutput("workspace_secondary"),
        class = "rcmdr-workspace-split",
        initial = 0.62,
        min = 360,
        min_second = 320,
        label = tr("Resize workspace")
      )
    })

    output$workspace_primary <- renderUI({
      language_revision()
      workspace_revision()
      render_workspace_view(input$main_tabs %||% "home", primary = TRUE)
    })

    output$workspace_secondary <- renderUI({
      language_revision()
      workspace_revision()
      view <- input$workspace_secondary_view %||% workspace_secondary()
      req(nzchar(view), !identical(view, input$main_tabs %||% "home"))
      render_workspace_view(view, primary = FALSE)
    })

    observeEvent(input$workspace_secondary_view, {
      value <- input$workspace_secondary_view %||% ""
      primary <- input$main_tabs %||% "home"
      if (identical(value, primary)) value <- ""
      workspace_secondary(value)
      state$options$workspace_secondary <- if (nzchar(value)) value else NULL
      persist_preferences()
    }, ignoreInit = TRUE)

    observeEvent(input$main_tabs, {
      primary <- input$main_tabs %||% "home"
      if (identical(workspace_secondary(), primary)) {
        workspace_secondary("")
        state$options$workspace_secondary <- NULL
        workspace_focus("split")
        state$options$workspace_focus <- "split"
        updateSelectInput(session, "workspace_secondary_view", selected = "")
        persist_preferences()
      }
    }, ignoreInit = TRUE)
    observeEvent(input$workspace_show_inspector, {
      workspace_panel_set(state, "data", "inspector",
                          isTRUE(input$workspace_show_inspector))
      persist_preferences()
      workspace_revision(workspace_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$workspace_show_preview, {
      workspace_panel_set(state, "charts", "preview",
                          isTRUE(input$workspace_show_preview))
      persist_preferences()
      workspace_revision(workspace_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$workspace_focus, {
      value <- input$workspace_focus %||% "split"
      if (!value %in% c("split", "primary", "secondary")) value <- "split"
      workspace_focus(value)
      state$options$workspace_focus <- value
      persist_preferences()
    }, ignoreInit = TRUE)

    observeEvent(input$workspace_swap, {
      primary <- input$main_tabs %||% "home"
      secondary <- workspace_secondary()
      if (!nzchar(secondary) || identical(primary, secondary)) return()
      updateTextInput(session, "main_tabs", value = secondary)
      workspace_secondary(primary)
      state$options$workspace_secondary <- primary
      updateSelectInput(session, "workspace_secondary_view",
                        selected = primary)
      persist_preferences()
      workspace_focus("split")
    }, ignoreInit = TRUE)

    open_dialog <- function(spec) {
      if (!is.null(spec$on_open)) spec$on_open(state)
      state$dialog_errors <- list()
      state$current_dialog <- spec$id
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      dialog_revision(dialog_revision() + 1L)
      showModal(dialog_modal(spec))
    }

    state$open_dialog <- function(id) {
      spec <- get_dialog_spec(id)
      if (!is.null(spec)) open_dialog(spec)
      invisible(NULL)
    }

    output$script_editor_ui <- renderUI({
      mode <- editor_mode()
      shinyAce::aceEditor(
        "script", value = isolate(script_value()),
        mode = document_ace_mode(mode), theme = ace_theme(),
        height = "460px", fontSize = 13, selectionId = "script_selection",
        autoComplete = "enabled"
      )
    })

    launch <- function(command) {
      availability <- command_availability(state, command)
      if (!identical(availability$status, "enabled")) {
        showNotification(
          command_status_message(availability$status),
          type = "warning", duration = 5
        )
        return(invisible(NULL))
      }

      menu_recent_add(state, command)
      persist_preferences()

      spec <- get_dialog_spec(command)
      if (!is.null(spec)) {
        open_dialog(spec)
        return(invisible(TRUE))
      }

      action <- direct_commands()[[command]]
      if (!is.null(action)) {
        old_source <- state$execution_source
        state$execution_source <- "menu"
        on.exit(state$execution_source <- old_source, add = TRUE)
        action(state)
        if (command %in% c("onUndo", "onRedo")) {
          data_grid_revision(data_grid_revision() + 1L)
          data_selection_revision(data_selection_revision() + 1L)
          chart_revision(chart_revision() + 1L)
          workspace_revision(workspace_revision() + 1L)
        }
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        return(invisible(TRUE))
      }

      showNotification(tr("This command has not been ported yet."),
                       type = "message", duration = 5)
      invisible(NULL)
    }

    for (i in seq_len(nrow(leaves))) {
      local({
        key <- leaves$key[[i]]
        command <- leaves$command[[i]]
        observeEvent(input[[key]], launch(command), ignoreInit = TRUE)
      })
    }

    observeEvent(input$menu_command, {
      command <- input$menu_command
      if (is.null(command) || !nzchar(command)) return()
      launch(command)
    }, ignoreInit = TRUE)

    # Ctrl+Z / Ctrl+Shift+Z click these hidden buttons from 70-keyboard.js.
    # They go through launch(), so availability and the Edit menu agree.
    observeEvent(input$undo_shortcut, launch("onUndo"), ignoreInit = TRUE)
    observeEvent(input$redo_shortcut, launch("onRedo"), ignoreInit = TRUE)

    # -- dialogs ------------------------------------------------------------

    output$dialog_body <- renderUI({
      dialog_revision()
      spec <- get_dialog_spec(state$current_dialog %||% "")
      req(spec)
      htmltools::div(
        class = "rcmdr-field-grid rcmdr-dialog-grid",
        spec$ui(state, get_dialog_memory(state, spec$id))
      )
    })

    strip_dialog_prefix <- function(values, id) {
      prefix <- paste0(id, "_")
      names(values) <- sub(paste0("^", prefix), "", names(values))
      values
    }

    capture_dialog_inputs <- function(id) {
      values <- shiny::reactiveValuesToList(input)
      prefix <- paste0(id, "_")
      keep <- startsWith(names(values), prefix)
      strip_dialog_prefix(values[keep], id)
    }

    dialog_preview_result <- shiny::reactive({
      dialog_revision()
      spec <- get_dialog_spec(state$current_dialog %||% "")
      if (is.null(spec) || !isTRUE(feature_enabled(state, "dialog_preview")) ||
          !isTRUE(spec$preview)) {
        return(NULL)
      }
      tryCatch(
        spec$on_ok(input, preview_state_clone(state)),
        error = function(e) list(error = conditionMessage(e))
      )
    })
    dialog_preview_result_d <- shiny::debounce(dialog_preview_result, 300)

    output$dialog_preview_panel <- renderUI({
      result <- dialog_preview_result_d()
      if (is.null(result)) return(NULL)
      if (!is.null(result$error)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          result$error
        ))
      }
      commands <- result$commands %||% character()
      if (length(commands) > 0L) {
        return(code_preview(paste(commands, collapse = "\n")))
      }
      if (!is.null(result$script) && nzchar(result$script)) {
        return(code_preview(result$script))
      }
      if (!is.null(result$interactive)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          tr("This dialog produces an interactive plot.")
        ))
      }
      if (!is.null(result$report)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          tr("This dialog prepares a report; no R command is generated.")
        ))
      }
      if (!is.null(result$tab)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          sprintf(tr("This dialog opens the %s tab."), result$tab)
        ))
      }
      htmltools::tags$p(
        class = "text-muted small mb-0",
        tr("No R command is generated by this dialog.")
      )
    })

    output$dialog_validation_ui <- renderUI({
      dialog_revision()
      dialog_validation_ui(state$dialog_errors %||% list())
    })

    output$dialog_presets_ui <- renderUI({
      dialog_revision()
      spec <- get_dialog_spec(state$current_dialog %||% "")
      if (is.null(spec) || !isTRUE(feature_enabled(state, "dialog_presets")) ||
          !isTRUE(spec$presets)) {
        return(NULL)
      }
      presets <- names(dialog_presets_for(state, spec$id))
      choices <- c(stats::setNames("", tr("(no preset)")),
                   stats::setNames(presets, presets))
      htmltools::tags$div(
        class = "rcmdr-dialog-presets d-flex gap-2 align-items-end flex-wrap",
        htmltools::tags$div(
          style = "min-width: 170px;",
          selectInput("dialog_preset_select", NULL, choices = choices,
                      width = "170px", selectize = FALSE)
        ),
        actionButton("dialog_preset_apply", tr("Apply"),
                     class = "btn-sm btn-outline-secondary"),
        actionButton("dialog_preset_delete", tr("Delete"),
                     class = "btn-sm btn-outline-secondary"),
        htmltools::tags$div(
          style = "width: 150px;",
          textInput("dialog_preset_name", NULL,
                    placeholder = tr("Preset name"))
        ),
        actionButton("dialog_preset_save", tr("Save preset"),
                     class = "btn-sm btn-outline-primary"),
        downloadButton("dialog_preset_export", tr("Export"),
                       class = "btn-sm btn-outline-secondary"),
        shiny::fileInput(
          "dialog_preset_import", NULL, accept = ".rds", width = "150px",
          buttonLabel = tr("Import"), placeholder = tr("Preset file")
        )
      )
    })

    observeEvent(input$dialog_preset_apply, {
      id <- state$current_dialog
      req(id)
      name <- input$dialog_preset_select %||% ""
      if (!nzchar(name)) return()
      preset <- dialog_preset_get(state, id, name)
      if (is.null(preset)) return()
      set_dialog_memory(state, id, preset)
      state$dialog_errors <- list()
      dialog_revision(dialog_revision() + 1L)
      showNotification(tr("Preset applied."), type = "message", duration = 2)
    }, ignoreInit = TRUE)

    observeEvent(input$dialog_preset_save, {
      id <- state$current_dialog
      req(id)
      result <- dialog_preset_save(
        state, id, input$dialog_preset_name %||% "",
        capture_dialog_inputs(id)
      )
      if (!isTRUE(result$ok)) {
        showNotification(result$error %||% tr("The preset could not be saved."),
                         type = "error", duration = 4)
        return()
      }
      persist_preferences()
      updateTextInput(session, "dialog_preset_name", value = "")
      dialog_revision(dialog_revision() + 1L)
      showNotification(tr("Preset saved."), type = "message", duration = 2)
    }, ignoreInit = TRUE)

    observeEvent(input$dialog_preset_delete, {
      id <- state$current_dialog
      req(id)
      name <- input$dialog_preset_select %||% ""
      if (!nzchar(name)) return()
      dialog_preset_delete(state, id, name)
      persist_preferences()
      dialog_revision(dialog_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$dialog_preset_import, {
      upload <- input$dialog_preset_import
      if (is.null(upload) || is.null(upload$datapath)) return()
      result <- dialog_presets_load_file(state, upload$datapath,
                                         overwrite = TRUE)
      if (!isTRUE(result$ok)) {
        showNotification(result$error %||% tr("The preset file could not be read."),
                         type = "error", duration = 5)
        return()
      }
      persist_preferences()
      dialog_revision(dialog_revision() + 1L)
      showNotification(
        sprintf(tr("%d presets imported."), result$imported %||% 0L),
        type = "message", duration = 3
      )
    }, ignoreInit = TRUE)

    output$dialog_preset_export <- downloadHandler(
      filename = function() "rcmdrshiny-presets.rds",
      content = function(file) {
        saveRDS(dialog_presets_export(state), file)
      }
    )

    observeEvent(input$dialog_insert_script, {
      result <- isolate(dialog_preview_result())
      commands <- result$commands %||% character()
      if (length(commands) == 0L && !is.null(result$script) &&
          nzchar(result$script)) {
        commands <- result$script
      }
      if (length(commands) == 0L) {
        showNotification(tr("This dialog has no command to insert."),
                         type = "message", duration = 3)
        return()
      }
      insert_commands_into_script(state, commands)
      removeModal()
      state$current_dialog <- NULL
      state$dialog_errors <- list()
      dialog_revision(dialog_revision() + 1L)
      tick(tick() + 1L)
      state$show_tab(tr("Script"))
    }, ignoreInit = TRUE)

    submit_dialog <- function(close = TRUE) {
      id <- state$current_dialog
      req(id)
      spec <- get_dialog_spec(id)
      req(spec)

      result <- tryCatch(
        spec$on_ok(input, state),
        error = function(e) list(error = conditionMessage(e))
      )

      field_errors <- dialog_field_errors(result)
      if (length(field_errors) > 0L) {
        prefixed <- stats::setNames(
          unlist(field_errors, use.names = FALSE),
          ifelse(startsWith(names(field_errors), paste0(id, "_")),
                 names(field_errors),
                 paste0(id, "_", names(field_errors)))
        )
        state$dialog_errors <- as.list(prefixed)
        dialog_revision(dialog_revision() + 1L)
        # An invalid field may sit in a closed panel: open them all before
        # the focus message so the highlight is reachable.  The messages wait
        # for the flush, otherwise they would hit the previous body: the
        # renderUI of the summary and the field marks arrive with it.
        session$onFlushed(function() {
          session$sendCustomMessage("rcmdr-open-accordions", list())
          session$sendCustomMessage(
            "rcmdr-field-errors",
            dialog_validation_payload(state$dialog_errors)
          )
        }, once = TRUE)
        return(invisible(FALSE))
      }

      if (!is.null(result$error)) {
        showNotification(result$error, type = "error", duration = 10)
        return(invisible(FALSE))
      }

      state$dialog_errors <- list()
      if (!is.null(result$memory)) set_dialog_memory(state, id, result$memory)

      before_history <- vapply(state$history %||% list(),
                               function(entry) entry$id %||% "", character(1))
      set_busy(TRUE, tr("Applying the command..."))
      ok <- tryCatch(
        apply_dialog_result(state, result),
        error = function(e) {
          state$last_error <- conditionMessage(e)
          state$messages <- c(state$messages, paste0("Error: ", state$last_error))
          FALSE
        }
      )
      set_busy(FALSE)

      if (isTRUE(ok) && !is.null(state$workflow)) {
        after_history <- vapply(state$history %||% list(),
                                function(entry) entry$id %||% "", character(1))
        workflow_mark_step(
          state, id, result,
          history_ids = setdiff(after_history, before_history)
        )
      }

      if (close) {
        removeModal()
        state$current_dialog <- NULL
        dialog_revision(dialog_revision() + 1L)
      }
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)

      if (!ok) {
        state$last_failed_dialog <- list(
          id = id,
          memory = get_dialog_memory(state, id)
        )
        showModal(modalDialog(
          title = tr("Command error"),
          htmltools::tagList(
            htmltools::tags$pre(state$last_error %||% tr("The command produced an error.")),
            tryCatch(error_help_link_ui(state$last_error),
                     error = function(e) NULL)
          ),
          easyClose = TRUE,
          footer = htmltools::tagList(
            modalButton(tr("Close")),
            actionButton("dialog_retry", tr("Retry"), class = "btn-primary")
          )
        ))
      } else if (!close) {
        showNotification(tr("Applied."), type = "message", duration = 2)
      }
      invisible(ok)
    }

    observeEvent(input$dialog_ok, submit_dialog(close = TRUE))
    observeEvent(input$dialog_apply, submit_dialog(close = FALSE))

    observeEvent(input$dialog_cancel, {
      removeModal()
      state$current_dialog <- NULL
      state$dialog_errors <- list()
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      dialog_revision(dialog_revision() + 1L)
    })

    observeEvent(input$dialog_reset, {
      id <- state$current_dialog
      req(id)
      spec <- get_dialog_spec(id)
      req(spec)
      state$dialog_errors <- list()
      clear_dialog_memory(state, id)
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      if (!is.null(spec$on_open)) spec$on_open(state)
      dialog_revision(dialog_revision() + 1L)
      showModal(dialog_modal(spec))
    })

    observeEvent(input$dialog_retry, {
      failed <- state$last_failed_dialog
      req(failed)
      removeModal()
      spec <- get_dialog_spec(failed$id)
      req(spec)
      state$current_dialog <- failed$id
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      if (!is.null(failed$memory)) {
        set_dialog_memory(state, failed$id, failed$memory)
      }
      if (!is.null(spec$on_open)) spec$on_open(state)
      dialog_revision(dialog_revision() + 1L)
      showModal(dialog_modal(spec))
    })

    for (spec in dialog_catalog()) {
      if (!is.null(spec$observers)) {
        spec$observers(input, output, session, state, tick)
      }
    }

    # -- output panes -------------------------------------------------------

    output$output_text <- renderText({
      tick()
      paste(state$output, collapse = "\n")
    })

    output$messages_text <- renderText({
      tick()
      paste(state$messages, collapse = "\n")
    })

    outputOptions(output, "output_text", suspendWhenHidden = FALSE)
    outputOptions(output, "messages_text", suspendWhenHidden = FALSE)

    output$output_cards <- renderUI({
      tick()
      menu_revision()
      history_revision()
      entries <- history_filter_entries(
        history_recent(state, 100L),
        input$output_filter %||% "",
        input$output_source %||% "all",
        input$output_status %||% "all"
      )
      if (isTRUE(input$output_pinned)) {
        pinned <- history_pinned_ids(state)
        entries <- Filter(function(entry) entry$id %in% pinned, entries)
      }
      history_cards_ui(entries, pinned = history_pinned_ids(state))
    })
    outputOptions(output, "output_cards", suspendWhenHidden = FALSE)

    output$messages_cards <- renderUI({
      tick()
      entries <- messages_filter(
        state$message_entries %||% list(),
        input$messages_filter %||% "",
        input$messages_severity %||% "all"
      )
      if (length(entries) == 0L) {
        return(empty_state(tr("No messages"),
                           tr("Warnings, errors and notes appear here.")))
      }
      htmltools::tagList(lapply(entries, function(entry) {
        severity <- entry$severity %||% "message"
        pill <- switch(
          severity,
          error = status_pill(tr("Error"), "error"),
          warning = status_pill(tr("Warning"), "warning"),
          status_pill(tr("Note"), "muted")
        )
        htmltools::tags$div(
          class = "rcmdr-history-card",
          htmltools::tags$div(
            class = "rcmdr-history-head",
            pill,
            htmltools::tags$span(class = "rcmdr-history-time",
                                 format(entry$time %||% Sys.time(), "%H:%M:%S")),
            if (nzchar(entry$history_id %||% "")) {
              htmltools::tags$div(
                class = "ms-auto",
                htmltools::tags$button(
                  type = "button", class = "btn btn-sm btn-outline-secondary",
                  onclick = sprintf(
                    "rcmdrHistoryClick(this, 'rerun'); return false;"
                  ),
                  `data-history-action` = "rerun",
                  `data-history-id` = entry$history_id,
                  tr("Rerun")
                )
              )
            }
          ),
          if (nzchar(entry$command %||% "")) {
            htmltools::tags$pre(class = "rcmdr-history-command", entry$command)
          },
          htmltools::tags$pre(class = "rcmdr-message-text", entry$text),
          if (identical(severity, "error")) {
            tryCatch(error_help_link_ui(entry$text), error = function(e) NULL)
          }
        )
      }))
    })
    outputOptions(output, "messages_cards", suspendWhenHidden = FALSE)

    observeEvent(input$clear_output, {
      state$output <- character()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$output_clear, {
      state$output <- character()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$clear_messages, {
      state$messages <- character()
      state$warnings <- character()
      state$last_error <- NULL
      messages_clear(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$messages_clear, {
      state$messages <- character()
      state$warnings <- character()
      state$last_error <- NULL
      messages_clear(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    # -- history, console and palette --------------------------------------

    output$history_cards <- renderUI({
      tick()
      menu_revision()
      history_revision()
      entries <- history_filter_entries(
        history_recent(state, 100L),
        input$history_filter %||% "",
        input$history_source %||% "all"
      )
      history_cards_ui(entries)
    })

    observeEvent(input$history_action, {
      action <- input$history_action
      if (is.null(action) || is.null(action$id)) return()
      switch(
        action$action %||% "rerun",
        rerun = history_rerun(state, action$id),
        dialog = history_open_dialog(state, action$id),
        script = history_insert_script(state, action$id),
        report = history_insert_report(state, action$id),
        pin = history_toggle_pin(state, action$id),
        unpin = history_toggle_pin(state, action$id)
      )
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$history_clear, {
      history_clear(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    # Nested console tabs are suspended while hidden; force the history output
    # to refresh when the History tab becomes visible.
    observeEvent(input$console_tabs, {
      if (identical(input$console_tabs, "history")) {
        history_revision(history_revision() + 1L)
      }
    }, ignoreInit = TRUE)

    output$console_log <- renderUI({
      tick()
      menu_revision()
      history_revision()
      entries <- console_entries(
        state,
        input$console_filter %||% "",
        input$console_status %||% "all",
        20L
      )
      if (length(entries) == 0L) {
        return(empty_state(
          tr("Console ready"),
          tr("Type an R command above. Commands are logged and added to the history.")
        ))
      }
      history_cards_ui(entries, pinned = history_pinned_ids(state))
    })

    output$console_status_ui <- renderUI({
      tick()
      last <- state$console_last
      if (is.null(last)) {
        return(htmltools::tags$p(
          class = "small text-muted mb-1",
          tr("Ready.")
        ))
      }
      htmltools::tags$p(
        class = if (identical(last$status, "ok")) "small text-success mb-1" else
          "small text-danger mb-1",
        sprintf(
          "%s - %s - %.0f ms",
          if (identical(last$status, "ok")) tr("OK") else tr("Error"),
          format(last$time %||% Sys.time(), "%H:%M:%S"),
          last$duration_ms %||% 0
        )
      )
    })
    outputOptions(output, "console_status_ui", suspendWhenHidden = FALSE)

    observeEvent(input$console_run, {
      code <- trimws(input$console_input %||% "")
      if (!nzchar(code)) return()
      if (console_is_interactive(code)) {
        showNotification(
          tr("Interactive commands such as readline() or menu() cannot run in the browser console."),
          type = "error", duration = 8
        )
        return()
      }
      set_busy(TRUE, tr("Running the command..."))
      console_execute(state, code)
      set_busy(FALSE)
      updateTextInput(session, "console_input", value = "")
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$console_prev, {
      updateTextInput(session, "console_input",
                      value = console_history_recall(state, -1L))
    }, ignoreInit = TRUE)

    observeEvent(input$console_next, {
      updateTextInput(session, "console_input",
                      value = console_history_recall(state, 1L))
    }, ignoreInit = TRUE)

    observeEvent(input$console_clear, {
      history <- Filter(function(entry) !identical(entry$source, "console"),
                        state$history %||% list())
      state$history <- history
      state$console_history <- character()
      state$console_index <- 0L
      state$console_last <- NULL
      tick(tick() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$palette_open, open_palette(), ignoreInit = TRUE)
    observeEvent(input$home_palette, open_palette(), ignoreInit = TRUE)

    output$palette_results <- renderUI({
      tick()
      menu_revision()
      index <- palette_index_cached(state)
      results <- palette_search(
        input$palette_query %||% "", index, 25L,
        type = input$palette_type %||% "all",
        favorites_only = isTRUE(input$palette_favorites)
      )
      palette_results_ui(results)
    })

    observeEvent(input$palette_action, {
      action <- input$palette_action
      if (is.null(action) || is.null(action$id)) return()
      type <- action$type %||% ""
      verb <- action$action %||% "run"
      if (identical(type, "menu") || identical(type, "dialog")) {
        if (identical(verb, "favorite")) {
          menu_favorite_toggle(state, action$id)
          persist_preferences()
          menu_revision(menu_revision() + 1L)
          return()
        }
        if (identical(verb, "copy")) {
          tryCatch(
            utils::writeClipboard(action$command %||% action$id),
            error = function(e) NULL
          )
          showNotification(tr("Command copied."), type = "message",
                           duration = 2)
          return()
        }
        removeModal()
        launch(action$id)
        return()
      }
      if (identical(type, "workflow")) {
        removeModal()
        result <- workflow_start(state, action$id)
        if (!isTRUE(result$ok)) {
          showNotification(result$error %||% tr("Unknown workflow."),
                           type = "error", duration = 5)
        } else {
          menu_recent_add(state, paste0("workflow:", action$id))
          persist_preferences()
          state$show_tab(tr("Workflows"))
          tick(tick() + 1L)
        }
        return()
      }
      removeModal()
      switch(
        type,
        help = {
          if (is.function(state$help_show)) state$help_show(action$id)
          state$show_tab(tr("Help"))
        },
        dataset = {
          tryCatch(active_dataset(state, action$id), error = function(e) NULL)
          tick(tick() + 1L)
          menu_revision(menu_revision() + 1L)
        },
        variable = {
          updateSelectInput(session, "data_inspector_column",
                            selected = action$id)
          state$show_tab(tr("Data"))
          showNotification(
            sprintf(tr("Variable: %s"), action$id),
            type = "message", duration = 2
          )
        },
        history = {
          if (identical(verb, "insert")) {
            history_insert_script(state, action$id)
          } else if (identical(verb, "copy")) {
            entry <- Filter(function(item) identical(item$id, action$id),
                            state$history %||% list())
            if (length(entry) > 0L) {
              tryCatch(utils::writeClipboard(entry[[1L]]$command %||% ""),
                       error = function(e) NULL)
              showNotification(tr("Command copied."), type = "message",
                               duration = 2)
            }
          } else {
            history_rerun(state, action$id)
          }
          tick(tick() + 1L)
          menu_revision(menu_revision() + 1L)
        }
      )
    }, ignoreInit = TRUE)

    output$workflow_panel <- renderUI({
      req(view_ready(input, "workflows"))
      tick()
      workflow_panel_ui(state)
    })

    observeEvent(input$workflow_action, {
      action <- input$workflow_action
      if (is.null(action) || is.null(action$action)) return()
      switch(
        action$action,
        start = {
          result <- workflow_start(state, action$step)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("Unknown workflow."),
                             type = "error", duration = 5)
          }
        },
        open = {
          result <- workflow_step_open(state, action$step %||% NULL)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("The step is not available."),
                             type = "error", duration = 5)
          } else if (!is.null(result$dialog)) {
            open_dialog_memory(state, result$dialog, result$memory %||% list())
          } else if (!is.null(result$message)) {
            showNotification(result$message, type = "message", duration = 3)
          }
        },
        skip = {
          result <- workflow_skip_step(state, action$step %||% NULL)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("The step cannot be skipped."),
                             type = "warning", duration = 4)
          }
        },
        back = workflow_back(state),
        cancel = {
          workflow_cancel(state)
          showNotification(tr("Workflow cancelled."), type = "message",
                           duration = 2)
        },
        report_section = {
          section <- workflow_report_section(state)
          showModal(modalDialog(
            title = tr("Draft report section"),
            code_preview(section),
            easyClose = TRUE,
            footer = modalButton(tr("Close")),
            size = "l"
          ))
        },
        report_insert = {
          result <- workflow_insert_report(state)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("No report section yet."),
                             type = "warning", duration = 4)
          } else {
            state$show_tab(tr("Report"))
            showNotification(tr("Workflow section inserted into the report."),
                             type = "message", duration = 3)
          }
        }
      )
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$ui_mode_toggle, {
      next_mode <- if (identical(ui_mode(state), "studio")) "classic" else "studio"
      set_ui_mode(state, next_mode)
      tick(tick() + 1L)
      showNotification(
        if (identical(next_mode, "studio")) {
          tr("Studio interface enabled.")
        } else {
          tr("Classic interface enabled.")
        },
        type = "message", duration = 2
      )
    }, ignoreInit = TRUE)

    observeEvent(input$theme, {
      set_ui_theme(state, input$theme %||% "system")
      ace_theme(ui_ace_theme(input$theme %||% "system"))
      persist_preferences()
      session$sendCustomMessage("rcmdr-theme", list(
        theme = input$theme %||% "system",
        density = ui_density(state)
      ))
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$about_open, {
      action <- direct_commands()[["helpAboutCommander"]]
      if (!is.null(action)) action(state)
    }, ignoreInit = TRUE)

    observeEvent(input$home_import, {
      state$open_dialog("readDataSet")
    }, ignoreInit = TRUE)

    observeEvent(input$home_report, {
      state$open_dialog("newRmd")
    }, ignoreInit = TRUE)

    observeEvent(input$home_help, {
      if (is.function(state$help_show)) state$help_show("getting-started")
      state$show_tab(tr("Help"))
    }, ignoreInit = TRUE)

    output$home_checklist <- renderUI({
      tick()
      language_revision()
      onboarding_checklist_ui(state)
    })

    observeEvent(input$home_check_import, {
      state$open_dialog("readDataSet")
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_summary, {
      state$open_dialog("numericalSummaries")
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_chart, {
      state$show_tab(tr("Charts"))
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_report, {
      state$open_dialog("newRmd")
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_project, {
      state$open_dialog("projectNew")
    }, ignoreInit = TRUE)

    output$home_projects <- renderUI({
      tick()
      language_revision()
      project_home_ui(state)
    })

    observeEvent(input$home_project_new, {
      state$open_dialog("projectNew")
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_open, {
      state$open_dialog("projectOpen")
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_save, {
      action <- direct_commands()[["projectSave"]]
      if (!is.null(action)) action(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_bundle, {
      state$open_dialog("projectBundle")
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_recent_open, {
      path <- input$home_project_recent %||% ""
      if (!nzchar(path)) return()
      result <- tryCatch(project_load(state, path), error = function(e) e)
      if (inherits(result, "error")) {
        showNotification(conditionMessage(result), type = "error")
        return()
      }
      if (is.function(state$sync_document)) state$sync_document()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$project_recovery_recover, {
      path <- state$project_recovery_path
      removeModal()
      if (is.null(path)) return()
      result <- tryCatch(project_recover(state, path), error = function(e) e)
      if (inherits(result, "error")) {
        showNotification(conditionMessage(result), type = "error")
        return()
      }
      if (is.function(state$sync_document)) state$sync_document()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$project_recovery_ignore, {
      state$project_recovery_ignored <- TRUE
      removeModal()
    }, ignoreInit = TRUE)

    observeEvent(input$project_recovery_delete, {
      path <- state$project_recovery_path
      removeModal()
      if (!is.null(path)) unlink(paste0(path, ".autosave"))
      state$project_recovery_ignored <- TRUE
    }, ignoreInit = TRUE)

    output$home_continue <- renderUI({
      tick()
      dataset_name <- active_dataset(state)
      model_name <- active_model(state)
      htmltools::tags$div(
        class = "rcmdr-home-card",
        card_head(htmltools::tags$h5(tr("Continue"))),
        note(sprintf(tr("Active data: %s"),
                     dataset_name %||% tr("none"))),
        note(sprintf(tr("Active model: %s"),
                     model_name %||% tr("none"))),
        note(sprintf(tr("Document: %s"), document_mode(state))),
        action_row(
          actionButton("home_view_data", tr("View data"),
                       class = "btn-sm btn-outline-secondary"),
          actionButton("home_script", tr("Open script"),
                       class = "btn-sm btn-outline-secondary")
        )
      )
    })

    observeEvent(input$home_view_data, {
      state$show_tab(tr("Data"))
    }, ignoreInit = TRUE)

    observeEvent(input$home_script, {
      state$show_tab(tr("Script"))
    }, ignoreInit = TRUE)

    output$home_recent <- renderUI({
      tick()
      history_revision()
      entries <- history_recent(state, 5L)
      htmltools::tags$div(
        class = "rcmdr-home-card",
        card_head(htmltools::tags$h5(tr("Recent commands"))),
        if (length(entries) == 0L) {
          note(tr("No commands yet."))
        } else {
          htmltools::tags$ul(
            class = "rcmdr-home-list",
            lapply(entries, function(entry) {
              htmltools::tags$li(
                paste0(history_command_label(entry, 70L), " \u00b7 ",
                       format(entry$time %||% Sys.time(), "%H:%M"))
              )
            })
          )
        }
      )
    })

    output$home_health <- renderUI({
      tick()
      language_revision()
      health_panel_ui(state)
    })

    observeEvent(input$health_refresh, {
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$health_diagnostics, {
      action <- direct_commands()[["helpDiagnostics"]]
      if (!is.null(action)) action(state)
    }, ignoreInit = TRUE)

    outputOptions(output, "history_cards", suspendWhenHidden = FALSE)
    outputOptions(output, "console_log", suspendWhenHidden = FALSE)
    outputOptions(output, "home_recent", suspendWhenHidden = FALSE)

    # -- data pane ----------------------------------------------------------

    output$data_info <- renderUI({
      tick()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      htmltools::tags$span(
        class = "text-muted",
        sprintf(tr("%d rows x %d columns, %d cells"),
                nrow(df), ncol(df), nrow(df) * ncol(df)),
        if (!editable_dataset(state)) {
          htmltools::tags$span(
            class = "text-warning",
            tr(" (editing disabled: threshold exceeded)")
          )
        }
      )
    })

    output$data_pane <- renderUI({
      tick()
      df <- dataset(state)
      if (is.null(df)) {
        return(htmltools::tags$p(class = "text-muted",
                                 tr("No active data set.")))
      }
      if (identical(input$data_mode %||% "view", "edit")) {
        if (!editable_dataset(state)) {
          return(htmltools::tags$div(
            class = "alert alert-warning",
            tr("This data set exceeds the interactive editing threshold.")
          ))
        }
        return(rhandsontable::rHandsontableOutput("data_editor"))
      }
      DT::dataTableOutput("data_table")
    })

    output$data_table <- DT::renderDataTable({
      tick()
      df <- dataset(state)
      req(df)
      DT::datatable(
        df,
        options = list(pageLength = 10, scrollX = TRUE, dom = "ftip"),
        rownames = FALSE
      )
    }, server = FALSE)

    output$data_editor <- rhandsontable::renderRHandsontable({
      tick()
      df <- dataset(state)
      req(df, editable_dataset(state))
      editor_context(list(dataset = active_dataset(state),
                          token = editor_token()))
      widget <- rhandsontable::rhandsontable(
        df, height = 480, stretchH = "all", useTypes = TRUE
      )
      for (column in editor_readonly_columns(df)) {
        widget <- rhandsontable::hot_col(widget, column, readOnly = TRUE)
      }
      widget |>
        rhandsontable::hot_rows(
          rowHeights = ui_table_row_height(ui_density(state))
        )
    })

    action_clicked <- function(value) {
      if (is.null(value) || length(value) == 0L) return(FALSE)
      if (is.character(value)) return(any(value == "click"))
      value <- suppressWarnings(as.numeric(value))
      length(value) == 1L && !is.na(value) && value > 0
    }

    data_selected_column <- reactive({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df) || ncol(df) == 0L) return(NULL)
      column <- input$data_inspector_column %||% ""
      if (!nzchar(column) || !column %in% names(df)) column <- names(df)[[1L]]
      column
    })

    observeEvent(input$data_dictionary, {
      if (!action_clicked(input$data_dictionary)) return()
      open_dialog_memory(state, "dataDictionary",
                         list(variable = data_selected_column()))
    }, ignoreInit = TRUE)

    observeEvent(input$data_checkpoints, {
      if (!action_clicked(input$data_checkpoints)) return()
      open_dialog_memory(state, "dataCheckpoints", list())
    }, ignoreInit = TRUE)

    observeEvent(input$data_create_subset, {
      if (!action_clicked(input$data_create_subset)) return()
      open_dialog_memory(state, "dataCreateSubset", list())
    }, ignoreInit = TRUE)

    observeEvent(input$data_delete_rows, {
      if (!action_clicked(input$data_delete_rows)) return()
      rows <- data_selection(state)$rows
      if (length(rows) == 0L) {
        showNotification(tr("Select one or more rows first."),
                         type = "message", duration = 4)
        return()
      }
      open_dialog_memory(state, "dataDeleteRows", list(rows = rows))
    }, ignoreInit = TRUE)

    observeEvent(input$data_duplicate_column, {
      if (!action_clicked(input$data_duplicate_column)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "dataDuplicateColumn", list(variable = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_add_column, {
      if (!action_clicked(input$data_add_column)) return()
      open_dialog_memory(state, "dataAddColumn", list())
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_type, {
      if (!action_clicked(input$data_col_type)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "dataColumnType", list(variable = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_label, {
      if (!action_clicked(input$data_col_label)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "dataDictionary", list(variable = column))
    }, ignoreInit = TRUE)

    refresh_data_ui <- function(touch_dataset = TRUE) {
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
      if (isTRUE(touch_dataset)) {
        data_grid_revision(data_grid_revision() + 1L)
      }
      invisible(NULL)
    }

    run_data_commands <- function(commands, checkpoint_label = NULL,
                                  destructive = FALSE) {
      commands <- commands %||% character()
      commands <- commands[nzchar(commands)]
      if (length(commands) == 0L) return(invisible(FALSE))
      if (isTRUE(destructive)) {
        checkpoint_create(state, checkpoint_label %||% tr("Before Data Studio change"))
      }
      before <- undo_data_snapshot(state)
      ok <- TRUE
      undo_suspended(state, {
        for (command in commands) {
          outcome <- run_command(state, command, source = "data")
          if (!identical(outcome$status, "ok")) ok <- FALSE
        }
      })
      label <- trimws(sub("^Before ", "", checkpoint_label %||%
                            tr("Data Studio change")))
      if (nzchar(label)) {
        label <- paste0(toupper(substr(label, 1L, 1L)), substring(label, 2L))
      }
      undo_record(state, "data", label, before, undo_data_snapshot(state))
      refresh_data_ui()
      invisible(ok)
    }

    observeEvent(input$data_apply, {
      if (!action_clicked(input$data_apply)) return()
      problem <- editor_apply_error(
        input$data_mode %||% "view",
        editor_context(),
        input$data_editor_stamp %||% "",
        editor_token(),
        active_dataset(state)
      )
      if (!is.null(problem)) {
        showNotification(problem, type = "warning", duration = 6)
        return()
      }
      editor <- input$data_studio_editor %||% input$data_editor
      req(editor)
      df <- tryCatch(
        rhandsontable::hot_to_r(editor),
        error = function(e) NULL
      )
      if (is.null(df) || !is.data.frame(df)) {
        showNotification(tr("The edited data are not valid."),
                         type = "error", duration = 6)
        return()
      }
      old <- dataset(state)
      req(old)
      problems <- validate_edited_data(old, df)
      if (length(problems) > 0L) {
        showNotification(paste(problems, collapse = " "),
                         type = "error", duration = 8)
        return()
      }
      df <- align_edited_data(old, df)
      commands <- cmd_edit_cells(active_dataset(state), old, df)
      if (length(commands) == 0L) {
        showNotification(tr("No changes to apply."), type = "message",
                         duration = 3)
        return()
      }
      ok <- run_data_commands(
        commands,
        checkpoint_label = tr("Before cell editing"),
        destructive = TRUE
      )
      if (!isTRUE(ok)) {
        showNotification(tr("Some changes could not be applied."),
                         type = "error", duration = 8)
        return()
      }
      showNotification(tr("Data set updated."), type = "message", duration = 3)
    }, ignoreInit = TRUE)

    observeEvent(input$data_refresh, {
      if (!action_clicked(input$data_refresh)) return()
      dataset_register(state, active_dataset(state), refresh = TRUE)
      refresh_data_ui()
    }, ignoreInit = TRUE)

    # -- Data Studio --------------------------------------------------------

    output$data_dataset_selector <- renderUI({
      tick()
      data_grid_revision()
      registry <- dataset_registry(state)
      if (nrow(registry) == 0L) {
        return(htmltools::tags$span(class = "text-muted small",
                                    tr("No data sets registered")))
      }
      labels <- sprintf("%s (%d x %d)", registry$name, registry$rows,
                        registry$cols)
      selectInput(
        "data_dataset_choice", tr("Active data set"),
        choices = stats::setNames(registry$name, labels),
        selected = active_dataset(state),
        width = "100%"
      )
    })

    observeEvent(input$data_dataset_choice, {
      choice <- input$data_dataset_choice %||% ""
      if (!nzchar(choice) || identical(choice, active_dataset(state))) return()
      dataset_activate(state, choice)
      clear_data_selection(state)
      data_selection_revision(data_selection_revision() + 1L)
      refresh_data_ui()
    }, ignoreInit = TRUE)

    data_filter_value_d <- shiny::debounce(
      reactive(input$data_filter_value %||% ""), 300
    )

    output$data_filter_ui <- renderUI({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      choices <- stats::setNames(
        c("", names(df)),
        c(tr("(no column filter)"), names(df))
      )
      selected <- input$data_filter_column %||% ""
      if (!selected %in% names(df)) selected <- ""
      value <- isolate(input$data_filter_value %||% "")
      dates <- isolate(input$data_filter_dates %||% NULL)
      by_date <- nzchar(selected) && date_column(df[[selected]])
      htmltools::div(
        class = "rcmdr-toolbar-fields",
        selectInput("data_filter_column", NULL, choices = choices,
                    selected = selected, width = "190px"),
        if (by_date) {
          date_range_input(
            "data_filter_dates", NULL,
            value = dates,
            language = current_language(),
            width = "260px"
          )
        } else {
          textInput("data_filter_value", NULL, value = value,
                    placeholder = tr("Filter value"), width = "150px")
        },
        actionButton("data_filter_clear", tr("Clear filter"),
                     class = "btn-sm btn-outline-secondary")
      )
    })

    data_view_frame <- reactive({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      grid <- data_grid_frame(df)
      frame <- grid
      column <- input$data_filter_column %||% ""
      if (nzchar(column) && column %in% names(grid)) {
        # A date column has its own control: the text value keeps working for
        # every other type, and neither path writes to the data set.
        if (date_column(grid[[column]])) {
          keep <- date_range_keep(grid[[column]],
                                  input$data_filter_dates %||% NULL)
          frame <- grid[keep %in% TRUE, , drop = FALSE]
        } else {
          value <- trim_blanks(data_filter_value_d() %||% "")
          if (nzchar(value)) {
            x <- grid[[column]]
            keep <- tryCatch({
              if (is.numeric(x)) {
                number <- suppressWarnings(as.numeric(value))
                if (!is.na(number)) {
                  !is.na(x) & x == number
                } else {
                  grepl(value, as.character(x), ignore.case = TRUE,
                        fixed = TRUE)
                }
              } else {
                grepl(value, as.character(x), ignore.case = TRUE, fixed = TRUE)
              }
            }, error = function(e) rep(TRUE, nrow(grid)))
            frame <- grid[keep %in% TRUE, , drop = FALSE]
          }
        }
      }
      # The column order is a view preference: it never writes the data frame.
      data_order_columns(frame, column_order_current(state, df))
    })

    observeEvent(input$data_filter_clear, {
      if (!action_clicked(input$data_filter_clear)) return()
      updateSelectInput(session, "data_filter_column", selected = "")
      updateTextInput(session, "data_filter_value", value = "")
      updateAirDateInput(session, "data_filter_dates", clear = TRUE)
      data_grid_revision(data_grid_revision() + 1L)
    }, ignoreInit = TRUE)

    # Column order: the header drag sends the names in the new order, the two
    # buttons move the selected column.  Both land in the same preference.
    move_data_column <- function(delta) {
      df <- dataset(state)
      column <- data_selected_column()
      if (is.null(df) || is.null(column) || !nzchar(column)) {
        return(invisible(FALSE))
      }
      order <- column_order_current(state, df)
      moved <- column_order_move(order, column, delta)
      if (is.null(moved)) return(invisible(FALSE))
      column_order_store(state, active_dataset(state), moved, names(df))
      persist_preferences()
      data_grid_revision(data_grid_revision() + 1L)
      invisible(TRUE)
    }

    observeEvent(input$data_column_order, {
      df <- dataset(state)
      if (is.null(df)) return()
      order <- input$data_column_order
      if (is.list(order)) order <- unlist(order, use.names = FALSE)
      if (!is.character(order) || length(order) == 0L) return()
      column_order_store(state, active_dataset(state), order, names(df))
      persist_preferences()
      data_grid_revision(data_grid_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_column_left, {
      if (!action_clicked(input$data_column_left)) return()
      move_data_column(-1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_column_right, {
      if (!action_clicked(input$data_column_right)) return()
      move_data_column(1L)
    }, ignoreInit = TRUE)

    output$data_grid <- renderUI({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df)) {
        return(empty_state(
          tr("No active data set"),
          tr("Import a file or load a data set from a package to start.")
        ))
      }
      mode <- input$data_mode %||% "view"
      if (identical(mode, "edit") && editable_dataset(state)) {
        return(rhandsontable::rHandsontableOutput("data_studio_editor"))
      }
      targeted <- identical(mode, "edit") && !editable_dataset(state)
      server_mode <- nrow(df) > (state$options$dt_server_threshold %||% 5000L)
      htmltools::tagList(
        if (targeted) {
          htmltools::tags$div(
            class = "alert alert-warning py-2",
            tr("This data set is above the interactive editing threshold. Targeted column and row actions remain available.")
          )
        },
        if (server_mode) {
          DT::dataTableOutput("data_studio_table_server")
        } else {
          DT::dataTableOutput("data_studio_table")
        }
      )
    })

    output$data_editor_note <- renderUI({
      req(identical(input$data_mode %||% "view", "edit"))
      df <- dataset(state)
      req(df, editable_dataset(state))
      readonly <- editor_readonly_columns(df)
      message <- if (length(readonly) > 0L) {
        sprintf(tr("Read-only in the editor: %s. Apply changes before leaving Edit; unapplied edits are discarded."),
                paste(readonly, collapse = ", "))
      } else {
        tr("Apply changes before leaving Edit; unapplied edits are discarded.")
      }
      note(message)
    })

    output$data_studio_table <- DT::renderDataTable({
      tick()
      data_grid_revision()
      selection_mode <- input$data_selection_mode %||% "rows"
      grid <- data_view_frame()
      req(grid)
      DT::datatable(
        grid,
        selection = "none",
        callback = grid_selection_callback(selection_mode),
        options = list(
          pageLength = 25L, scrollX = TRUE, searchHighlight = TRUE,
          autoWidth = TRUE,
          columnDefs = list(
            list(visible = FALSE, targets = ncol(grid) - 1L)
          )
        ),
        rownames = FALSE
      )
    }, server = FALSE)

    output$data_studio_table_server <- DT::renderDataTable({
      tick()
      data_grid_revision()
      selection_mode <- input$data_selection_mode %||% "rows"
      grid <- data_view_frame()
      req(grid)
      DT::datatable(
        grid,
        selection = "none",
        callback = grid_selection_callback(selection_mode),
        options = list(
          pageLength = 25L, scrollX = TRUE, autoWidth = TRUE,
          dom = "ftip",
          columnDefs = list(
            list(visible = FALSE, targets = ncol(grid) - 1L)
          )
        ),
        rownames = FALSE
      )
    }, server = TRUE)

    output$data_studio_editor <- rhandsontable::renderRHandsontable({
      tick()
      data_grid_revision()
      df <- dataset(state)
      req(df, editable_dataset(state))
      editor_context(list(dataset = active_dataset(state),
                          token = editor_token()))
      widget <- rhandsontable::rhandsontable(
        df, height = 520, stretchH = "all", useTypes = TRUE
      ) |>
        # Row insertion/removal and column sorting have no command yet: the
        # editor must not offer them until they can be applied.
        rhandsontable::hot_context_menu(allowRowEdit = FALSE,
                                        allowColEdit = FALSE) |>
        rhandsontable::hot_cols(manualColumnResize = TRUE)
      for (column in editor_readonly_columns(df)) {
        widget <- rhandsontable::hot_col(widget, column, readOnly = TRUE)
      }
      widget |>
        rhandsontable::hot_rows(
          rowHeights = ui_table_row_height(ui_density(state))
        )
    })

    output$data_inspector <- renderUI({
      tick()
      data_grid_revision()
      data_selection_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      column <- data_selected_column()
      profile <- column_profile(state, active_dataset(state), column)
      htmltools::tags$div(
        class = "rcmdr-section-card",
        selectInput(
          "data_inspector_column", tr("Column"),
          choices = stats::setNames(names(df), names(df)),
          selected = column, width = "100%"
        ),
        data_inspector_ui(profile),
        if (!is.null(column)) variable_suggestions_ui(state, column)
      )
    })

    observeEvent(input$variable_suggestion, {
      action <- input$variable_suggestion
      if (is.null(action) || is.null(action$variable) ||
          is.null(action$dialog)) {
        return()
      }
      if (!action$dialog %in% dialog_ids()) return()
      open_dialog_memory(
        state, action$dialog,
        suggestion_memory(state, action$variable, action$dialog)
      )
    }, ignoreInit = TRUE)

    output$data_selection_columns_ui <- renderUI({
      tick()
      data_grid_revision()
      data_selection_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      selectizeInput(
        "data_selection_columns", tr("Columns for subset"),
        choices = stats::setNames(names(df), names(df)),
        selected = data_selection(state)$columns,
        multiple = TRUE, width = "100%"
      )
    })

    output$data_profile_plot <- renderPlot({
      tick()
      data_grid_revision()
      column <- data_selected_column()
      req(column)
      profile <- column_profile(state, active_dataset(state), column)
      req(profile)
      graphics::par(mar = c(3, 3, 1, 1))
      if (!is.null(profile$histogram)) {
        graphics::barplot(
          profile$histogram$counts,
          names.arg = format(profile$histogram$mids, digits = 3),
          col = "#4c78a8", border = NA, las = 2, cex.names = 0.7,
          main = "", ylab = "", xlab = ""
        )
      } else if (!is.null(profile$levels)) {
        top <- utils::head(profile$levels, 10L)
        graphics::barplot(
          top$count, names.arg = top$value, col = "#4c78a8", border = NA,
          las = 2, cex.names = 0.7, ylab = "", xlab = ""
        )
      } else {
        graphics::plot.new()
      }
    })

    output$data_missingness <- renderUI({
      tick()
      data_grid_revision()
      data_missingness_ui(data_missingness(state))
    })

    output$data_selection_bar <- renderUI({
      tick()
      data_selection_revision()
      selection <- data_selection(state)
      htmltools::tags$div(
        class = "rcmdr-selection-bar",
        htmltools::tags$span(selection_summary(state)),
        if (length(selection$rows) > 0L || length(selection$columns) > 0L ||
            nzchar(selection$expression %||% "") ||
            length(selection$cells$row_ids %||% integer()) > 0L) {
          htmltools::tagList(
            actionButton("data_selection_copy", tr("Copy selection"),
                         class = "btn-sm btn-link"),
            actionButton("data_selection_clear", tr("Clear selection"),
                         class = "btn-sm btn-link")
          )
        }
      )
    })

    observeEvent(input$data_selection_mode, {
      mode <- input$data_selection_mode %||% "rows"
      state$data_selection_mode <- if (identical(mode, "cells")) "cells" else "rows"
      clear_data_selection(state)
      data_selection_revision(data_selection_revision() + 1L)
      data_grid_revision(data_grid_revision() + 1L)
    }, ignoreInit = TRUE)

    # A redraw invalidates the visual selection: the row nodes and the page
    # are new, and a stale range would copy the wrong rows.
    observeEvent(data_grid_revision(), {
      if (!is.null(state$data_selection)) {
        clear_data_selection(state)
        data_selection_revision(data_selection_revision() + 1L)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$data_grid_selection, {
      if (!identical(state$data_selection_mode %||% "rows", "rows")) return()
      rows <- input$data_grid_selection %||% integer()
      rows <- as.integer(rows)
      rows <- rows[!is.na(rows)]
      columns <- data_selection(state)$columns
      set_data_selection(state, rows = rows, columns = columns)
      data_selection_revision(data_selection_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_cell_selection, {
      if (!identical(state$data_selection_mode %||% "rows", "cells")) return()
      payload <- input$data_cell_selection
      frame <- data_view_frame()
      if (is.null(payload) || is.null(frame)) {
        clear_data_selection(state)
        data_selection_revision(data_selection_revision() + 1L)
        return()
      }
      row_ids <- suppressWarnings(as.integer(unlist(payload$row_ids %||% integer())))
      row_ids <- row_ids[!is.na(row_ids)]
      columns <- as.character(unlist(payload$columns %||% character()))
      row_ids <- frame$.row_id[frame$.row_id %in% row_ids]
      columns <- setdiff(names(frame)[names(frame) %in% columns], ".row_id")
      if (length(row_ids) == 0L || length(columns) == 0L) {
        clear_data_selection(state)
        data_selection_revision(data_selection_revision() + 1L)
        return()
      }
      row_pos <- match(row_ids, frame$.row_id)
      col_pos <- match(columns, names(frame))
      range <- sprintf("R%dC%d:R%dC%d", min(row_pos), min(col_pos),
                       max(row_pos), max(col_pos))
      set_data_selection(
        state, rows = row_ids, columns = columns,
        cells = list(row_ids = row_ids, columns = columns, range = range)
      )
      data_selection_revision(data_selection_revision() + 1L)
    }, ignoreInit = TRUE)

    copy_selection <- function() {
      frame <- data_view_frame()
      text <- selection_tsv(state, frame)
      if (!nzchar(text)) {
        showNotification(tr("Select one or more cells first."),
                         type = "message", duration = 4)
        return(invisible(FALSE))
      }
      session$sendCustomMessage("rcmdr-copy", list(text = text))
      subset <- selection_subset_frame(state, frame)
      showNotification(
        sprintf(tr("Copied %d row(s) and %d column(s) as TSV."),
                nrow(subset), ncol(subset)),
        type = "message", duration = 3
      )
      invisible(TRUE)
    }
    state$copy_selection <- copy_selection

    observeEvent(input$data_selection_copy, {
      if (!action_clicked(input$data_selection_copy)) return()
      copy_selection()
    }, ignoreInit = TRUE)

    observeEvent(input$copy_selection_shortcut, {
      copy_selection()
    }, ignoreInit = TRUE)

    observeEvent(input$data_selection_columns, {
      rows <- data_selection(state)$rows
      set_data_selection(
        state, rows = rows,
        columns = input$data_selection_columns %||% character()
      )
      data_selection_revision(data_selection_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_selection_clear, {
      if (!action_clicked(input$data_selection_clear)) return()
      clear_data_selection(state)
      data_selection_revision(data_selection_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_search, {
      df <- dataset(state)
      if (is.null(df)) return()
      id <- if (nrow(df) > (state$options$dt_server_threshold %||% 5000L)) {
        "data_studio_table_server"
      } else {
        "data_studio_table"
      }
      tryCatch({
        proxy <- DT::dataTableProxy(id, session = session)
        DT::updateSearch(
          proxy,
          keywords = list(global = input$data_search %||% "")
        )
      }, error = function(e) NULL)
    }, ignoreInit = TRUE)

    observeEvent(input$data_import_wizard, {
      if (!action_clicked(input$data_import_wizard)) return()
      state$open_dialog("dataImportWizard")
    }, ignoreInit = TRUE)

    # A dropped text file is stored and handed to the normal Read Text Data
    # dialog, prefilled.  The dialog is the confirmation step: no command runs
    # until the user presses OK.
    observeEvent(input$data_drop_file, {
      drop <- input$data_drop_file
      if (!is.list(drop)) return()
      name <- paste(as.character(drop$name %||% ""), collapse = "")
      text <- paste(as.character(drop$text %||% ""), collapse = "\n")
      if (!nzchar(name)) return()
      extension <- tolower(tools::file_ext(name))
      text_file <- extension %in% c("csv", "txt", "tsv", "dat", "psv")
      if (!text_file || nchar(text, type = "bytes") > 2 * 1024^2) {
        showNotification(
          tr("Only text data files (CSV, TSV or TXT) up to 2 MB can be dropped."),
          type = "warning", duration = 8
        )
        return()
      }
      path <- tempfile(fileext = paste0(".", extension))
      ok <- tryCatch({
        writeLines(text, path, useBytes = TRUE)
        TRUE
      }, error = function(e) FALSE)
      if (!ok) {
        showNotification(tr("The dropped file could not be stored."),
                         type = "error", duration = 8)
        return()
      }
      stored <- store_import_file(path, name)
      unlink(path)
      if (is.null(stored)) {
        showNotification(tr("The dropped file could not be stored."),
                         type = "error", duration = 8)
        return()
      }
      suggestion <- make.names(tools::file_path_sans_ext(basename(name)))
      if (!nzchar(suggestion) || !is_valid_name(suggestion)) {
        suggestion <- "Dataset"
      }
      open_dialog_memory(state, "readDataSet", list(
        dsname = suggestion,
        location = "local",
        path = stored,
        header = TRUE,
        delimiter = switch(
          extension,
          csv = "commas",
          tsv = "tabs",
          "whitespace"
        ),
        stringsAsFactors = TRUE
      ))
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_summary, {
      if (!action_clicked(input$data_col_summary)) return()
      column <- data_selected_column()
      req(column)
      if (!column %in% numeric_variables(state)) {
        showNotification(tr("Numerical summaries need a numeric variable."),
                         type = "message", duration = 5)
        return()
      }
      open_dialog_memory(state, "numericalSummaries", list(x = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_plot, {
      if (!action_clicked(input$data_col_plot)) return()
      column <- data_selected_column()
      req(column)
      df <- dataset(state)
      if (is.numeric(df[[column]])) {
        open_dialog_memory(state, "Histogram", list(variable = column))
      } else {
        open_dialog_memory(state, "barGraph", list(variable = column))
      }
    }, ignoreInit = TRUE)



    observeEvent(input$data_col_rename, {
      if (!action_clicked(input$data_col_rename)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "renameVariables",
                         list(variables = column, names = column))
    }, ignoreInit = TRUE)



    observeEvent(input$data_col_recode, {
      if (!action_clicked(input$data_col_recode)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "RecodeDialog", list(variables = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_delete, {
      if (!action_clicked(input$data_col_delete)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "deleteVariable", list(variables = column))
    }, ignoreInit = TRUE)



    observeEvent(input$data_add_row, {
      if (!action_clicked(input$data_add_row)) return()
      run_data_commands(
        cmd_add_row(active_dataset(state)),
        checkpoint_label = tr("Before adding a row"),
        destructive = TRUE
      )
    }, ignoreInit = TRUE)

    observeEvent(input$data_duplicate_rows, {
      if (!action_clicked(input$data_duplicate_rows)) return()
      rows <- data_selection(state)$rows
      if (length(rows) == 0L) {
        showNotification(tr("Select one or more rows first."),
                         type = "message", duration = 4)
        return()
      }
      run_data_commands(
        cmd_duplicate_rows(active_dataset(state), rows),
        checkpoint_label = tr("Before duplicating rows"),
        destructive = TRUE
      )
    }, ignoreInit = TRUE)






    output$download_dictionary_csv <- downloadHandler(
      filename = function() {
        paste0(active_dataset(state) %||% "dictionary", "-dictionary.csv")
      },
      content = function(file) {
        utils::write.csv(dictionary_export(state), file, row.names = FALSE)
      }
    )

    output$download_dictionary_yaml <- downloadHandler(
      filename = function() {
        paste0(active_dataset(state) %||% "dictionary", "-dictionary.yml")
      },
      content = function(file) {
        table <- dictionary_export(state)
        entries <- lapply(seq_len(nrow(table)), function(i) {
          list(
            variable = table$variable[[i]],
            label = table$label[[i]],
            units = table$units[[i]],
            description = table$description[[i]]
          )
        })
        names(entries) <- table$variable
        yaml::write_yaml(entries, file)
      }
    )

    output$environment_pane <- renderUI({
      req(view_ready(input, "environment"))
      tick()
      objects <- ls(envir = state$env)
      if (length(objects) == 0L) {
        return(htmltools::tags$p(class = "text-muted",
                                 tr("The environment is empty.")))
      }
      info <- data.frame(
        name = objects,
        class = vapply(objects, function(x) {
          paste(class(get(x, envir = state$env)), collapse = ", ")
        }, character(1)),
        size = vapply(objects, function(x) {
          object <- get(x, envir = state$env)
          if (is.data.frame(object)) {
            sprintf("%d x %d", nrow(object), ncol(object))
          } else {
            as.character(utils::object.size(object))
          }
        }, character(1)),
        stringsAsFactors = FALSE
      )
      DT::datatable(info, rownames = FALSE, options = list(dom = "t"))
    })

    # -- environment and models ---------------------------------------------

    output$environment_objects <- renderUI({
      req(view_ready(input, "environment"))
      tick()
      environment_objects_ui(state, input$environment_filter %||% "")
    })

    output$environment_preview <- renderUI({
      req(view_ready(input, "environment"))
      tick()
      preview <- state$environment_preview
      if (is.null(preview) || !nzchar(preview)) {
        return(help_text(tr("Select Preview on an object to inspect it here.")))
      }
      htmltools::tags$pre(class = "rcmdr-object-preview", preview)
    })

    output$environment_datasets <- renderUI({
      req(view_ready(input, "environment"))
      tick()
      environment_datasets_ui(state)
    })

    output$models_dashboard <- renderUI({
      req(view_ready(input, "environment"))
      tick()
      menu_revision()
      models_dashboard_ui(state)
    })

    # The environment outputs are built on first open; no hidden output keeps
    # the models dashboard alive in the background.

    observeEvent(input$environment_action, {
      action <- input$environment_action
      if (is.null(action) || !nzchar(action$name %||% "")) return()
      result <- object_action(state, action$name, action$action %||% "preview")
      if (!isTRUE(result$ok) && nzchar(result$message %||% "")) {
        showNotification(result$message, type = "message", duration = 5)
      }
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$environment_refresh, {
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$environment_refresh_datasets, {
      dataset_registry(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$model_action, {
      action <- input$model_action
      if (is.null(action) || !nzchar(action$name %||% "")) return()
      result <- model_action(state, action$name, action$action %||% "select")
      if (!isTRUE(result$ok) && nzchar(result$message %||% "")) {
        showNotification(result$message, type = "message", duration = 5)
      }
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    # -- plots --------------------------------------------------------------

    current_plot <- reactive({
      tick()
      n <- length(state$plots)
      if (n == 0L) return(NULL)
      index <- plot_selected()
      if (is.null(index) || index < 1L || index > n) index <- n
      state$plots[[index]]
    })

    observeEvent(input$plot_selected, {
      plot_selected(input$plot_selected)
    }, ignoreInit = TRUE)

    observeEvent(tick(), {
      n <- length(state$plots)
      if (n > last_plot_count()) {
        plot_selected(NULL)
        last_plot_count(n)
      }
    }, ignoreInit = TRUE)

    output$plot_gallery <- renderUI({
      tick()
      n <- length(state$plots)
      if (n == 0L) return(NULL)
      active <- plot_selected()
      if (is.null(active) || active < 1L || active > n) active <- n
      htmltools::div(
        class = "rcmdr-gallery",
        lapply(seq_len(n), function(index) {
          plot <- state$plots[[index]]
          htmltools::tags$img(
            src = plot$url %||% "",
            class = paste("rcmdr-thumb", if (index == active) "active"),
            title = plot$code, alt = plot$code,
            onclick = sprintf(
              "Shiny.setInputValue('plot_selected', %d, {priority: 'event'})",
              index
            )
          )
        })
      )
    })

    output$plotly_pane <- renderUI({
      tick()
      if (!plotly_available() || is.null(state$plotly_widget)) return(NULL)
      htmltools::tagList(
        htmltools::tags$h6(state$plotly_title %||% tr("Interactive plot")),
        plotly::plotlyOutput("plotly_plot", height = "480px")
      )
    })

    if (plotly_available()) {
      output$plotly_plot <- plotly::renderPlotly({
        tick()
        req(state$plotly_widget)
        state$plotly_widget
      })
    }

    output$plot_image <- renderImage({
      plot <- current_plot()
      req(plot)
      list(src = plot$file, contentType = "image/png", alt = plot$code)
    }, deleteFile = FALSE)

    output$plot_header <- renderUI({
      tick()
      if (length(state$plots) == 0L) {
        return(htmltools::tags$p(class = "text-muted", tr("No plot yet.")))
      }
      plot <- current_plot()
      req(plot)
      htmltools::tags$div(
        class = "mb-2",
        htmltools::tags$strong(sprintf(
          tr("Plot %d of %d"),
          plot_selected() %||% length(state$plots), length(state$plots)
        )),
        htmltools::tags$pre(class = "small text-muted mb-1", plot$code)
      )
    })

    output$rgl_pane <- renderUI({
      tick()
      if (is.null(state$rgl_widget)) return(NULL)
      htmltools::tagList(
        htmltools::tags$h6(tr("3D plot")),
        if (requireNamespace("rgl", quietly = TRUE)) {
          rgl::rglwidgetOutput("rgl_plot", height = "420px")
        }
      )
    })

    if (requireNamespace("rgl", quietly = TRUE)) {
      output$rgl_plot <- rgl::renderRglwidget({
        tick()
        req(state$rgl_widget)
        state$rgl_widget
      })
    }

    # -- Chart Studio -------------------------------------------------------

    chart_studio_server(
      input, output, session, state, chart_revision,
      tick = tick,
      refresh = function(...) {
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        chart_revision(chart_revision() + 1L)
        invisible(NULL)
      }
    )

    # -- Report Studio ------------------------------------------------------

    report_studio_server(
      input, output, session, state,
      tick = tick,
      refresh = function(...) {
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        invisible(NULL)
      }
    )

    # -- downloads ----------------------------------------------------------

    output$download_report_rmd <- downloadHandler(
      filename = function() {
        paste0("rcmdrshiny-report-", Sys.Date(), ".Rmd")
      },
      content = function(file) {
        write_report_rmd(state, file,
                         title = state$report_title %||% "RcmdrShiny report")
      }
    )

    output$download_report_html <- downloadHandler(
      filename = function() {
        paste0("rcmdrshiny-report-", Sys.Date(), ".html")
      },
      content = function(file) {
        write_report_html(state, file,
                          title = state$report_title %||% "RcmdrShiny report")
      }
    )

    output$report_pane <- renderUI({
      tick()
      result <- state$knit_result
      if (is.null(result)) {
        return(htmltools::tags$p(
          class = "text-muted",
          tr("No report yet. Use Knit to build one.")
        ))
      }
      if (identical(result$format, "word")) {
        return(htmltools::tagList(
          htmltools::tags$p(tr("The Word document is ready for download.")),
          htmltools::tags$p(basename(result$file))
        ))
      }
      htmltools::tags$iframe(
        src = result$url %||% "",
        style = "width:100%;height:70vh;border:1px solid #dde2e8;"
      )
    })

    output$download_knit <- downloadHandler(
      filename = function() {
        if (is.null(state$knit_result)) {
          "report.html"
        } else {
          basename(state$knit_result$file)
        }
      },
      content = function(file) {
        req(state$knit_result)
        file.copy(state$knit_result$file, file, overwrite = TRUE)
      }
    )

    observeEvent(input$knit_refresh, {
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    output$download_script <- downloadHandler(
      filename = function() {
        mode <- document_mode(state)
        paste0("RcmdrShiny-script-", Sys.Date(),
               ".", document_extension(mode))
      },
      content = function(file) {
        writeLines(isolate(script_value()), file)
      }
    )

    output$download_output <- downloadHandler(
      filename = function() "RcmdrShiny-output.txt",
      content = function(file) {
        writeLines(isolate(paste(state$output, collapse = "\n")), file)
      }
    )

    output$download_dataset <- downloadHandler(
      filename = function() {
        name <- active_dataset(state) %||% "dataset"
        paste0(name, ".csv")
      },
      content = function(file) {
        df <- isolate(dataset(state))
        req(df)
        utils::write.csv(df, file, row.names = FALSE)
      }
    )

    output$download_dataset_rdata <- downloadHandler(
      filename = function() {
        name <- active_dataset(state) %||% "dataset"
        paste0(name, ".RData")
      },
      content = function(file) {
        name <- isolate(active_dataset(state))
        req(name)
        save(list = name, file = file, envir = state$env)
      }
    )

    output$download_workspace <- downloadHandler(
      filename = function() "RcmdrShiny-workspace.RData",
      content = function(file) {
        objects <- isolate(ls(envir = state$env))
        req(length(objects) > 0L)
        save(list = objects, file = file, envir = state$env)
      }
    )

    output$download_plot_png <- downloadHandler(
      filename = function() "RcmdrShiny-plot.png",
      content = function(file) {
        plot <- isolate(current_plot())
        req(plot)
        file.copy(plot$file, file, overwrite = TRUE)
      }
    )

    output$download_rgl <- downloadHandler(
      filename = function() "RcmdrShiny-3D.png",
      content = function(file) {
        req(state$rgl_widget)
        rgl::rgl.snapshot(file)
      }
    )

    output$download_plot_pdf <- downloadHandler(
      filename = function() "RcmdrShiny-plot.pdf",
      content = function(file) {
        plot <- isolate(current_plot())
        req(plot, plot$recorded)
        grDevices::pdf(file)
        on.exit(grDevices::dev.off(), add = TRUE)
        grDevices::replayPlot(plot$recorded)
      }
    )

    # -- language -----------------------------------------------------------

    observeEvent(input$language, {
      language <- i18n_normalize(input$language %||% "en")
      state$options$language <- language
      i18n_set_language(language)
      state$palette_cache <- NULL
      persist_preferences()
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      language_revision(language_revision() + 1L)
      showNotification(
        tr("Language changed. Menus, help and new output use the new language."),
        type = "message", duration = 5
      )
    }, ignoreInit = TRUE)

    # -- status bar and badges ---------------------------------------------

    output$dataset_badge <- renderUI({
      tick()
      name <- active_dataset(state)
      htmltools::tags$span(
        if (is.null(name)) tr("No active data set") else name,
        class = if (is.null(name)) {
          "rcmdr-topbar-value rcmdr-topbar-value-empty"
        } else {
          "rcmdr-topbar-value"
        }
      )
    })

    output$model_badge <- renderUI({
      tick()
      name <- active_model(state)
      htmltools::tags$span(
        if (is.null(name)) tr("No active model") else name,
        class = if (is.null(name)) {
          "rcmdr-topbar-value rcmdr-topbar-value-empty"
        } else {
          "rcmdr-topbar-value"
        }
      )
    })

    output$statusbar <- renderUI({
      tick()
      data_selection_revision()
      version <- tryCatch(
        as.character(utils::packageVersion("RcmdrShiny")),
        error = function(e) "0.1.0"
      )
      df <- dataset(state)
      dimensions <- if (is.null(df)) {
        tr("no data")
      } else {
        sprintf("%d x %d", nrow(df), ncol(df))
      }
      selection_text <- selection_status_text(state, data_view_frame())
      # One item per fact: the separators are CSS borders, so a screen reader
      # reads the facts, not a row of pipes.
      htmltools::tagList(
        htmltools::tags$span(
          class = "rcmdr-status-item",
          sprintf(tr("RcmdrShiny Studio %s"), version)
        ),
        htmltools::tags$span(
          class = "rcmdr-status-item",
          badge(toupper(ui_mode(state)), "neutral")
        ),
        htmltools::tags$span(class = "rcmdr-status-item", dimensions),
        htmltools::tags$span(
          class = "rcmdr-status-item",
          sprintf(tr("%d command(s)"), length(state$log))
        ),
        htmltools::tags$span(
          class = "rcmdr-status-item",
          sprintf(tr("%d history step(s)"), length(state$history %||% list()))
        ),
        htmltools::tags$span(
          class = "rcmdr-status-item",
          sprintf(tr("%d plot(s)"), length(state$plots))
        ),
        if (nzchar(selection_text)) {
          htmltools::tags$span(
            class = "rcmdr-status-item rcmdr-status-selection",
            selection_text
          )
        },
        if (!is.null(state$undo_message) && nzchar(state$undo_message)) {
          htmltools::tags$span(
            class = "rcmdr-status-item rcmdr-status-undo",
            state$undo_message
          )
        },
        if (isTRUE(state$busy)) {
          htmltools::tags$span(class = "rcmdr-status-item",
                               badge(tr("busy"), "warning"))
        },
        if (!is.null(state$last_error)) {
          htmltools::tags$span(
            class = "rcmdr-status-item text-danger",
            sprintf(tr("last error: %s"), state$last_error)
          )
        }
      )
    })

    # -- script pane --------------------------------------------------------

    observeEvent(input$script, {
      value <- input$script %||% ""
      if (!identical(isolate(script_value()), value)) {
        script_value(value)
        document_set_text(state, value)
      }
    }, ignoreInit = TRUE)

    observeEvent(tick(), {
      mode <- document_mode(state)
      if (!identical(mode, isolate(editor_mode()))) {
        editor_mode(mode)
        script_value(document_text(state))
      }
    }, ignoreInit = FALSE)

    append_log_to_script <- function() {
      if (!isTRUE(input$auto_append)) return(invisible(NULL))
      if (length(state$log) <= state$script_consumed) return(invisible(NULL))
      new_commands <- state$log[seq.int(state$script_consumed + 1L, length(state$log))]
      state$script_consumed <- length(state$log)
      if (!identical(document_mode(state), "r")) {
        current_document_text()
        for (command in new_commands) document_append_chunk(state, command)
        sync_editor()
        return(invisible(NULL))
      }
      value <- paste(c(isolate(script_value()), new_commands), collapse = "\n")
      script_value(value)
      shinyAce::updateAceEditor(session, "script", value = value)
      invisible(NULL)
    }

    observeEvent(tick(), append_log_to_script(), ignoreInit = TRUE)

    run_script <- function(code) {
      if (is.null(code) || !nzchar(trimws(code))) return(invisible(NULL))
      set_busy(TRUE, tr("Running the script..."))
      result <- script_execute(state, code, source = "script")
      set_busy(FALSE)
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
      if (identical(result$status, "error")) {
        showNotification(
          result$error %||% tr("The script produced an error."),
          type = "error", duration = 8
        )
      }
      invisible(result)
    }

    observeEvent(input$run_all, {
      code <- isolate(script_value())
      mode <- document_mode(state)
      if (!identical(mode, "r")) {
        code <- document_script_from_chunks(code, mode)
      }
      run_script(code)
    }, ignoreInit = TRUE)

    observeEvent(input$run_selection, {
      selection <- input$script_selection %||% ""
      run_script(if (nzchar(trimws(selection))) selection else script_value())
    }, ignoreInit = TRUE)

    observeEvent(input$run_chunk_at, {
      position <- input$run_chunk_at
      row <- position$row %||% 0
      code <- document_chunk_at(current_document_text(), row,
                                document_mode(state))
      if (nzchar(trimws(code))) run_script(code)
    }, ignoreInit = TRUE)

    observeEvent(input$clear_script, {
      if (!identical(document_mode(state), "r")) {
        document_set_text(state, "")
      }
      script_value("")
      shinyAce::updateAceEditor(session, "script", value = "")
    }, ignoreInit = TRUE)

    observeEvent(input$document_mode, {
      mode <- input$document_mode %||% "r"
      if (!identical(mode, document_mode(state))) {
        document_switch_mode(state, mode)
        editor_mode(mode)
        sync_editor()
        menu_revision(menu_revision() + 1L)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$document_new, {
      if (identical(document_mode(state), "r")) {
        current_document_text()
        script_create(state)
        sync_editor()
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        return()
      }
      state$open_dialog(
        if (identical(document_mode(state), "rnw")) "newRnw" else "newRmd"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$document_open, {
      document_open_current(state, document_mode(state))
    }, ignoreInit = TRUE)

    observeEvent(input$document_save, {
      current_document_text()
      document_save_current(state)
    }, ignoreInit = TRUE)

    observeEvent(input$document_save_as, {
      current_document_text()
      state$open_dialog(
        if (identical(document_mode(state), "rnw")) "saveRnwAs" else "saveRmdAs"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$document_knit, {
      current_document_text()
      document_knit_current(state)
    }, ignoreInit = TRUE)

    observeEvent(input$document_section, {
      state$open_dialog("insertSection")
    }, ignoreInit = TRUE)

    observeEvent(input$document_chunk, {
      state$open_dialog("insertChunk")
    }, ignoreInit = TRUE)

    observeEvent(input$document_remove_block, {
      current_document_text()
      removed <- document_remove_current_chunk(state)
      if (isTRUE(removed)) sync_editor()
    }, ignoreInit = TRUE)

    observeEvent(input$document_remove_section, {
      current_document_text()
      removed <- document_remove_current_section(state)
      if (isTRUE(removed)) sync_editor()
    }, ignoreInit = TRUE)

    # -- Script Studio ------------------------------------------------------

    script_studio_server(
      input, output, session, state,
      tick = tick,
      run_code = run_script,
      refresh = function(...) {
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        invisible(NULL)
      }
    )
  }
}

#' Create the RcmdrShiny application
#'
#' @param env Evaluation environment for user commands.  Defaults to the
#'   global environment.
#' @return A `shiny.appobj`.
#' @export
app <- function(env = globalenv(), plugins = NULL) {
  saved <- tryCatch(saved_plugin_selection(), error = function(e) character())
  load_plugins(resolve_startup_plugins(plugins, saved))
  persisted <- tryCatch(preferences_peek(), error = function(e) list())
  if (is.character(persisted$language) && length(persisted$language) == 1L &&
      nzchar(persisted$language)) {
    i18n_set_language(persisted$language)
  }
  shinyApp(ui = app_ui(), server = app_server(env))
}

#' Run RcmdrShiny
#'
#' Starts the local Shiny application in the browser.
#'
#' @param env Evaluation environment for user commands.
#' @param language Language code for the session (for example `"en"` or
#'   `"it"`).  Defaults to the current language.
#' @param ... Further arguments passed to [shiny::runApp()].
#' @return The value returned by [shiny::runApp()], invisibly.
#' @examples
#' \dontrun{
#' RcmdrShiny::run()
#' }
#' @export
run_app <- function(env = globalenv(), language = NULL, plugins = NULL, ...) {
  if (!is.null(language)) Sys.setenv(LANGUAGE = language)
  shiny::runApp(app(env = env, plugins = plugins), ...)
}

#' @rdname run_app
#' @export
run <- run_app
