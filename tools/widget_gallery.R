#!/usr/bin/env Rscript
#
# Widget gallery — development only.
#
#   Rscript tools/widget_gallery.R
#
# Renders every family of parameter controls in the states the Studio promises
# (normal, disabled, invalid, read-only) and lets you switch the eight themes
# and the two densities to check the token bridge.  This file lives in tools/
# and is excluded from the package by .Rbuildignore: it is a workbench, not a
# feature of the application.
#
# The controls use the same helpers and the same IDs a dialog would use.  A
# family that looks wrong here is wrong everywhere.

args <- commandArgs(trailingOnly = FALSE)
hit <- grep("^--file=", args, value = TRUE)
root <- if (length(hit) == 0L) getwd() else {
  dirname(dirname(normalizePath(sub("^--file=", "", hit[[1L]]))))
}
setwd(root)

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required to run the gallery from the working tree.")
}
pkgload::load_all(".", quiet = TRUE, export_all = TRUE)

gallery_card <- function(title, body, note = NULL) {
  htmltools::div(
    class = "rcmdr-section-card",
    htmltools::tags$h6(title),
    if (!is.null(note)) htmltools::tags$p(class = "rcmdr-note", note),
    body
  )
}

gallery_states <- function(input) {
  htmltools::div(
    class = "rcmdr-field-grid",
    htmltools::div(
      class = "rcmdr-field",
      htmltools::tags$label("Normal", class = "form-label"),
      input
    ),
    htmltools::div(
      class = "rcmdr-field",
      htmltools::tags$label("Disabled", class = "form-label"),
      htmltools::tags$input(
        type = "text", class = "form-control", value = "Disabled",
        disabled = NA
      )
    ),
    htmltools::div(
      class = "rcmdr-field",
      htmltools::tags$label("Invalid", class = "form-label"),
      htmltools::tags$input(
        type = "text", class = "form-control is-invalid", value = "Invalid"
      )
    ),
    htmltools::div(
      class = "rcmdr-field",
      htmltools::tags$label("Read only", class = "form-label"),
      htmltools::tags$input(
        type = "text", class = "form-control", value = "Read only",
        readonly = NA
      )
    )
  )
}

