# Variable suggestions -------------------------------------------------------
#
# Suggestions answer "what can I do with this variable?" using only simple
# rules based on the variable type, the number of levels, missing values and
# the data set that is active.  They never recommend a statistical model and
# every button opens an existing dialog with pre-filled memory.

#' Basic metadata for a variable
#' @keywords internal
variable_info <- function(state, variable) {
  df <- dataset(state)
  if (is.null(df) || is.null(variable) || !variable %in% names(df)) {
    return(NULL)
  }
  x <- df[[variable]]
  missing <- sum(is.na(x))
  type <- if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    "date"
  } else if (is.factor(x)) {
    "factor"
  } else if (is.numeric(x)) {
    "numeric"
  } else if (is.logical(x)) {
    "logical"
  } else if (is.character(x)) {
    "character"
  } else {
    class(x)[[1L]]
  }
  list(
    variable = variable,
    type = type,
    class = paste(class(x), collapse = ", "),
    n = length(x),
    missing = missing,
    unique = length(unique(x[!is.na(x)])),
    levels = if (is.factor(x)) levels(x) else NULL
  )
}

#' Compact description used by enriched selectors
#' @keywords internal
variable_descriptions <- function(state, variables = NULL) {
  variables <- variables %||% variables(state)
  if (length(variables) == 0L) return(stats::setNames(character(), character()))
  descriptions <- vapply(variables, function(variable) {
    info <- variable_info(state, variable)
    if (is.null(info)) return("")
    sprintf("%s, %d missing, %d unique", info$type, info$missing, info$unique)
  }, character(1))
  stats::setNames(descriptions, variables)
}

#' Suggestions for a variable
#'
#' @param state Application state.
#' @param variable Variable in the active data set.
#' @return A data frame with `id`, `title`, `description`, `dialog` and
#'   `available`.
#' @keywords internal
variable_suggestions <- function(state, variable) {
  info <- variable_info(state, variable)
  if (is.null(info)) {
    return(data.frame(
      id = character(), title = character(), description = character(),
      dialog = character(), available = logical(), stringsAsFactors = FALSE
    ))
  }
  numeric_vars <- numeric_variables(state)
  factor_vars <- factor_variables(state)
  other_numeric <- setdiff(numeric_vars, variable)
  other_factor <- setdiff(factor_vars, variable)
  rows <- list()

  add <- function(id, title, description, dialog, available = TRUE) {
    rows[[length(rows) + 1L]] <<- data.frame(
      id = id, title = title, description = description, dialog = dialog,
      available = isTRUE(available) && dialog %in% dialog_ids(),
      stringsAsFactors = FALSE
    )
  }

  if (identical(info$type, "numeric")) {
    add("summary", tr("Summary"), tr("Mean, median, spread and quantiles."),
        "numericalSummaries")
    add("histogram", tr("Histogram"), tr("Distribution of the values."),
        "Histogram")
    add("density", tr("Density plot"), tr("Smoothed distribution."),
        "DensityPlot")
    add("boxplot", tr("Boxplot"), tr("Median, quartiles and outliers."),
        "boxPlot")
    add("scatter", tr("Scatterplot"), tr("Plot against another numeric variable."),
        "scatterPlot", length(other_numeric) > 0L)
    add("correlation", tr("Correlation"), tr("Correlation with other numeric variables."),
        "correlationMatrix", length(other_numeric) > 0L)
    add("transform", tr("Transform"), tr("Transform toward normality."),
        "transformVariables")
  } else if (identical(info$type, "factor")) {
    add("frequency", tr("Frequency table"), tr("Counts and percentages."),
        "frequencyDistribution")
    add("bar", tr("Bar graph"), tr("Compare the levels."), "barGraph")
    add("boxplot", tr("Boxplot by group"), tr("Compare a numeric response by group."),
        "boxPlot", TRUE)
    add("twoway", tr("Two-way table"), tr("Cross-tabulate with another factor."),
        "twoWayTable", length(other_factor) > 0L)
    add("recode", tr("Recode"), tr("Combine or relabel the levels."),
        "RecodeDialog")
    add("reorder", tr("Reorder levels"), tr("Change the order of the levels."),
        "reorderFactor")
  } else if (identical(info$type, "character")) {
    add("frequency", tr("Frequency table"), tr("Counts and percentages."),
        "frequencyDistribution")
    add("factor", tr("Convert to factor"), tr("Create a categorical variable."),
        "characterToFactor")
  } else if (identical(info$type, "logical")) {
    add("frequency", tr("Frequency table"), tr("Counts and percentages."),
        "frequencyDistribution")
    add("factor", tr("Convert to factor"), tr("Create a two-level factor."),
        "characterToFactor")
  } else if (identical(info$type, "date")) {
    add("frequency", tr("Frequency table"), tr("Counts by date."),
        "frequencyDistribution")
  }

  if (length(rows) == 0L) {
    return(data.frame(
      id = character(), title = character(), description = character(),
      dialog = character(), available = logical(), stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

#' Pre-filled dialog memory for a suggestion
#' @keywords internal
suggestion_memory <- function(state, variable, dialog) {
  other_numeric <- setdiff(numeric_variables(state), variable)
  other_factor <- setdiff(factor_variables(state), variable)
  first_numeric_other <- if (length(other_numeric) > 0L) other_numeric[[1L]] else
    NULL
  first_factor_other <- if (length(other_factor) > 0L) other_factor[[1L]] else
    NULL
  switch(
    dialog,
    numericalSummaries = list(x = variable),
    Histogram = list(variable = variable),
    DensityPlot = list(variable = variable),
    barGraph = list(variable = variable),
    boxPlot = list(variables = variable,
                  response = if (variable %in% numeric_variables(state)) variable else NULL,
                  group = if (variable %in% factor_variables(state)) variable else ""),
    frequencyDistribution = list(variables = variable),
    scatterPlot = list(x = variable, y = first_numeric_other),
    correlationMatrix = list(variables = c(variable, utils::head(other_numeric, 2L))),
    transformVariables = list(variables = variable),
    twoWayTable = list(row = variable, column = first_factor_other),
    RecodeDialog = list(variables = variable),
    reorderFactor = list(variable = variable),
    numericToFactor = list(variables = variable),
    characterToFactor = list(variables = variable),
    list()
  )
}

#' Suggestion buttons for the Data Studio inspector
#' @keywords internal
variable_suggestions_ui <- function(state, variable) {
  table <- variable_suggestions(state, variable)
  if (nrow(table) == 0L) return(NULL)
  buttons <- lapply(seq_len(nrow(table)), function(i) {
    row <- table[i, , drop = FALSE]
    if (!isTRUE(row$available[[1L]])) {
      return(htmltools::tags$button(
        type = "button", class = "btn btn-sm btn-outline-secondary",
        disabled = "disabled", title = tr("Dialog not available"),
        row$title[[1L]]
      ))
    }
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary",
      title = row$description[[1L]],
      onclick = sprintf(
        "Shiny.setInputValue('variable_suggestion', {variable: '%s', dialog: '%s'}, {priority: 'event'}); return false;",
        gsub("'", "\\\\'", variable),
        row$dialog[[1L]]
      ),
      row$title[[1L]]
    )
  })
  htmltools::tags$div(
    class = "rcmdr-variable-suggestions",
    htmltools::tags$h6(tr("What can I do with this variable?")),
    htmltools::tags$div(class = "d-flex gap-1 flex-wrap", buttons)
  )
}
