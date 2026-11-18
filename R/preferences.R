# Session preferences ---------------------------------------------------------
#
# Favourites, recents, menu expansion, dialog presets, language, theme and the
# split-pane sizes are user preferences, not statistical state.  They are kept
# in the session state and written to a single RDS file so that they survive a
# restart.  The file is deliberately small and dependency-free.

# The layout entries carry their own version: a changed default can be adopted
# without misreading a size saved by an older build.
layout_version <- 1L
layout_min_ratio <- 0.05
layout_max_ratio <- 0.95

#' A valid split ratio
#'
#' `NULL` or a non-finite value is rejected, so a corrupt preference falls back
#' to the caller's default instead of producing an empty pane.
#' @keywords internal
layout_ratio <- function(value, fallback = NULL) {
  if (length(value) != 1L) return(fallback)
  value <- suppressWarnings(as.numeric(value))
  if (!is.finite(value)) return(fallback)
  min(max(value, layout_min_ratio), layout_max_ratio)
}

#' Read a saved split size
#'
#' The UI is built before the server exists, so the first render reads the same
#' file `preferences_load()` will read a moment later.
#'
#' @param id Split pane id.
#' @param layouts Optional layout list; the persisted file by default.
#' @return A ratio, or `NULL` when the id has no usable entry.
#' @keywords internal
layout_saved <- function(id, layouts = NULL) {
  if (is.null(layouts)) {
    layouts <- tryCatch(preferences_peek()$layouts, error = function(e) NULL)
  }
  if (!is.list(layouts)) return(NULL)
  entry <- layouts[[id]]
  if (!is.list(entry)) return(NULL)
  version <- suppressWarnings(as.integer(entry$version %||% 0L))
  if (length(version) != 1L || is.na(version) || version != layout_version) {
    return(NULL)
  }
  layout_ratio(entry$first, fallback = NULL)
}

#' Initial size of a split pane
#'
#' @inheritParams layout_saved
#' @param default Ratio used when nothing usable is saved.
#' @return A ratio.
#' @keywords internal
layout_initial <- function(id, default = 0.5, layouts = NULL) {
  saved <- layout_saved(id, layouts)
  if (is.null(saved)) layout_ratio(default, fallback = 0.5) else saved
}

#' Record a split size in the session preferences
#'
#' @param state Application state.
#' @param id Split pane id.
#' @param first New ratio.
#' @return Invisibly, the stored ratio, or `NULL` when the value was rejected.
#' @keywords internal
layout_set <- function(state, id, first) {
  value <- layout_ratio(first, fallback = NULL)
  if (is.null(value) || !nzchar(id)) return(invisible(NULL))
  if (is.null(state$options$layouts) || !is.list(state$options$layouts)) {
    state$options$layouts <- list()
  }
  state$options$layouts[[id]] <- list(version = layout_version, first = value)
  invisible(value)
}

#' Drop the saved split sizes
#' @keywords internal
layout_clear <- function(state) {
  state$options$layouts <- list()
  invisible(NULL)
}

# Column order ---------------------------------------------------------------
#
# The Data Studio column order is a view preference: it changes how the grid
# reads, never the data frame and never the command history.

column_order_version <- 1L

#' Read a saved column order for a data set
#' @keywords internal
column_order_saved <- function(state, dataset_name) {
  entry <- (state$options$column_order %||% list())[[dataset_name]]
  if (!is.list(entry)) return(NULL)
  version <- suppressWarnings(as.integer(entry$version %||% 0L))
  if (length(version) != 1L || is.na(version) ||
      version != column_order_version) {
    return(NULL)
  }
  order <- as.character(entry$order %||% character())
  order <- order[!is.na(order) & nzchar(order)]
  if (length(order) == 0L) NULL else unique(order)
}

#' Keep every current column exactly once, in the preferred order
#' @keywords internal
column_order_normalize <- function(order, columns) {
  columns <- as.character(columns)
  order <- as.character(order %||% character())
  order <- order[!is.na(order) & order %in% columns]
  c(unique(order), setdiff(columns, order))
}

#' Store a column order
#' @keywords internal
column_order_store <- function(state, dataset_name, order, columns) {
  if (is.null(dataset_name) || !nzchar(dataset_name)) return(invisible(NULL))
  order <- column_order_normalize(order, columns)
  if (is.null(state$options$column_order) ||
      !is.list(state$options$column_order)) {
    state$options$column_order <- list()
  }
  state$options$column_order[[dataset_name]] <- list(
    version = column_order_version,
    order = order
  )
  invisible(order)
}

