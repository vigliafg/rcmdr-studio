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
    dialog_validation = TRUE,
    menu_search = TRUE,
    workflows = TRUE,
    suggestions = TRUE,
    data_studio = FALSE,
    chart_studio = TRUE,
    report_studio = TRUE,
    console = TRUE,
    script_studio = TRUE,
    environment_studio = TRUE,
    models_studio = TRUE,
    project = TRUE
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

#' Supported visual themes
#'
#' `system` follows the operating-system appearance.  The light and the dark
#' families each ship three palettes, plus the high-contrast theme.
#'
#' @return A character vector of theme identifiers.
#' @keywords internal
ui_themes <- function() {
  c(
    "system",
    "light", "light-warm", "light-cool",
    "dark", "dark-dim", "dark-graphite",
    "contrast"
  )
}

#' Theme selector choices, grouped by family
#'
#' @return A named list suitable for [shiny::selectInput()].
#' @keywords internal
theme_choices <- function() {
  stats::setNames(
    list(
      stats::setNames(
        c("light", "light-warm", "light-cool"),
        c(tr("Light neutral"), tr("Light warm"), tr("Light cool"))
      ),
      stats::setNames(
        c("dark", "dark-dim", "dark-graphite"),
        c(tr("Dark midnight"), tr("Dark dim"), tr("Dark graphite"))
      ),
      stats::setNames(
        c("system", "contrast"),
        c(tr("Follow system"), tr("High contrast"))
      )
    ),
    c(tr("Light"), tr("Dark"), tr("Other"))
  )
}

#' Current visual theme
#' @return One of [ui_themes()].
#' @keywords internal
ui_theme <- function(state) {
  theme <- state$options$theme %||% "system"
  if (is.character(theme) && length(theme) == 1L && theme %in% ui_themes()) {
    theme
  } else {
    "system"
  }
}

#' Set visual theme
#' @keywords internal
set_ui_theme <- function(state, theme = "system") {
  theme <- as.character(theme %||% "system")[[1L]]
  if (!theme %in% ui_themes()) theme <- "system"
  state$options$theme <- theme
  state_touch(state)
  invisible(theme)
}

#' Supported interface densities
#' @return `c("compact", "comfortable")`.
#' @keywords internal
ui_densities <- function() c("compact", "comfortable")

#' Density selector choices
#' @keywords internal
ui_density_choices <- function() {
  stats::setNames(
    c("compact", "comfortable"),
    c(tr("Compact"), tr("Comfortable"))
  )
}

#' Current interface density
#' @return One of [ui_densities()]; "compact" when unset or unknown.
#' @keywords internal
ui_density <- function(state) {
  density <- state$options$density %||% "compact"
  if (is.character(density) && length(density) == 1L &&
      density %in% ui_densities()) {
    density
  } else {
    "compact"
  }
}

#' Set interface density
#' @keywords internal
set_ui_density <- function(state, density = "compact") {
  density <- as.character(density %||% "compact")[[1L]]
  if (!density %in% ui_densities()) density <- "compact"
  state$options$density <- density
  state_touch(state)
  invisible(density)
}
