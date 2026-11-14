# Inline dialog validation ---------------------------------------------------
#
# A dialog `on_ok` callback may return `field_errors`, a named list or vector.
# The names are input ids or the input suffix without the dialog prefix.  The
# runtime keeps the modal open, renders a summary and asks the browser to mark
# and focus the first invalid field.  `error` remains the historical contract
# for a message-only failure.

#' Normalise field errors returned by a dialog
#' @keywords internal
dialog_field_errors <- function(result) {
  errors <- result$field_errors %||% NULL
  if (is.null(errors) || length(errors) == 0L) return(list())
  if (is.character(errors)) errors <- as.list(errors)
  if (!is.list(errors)) return(list())
  errors <- errors[!vapply(errors, is.null, logical(1))]
  if (length(errors) == 0L) return(list())
  if (is.null(names(errors))) names(errors) <- rep("field", length(errors))
  blank <- !nzchar(names(errors))
  names(errors)[blank] <- paste0("field", which(blank))
  errors <- lapply(errors, function(message) {
    paste(as.character(message %||% ""), collapse = " ")
  })
  errors[nzchar(unlist(errors, use.names = FALSE))]
}

#' Inline validation summary
#' @keywords internal
dialog_validation_ui <- function(errors) {
  errors <- errors %||% list()
  if (length(errors) == 0L) return(NULL)
  htmltools::tags$div(
    class = "alert alert-danger rcmdr-dialog-errors",
    role = "alert", `aria-live` = "assertive",
    htmltools::tags$strong(tr("Please correct the highlighted fields.")),
    htmltools::tags$ul(
      class = "mb-0 mt-1",
      lapply(names(errors), function(field) {
        htmltools::tags$li(
          htmltools::tags$a(
            href = paste0("#", field),
            onclick = sprintf(
              "rcmdrFocusField('%s'); return false;",
              gsub("'", "\\\\'", field)
            ),
            errors[[field]]
          )
        )
      })
    )
  )
}

#' Browser payload for inline errors
#' @keywords internal
dialog_validation_payload <- function(errors) {
  list(errors = errors %||% list())
}
