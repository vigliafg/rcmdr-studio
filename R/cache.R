# Session caches -------------------------------------------------------------
#
# The application keeps four expensive catalogues in memory: the menu
# registry, the merged help index, the plugin catalogues and the palette (which
# is per state).  They are derived data, never a second source of truth.  The
# health panel and the diagnostics report show their keys so that a stale cache
# is easy to spot.

#' Describe the process-level caches
#'
#' @return A data frame with `cache`, `key`, `entries` and `ready`.
#' @keywords internal
cache_stats <- function() {
  menu <- .menu_registry_cache %||% NULL
  help <- .help_index %||% NULL
  plugin <- .plugin_catalog_cache %||% NULL

  rows <- list(
    data.frame(
      cache = "menu registry",
      key = if (is.null(menu) || is.null(menu$key)) "" else menu$key,
      entries = if (is.null(menu) || is.null(menu$value)) 0L else {
        length(menu$value$groups %||% list()) +
          length(menu$value$items %||% list())
      },
      ready = !is.null(menu) && !is.null(menu$value),
      stringsAsFactors = FALSE
    ),
    data.frame(
      cache = "help index",
      key = if (is.null(help) || is.null(help$key)) "" else help$key,
      entries = if (is.null(help) || is.null(help$value)) 0L else {
        nrow(help$value$docs %||% data.frame())
      },
      ready = !is.null(help) && !is.null(help$value),
      stringsAsFactors = FALSE
    ),
    data.frame(
      cache = "plugin catalog",
      key = if (is.null(plugin) || is.null(plugin$version)) "" else {
        as.character(plugin$version)
      },
      entries = if (is.null(plugin) || is.null(plugin$value)) 0L else {
        length(plugin$value)
      },
      ready = !is.null(plugin) && length(plugin$value %||% list()) > 0L,
      stringsAsFactors = FALSE
    )
  )
  do.call(rbind, rows)
}

#' Clear every process-level cache
#'
#' Used by tests and by the "Reload" action in diagnostics.  The next menu or
#' help render rebuilds the catalogue from its source files.
#' @keywords internal
cache_clear <- function() {
  menu_registry_reset()
  help_index_reset()
  plugin_catalog_reset()
  invisible(NULL)
}

#' Cache summary for one line of text
#' @keywords internal
cache_summary <- function() {
  stats <- cache_stats()
  sprintf("%s: %s", stats$cache,
          ifelse(stats$ready,
                 paste0(stats$entries, " entries"),
                 "cold"))
}
