# Feature flags and interface modes -----------------------------------------
#
# The Studio interface is introduced behind feature flags so that the
# historical RcmdrShiny layout remains available while the new modules land.
# The flags only gate UI; the command engine is shared.

#' Default feature flags
#' @keywords internal
default_features <- function() {
  list(
    command_palette = TRUE,
    history = TRUE,
    dialog_preview = TRUE,
    dialog_presets = TRUE,
    data_studio = FALSE,
    chart_studio = FALSE,
    report_studio = FALSE,
    console = TRUE,
    project = FALSE
  )
}

#' Names of the feature flags
#' @keywords internal
feature_names <- function() names(default_features())

#' Read a feature flag
#' @param state Application state.
#' @param name Flag name.
#' @return `TRUE` or `FALSE`.
#' @keywords internal
feature_enabled <- function(state, name) {
  features <- state$options$features %||% list()
  isTRUE(features[[name]] %||% default_features()[[name]] %||% FALSE)
}

#' Set a feature flag
#' @keywords internal
set_feature <- function(state, name, value) {
  if (!name %in% feature_names()) {
    stop(sprintf("Unknown feature flag: %s", name), call. = FALSE)
  }
  features <- state$options$features %||% default_features()
  features[[name]] <- isTRUE(value)
  state$options$features <- features
  state_touch(state)
  invisible(features[[name]])
}

#' Current interface mode
#' @return `"studio"` or `"classic"`.
#' @keywords internal
ui_mode <- function(state) {
  mode <- state$options$ui_mode %||% "studio"
  if (!mode %in% c("studio", "classic")) "studio" else mode
}

#' Switch interface mode
#' @keywords internal
set_ui_mode <- function(state, mode = c("studio", "classic")) {
  mode <- match.arg(mode)
  state$options$ui_mode <- mode
  state_touch(state)
  invisible(mode)
}

#' Current visual theme
#' @return `"system"`, `"light"`, `"dark"` or `"contrast"`.
#' @keywords internal
ui_theme <- function(state) {
  theme <- state$options$theme %||% "system"
  if (!theme %in% c("system", "light", "dark", "contrast")) "system" else theme
}

#' Set visual theme
#' @keywords internal
set_ui_theme <- function(state, theme = c("system", "light", "dark", "contrast")) {
  theme <- match.arg(theme)
  state$options$theme <- theme
  state_touch(state)
  invisible(theme)
}
