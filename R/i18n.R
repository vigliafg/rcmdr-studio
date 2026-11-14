# Internationalisation ------------------------------------------------------
#
# Rcmdr's translation catalogues are reused as-is.  The gettext domain is
# derived from the package name, so the files installed in po/ are picked up by
# the standard R translation machinery.
#
# A second, in-process catalogue is read from the same .po files.  It makes the
# language switch work without restarting R: every call to tr() consults the
# active language first and falls back to gettext.  The catalogue is cached per
# language and reparsed only when the file changes.

.i18n <- new.env(parent = emptyenv())
.i18n$catalogues <- list()
.i18n$paths <- list()

i18n_po_path <- function(language) {
  if (is.null(language) || !nzchar(language) || identical(language, "en")) {
    return("")
  }
  file <- sprintf("R-%s.po", language)
  candidates <- c(
    system.file("po", file, package = "RcmdrShiny"),
    file.path("inst", "po", file),
    file.path("po", file),
    file.path(getwd(), "inst", "po", file)
  )
  for (candidate in candidates) {
    if (nzchar(candidate) && file.exists(candidate)) return(candidate)
  }
  ""
}

i18n_supported <- function(language) {
  language %in% available_languages()
}

i18n_normalize <- function(language) {
  if (is.null(language) || length(language) == 0L || is.na(language)) return("en")
  code <- trimws(as.character(language)[[1L]])
  if (!nzchar(code)) return("en")
  code <- strsplit(code, ":", fixed = TRUE)[[1L]][1L]
  if (is.na(code) || !nzchar(code)) return("en")
  code <- sub("[_.].*$", "", code)
  if (!nzchar(code) || identical(code, "C")) "en" else code
}

#' Language used for the current session
#' @keywords internal
current_language <- function() {
  configured <- getOption("RcmdrShiny.language", NULL)
  if (!is.null(configured) && nzchar(configured)) {
    return(i18n_normalize(configured))
  }
  lang <- Sys.getenv("LANGUAGE", "")
  if (!nzchar(lang)) lang <- Sys.getlocale("LC_MESSAGES")
  i18n_normalize(lang)
}

#' Set the session language
#'
#' Updates the in-process option used by [tr()] and the `LANGUAGE` environment
#' variable used by gettext.  The help centre and the reactive parts of the
#' interface pick the change up on their next render.
#'
#' @param language Language code, for example `"en"` or `"it"`.
#' @return The normalized language code, invisibly.
#' @export
i18n_set_language <- function(language = "en") {
  language <- i18n_normalize(language)
  options(RcmdrShiny.language = language)
  Sys.setenv(LANGUAGE = language)
  invisible(language)
}

i18n_po_unquote <- function(x) {
  x <- trimws(x)
  if (nchar(x) >= 2L && substr(x, 1L, 1L) == "\"" &&
      substr(x, nchar(x), nchar(x)) == "\"") {
    x <- substr(x, 2L, nchar(x) - 1L)
  }
  x <- gsub("\\n", "\n", x, fixed = TRUE)
  x <- gsub("\\t", "\t", x, fixed = TRUE)
  x <- gsub("\\\"", "\"", x, fixed = TRUE)
  gsub("\\\\", "\\", x, fixed = TRUE)
}

i18n_po_read <- function(path) {
  header <- tryCatch(
    readLines(path, n = 40L, warn = FALSE, encoding = "latin1"),
    error = function(e) character()
  )
  joined <- paste(header, collapse = "\n")
  charset <- sub(".*charset=([^\\s\\\\]+).*", "\\1", joined)
  from <- if (grepl("^utf-?8$", charset, ignore.case = TRUE)) {
    "UTF-8"
  } else if (grepl("^iso-?8859-1$|^latin-?1$", charset, ignore.case = TRUE)) {
    "latin1"
  } else {
    "latin1"
  }
  lines <- tryCatch(
    readLines(path, warn = FALSE, encoding = from),
    error = function(e) character()
  )
  enc2utf8(lines)
}

#' Parse a gettext PO file
#'
#' Reads `msgid`/`msgstr` pairs, joins multiline entries and skips fuzzy
#' translations, mirroring what gettext does at runtime.
#'
#' @param path Path to a `.po` file.
#' @return A named character vector of translations.
#' @export
i18n_parse_po <- function(path) {
  lines <- i18n_po_read(path)
  if (length(lines) == 0L) return(character())

  entries <- list()
  msgid <- character()
  msgstr <- character()
  fuzzy <- FALSE
  field <- NULL

  flush <- function() {
    if (length(msgid) > 0L) {
      key <- paste(msgid, collapse = "")
      value <- paste(msgstr, collapse = "")
      if (nzchar(key) && nzchar(value) && !fuzzy) {
        entries[[key]] <<- value
      }
    }
    msgid <<- character()
    msgstr <<- character()
    fuzzy <<- FALSE
    field <<- NULL
  }

  for (line in lines) {
    trimmed <- trimws(line)
    if (!nzchar(trimmed)) {
      flush()
      next
    }
    if (startsWith(trimmed, "#")) {
      # A fuzzy flag belongs to the entry that follows it, so it must survive
      # the flush of the previous entry.
      if (grepl("fuzzy", trimmed, fixed = TRUE)) fuzzy <- TRUE
      next
    }
    if (grepl("^msgid[ \t]", line)) {
      pending_fuzzy <- fuzzy
      flush()
      fuzzy <- pending_fuzzy
      field <- "msgid"
      msgid <- c(msgid, i18n_po_unquote(sub("^msgid[ \t]+", "", line)))
    } else if (grepl("^msgctxt[ \t]", line)) {
      field <- "msgid"
    } else if (grepl("^msgstr([ \t]|\\[)", line)) {
      field <- "msgstr"
      msgstr <- c(msgstr, i18n_po_unquote(sub("^msgstr([ \t]+|\\[[0-9]+\\][ \t]*)", "", line)))
    } else if (grepl("^\"", trimmed) && !is.null(field)) {
      value <- i18n_po_unquote(trimmed)
      if (identical(field, "msgid")) {
        msgid <- c(msgid, value)
      } else {
        msgstr <- c(msgstr, value)
      }
    }
  }
  flush()

  if (length(entries) == 0L) return(character())
  unlist(entries, use.names = TRUE)
}