gallery_ui <- function() {
  bslib::page_fluid(
    theme = bslib::bs_theme(version = 5, primary = "#1f3a5f"),
    htmltools::tags$head(
      htmltools::tags$title("RcmdrShiny widget gallery"),
      htmltools::tags$style(app_css()),
      htmltools::tags$style(htmltools::HTML(
        ".rcmdr-gallery { padding: 1rem; }",
        ".rcmdr-gallery-toolbar { margin-bottom: 1rem; }",
        ".rcmdr-gallery-toolbar h1 { font-size: var(--rcmdr-text-xl); }",
        ".rcmdr-gallery-controls { display: flex; gap: var(--rcmdr-space-3);",
        "  flex-wrap: wrap; align-items: flex-end; }",
        ".rcmdr-gallery-grid { display: grid;",
        "  grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));",
        "  gap: var(--rcmdr-space-4); align-items: start; }",
        ".rcmdr-gallery .rcmdr-section-card { padding: var(--rcmdr-space-3); }",
        ".rcmdr-gallery .rcmdr-section-card > h6 {",
        "  margin: 0 0 var(--rcmdr-space-2);",
        "  font-size: var(--rcmdr-text-md);",
        "  font-weight: var(--rcmdr-weight-strong); }"
      )),
      htmltools::tags$script(app_js())
    ),
    htmltools::div(
      class = "rcmdr-gallery",
      htmltools::div(
        class = "rcmdr-gallery-toolbar",
        htmltools::tags$h1("Widget gallery"),
        htmltools::tags$p(
          class = "rcmdr-note",
          "Development bench: every family, every state, eight themes and two densities."
        ),
        htmltools::div(
          class = "rcmdr-gallery-controls",
          selectInput(
            "gallery_theme", "Theme",
            choices = stats::setNames(ui_themes(), ui_themes()),
            selected = "light", width = "180px"
          ),
          selectInput(
            "gallery_density", "Density",
            choices = stats::setNames(ui_densities(), ui_densities()),
            selected = "compact", width = "160px"
          )
        )
      ),
      htmltools::div(
        class = "rcmdr-gallery-grid",
        gallery_card(
          "Text, number, textarea, search",
          gallery_states(textInput("g_text", "Text", "value")),
          note = "The same 34/40 px height, border and focus ring."
        ),
        gallery_card(
          "Select and listbox",
          htmltools::tagList(
            selectInput("g_select", "Single select",
                        c("Alpha" = "a", "Beta" = "b")),
            selectInput("g_multi", "Native listbox",
                        c("Alpha" = "a", "Beta" = "b", "Gamma" = "g",
                          "Delta" = "d"),
                        multiple = TRUE, selectize = FALSE, size = 6)
          ),
          note = "Native multiple select is the desktop listbox."
        ),
        gallery_card(
          "Checkbox, radio, switch, segmented",
          htmltools::tagList(
            checkboxInput("g_check", "Checkbox", TRUE),
            radioButtons("g_radio", "Radio",
                         c("One" = "1", "Two" = "2"), selected = "1",
                         inline = TRUE),
            switch_input("g_switch", "Switch", TRUE),
            segmented_input("g_seg", "Segmented",
                            c("Studio" = "studio", "Classic" = "classic"),
                            "studio")
          )
        ),
        gallery_card(
          "Searchable picker and variable list",
          htmltools::tagList(
            shinyWidgets::virtualSelectInput(
              "g_virtual", "Virtual select",
              c("Alpha" = "a", "Beta" = "b", "Gamma" = "g"),
              multiple = TRUE, search = TRUE, showValueAsTags = TRUE
            ),
            picker_input(
              "g_picker", "Searchable picker",
              c("Alpha" = "a", "Beta" = "b", "Gamma" = "g"),
              multiple = FALSE
            ),
            listbox_input(
              "g_listbox", "Desktop listbox",
              c("mpg", "cyl", "disp", "hp"),
              selected = c("mpg", "hp")
            ),
            var_input("g_var", "Variable list (current)",
                      c("mpg", "cyl", "disp", "hp"), multiple = TRUE)
          )
        ),
        gallery_card(
          "Sliders, colour, date",
          htmltools::tagList(
            sliderInput("g_slider", "Shiny slider", 0, 1, .5, .05),
            slider_input("g_slider_desktop", "Studio slider", 0, 1, .5, .05),
            color_input("g_colour", "Colour"),
            shinyWidgets::airDatepickerInput("g_date", "Date")
          )
        ),
        gallery_card(
          "Accordion (bslib bridge)",
          settings_accordion(
            id = "g_accordion",
            open = "First",
            settings_panel(
              "First",
              htmltools::tags$p("The first panel is open."),
              icon = "sliders", badge = "3", grid = FALSE
            ),
            settings_panel(
              "Second",
              htmltools::tags$p("The second panel is closed."),
              grid = FALSE
            )
          )
        ),
        gallery_card(
          "Table",
          DT::datatable(
            utils::head(mtcars, 6),
            rownames = FALSE,
            options = list(dom = "t", pageLength = 6)
          )
        )
      )
    )
  )
}

gallery_server <- function(input, output, session) {
  observeEvent(
    list(input$gallery_theme, input$gallery_density),
    {
      session$sendCustomMessage("rcmdr-theme", list(
        theme = input$gallery_theme %||% "light",
        density = input$gallery_density %||% "compact"
      ))
    },
    ignoreInit = FALSE
  )
}

if (identical(Sys.getenv("RCMDRSHINY_GALLERY_CHECK"), "1")) {
  html <- as.character(gallery_ui())
  stopifnot(nchar(html) > 1000L)
  cat("gallery ok: ", nchar(html), " bytes\n", sep = "")
  quit(status = 0L)
}

port <- suppressWarnings(as.integer(Sys.getenv("RCMDRSHINY_GALLERY_PORT", "0")))
if (!is.na(port) && port > 0L) options(shiny.port = port)

shiny::shinyApp(gallery_ui(), gallery_server)
