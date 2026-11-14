#!/usr/bin/env Rscript
# Audit the translatable strings used by the interface.
#
# Usage:
#   Rscript tools/audit_i18n.R
#   Rscript tools/audit_i18n.R --language it --strict
#   Rscript tools/audit_i18n.R --write inst/etc/i18n-audit.csv
#
# The audit reads the literal msgids passed to tr() in R/ and the labels in
# inst/etc/Rcmdr-menus.txt, then compares them with the PO catalogue.  It never
# changes the sources; --write only writes the report.

args <- commandArgs(trailingOnly = TRUE)
value_of <- function(flag, default = NULL) {
  index <- match(flag, args)
  if (is.na(index) || index == length(args)) return(default)
  args[[index + 1L]]
}
has_flag <- function(flag) flag %in% args

root <- normalizePath(getwd(), mustWork = TRUE)
if (!dir.exists(file.path(root, "R"))) {
  stop("Run this script from the package root.", call. = FALSE)
}

language <- value_of("--language", "it")
strict <- has_flag("--strict")
write_to <- value_of("--write", NULL)

source(file.path(root, "R", "i18n.R"), local = TRUE)

extract_tr <- function(path) {
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  pattern <- "\\btr\\(\\s*(\"((?:[^\"\\\\]|\\\\.)*)\"|'((?:[^'\\\\]|\\\\.)*)')"
  matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (matches[[1L]] == -1L) return(character())
  hits <- regmatches(text, list(matches))[[1L]]
  values <- sub(pattern, "\\2\\3", hits, perl = TRUE)
  values <- gsub("\\\\n", "\n", values, fixed = TRUE)
  values <- gsub("\\\\\"", "\"", values, fixed = TRUE)
  unique(values[nzchar(values)])
}

menu_msgids <- function(path) {
  if (!file.exists(path)) return(character())
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  labels <- sub('^.*?"([^"]*)".*$', "\\1", lines)
  labels <- trimws(labels)
  unique(labels[nzchar(labels) & grepl("\"", lines, fixed = TRUE)])
}

r_files <- list.files(file.path(root, "R"), pattern = "\\.R$",
                      full.names = TRUE)
messages <- unique(unlist(lapply(r_files, extract_tr), use.names = FALSE))
menus <- menu_msgids(file.path(root, "inst", "etc", "Rcmdr-menus.txt"))
messages <- unique(c(messages, menus))

catalogue <- i18n_catalog(language)
translated <- messages %in% names(catalogue)
missing <- sort(messages[!translated])

report <- data.frame(
  msgid = messages,
  translated = translated,
  stringsAsFactors = FALSE
)

cat(sprintf("Language: %s\n", language))
cat(sprintf("Interface msgids: %d\n", length(messages)))
cat(sprintf("Translated: %d (%.1f%%)\n", sum(translated),
            100 * sum(translated) / max(1L, length(messages))))
cat(sprintf("Missing: %d\n", length(missing)))

if (length(missing) > 0L) {
  cat("\nFirst missing strings:\n")
  cat(paste0("  - ", utils::head(missing, 20L), collapse = "\n"), "\n")
}

if (!is.null(write_to)) {
  directory <- dirname(write_to)
  if (!dir.exists(directory)) dir.create(directory, recursive = TRUE)
  utils::write.csv(report, write_to, row.names = FALSE)
  cat(sprintf("\nReport written to %s\n", write_to))
}

if (isTRUE(strict) && length(missing) > 0L) {
  quit(status = 1L)
}