#' Translation catalogue for a language
#'
#' @param language Language code.
#' @param force Reparse even when the cache is valid.
#' @return A named character vector, empty when no catalogue exists.
#' @keywords internal
i18n_extra_path <- function(language) {
  if (is.null(language) || !nzchar(language) || identical(language, "en")) {
    return("")
  }
  file <- paste0(language, ".tsv")
  candidates <- c(
    system.file("i18n", file, package = "RcmdrShiny"),
    file.path("inst", "i18n", file),
    file.path(getwd(), "inst", "i18n", file)
  )
  for (candidate in candidates) {
    if (nzchar(candidate) && file.exists(candidate)) return(candidate)
  }
  ""
}

# The Studio adds many strings that are not in the Rcmdr catalogues.  They live
# in a small TSV overlay so that the inherited PO files stay untouched.
i18n_parse_tsv <- function(path) {
  lines <- tryCatch(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    error = function(e) character()
  )
  lines <- lines[nzchar(trimws(lines))]
  lines <- lines[!startsWith(trimws(lines), "#")]
  lines <- lines[trimws(lines) != "msgid\tmsgstr"]
  if (length(lines) == 0L) return(character())
  parts <- strsplit(lines, "\t", fixed = TRUE)
  parts <- parts[vapply(parts, length, integer(1)) >= 2L]
  if (length(parts) == 0L) return(character())
  keys <- vapply(parts, function(part) part[[1L]], character(1))
  values <- vapply(parts, function(part) {
    paste(part[-1L], collapse = "\t")
  }, character(1))
  stats::setNames(values, keys)
}

i18n_catalog <- function(language = current_language(), force = FALSE) {
  language <- i18n_normalize(language)
  if (identical(language, "en")) return(character())
  cached <- .i18n$catalogues[[language]]
  if (!isTRUE(force) && !is.null(cached)) return(cached)
  path <- i18n_po_path(language)
  base <- if (nzchar(path)) {
    tryCatch(i18n_parse_po(path), error = function(e) character())
  } else {
    character()
  }
  extra_path <- i18n_extra_path(language)
  extra <- if (nzchar(extra_path)) {
    tryCatch(i18n_parse_tsv(extra_path), error = function(e) character())
  } else {
    character()
  }
  catalogue <- if (length(extra) == 0L) base else {
    merged <- c(base, extra)
    merged[!duplicated(names(merged), fromLast = TRUE)]
  }
  .i18n$catalogues[[language]] <- catalogue
  .i18n$paths[[language]] <- c(path, extra_path)
  catalogue
}

i18n_lookup <- function(text, language = current_language()) {
  if (is.null(text) || !nzchar(text)) return(NULL)
  catalogue <- i18n_catalog(language)
  if (length(catalogue) == 0L || !text %in% names(catalogue)) return(NULL)
  value <- unname(catalogue[[text]])
  if (is.null(value) || !nzchar(value)) NULL else value
}

i18n_reset <- function() {
  .i18n$catalogues <- list()
  .i18n$paths <- list()
  invisible(NULL)
}

#' Translate a message
#'
#' Uses the in-process catalogue for the active language and falls back to the
#' gettext domain installed with the package.  The lookup is deliberately cheap
#' because it runs for every label rendered by the interface.
#'
#' @param ... Pieces of the message, pasted together.
#' @export
tr <- function(...) {
  text <- paste0(...)
  if (!nzchar(text)) return(text)
  translated <- i18n_lookup(text)
  if (!is.null(translated)) return(translated)
  gettext(text, domain = "R-RcmdrShiny")
}

#' @keywords internal
trn <- function(n, msg1, msg2) {
  if (isTRUE(n == 1L)) tr(msg1) else tr(msg2)
}

#' Languages shipped with the package
#'
#' @return A character vector of language codes, with `"en"` first.
#' @export
available_languages <- function() {
  directories <- unique(c(
    system.file("po", package = "RcmdrShiny"),
    file.path("inst", "po"),
    file.path(getwd(), "inst", "po")
  ))
  files <- unlist(lapply(directories[nzchar(directories)], function(directory) {
    if (!dir.exists(directory)) return(character())
    list.files(directory, pattern = "^R-[a-zA-Z_]+\\.po$")
  }), use.names = FALSE)
  if (length(files) == 0L) return("en")
  langs <- sub("^R-", "", sub("\\.po$", "", files))
  c("en", sort(unique(langs)))
}

# Labels stored in the menus file are English msgids; translate them on the
# fly so that a translated catalogue can be plugged in without touching the
# parser.
menu_label <- function(label) {
  if (!nzchar(label)) return(label)
  tr(label)
}
