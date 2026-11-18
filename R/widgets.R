# Shiny widget library ------------------------------------------------------
#
# Names mirror the Rcmdr widgets they replace (variableListBox, checkBoxes,
# radioButtons, ...), so that a dialog can be ported by substituting widgets
# without rewriting its validation logic.

#' The external widget families this package adopts
#'
#' A single place that names the shinyWidgets functions used by the Studio.
#' The list is intentionally short: searchable lists, bounded numbers and
#' colours.  Everything else stays on Shiny or on our own helpers, so there is
#' no second switch, segmented control or card implementation.
#'
#' @return A named list of functions.
#' @keywords internal
widget_library <- function() {
  list(
    virtual_select = shinyWidgets::virtualSelectInput,
    picker = shinyWidgets::pickerInput,
    slider = shinyWidgets::noUiSliderInput,
    colour = shinyWidgets::spectrumInput
  )
}

w_label <- function(text) {
  htmltools::tags$label(text, class = "form-label")
}

#' @keywords internal
form_group <- function(label, input, help = NULL) {
  htmltools::div(
    class = "mb-3",
    if (!is.null(label)) w_label(label),
    input,
    if (!is.null(help)) htmltools::tags$div(class = "form-text", help)
  )
}

#' Field container
#'
#' A label, a control and a help line with the spacing of the field grid.
#' Use it for hand-built controls; Shiny's own inputs already carry their
#' label and container.
#' @keywords internal
field <- function(input, label = NULL, help = NULL, class = NULL,
                   for_id = NULL) {
  htmltools::div(
    class = c("rcmdr-field", class),
    if (!is.null(label)) {
      htmltools::tags$label(label, class = "form-label", `for` = for_id)
    },
    input,
    if (!is.null(help)) htmltools::tags$div(class = "form-text", help)
  )
}

#' Grid of fields
#'
#' The same `.rcmdr-field-grid` the dialog bodies already use, so a component
#' can join the layout without repeating the class name.
#' @keywords internal
field_grid <- function(..., class = NULL) {
  htmltools::div(class = c("rcmdr-field-grid", class), ...)
}

#' Variable selector
#'
#' Shiny equivalent of Rcmdr's `variableListBox()`.
#' @export
var_input <- function(id, label, choices, selected = NULL, multiple = FALSE,
                      size = NULL, placeholder = NULL, descriptions = NULL) {
  if (length(choices) == 0L) {
    return(form_group(
      label,
      htmltools::tags$div(class = "text-muted", tr("No variables available"))
    ))
  }
  options <- list()
  if (!is.null(placeholder)) options$placeholder <- placeholder
  if (is.null(selected) || (length(selected) == 1L && !nzchar(selected))) {
    selected <- character()
  }
  selected <- intersect(selected, choices)
  labels <- choices
  if (!is.null(descriptions)) {
    notes <- descriptions[choices]
    notes[is.na(notes)] <- ""
    note <- ifelse(nzchar(notes), paste0(" \u2014 ", notes), "")
    labels <- stats::setNames(choices, paste0(choices, note))
  } else {
    labels <- stats::setNames(choices, choices)
  }
  selectizeInput(
    id, label,
    choices = labels,
    selected = selected,
    multiple = multiple,
    width = "100%",
    options = options
  )
}

#' @keywords internal
groups_input <- function(id, label, choices, selected = NULL,
                         descriptions = NULL) {
  values <- unname(choices)
  labels <- names(choices) %||% values
  if (!is.null(descriptions)) {
    notes <- descriptions[values]
    notes[is.na(notes)] <- ""
    labels <- ifelse(nzchar(notes), paste0(labels, " \u2014 ", notes), labels)
  }
  selectInput(
    id, label,
    choices = stats::setNames(values, labels),
    selected = if (is.null(selected)) choices[[1L]] else selected,
    width = "100%"
  )
}

#' Single checkbox
#' @export
checkbox_input <- function(id, label, value = FALSE) {
  checkboxInput(id, label, value = isTRUE(value))
}

#' Switch
#'
#' The same `<input type="checkbox">` Shiny would build (same id, same value),
#' dressed as a switch.  A switch promises an immediate effect, so use it for
#' preferences, not for parameters of a command.
#' @export
switch_input <- function(id, label, value = FALSE) {
  htmltools::div(
    class = "rcmdr-switch",
    checkboxInput(id, label, value = isTRUE(value))
  )
}

#' Group of checkboxes laid out in a grid
#'
#' `choices` is a named character vector: names are the suffixes used to build
#' input ids (`<prefix>_<name>`) and values are the labels.
#' @export
checkboxes_input <- function(prefix, choices, selected = character(), ncol = 1L) {
  ids <- names(choices)
  if (is.null(ids)) ids <- choices
  htmltools::div(
    class = "row",
    lapply(seq_along(choices), function(i) {
      htmltools::div(
        class = sprintf("col-md-%d", max(1L, floor(12L / ncol))),
        checkboxInput(
          paste0(prefix, "_", ids[[i]]),
          choices[[i]],
          value = isTRUE(ids[[i]] %in% selected)
        )
      )
    })
  )
}

