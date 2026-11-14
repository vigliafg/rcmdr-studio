# Dialog presets -------------------------------------------------------------
#
# A preset is a named set of dialog inputs.  It is stored as plain data in the
# session state and can be exported to a small RDS file.  Presets never execute
# a command: they only pre-fill the existing dialog.

dialog_presets_version <- function() 1L

#' Saved presets for a dialog
#' @keywords internal
dialog_presets_for <- function(state, id) {
  if (is.null(id) || !nzchar(id)) return(list())
  state$dialog_presets[[id]] %||% list()
}

#' Save a preset for a dialog
#' @keywords internal
dialog_preset_save <- function(state, id, name, values) {
  name <- trimws(name %||% "")
  if (!nzchar(name)) {
    return(list(ok = FALSE, error = tr("Enter a preset name first.")))
  }
  if (!is.list(values)) values <- list()
  presets <- state$dialog_presets[[id]] %||% list()
  presets[[name]] <- values
  state$dialog_presets[[id]] <- presets
  state_touch(state)
  list(ok = TRUE, name = name)
}

#' Delete a preset
#' @keywords internal
dialog_preset_delete <- function(state, id, name) {
  presets <- state$dialog_presets[[id]] %||% list()
  if (is.null(presets[[name]])) {
    return(list(ok = FALSE, error = tr("Preset not found.")))
  }
  presets[[name]] <- NULL
  state$dialog_presets[[id]] <- presets
  state_touch(state)
  list(ok = TRUE)
}

#' Read a preset
#' @keywords internal
dialog_preset_get <- function(state, id, name) {
  presets <- state$dialog_presets[[id]] %||% list()
  presets[[name]] %||% NULL
}

#' Export presets as a portable list
#'
#' @param state Application state.
#' @param id Optional dialog id; all dialogs when `NULL`.
#' @return A versioned list.
#' @keywords internal
dialog_presets_export <- function(state, id = NULL) {
  presets <- if (is.null(id)) {
    state$dialog_presets %||% list()
  } else {
    stats::setNames(list(dialog_presets_for(state, id)), id)
  }
  list(
    application = "RcmdrShiny",
    version = dialog_presets_version(),
    created = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    presets = presets
  )
}

#' Import presets from a portable list
#'
#' Unknown or malformed entries are ignored; a version mismatch is refused so
#' that a future format never silently corrupts the current one.
#'
#' @param state Application state.
#' @param value List returned by [dialog_presets_export()].
#' @param overwrite Replace presets with the same name.
#' @return A list with `ok`, `imported` and an optional `error`.
#' @keywords internal
dialog_presets_import <- function(state, value, overwrite = FALSE) {
  if (!is.list(value) || !is.list(value$presets)) {
    return(list(ok = FALSE, error = tr("This file does not contain dialog presets.")))
  }
  version <- as.integer(value$version %||% dialog_presets_version())
  if (!identical(version, dialog_presets_version())) {
    return(list(ok = FALSE, error = tr("Unsupported preset file version.")))
  }
  imported <- 0L
  for (id in names(value$presets)) {
    presets <- value$presets[[id]]
    if (!is.list(presets)) next
    current <- state$dialog_presets[[id]] %||% list()
    for (name in names(presets)) {
      if (!nzchar(name)) next
      if (!is.list(presets[[name]])) next
      if (!isTRUE(overwrite) && !is.null(current[[name]])) next
      current[[name]] <- presets[[name]]
      imported <- imported + 1L
    }
    state$dialog_presets[[id]] <- current
  }
  state_touch(state)
  list(ok = TRUE, imported = imported)
}

#' Write presets to an RDS file
#' @keywords internal
dialog_presets_save_file <- function(state, path, id = NULL) {
  path <- trim_blanks(path %||% "")
  if (!nzchar(path)) {
    return(list(ok = FALSE, error = tr("Enter a preset file path.")))
  }
  directory <- dirname(path)
  if (!dir.exists(directory)) {
    return(list(ok = FALSE, error = sprintf(tr("Directory not found: %s"),
                                            directory)))
  }
  ok <- tryCatch(
    {
      saveRDS(dialog_presets_export(state, id), path)
      TRUE
    },
    error = function(e) FALSE
  )
  if (!isTRUE(ok)) {
    return(list(ok = FALSE, error = tr("The preset file could not be written.")))
  }
  list(ok = TRUE, path = path)
}

#' Read presets from an RDS file
#' @keywords internal
dialog_presets_load_file <- function(state, path, overwrite = FALSE) {
  path <- trim_blanks(path %||% "")
  if (!nzchar(path) || !file.exists(path)) {
    return(list(ok = FALSE, error = tr("Preset file not found.")))
  }
  value <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(value)) {
    return(list(ok = FALSE, error = tr("The preset file could not be read.")))
  }
  dialog_presets_import(state, value, overwrite = overwrite)
}