#' Move one column inside an order
#'
#' Returns `NULL` when the column is unknown or the move would leave the
#' range.
#' @keywords internal
column_order_move <- function(order, column, delta) {
  columns <- as.character(order %||% character())
  position <- match(column, columns)
  if (is.na(position)) return(NULL)
  target <- position + as.integer(delta)
  if (target < 1L || target > length(columns)) return(NULL)
  columns[c(position, target)] <- columns[c(target, position)]
  columns
}

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

#' Read the persisted preferences without applying them
#'
#' Used before the UI is built so that the saved language and theme take effect
#' on the first render.  Missing or unreadable files yield an empty list.
#'
#' @param path Optional file path.
#' @return A list.
#' @keywords internal
preferences_peek <- function(path = preferences_default_file()) {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) return(list())
  value <- tryCatch(readRDS(path), error = function(e) NULL)
  if (!is.list(value)) list() else value
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
    plugins = as.character(state$options$plugins %||% character()),
    language = state$options$language %||% current_language(),
    theme = state$options$theme %||% "system",
    density = state$options$density %||% "compact",
    auto_switch_result = isTRUE(state$options$auto_switch_result),
    layouts = state$options$layouts %||% list(),
    column_order = state$options$column_order %||% list(),
    workspace_secondary = state$options$workspace_secondary %||% NULL,
    workspace_panels = state$options$workspace_panels %||% list(),
    workspace_focus = state$options$workspace_focus %||% "split"
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
  if (length(state$menu_expanded) > 0L &&
      is.function(menu_migrate_ids)) {
    state$menu_expanded <- unique(menu_migrate_ids(state$menu_expanded))
  }
  if (is.list(value$presets)) {
    state$dialog_presets <- value$presets
    state$dialog_presets_version <- as.integer(value$presets_version %||% 1L)
  }
  plugins <- value$plugins %||% character()
  if (is.character(plugins)) {
    state$options$plugins <- unique(plugins[nzchar(plugins)])
  }
  language <- value$language %||% NULL
  if (is.character(language) && length(language) == 1L && nzchar(language)) {
    state$options$language <- i18n_normalize(language)
  }
  theme <- value$theme %||% NULL
  if (is.character(theme) && length(theme) == 1L && theme %in% ui_themes()) {
    state$options$theme <- theme
  }
  density <- value$density %||% NULL
  if (is.character(density) && length(density) == 1L &&
      density %in% ui_densities()) {
    state$options$density <- density
  }
  state$options$auto_switch_result <- isTRUE(value$auto_switch_result)
  layouts <- value$layouts
  if (is.list(layouts) && length(layouts) > 0L) {
    cleaned <- list()
    for (id in names(layouts)) {
      first <- layout_saved(id, layouts)
      if (!is.null(first)) {
        cleaned[[id]] <- list(version = layout_version, first = first)
      }
    }
    state$options$layouts <- cleaned
  }
  secondary <- value$workspace_secondary %||% NULL
  if (is.character(secondary) && length(secondary) == 1L &&
      secondary %in% workspace_view_ids()) {
    state$options$workspace_secondary <- secondary
  }
  panels <- value$workspace_panels
  if (is.list(panels)) {
    cleaned <- list()
    for (view in names(panels)) {
      entry <- panels[[view]]
      if (is.list(entry)) {
        entry <- entry[!vapply(entry, is.null, logical(1))]
        entry <- lapply(entry, function(x) isTRUE(x))
        if (length(entry) > 0L) cleaned[[view]] <- entry
      }
    }
    state$options$workspace_panels <- cleaned
  }
  focus <- value$workspace_focus %||% "split"
  if (is.character(focus) && length(focus) == 1L &&
      focus %in% c("split", "primary", "secondary")) {
    state$options$workspace_focus <- focus
  }
  columns <- value$column_order
  if (is.list(columns) && length(columns) > 0L) {
    cleaned <- list()
    for (dataset_name in names(columns)) {
      entry <- columns[[dataset_name]]
      if (!is.list(entry)) next
      version <- suppressWarnings(as.integer(entry$version %||% 0L))
      order <- as.character(entry$order %||% character())
      order <- order[!is.na(order) & nzchar(order)]
      if (length(version) == 1L && !is.na(version) &&
          version == column_order_version && length(order) > 0L) {
        cleaned[[dataset_name]] <- list(
          version = column_order_version,
          order = unique(order)
        )
      }
    }
    state$options$column_order <- cleaned
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
  state$options$plugins <- character()
  layout_clear(state)
  state$options$column_order <- list()
  state$options$workspace_secondary <- NULL
  state$options$workspace_panels <- list()
  state$options$workspace_focus <- "split"
  if (isTRUE(remove) && !is.null(path) && nzchar(path) && file.exists(path)) {
    unlink(path)
  }
  invisible(NULL)
}