#' Radio buttons
#' @export
radio_input <- function(id, label, choices, selected = NULL, inline = TRUE) {
  if (is.null(names(choices))) names(choices) <- choices
  radioButtons(
    id, label,
    choices = choices,
    selected = if (is.null(selected)) choices[[1L]] else selected,
    inline = inline
  )
}

#' Segmented control
#'
#' A radio group under a pill-shaped skin, for two to four short choices.
#' Same ids, same names and same selected value as [radio_input()]: only the
#' presentation changes.
#' @export
segmented_input <- function(id, label, choices, selected = NULL) {
  htmltools::div(
    class = "rcmdr-segmented",
    radio_input(id, label, choices, selected = selected, inline = TRUE)
  )
}

#' Text entry
#' @export
entry_input <- function(id, label, value = "", placeholder = NULL, width = NULL) {
  textInput(id, label, value = value, placeholder = placeholder, width = width)
}

#' Numeric entry
#'
#' Shiny's `numericInput()` already renders `<input type="number">`: this alias
#' exists so a component reads in the same vocabulary as [field()] and
#' [switch_input()].  The markup and the value Shiny reads are unchanged.
#' @export
number_input <- function(id, label, value = 0, min = NA, max = NA, step = 1) {
  numericInput(id, label, value = value, min = min, max = max, step = step)
}

#' Numeric entry (Rcmdr name)
#' @export
spin_input <- function(id, label, value = 0, min = NA, max = NA, step = 1) {
  number_input(id, label, value = value, min = min, max = max, step = step)
}

#' Slider
#' @export
slider_input <- function(id, label, min, max, value, step = 1) {
  sliderInput(id, label, min = min, max = max, value = value, step = step)
}

#' Drop-down / combo box
#' @export
combo_input <- function(id, label, choices, selected = NULL, multiple = FALSE) {
  if (is.null(selected) || (length(selected) == 1L && !nzchar(selected))) {
    selected <- character()
  }
  selectInput(
    id, label,
    choices = choices,
    selected = if (length(selected) == 0L) NULL else selected,
    multiple = multiple,
    width = "100%"
  )
}

#' Subset expression entry
#' @export
subset_input <- function(id, label = tr("Subset expression:"), value = "") {
  textInput(id, label, value = value, width = "100%")
}

#' Read-only text area
#' @keywords internal
text_area <- function(id, label, value = "", rows = 4L) {
  textAreaInput(id, label, value = value, rows = rows, resize = "vertical")
}

#' File or directory chooser
#'
#' The text entry is the source of truth: it can be typed, which keeps the
#' generated command reproducible and makes the widget testable.  The button
#' opens `shinyFiles` for local browsing.
#' @export
file_input <- function(id, label, value = "", button = TRUE,
                       placeholder = NULL, filetypes = NULL) {
  tagList(
    textInput(id, label, value = value, placeholder = placeholder,
              width = "100%"),
    if (isTRUE(button)) {
      shinyFiles::shinyFilesButton(
        paste0(id, "_browse"),
        tr("Browse..."),
        tr("Select a file"),
        multiple = FALSE
      )
    }
  )
}

#' @export
dir_input <- function(id, label, value = "", button = TRUE,
                      placeholder = NULL) {
  tagList(
    textInput(id, label, value = value, placeholder = placeholder,
              width = "100%"),
    if (isTRUE(button)) {
      shinyFiles::shinyDirButton(
        paste0(id, "_browse"),
        tr("Browse..."),
        tr("Select a directory")
      )
    }
  )
}

#' Observers for [file_input()]
#' @keywords internal
file_input_observers <- function(input, session, id, roots,
                                 guard = function() TRUE,
                                 filetypes = NULL, state = NULL) {
  browse <- paste0(id, "_browse")
  shinyFiles::shinyFileChoose(input, browse, roots = roots,
                              filetypes = filetypes)
  observeEvent(input[[browse]], {
    if (!isTRUE(guard())) return()
    selected <- shinyFiles::parseFilePaths(roots, input[[browse]])
    if (nrow(selected) > 0L) {
      updateTextInput(session, id, value = as.character(selected$datapath[[1L]]))
    }
  }, ignoreInit = TRUE)
  invisible(NULL)
}

#' Observers for [dir_input()]
#' @keywords internal
dir_input_observers <- function(input, session, id, roots,
                                guard = function() TRUE) {
  browse <- paste0(id, "_browse")
  shinyFiles::shinyDirChoose(input, browse, roots = roots)
  observeEvent(input[[browse]], {
    if (!isTRUE(guard())) return()
    selected <- shinyFiles::parseDirPath(roots, input[[browse]])
    if (length(selected) > 0L) {
      updateTextInput(session, id, value = as.character(selected[[1L]]))
    }
  }, ignoreInit = TRUE)
  invisible(NULL)
}

