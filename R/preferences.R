# Session preferences ---------------------------------------------------------
#
# Favourites, recents, menu expansion, dialog presets, language and theme are
# user preferences, not statistical state.  They are kept in the session state
# and written to a single RDS file so that they survive a restart.  The file is
# deliberately small and dependency-free.

preferences_default_file <- function() {
  override <- Sys.getenv("RCMDRSHINY_PREFERENCES", unset = "")
  if (nzchar(override)) return(override)
  override <- getOption("RcmdrShiny.preferences")
  if (!is.null(override) && nzchar(override)) return(override)
  base <- if (identical(.Platform$OS.type, "windows")) {
    Sys.getenv("APPDATA", unset = path.expand("~"))
  } else {
    Sys.getenv("XDG_CONFIG_HOME", unset = file.path(path.expand("~"), ".config"))
  }
  file.path(base, "RcmdrShiny", "preferences.rds")
}

preferences_file <- function(state = NULL) {
  configured <- if (!is.null(state)) state$options$preferences_file else NULL
  if (!is.null(configured) && nzchar(configured)) return(configured)
  preferences_default_file()
}

#' Preference snapshot
#'
#' @param state Application state.
#' @return A list with the persisted preference fields.
#' @keywords internal
preferences_snapshot <- function(state) {
  list(
    version = 1L,
    favorites = state$menu_favorites %||% character(),
    recents = state$menu_recents %||% character(),
    expanded = state$menu_expanded %||% character(),
    presets = state$dialog_presets %||% list(),
    presets_version = state$dialog_presets_version %||% 1L,
    language = state$options$language %||% current_language(),
    theme = state$options$theme %||% "system"
  )
}

#' Load preferences into the state
#'
#' Missing or unreadable files are ignored: a fresh session simply starts with
#' empty preferences.
#'
#' @param state Application state.
#' @param path Optional file path.
#' @return Invisibly, `TRUE` when a file was loaded.
#' @keywords internal
preferences_load <- function(state, path = preferences_file(state)) {
  if (!isTRUE(state$options$persist_preferences)) return(invisible(FALSE))
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    return(invisible(FALSE))
  }
  value <- tryCatch(readRDS(path), error = function(e) NULL)
  if (!is.list(value)) return(invisible(FALSE))
  state$menu_favorites <- unique(as.character(value$favorites %||% character()))
  state$menu_favorites <- state$menu_favorites[nzchar(state$menu_favorites)]
  state$menu_recents <- unique(as.character(value$recents %||% character()))
  state$menu_recents <- state$menu_recents[nzchar(state$menu_recents)]
  state$menu_expanded <- unique(as.character(value$expanded %||% character()))
  state$menu_expanded <- state$menu_expanded[nzchar(state$menu_expanded)]
  if (is.list(value$presets)) {
    state$dialog_presets <- value$presets
    state$dialog_presets_version <- as.integer(value$presets_version %||% 1L)
  }
  invisible(TRUE)
}

#' Save preferences
#'
#' @param state Application state.
#' @param path Optional file path.
#' @return Invisibly, `TRUE` when the file was written.
#' @keywords internal
preferences_save <- function(state, path = preferences_file(state)) {
  if (!isTRUE(state$options$persist_preferences)) return(invisible(FALSE))
  if (is.null(path) || !nzchar(path)) return(invisible(FALSE))
  directory <- dirname(path)
  if (!dir.exists(directory)) {
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  }
  ok <- tryCatch(
    {
      saveRDS(preferences_snapshot(state), path)
      TRUE
    },
    error = function(e) FALSE
  )
  invisible(ok)
}

#' Clear preferences
#'
#' Resets the in-memory preferences and, when `remove = TRUE`, the file.
#' @keywords internal
preferences_clear <- function(state, remove = FALSE,
                              path = preferences_file(state)) {
  state$menu_favorites <- character()
  state$menu_recents <- character()
  state$menu_expanded <- character()
  state$dialog_presets <- list()
  state$dialog_presets_version <- 1L
  if (isTRUE(remove) && !is.null(path) && nzchar(path) && file.exists(path)) {
    unlink(path)
  }
  invisible(NULL)
}
