# Shared browser-tab helpers for the end-to-end tests.
#
# The main views have stable ids: the visible label is translated and changes
# with the UI mode, so the tests select a tab by id, exactly like the server
# does through state$show_tab().

tab_value <- function(label) {
  map <- c(
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
    "Environment" = "environment",
    "Help" = "help",
    "Help centre" = "help",
    "Help center" = "help"
  )
  value <- map[[label]]
  if (is.null(value)) label else unname(value)
}

# Click a main tab by label or id, through the Shiny tabset value.
switch_main_tab <- function(app, label) {
  app$run_js(sprintf(
    paste0(
      "(function(){var id='%s';",
      "var bar=document.getElementById('main_tabs');",
      "var links=bar?bar.querySelectorAll('.nav-link'):[];",
      "var link=Array.from(links).find(function(a){",
      "return a.getAttribute('data-value')===id;});",
      "if(link)link.click();})();"
    ),
    tab_value(label)
  ))
  app$wait_for_idle(timeout = 30000)
}
