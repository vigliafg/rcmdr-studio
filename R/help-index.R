# Help full-text index -------------------------------------------------------
#
# The help centre used to score every topic on every search.  The index below
# is built once per registry revision and language, then reused by the search
# box, the command palette and the documentation tools.  It stays in memory and
# is never persisted: it is a cache over the Markdown files, not a second
# source of truth.
#
# Weights follow the product specification: title 5, keywords and aliases 4,
# headings 3, body 1.  Exact title matches get an extra boost so that searching
# for a topic title always puts that topic first.

.help_index <- new.env(parent = emptyenv())
.help_index$key <- NULL
.help_index$value <- NULL

help_index_reset <- function() {
  .help_index$key <- NULL
  .help_index$value <- NULL
  invisible(NULL)
}

help_index_key <- function(language = NULL) {
  sprintf("%d|%s", .help_registry$revision %||% 0L, language %||% "")
}

# Headings are useful both for the index and for the in-topic table of
# contents.  Only Markdown ATX headings are considered; fenced code blocks are
# skipped so that a comment inside an example is not mistaken for a heading.
help_headings <- function(markdown) {
  lines <- strsplit(paste(markdown, collapse = "\n"), "\n", fixed = TRUE)[[1L]]
  in_code <- FALSE
  level <- integer()
  title <- character()
  line_number <- integer()
  for (i in seq_along(lines)) {
    line <- lines[[i]]
    if (grepl("^[ \t]*(```|~~~)", line)) {
      in_code <- !in_code
      next
    }
    if (in_code) next
    match <- regmatches(line, regexec("^(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$", line))[[1L]]
    if (length(match) < 3L) next
    level <- c(level, nchar(match[[2L]]))
    title <- c(title, trimws(match[[3L]]))
    line_number <- c(line_number, i)
  }
  if (length(level) == 0L) {
    return(data.frame(level = integer(), title = character(),
                      line = integer(), stringsAsFactors = FALSE))
  }
  data.frame(level = level, title = title, line = line_number,
             stringsAsFactors = FALSE)
}

help_slug <- function(text) {
  slug <- tolower(paste(text, collapse = " "))
  slug <- gsub("[^[:alnum:]]+", "-", slug)
  slug <- gsub("^-+|-+$", "", slug)
  if (!nzchar(slug)) "section" else slug
}

#' Table of contents for a help topic
#'
#' @param markdown Topic body.
#' @return A data frame with `level`, `title`, `anchor` and `line`.
#' @keywords internal
help_toc <- function(markdown) {
  headings <- help_headings(markdown)
  if (nrow(headings) == 0L) {
    return(data.frame(level = integer(), title = character(),
                      anchor = character(), line = integer(),
                      stringsAsFactors = FALSE))
  }
  anchors <- vapply(seq_len(nrow(headings)), function(i) {
    base <- paste0("rcmdr-help-", help_slug(headings$title[[i]]))
    if (i == 1L) base else paste0(base, "-", i)
  }, character(1))
  data.frame(
    level = headings$level,
    title = headings$title,
    anchor = anchors,
    line = headings$line,
    stringsAsFactors = FALSE
  )
}

# Put explicit anchors in the Markdown before rendering.  This keeps the HTML
# renderer replaceable: both commonmark and the plain fallback receive exactly
# the same source, and the table of contents can link to the anchors.
help_markdown_with_anchors <- function(markdown, toc = help_toc(markdown)) {
  markdown <- paste(markdown, collapse = "\n")
  if (nrow(toc) == 0L) return(markdown)
  lines <- strsplit(markdown, "\n", fixed = TRUE)[[1L]]
  for (i in seq_len(nrow(toc))) {
    index <- toc$line[[i]]
    if (index < 1L || index > length(lines)) next
    hashes <- strrep("#", toc$level[[i]])
    lines[[index]] <- sprintf(
      "%s <a id=\"%s\"></a>%s",
      hashes, toc$anchor[[i]], toc$title[[i]]
    )
  }
  paste(lines, collapse = "\n")
}

# -- examples ----------------------------------------------------------------

