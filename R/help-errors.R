# Error to help mapping ------------------------------------------------------
#
# When a command fails, the interface offers the topic that most likely
# explains the problem.  Patterns are deliberately conservative: a wrong link is
# worse than no link, so only well-known R error messages are mapped.

help_error_patterns <- function() {
  list(
    list(
      pattern = "there is no package called|could not find function|unable to find an inherited method|no applicable method",
      topic = "loadPackages"
    ),
    list(
      pattern = "object '?[^']*'? not found|object not found",
      topic = "data-import"
    ),
    list(
      pattern = "contrasts can be applied only to factors|variable is not a factor",
      topic = "converting-character-variables"
    ),
    list(
      pattern = "NA/NaN/Inf in|missing values|infinite or missing values",
      topic = "troubleshooting"
    ),
    list(
      pattern = "pandoc|there is no package called 'rmarkdown'|knit",
      topic = "document-authoring"
    ),
    list(
      pattern = "cannot open file|No such file or directory|does not exist in current working directory",
      topic = "data-import"
    ),
    list(
      pattern = "subscript out of bounds|undefined columns selected|incorrect number of dimensions",
      topic = "data-editing"
    ),
    list(
      pattern = "non-numeric argument|invalid 'type'|replacement has [0-9]+ rows",
      topic = "converting-character-variables"
    ),
    list(
      pattern = "system is computationally singular|singular fit|fitted probabilities numerically 0 or 1|algorithm did not converge",
      topic = "troubleshooting"
    ),
    list(
      pattern = "cannot allocate vector|memory exhausted|vector memory exhausted",
      topic = "troubleshooting"
    ),
    list(
      pattern = "unexpected symbol|unexpected end of input|unexpected '",
      topic = "troubleshooting"
    ),
    list(
      pattern = "there is no active data set|no active data set",
      topic = "selectActiveDataSet"
    )
  )
}

#' Map an error message to a help topic
#'
#' @param message Error message, or a character vector of messages.
#' @param language Language code used to choose the topic title.
#' @return A topic id, or `NULL` when no pattern matches.
#' @export
error_help_topic <- function(message, language = NULL) {
  if (is.null(message) || length(message) == 0L) return(NULL)
  text <- tolower(paste(message, collapse = " "))
  if (!nzchar(trimws(text))) return(NULL)

  for (entry in help_error_patterns()) {
    if (grepl(entry$pattern, text, ignore.case = TRUE, perl = TRUE)) {
      topic <- help_topic(entry$topic, language)
      if (is.null(topic)) {
        topic <- help_topic(entry$topic)
        if (is.null(topic)) next
      }
      return(topic$id)
    }
  }
  NULL
}

#' Error suggestion with a topic title
#'
#' @param message Error message.
#' @param language Language code.
#' @return A list with `id` and `title`, or `NULL`.
#' @export
error_help_suggestion <- function(message, language = NULL) {
  id <- error_help_topic(message, language)
  if (is.null(id)) return(NULL)
  topic <- help_topic(id, language) %||% help_topic(id)
  if (is.null(topic)) return(NULL)
  list(id = topic$id, title = topic$title)
}

#' Link to the help topic suggested by an error
#'
#' Returns `NULL` when nothing matches, so callers can simply drop the result
#' into a `tagList()`.
#'
#' @param message Error message.
#' @param language Language code.
#' @param label Optional link label.
#' @return An `<a>` tag, or `NULL`.
#' @export
error_help_link_ui <- function(message, language = NULL, label = NULL) {
  suggestion <- error_help_suggestion(message, language)
  if (is.null(suggestion)) return(NULL)
  label <- label %||% sprintf(tr("Open help: %s"), suggestion$title)
  htmltools::tags$a(
    href = "#",
    class = "rcmdr-error-help",
    `data-help-topic` = suggestion$id,
    label
  )
}