#' @keywords internal
help_text <- function(...) {
  htmltools::tags$div(class = "form-text", ...)
}

#' @keywords internal
dialog_tabs <- function(...) {
  tabsetPanel(...)
}

#' @keywords internal
button_row <- function(...) {
  action_row(...)
}

#' Model formula builder
#'
#' Shiny equivalent of Rcmdr's `modelFormula()`: a response selector, a
#' free-form right-hand side, an "insert variable" control and the usual
#' formula operators.
#' @export
model_formula_input <- function(id, variables, lhs = "", rhs = "",
                                response_label = tr("Response variable:"),
                                formula_label = tr("Model formula (right-hand side):"),
                                show_operators = TRUE, descriptions = NULL) {
  operator_button <- function(op, label) {
    actionButton(paste0(id, "_op_", op), label,
                 class = "btn-sm btn-outline-secondary")
  }

  tagList(
    var_input(paste0(id, "_lhs"), response_label, variables, selected = lhs,
              descriptions = descriptions),
    entry_input(paste0(id, "_rhs"), formula_label, rhs),
    htmltools::div(
      class = "row g-2 align-items-end mb-3",
      htmltools::div(
        class = "col-md-6",
        selectInput(
          paste0(id, "_insert_var"), tr("Add variable"),
          choices = stats::setNames(variables, variables), width = "100%"
        )
      ),
      htmltools::div(
        class = "col-md-3",
        actionButton(paste0(id, "_insert"), tr("Insert"),
                     class = "btn-sm btn-outline-primary")
      ),
      if (isTRUE(show_operators)) {
        htmltools::div(
          class = "col-md-3",
          button_row(
            operator_button("plus", "+"),
            operator_button("star", "*"),
            operator_button("colon", ":"),
            operator_button("caret", "^"),
            operator_button("lparen", "("),
            operator_button("rparen", ")")
          )
        )
      }
    )
  )
}

#' Observers for [model_formula_input()]
#' @keywords internal
model_formula_observers <- function(input, session, id, guard = function() TRUE) {
  append_text <- function(text) {
    current <- input[[paste0(id, "_rhs")]] %||% ""
    updateTextInput(
      session, paste0(id, "_rhs"),
      value = paste0(current, if (nzchar(current)) " " else "", text)
    )
  }

  observeEvent(input[[paste0(id, "_insert")]], {
    if (!isTRUE(guard())) return()
    variable <- input[[paste0(id, "_insert_var")]]
    if (!is.null(variable) && nzchar(variable)) {
      current <- trim_blanks(input[[paste0(id, "_rhs")]] %||% "")
      updateTextInput(
        session, paste0(id, "_rhs"),
        value = paste0(current, if (nzchar(current)) " + " else "", variable)
      )
    }
  }, ignoreInit = TRUE)

  operators <- c(
    plus = "+", star = "*", colon = ":",
    caret = "^", lparen = "(", rparen = ")"
  )
  for (key in names(operators)) {
    local({
      op <- operators[[key]]
      observeEvent(input[[paste0(id, "_op_", key)]], {
        if (!isTRUE(guard())) return()
        append_text(op)
      }, ignoreInit = TRUE)
    })
  }
  invisible(NULL)
}

# A compact label/value helper used by the menus and the status bar.
kv <- function(label, value) {
  htmltools::tags$span(
    htmltools::tags$strong(label), " ",
    htmltools::tags$span(value)
  )
}

#' Text input with a "Save as" browser
#' @keywords internal
file_save_input <- function(id, label, value = "", filename = "",
                            filetypes = NULL) {
  tagList(
    textInput(id, label, value = value, width = "100%"),
    shinyFiles::shinySaveButton(
      paste0(id, "_browse"),
      tr("Browse..."),
      tr("Save file"),
      filename = filename,
      filetype = filetypes
    )
  )
}

#' Observers for [file_save_input()]
#' @keywords internal
file_save_observers <- function(input, session, id, roots,
                                guard = function() TRUE,
                                filetypes = NULL, defaultPath = "") {
  browse <- paste0(id, "_browse")
  shinyFiles::shinyFileSave(
    input, browse, roots = roots, filetypes = filetypes,
    defaultPath = defaultPath
  )
  observeEvent(input[[browse]], {
    if (!isTRUE(guard())) return()
    selected <- shinyFiles::parseSavePath(roots, input[[browse]])
    if (nrow(selected) > 0L) {
      updateTextInput(session, id, value = as.character(selected$datapath[[1L]]))
    }
  }, ignoreInit = TRUE)
  invisible(NULL)
}