#' Parse the examples declared in a topic's front matter
#'
#' Accepts either a character vector of code strings or a list of mappings with
#' `code`, optional `title` and `runnable`.  Only examples explicitly marked
#' `runnable: true` can be executed from the help centre.
#'
#' @param value Raw `examples` value from the YAML front matter.
#' @return A list of example records.
#' @keywords internal
help_parse_examples <- function(value) {
  if (is.null(value) || length(value) == 0L) return(list())

  parse_one <- function(entry, index) {
    if (is.null(entry)) return(NULL)
    if (is.character(entry) && length(entry) > 0L) {
      return(list(
        index = index,
        code = paste(entry, collapse = "\n"),
        title = NULL,
        runnable = FALSE
      ))
    }
    if (!is.list(entry)) return(NULL)
    code <- help_meta_chr(entry, "code", NULL)
    if (is.null(code) || !nzchar(trimws(paste(code, collapse = "\n")))) {
      return(NULL)
    }
    list(
      index = index,
      code = paste(code, collapse = "\n"),
      title = help_meta_chr(entry, "title", NULL),
      runnable = isTRUE(entry$runnable) ||
        identical(tolower(as.character(entry$runnable %||% "false")[[1L]]), "true")
    )
  }

  out <- lapply(seq_along(value), function(i) parse_one(value[[i]], i))
  out <- Filter(Negate(is.null), out)
  if (length(out) == 0L) return(list())
  for (i in seq_along(out)) out[[i]]$index <- i
  out
}

help_topic_examples <- function(topic) {
  if (is.null(topic)) return(list())
  topic$examples %||% list()
}

# -- index -------------------------------------------------------------------

help_index_weighted_tokens <- function(topic) {
  headings <- help_headings(topic$body)
  list(
    title = help_tokens(topic$title),
    keywords = help_tokens(topic$keywords),
    aliases = help_tokens(c(topic$aliases, topic$commands, topic$dialogs,
                            topic$local_id)),
    headings = help_tokens(headings$title),
    body = help_tokens(topic$body)
  )
}

help_index_add_term <- function(terms, term, id, weight) {
  current <- terms[[term]]
  if (is.null(current)) current <- numeric()
  previous <- if (id %in% names(current)) current[[id]] else 0
  current[id] <- previous + weight
  terms[[term]] <- current
  terms
}

#' Build a full-text index over help topics
#'
#' @param topics Named list of topic records.  Defaults to the registered
#'   topics.
#' @param language Language code used to resolve the topics.
#' @param revision Optional registry revision used as cache key.
#' @return A list with `terms`, `docs`, `titles`, `title_tokens`, `language`
#'   and `revision`.
#' @keywords internal
help_index_build <- function(topics = NULL, language = NULL, revision = NULL) {
  if (is.null(topics)) topics <- help_topics(language)
  terms <- list()
  titles <- character()
  title_tokens <- list()

  ids <- names(topics)
  for (id in ids) {
    topic <- topics[[id]]
    fields <- help_index_weighted_tokens(topic)
    has_any <- FALSE
    for (field in names(fields)) {
      weight <- switch(
        field,
        title = 5,
        keywords = 4,
        aliases = 4,
        headings = 3,
        body = 1,
        1
      )
      for (token in fields[[field]]) {
        terms <- help_index_add_term(terms, token, id, weight)
        has_any <- TRUE
      }
    }
    titles[[id]] <- topic$title %||% id
    title_tokens[[id]] <- fields$title
    if (!has_any) next
  }

  docs <- data.frame(
    id = ids,
    title = vapply(topics, function(topic) topic$title %||% topic$id, character(1)),
    category = vapply(topics, function(topic) topic$category %||% "general", character(1)),
    type = vapply(topics, function(topic) topic$type %||% "task", character(1)),
    language = vapply(topics, function(topic) topic$language %||% "en", character(1)),
    package = vapply(topics, function(topic) topic$package %||% NA_character_, character(1)),
    length = vapply(topics, function(topic) nchar(help_plain_text(topic$body)),
                    integer(1)),
    stringsAsFactors = FALSE
  )

  list(
    terms = terms,
    docs = docs,
    titles = titles,
    title_tokens = title_tokens,
    language = language,
    revision = revision %||% (.help_registry$revision %||% 0L)
  )
}

#' Cached help index
#'
#' @param language Language code.
#' @param force Rebuild even when the cache is valid.
#' @return An index as returned by [help_index_build()].
#' @keywords internal
help_index_cached <- function(language = NULL, force = FALSE) {
  help_ensure_loaded()
  key <- help_index_key(language)
  if (!isTRUE(force) && identical(.help_index$key, key) &&
      !is.null(.help_index$value)) {
    return(.help_index$value)
  }
  index <- help_index_build(help_topics(language), language = language,
                            revision = .help_registry$revision)
  .help_index$key <- key
  .help_index$value <- index
  index
}

