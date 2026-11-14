# Minimal Studio console -----------------------------------------------------
#
# A command input is enough for the first Studio release; richer output cards
# arrive with the Workbench wave.  Commands run through run_command(), so the
# log, the structured history and the plot capture are shared with the rest of
# the application.

console_interactive_pattern <- paste0(
  "\\b(readline|readLines|menu|browser|scan|file\\.choose|select\\.list|",
  "utils::menu|utils::readline)\\s*\\("
)

#' Detect commands that may block the browser session
#' @keywords internal
console_is_interactive <- function(code) {
  grepl(console_interactive_pattern, paste(code, collapse = "\n"), perl = TRUE)
}

console_pane_ui <- function() {
  htmltools::tagList(
    htmltools::tags$div(
      class = "rcmdr-console",
      htmltools::tags$div(
        class = "rcmdr-console-input",
        textInput(
          "console_input", NULL,
          placeholder = tr("Type an R command and press Enter"),
          width = "100%"
        ),
        actionButton("console_run", tr("Run"), class = "btn-primary")
      ),
      htmltools::tags$p(
        class = "rcmdr-console-note",
        tr("Commands are logged and added to the history. Interactive prompts are blocked.")
      ),
      uiOutput("console_log")
    )
  )
}