help_index_terms <- function(index, token) {
  terms <- names(index$terms)
  if (length(terms) == 0L || !nzchar(token)) return(character())
  if (nchar(token) < 4L) return(if (token %in% terms) token else character())
  stem <- substr(token, 1L, 5L)
  prefix <- terms[substr(terms, 1L, 5L) == stem]
  # Only complete the word by a few characters.  Without this guard a query
  # like "logistic" would also match "logisticquantiles" from dialog ids.
  prefix <- prefix[nchar(prefix) <= nchar(token) + 3L]
  unique(c(if (token %in% terms) token else character(), prefix))
}

help_index_score <- function(index, tokens) {
  docs <- index$docs
  scores <- stats::setNames(numeric(nrow(docs)), docs$id)
  for (token in tokens) {
    matches <- help_index_terms(index, token)
    for (term in matches) {
      weights <- index$terms[[term]]
      ids <- names(weights)
      known <- ids %in% names(scores)
      if (any(known)) {
        scores[ids[known]] <- scores[ids[known]] + unname(weights[known])
      }
    }
  }

  # Exact term matches in the title or in the aliases are more valuable than a
  # prefix hit in the body; a full title match is boosted again below.
  query <- paste(tokens, collapse = " ")
  for (id in names(scores)) {
    title <- help_tokens(index$titles[[id]] %||% "")
    if (all(tokens %in% title)) scores[[id]] <- scores[[id]] + 6
    if (identical(query, paste(title, collapse = " "))) {
      scores[[id]] <- scores[[id]] + 25
    }
  }
  scores
}

help_filter_docs <- function(docs, category = NULL, type = NULL,
                             package = "all") {
  if (!is.null(category) && length(category) > 0L && nzchar(category) &&
      !identical(category, "all")) {
    docs <- docs[docs$category == category, , drop = FALSE]
  }
  if (!is.null(type) && length(type) > 0L && nzchar(type) &&
      !identical(type, "all")) {
    docs <- docs[docs$type == type, , drop = FALSE]
  }
  if (!is.null(package) && length(package) > 0L && nzchar(package) &&
      !identical(package, "all")) {
    if (identical(package, "core")) {
      docs <- docs[is.na(docs$package) | !nzchar(docs$package), , drop = FALSE]
    } else {
      docs <- docs[!is.na(docs$package) & docs$package == package, , drop = FALSE]
    }
  }
  docs
}

#' Available help filters
#'
#' @param language Language code.
#' @return A list with `packages`, `types` and `categories`, each a named
#'   character vector suitable for [shiny::selectInput()].
#' @keywords internal
help_filter_choices <- function(language = NULL) {
  catalog <- help_catalog(language = language)
  packages <- sort(unique(stats::na.omit(catalog$package)))
  types <- sort(unique(catalog$type))
  categories <- help_index()
  list(
    packages = stats::setNames(
      c("all", "core", packages),
      c(tr("All sources"), tr("Core"), packages)
    ),
    types = stats::setNames(
      c("all", types),
      c(tr("All types"), vapply(types, help_title_case, character(1)))
    ),
    categories = stats::setNames(
      c("all", categories$id),
      c(tr("All categories"), vapply(categories$title, tr, character(1)))
    )
  )
}

# -- snippets ----------------------------------------------------------------

#' Highlight query terms in a snippet
#'
#' The snippet is escaped first; only the query tokens are wrapped in `<mark>`
#' elements.  Query tokens come from [help_tokens()] and therefore contain only
#' letters, digits and underscores.
#'
#' @param text Plain snippet.
#' @param tokens Query tokens.
#' @return An HTML string.
#' @keywords internal
help_snippet_highlight <- function(text, tokens) {
  if (!nzchar(text) || length(tokens) == 0L) return(htmltools::htmlEscape(text))
  escaped <- htmltools::htmlEscape(text)
  ordered <- tokens[order(nchar(tokens), decreasing = TRUE)]
  for (token in ordered) {
    if (!nzchar(token)) next
    pattern <- paste0("(?i)(", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", token), ")")
    escaped <- gsub(pattern, "<mark>\\1</mark>", escaped, perl = TRUE)
  }
  escaped
}
