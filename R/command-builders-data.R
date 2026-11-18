# Command generation for the Data menu --------------------------------------
#
# These builders mirror the R code produced by Rcmdr's data-menu.R dialogs.
# They are pure functions so that parity can be tested without Shiny.

quote_vars_data <- function(x) quote_vars(x)

#' @keywords internal
cmd_new_dataset <- function(name, rows = 10L, columns = 3L) {
  n <- max(1L, as.integer(rows))
  p <- max(1L, as.integer(columns))
  names <- paste0("V", seq_len(p))
  columns_code <- vapply(names, function(variable) {
    sprintf("%s = rep(NA_real_, %d)", variable, n)
  }, character(1))
  sprintf("%s <- data.frame(%s)", name, paste(columns_code, collapse = ", "))
}

#' @keywords internal
cmd_compute <- function(dataset, variable, expression) {
  sprintf("%s$%s <- with(%s, %s)", dataset, variable, dataset, expression)
}

# Structural column and row operations --------------------------------------
#
# The Data Studio issues these commands for every structural change so that the
# grid never becomes a second, untracked editing engine.  `values` and
# `expression` are R source snippets supplied by the caller; the builders only
# assemble commands and never evaluate them.

r_quote_data <- function(x) {
  encodeString(as.character(x), quote = "\"")
}

#' @keywords internal
cmd_add_column <- function(dataset, name, value = NA, expression = NULL) {
  if (!is.null(expression) && nzchar(trimws(expression))) {
    return(sprintf("%s$%s <- with(%s, %s)", dataset, name, dataset,
                   trimws(expression)))
  }
  value <- value %||% NA
  if (length(value) == 1L && is.na(value)) {
    sprintf("%s$%s <- rep(NA, nrow(%s))", dataset, name, dataset)
  } else if (is.character(value) && length(value) == 1L) {
    sprintf("%s$%s <- %s", dataset, name, value)
  } else {
    sprintf("%s$%s <- %s", dataset, name, paste(deparse(value), collapse = ""))
  }
}

#' @keywords internal
cmd_duplicate_column <- function(dataset, variable, name) {
  sprintf("%s$%s <- %s$%s", dataset, name, dataset, variable)
}

#' @keywords internal
cmd_delete_columns <- function(dataset, variables) {
  cmd_delete_variables(dataset, variables)
}

#' @keywords internal
cmd_rename_column <- function(dataset, variable, new_name) {
  sprintf("names(%s)[names(%s) == %s] <- %s", dataset, dataset,
          r_quote_data(variable), r_quote_data(new_name))
}

#' @keywords internal
cmd_reorder_columns <- function(dataset, order) {
  sprintf("%s <- %s[, c(%s), drop = FALSE]", dataset, dataset,
          paste0(r_quote_data(order), collapse = ", "))
}

#' @keywords internal
cmd_factor_to_numeric <- function(dataset, variable) {
  sprintf("%s$%s <- as.numeric(as.character(%s$%s))",
          dataset, variable, dataset, variable)
}

#' @keywords internal
cmd_logical_to_numeric <- function(dataset, variable) {
  sprintf("%s$%s <- as.numeric(%s$%s)", dataset, variable, dataset, variable)
}

#' @keywords internal
cmd_logical_to_factor <- function(dataset, variable, labels = NULL) {
  if (!is.null(labels) && length(labels) > 0L) {
    sprintf("%s$%s <- factor(%s$%s, labels = c(%s))", dataset, variable,
            dataset, variable,
            paste0(r_quote_data(labels), collapse = ", "))
  } else {
    sprintf("%s$%s <- factor(%s$%s)", dataset, variable, dataset, variable)
  }
}

#' @keywords internal
cmd_set_column_type <- function(dataset, variable, type = c(
                                  "numeric", "factor", "character", "logical",
                                  "date")) {
  type <- match.arg(type)
  source <- sprintf("%s$%s", dataset, variable)
  expression <- switch(
    type,
    numeric = sprintf("as.numeric(as.character(%s))", source),
    factor = sprintf("as.factor(%s)", source),
    character = sprintf("as.character(%s)", source),
    logical = sprintf("as.logical(%s)", source),
    date = sprintf("as.Date(%s)", source)
  )
  sprintf("%s <- %s", source, expression)
}

#' @keywords internal
cmd_add_row <- function(dataset, values = NULL) {
  if (is.null(values) || length(values) == 0L) {
    return(sprintf("%s[nrow(%s) + 1L, ] <- NA", dataset, dataset))
  }
  if (is.null(names(values)) || any(!nzchar(names(values)))) {
    stop("Row values must be named.", call. = FALSE)
  }
  sprintf("%s[nrow(%s) + 1L, c(%s)] <- list(%s)", dataset, dataset,
          paste0(r_quote_data(names(values)), collapse = ", "),
          paste(values, collapse = ", "))
}

#' @keywords internal
cmd_delete_rows <- function(dataset, rows, new_name = NULL) {
  rows <- as.integer(rows)
  rows <- rows[!is.na(rows) & rows > 0L]
  if (length(rows) == 0L) return(character())
  index <- paste0("-c(", paste(rows, collapse = ", "), ")")
  if (is.null(new_name) || !nzchar(new_name) || identical(new_name, dataset)) {
    sprintf("%s <- %s[%s, , drop = FALSE]", dataset, dataset, index)
  } else {
    sprintf("%s <- %s[%s, , drop = FALSE]", new_name, dataset, index)
  }
}

#' @keywords internal
cmd_duplicate_rows <- function(dataset, rows, new_name = NULL) {
  rows <- as.integer(rows)
  rows <- rows[!is.na(rows) & rows > 0L]
  if (length(rows) == 0L) return(character())
  target <- if (is.null(new_name) || !nzchar(new_name)) dataset else new_name
  sprintf("%s <- rbind(%s, %s[c(%s), , drop = FALSE])",
          target, dataset, dataset, paste(rows, collapse = ", "))
}

#' @keywords internal
cmd_set_variable_label <- function(dataset, variable, label = NULL,
                                   units = NULL, description = NULL) {
  source <- sprintf("%s$%s", dataset, variable)
  commands <- character()
  if (!is.null(label)) {
    commands <- c(commands, sprintf("attr(%s, \"label\") <- %s", source,
                                    r_quote_data(label)))
  }
  if (!is.null(units)) {
    commands <- c(commands, sprintf("attr(%s, \"units\") <- %s", source,
                                    r_quote_data(units)))
  }
  if (!is.null(description)) {
    commands <- c(commands, sprintf("attr(%s, \"description\") <- %s", source,
                                    r_quote_data(description)))
  }
  commands
}

#' @keywords internal
cmd_delete_variables <- function(dataset, variables) {
  lines <- vapply(variables, function(variable) {
    sprintf("  %s <- NULL", variable)
  }, character(1))
  paste0(
    dataset, " <- within(", dataset, ", {\n",
    paste(lines, collapse = "\n"),
    "\n})"
  )
}

#' @keywords internal
cmd_numeric_to_factor <- function(dataset, variables, name = NULL,
                                  labels = NULL) {
  commands <- character()
  same <- is.null(name) || !nzchar(name) || identical(name, "<same as variables>")
  for (variable in variables) {
    target <- if (same) {
      variable
    } else if (length(variables) == 1L) {
      name
    } else {
      paste0(name, variable)
    }
    rhs <- if (!is.null(labels) && length(labels) > 0L) {
      sprintf("factor(%s, labels=c(%s))", variable,
              paste0("'", labels, "'", collapse = ","))
    } else {
      sprintf("as.factor(%s)", variable)
    }
    commands <- c(commands, sprintf("%s <- within(%s, {\n  %s <- %s\n})",
                                    dataset, dataset, target, rhs))
  }
  commands
}

#' @keywords internal
cmd_character_to_factor <- function(dataset, variables, name = NULL) {
  cmd_numeric_to_factor(dataset, variables, name = name, labels = NULL)
}

# Rcmdr's convertStrings2Factors() converts every character column in place.
#' @keywords internal
cmd_convert_strings_to_factors <- function(dataset, variables) {
  variables <- variables[nzchar(variables)]
  if (length(variables) == 0L) return(character())
  cmd_numeric_to_factor(dataset, variables, name = NULL, labels = NULL)
}

#' @keywords internal
cmd_bin_variable <- function(dataset, variable, new_variable, bins = 3L,
                             method = "intervals", labels = NULL) {
  labels_code <- if (is.null(labels)) {
    "FALSE"
  } else if (identical(labels, "ranges")) {
    "NULL"
  } else {
    sprintf("c(%s)", paste0("'", labels, "'", collapse = ","))
  }
  sprintf(
    "%s$%s <- with(%s, binVariable(%s, bins=%d, method='%s', labels=%s))",
    dataset, new_variable, dataset, variable, as.integer(bins),
    method, labels_code
  )
}

#' @keywords internal
cmd_reorder_factor <- function(dataset, variable, name, levels,
                               ordered = FALSE) {
  sprintf(
    "%s$%s <- with(%s, factor(%s, levels=c(%s)%s))",
    dataset, name, dataset, variable,
    paste0("'", levels, "'", collapse = ","),
    if (isTRUE(ordered)) ", ordered=TRUE" else ""
  )
}

#' @keywords internal
cmd_standardize <- function(dataset, variables) {
  quoted <- paste0('"', variables, '"', collapse = ",")
  assignments <- vapply(rev(seq_along(variables)), function(i) {
    sprintf("    Z.%s <- .Z[,%d]", variables[[i]], i)
  }, character(1))
  paste0(
    dataset, " <- local({\n",
    "  .Z <- scale(", dataset, "[,c(", quoted, ")])\n",
    "  within(", dataset, ", {\n",
    paste(assignments, collapse = "\n"),
    "\n  })\n})"
  )
}

#' @keywords internal
cmd_recode <- function(dataset, variables, name, directives,
                       as_factor = FALSE, to_value = "=",
                       interval = ":", separator = ";") {
  directives <- gsub("'", '"', directives)
  directives <- gsub("\n", paste0(separator, " "), directives)
  directives <- sub(paste0(" *", separator, " *$"), "", directives)
  process <- function(recode) {
    parts <- strsplit(recode, "=", fixed = TRUE)[[1L]]
    if (grepl(",", parts[[1L]], fixed = TRUE)) {
      paste0("c(", parts[[1L]], ") = ", paste(parts[-1L], collapse = "="))
    } else {
      paste(parts, collapse = "=")
    }
  }
  pieces <- strsplit(directives, separator, fixed = TRUE)[[1L]]
  pieces <- vapply(pieces, process, character(1))
  directives <- paste(pieces, collapse = separator)

  multiple <- length(variables) > 1L
  lines <- vapply(rev(variables), function(variable) {
    target <- if (multiple) paste0(name, variable) else name
    sprintf(
      "  %s <- Recode(%s, '%s', as.factor=%s, to.value=\"%s\", interval=\"%s\", separator=\"%s\")",
      target, variable, directives, isTRUE(as_factor), to_value,
      interval, separator
    )
  }, character(1))

  paste0(dataset, " <- within(", dataset, ", {\n",
         paste(lines, collapse = "\n"), "\n})")
}

#' @keywords internal
cmd_export_data <- function(dataset, file, sep = ",",
                            col_names = TRUE, row_names = FALSE,
                            quote = TRUE, na = "NA") {
  sprintf(
    "write.table(%s, \"%s\", sep=\"%s\", col.names=%s, row.names=%s, quote=%s, na=\"%s\")",
    dataset, file, sep, isTRUE(col_names), isTRUE(row_names),
    isTRUE(quote), na
  )
}

#' @keywords internal
cmd_filter_na <- function(dataset, new_name, variables = NULL) {
  if (is.null(variables) || length(variables) == 0L) {
    sprintf("%s <- na.omit(%s)", new_name, dataset)
  } else {
    sprintf("%s <- na.omit(%s[,c(%s)])", new_name, dataset,
            paste0('"', variables, '"', collapse = ","))
  }
}

#' @keywords internal
cmd_subset_dataset <- function(dataset, new_name, variables = NULL,
                               cases = NULL) {
  select <- if (is.null(variables) || length(variables) == 0L) {
    ""
  } else {
    paste0(", select=c(", paste(variables, collapse = ","), ")")
  }
  subset <- if (is.null(cases) || !nzchar(trimws(cases))) {
    ""
  } else {
    paste0(", subset=", cases)
  }
  sprintf("%s <- subset(%s%s%s)", new_name, dataset, subset, select)
}

#' @keywords internal
cmd_set_case_names <- function(dataset, variable) {
  c(
    sprintf('row.names(%s) <- as.character(%s$%s)', dataset, dataset, variable),
    sprintf("%s$%s <- NULL", dataset, variable)
  )
}

#' @keywords internal
cmd_rename_variables_at <- function(dataset, positions, new) {
  sprintf(
    'names(%s)[c(%s)] <- c(%s)',
    dataset, paste(positions, collapse = ","),
    paste0('"', new, '"', collapse = ",")
  )
}

#' @keywords internal
cmd_set_contrasts <- function(dataset, variable, type) {
  sprintf('contrasts(%s$%s) <- "%s"', dataset, variable, type)
}

#' @keywords internal
cmd_stack <- function(dataset, variables, new_dataset,
                      variable_name = "variable", factor_name = "factor") {
  c(
    sprintf('%s <- stack(%s[, c(%s)])', new_dataset, dataset,
            paste0('"', variables, '"', collapse = ",")),
    sprintf('names(%s) <- c("%s", "%s")',
            new_dataset, variable_name, factor_name)
  )
}

#' @keywords internal
cases_select <- function(dataset, df, cases) {
  tokens <- scan(text = gsub(",", " ", cases), what = "", quiet = TRUE)
  if (length(tokens) == 0L) return(list(error = tr("No rows to select")))

  numbers <- suppressWarnings(as.numeric(tokens))
  if (!anyNA(numbers)) {
    bad <- numbers[!numbers %in% seq_len(nrow(df))]
    if (length(bad) > 0L) {
      return(list(error = paste(tr("bad row numbers:"),
                                paste(bad, collapse = ", "))))
    }
  } else {
    bad <- tokens[!tokens %in% rownames(df)]
    if (length(bad) > 0L) {
      return(list(error = paste(tr("bad row names:"),
                                paste(bad, collapse = ", "))))
    }
  }
  list(value = paste0("c(", paste0("'", tokens, "'", collapse = ", "), ")"))
}

#' @keywords internal
cmd_remove_rows <- function(dataset, new_name, remove_rows) {
  sprintf("%s <- %s[%s,]", new_name, dataset, remove_rows)
}

#' @keywords internal
cmd_select_rows <- function(dataset, new_name, select_rows, ncol) {
  suffix <- if (ncol == 1L) ", drop = FALSE" else ""
  sprintf("%s <- %s[%s, %s]", new_name, dataset, select_rows, suffix)
}

#' @keywords internal
cmd_merge <- function(first, second, new_name, direction = "rows",
                      common = FALSE) {
  if (identical(direction, "rows")) {
    sprintf("%s <- mergeRows(%s, %s, common.only=%s)",
            new_name, first, second, isTRUE(common))
  } else {
    c(
      sprintf('%s <- merge(%s, %s, all=%s, by="row.names")',
              new_name, first, second, !isTRUE(common)),
      sprintf("rownames(%s) <- %s$Row.names", new_name, new_name),
      sprintf("%s$Row.names <- NULL", new_name)
    )
  }
}

#' @keywords internal
cmd_aggregate <- function(dataset, new_name, variables, by, fun = "mean") {
  response <- if (length(variables) > 1L) {
    paste0("cbind(", paste(variables, collapse = ", "), ")")
  } else {
    variables
  }
  sprintf('%s <- aggregate(%s ~ %s, data=%s, FUN=%s)',
          new_name, response, paste(by, collapse = " + "), dataset, fun)
}

#' @keywords internal
cmd_drop_levels <- function(dataset, variables = NULL) {
  if (is.null(variables) || length(variables) == 0L) {
    sprintf("%s <- droplevels(%s)", dataset, dataset)
  } else {
    lines <- vapply(variables, function(variable) {
      sprintf("  %s <- droplevels(%s)", variable, variable)
    }, character(1))
    paste0(dataset, " <- within(", dataset, ", {\n",
           paste(lines, collapse = "\n"), "\n})")
  }
}

#' @keywords internal
cmd_sort <- function(dataset, new_name, keys, decreasing = FALSE) {
  sprintf("%s <- with(%s, %s[order(%s, decreasing=%s), ])",
          new_name, dataset, dataset, paste(keys, collapse = ", "),
          isTRUE(decreasing))
}

#' @keywords internal
cmd_reshape_long2wide <- function(dataset, new_name, id, within,
                                  varying, ignore = NULL) {
  quote1 <- function(x) {
    if (length(x) == 1L) paste0('"', x, '"')
    else paste0("c(", paste0('"', x, '"', collapse = ", "), ")")
  }
  ignore_code <- if (is.null(ignore) || length(ignore) == 0L) {
    ""
  } else {
    paste0(", ignore=", quote1(ignore))
  }
  sprintf('%s <- reshapeL2W(%s, within=%s, id="%s", varying=%s%s)',
          new_name, dataset, quote1(within), id, quote1(varying), ignore_code)
}

#' @keywords internal
cmd_reshape_wide2long <- function(dataset, new_name, within, responses,
                                  levels = NULL, ignore = NULL,
                                  id = "id") {
  if (is.null(levels)) levels <- paste0("Level-", seq_along(responses))
  ignore_code <- if (is.null(ignore) || length(ignore) == 0L) {
    ""
  } else {
    paste0(", ignore=", paste0('c(', paste0('"', ignore, '"', collapse = ", "), ')'))
  }
  sprintf(
    '%s <- reshapeW2L(%s, within="%s", levels=list(%s=c(%s)), varying=list(%s=c(%s))%s, id="%s")',
    new_name, dataset, within, within,
    paste0('"', levels, '"', collapse = ", "),
    within, paste0('"', responses, '"', collapse = ", "),
    ignore_code, id
  )
}

#' @keywords internal
cmd_read_package <- function(dataset, package) {
  sprintf('data(%s, package="%s")', dataset, package)
}

#' @keywords internal
cmd_add_obs_numbers <- function(dataset, nrow) {
  sprintf("%s$ObsNumber <- 1:%d", dataset, as.integer(nrow))
}

# Import commands -----------------------------------------------------------

#' @keywords internal
cmd_import_excel <- function(dataset, file, sheet = 1, header = TRUE,
                             rownames = FALSE, na = "", stringsAsFactors = FALSE) {
  sheet_code <- if (is.numeric(sheet)) as.character(as.integer(sheet)) else paste0('"', sheet, '"')
  sprintf(
    'readXL("%s", rownames=%s, header=%s, na="%s", sheet=%s, stringsAsFactors=%s)',
    file, isTRUE(rownames), isTRUE(header), na, sheet_code,
    isTRUE(stringsAsFactors)
  )
}

#' @keywords internal
cmd_import_sas <- function(dataset, file, stringsAsFactors = TRUE, rownames = FALSE) {
  sprintf('readSAS("%s", stringsAsFactors=%s, rownames=%s)',
          file, isTRUE(stringsAsFactors), isTRUE(rownames))
}

#' @keywords internal
cmd_import_spss <- function(dataset, file, rownames = TRUE,
                            stringsAsFactors = TRUE, tolower = TRUE) {
  sprintf('readSPSS("%s", rownames=%s, stringsAsFactors=%s, tolower=%s)',
          file, isTRUE(rownames), isTRUE(stringsAsFactors), isTRUE(tolower))
}

#' @keywords internal
cmd_import_stata <- function(dataset, file, convert_dates = TRUE,
                             stringsAsFactors = TRUE, rownames = FALSE) {
  sprintf('readStata("%s", convert.dates=%s, stringsAsFactors=%s, rownames=%s)',
          file, isTRUE(convert_dates), isTRUE(stringsAsFactors), isTRUE(rownames))
}

#' @keywords internal
cmd_import_minitab <- function(dataset, file) {
  sprintf('%s <- as.data.frame(read.mtp("%s"))', dataset, file)
}

#' @keywords internal
cmd_import_sas_xport <- function(dataset, file) {
  c(
    sprintf('.Datasets <- read.xport("%s")', file),
    sprintf('%s <- .Datasets[[1]]', dataset),
    "remove(.Datasets)"
  )
}

# Cell edits ----------------------------------------------------------------

format_cell_value <- function(x) {
  if (length(x) == 0L || is.na(x)) return("NA")
  if (is.character(x)) return(r_quote_data(x))
  if (is.logical(x)) return(if (isTRUE(x)) "TRUE" else "FALSE")
  if (inherits(x, "Date")) {
    return(sprintf("as.Date(%s)", r_quote_data(format(x, "%Y-%m-%d"))))
  }
  if (is.numeric(x)) {
    return(format(x, digits = 15, scientific = FALSE, trim = TRUE))
  }
  r_quote_data(as.character(x))
}

#' Align edited values with the classes of the original columns
#'
#' `rhandsontable` returns a data frame inferred from the grid: factors may be
#' unordered, dates may be strings and a numeric column may have become
#' character.  The editor must not change a column's class by accident, so the
#' original class wins.  A factor keeps its ordered flag and gains any new
#' level the user typed.
#' @keywords internal
align_edited_data <- function(old, new) {
  if (is.null(old) || is.null(new)) return(new)
  if (!is.data.frame(old) || !is.data.frame(new)) return(new)
  for (column in intersect(names(old), names(new))) {
    before <- old[[column]]
    after <- new[[column]]
    if (length(before) != length(after)) next
    if (is.factor(before)) {
      values <- as.character(after)
      levels <- union(levels(before), unique(values[!is.na(values)]))
      new[[column]] <- factor(
        values, levels = levels, ordered = is.ordered(before)
      )
    } else if (inherits(before, "Date")) {
      new[[column]] <- if (is.numeric(after)) {
        as.Date(after, origin = "1970-01-01")
      } else {
        as.Date(as.character(after))
      }
    } else if (inherits(before, "POSIXct") ||
               inherits(before, "POSIXlt")) {
      # Read-only in the editor; no silent time-zone change.
    } else if (is.logical(before)) {
      new[[column]] <- as.logical(after)
    } else if (is.numeric(before)) {
      new[[column]] <- suppressWarnings(as.numeric(as.character(after)))
    } else if (is.character(before)) {
      new[[column]] <- as.character(after)
    }
  }
  new
}

#' Problems in an edited data frame, before any command is generated
#'
#' The grid can hand back text in a numeric column, a different number of rows
#' or an edit to a column that the editor marks read-only.  These are refused
#' with a message instead of being written as `NA` or silently ignored.
#' @keywords internal
validate_edited_data <- function(old, new) {
  problems <- character()
  if (is.null(old) || is.null(new) ||
      !is.data.frame(old) || !is.data.frame(new)) {
    return(tr("The edited data are not valid."))
  }
  if (!identical(names(old), names(new))) {
    return(tr("The editor changed the columns; apply the column actions instead."))
  }
  if (nrow(old) != nrow(new)) {
    problems <- c(problems,
                  tr("The editor changed the number of rows; use the row actions instead."))
  }
  for (column in names(old)) {
    before <- old[[column]]
    after <- new[[column]]
    if (length(before) != length(after)) next
    if (length(before) == 0L) next
    if (inherits(before, "POSIXct") || inherits(before, "POSIXlt") ||
        is.list(before)) {
      same <- mapply(identical, before, after, USE.NAMES = FALSE)
      if (any(!same)) {
        problems <- c(problems, sprintf(
          tr("Column %s is read-only in the editor."), column
        ))
      }
      next
    }
    raw <- as.character(after)
    if (is.numeric(before) && !is.factor(before)) {
      bad <- !is.na(raw) & nzchar(trimws(raw)) &
        is.na(suppressWarnings(as.numeric(raw)))
      if (any(bad)) {
        problems <- c(problems, sprintf(
          tr("Column %s needs numeric values."), column
        ))
      }
    } else if (is.logical(before)) {
      allowed <- is.na(raw) | !nzchar(trimws(raw)) |
        tolower(trimws(raw)) %in% c("true", "false", "t", "f", "1", "0")
      if (any(!allowed)) {
        problems <- c(problems, sprintf(
          tr("Column %s needs TRUE or FALSE."), column
        ))
      }
    } else if (inherits(before, "Date")) {
      bad <- !is.na(raw) & nzchar(trimws(raw)) &
        is.na(suppressWarnings(as.Date(raw)))
      if (any(bad)) {
        problems <- c(problems, sprintf(
          tr("Column %s needs a valid date."), column
        ))
      }
    }
  }
  unique(problems)
}

#' Rows of a command, one index or a vector
#' @keywords internal
command_row_index <- function(rows) {
  if (length(rows) == 1L) as.character(rows)
  else sprintf("c(%s)", paste(rows, collapse = ", "))
}

#' One right-hand side for one or more cells
#' @keywords internal
command_cell_values <- function(values) {
  formatted <- vapply(seq_along(values), function(i) {
    format_cell_value(values[[i]])
  }, character(1))
  if (length(formatted) == 1L) formatted else {
    sprintf("c(%s)", paste(formatted, collapse = ", "))
  }
}

#' @keywords internal
cmd_edit_cells <- function(dataset, old, new) {
  if (is.null(old) || is.null(new)) return(character())
  if (!is.data.frame(old) || !is.data.frame(new)) return(character())
  if (!identical(names(old), names(new))) return(character())
  new <- align_edited_data(old, new)

  commands <- character()
  for (column in names(old)) {
    before <- old[[column]]
    after <- new[[column]]
    if (length(before) != length(after)) next
    if (is.list(before) || is.list(after)) next
    if (inherits(before, "POSIXct") || inherits(before, "POSIXlt")) next
    same <- (is.na(before) & is.na(after)) |
      (!is.na(before) & !is.na(after) &
         as.character(before) == as.character(after))
    changed <- which(!same)
    if (length(changed) == 0L) next
    if (is.factor(before)) {
      new_levels <- setdiff(unique(as.character(after[changed])),
                            levels(before))
      new_levels <- new_levels[!is.na(new_levels)]
      if (length(new_levels) > 0L) {
        quoted <- vapply(new_levels, r_quote_data, character(1))
        commands <- c(commands, sprintf(
          "levels(%s[[%s]]) <- c(levels(%s[[%s]]), %s)",
          dataset, r_quote_data(column),
          dataset, r_quote_data(column),
          paste(quoted, collapse = ", ")
        ))
      }
    }
    commands <- c(commands, sprintf(
      "%s[%s, %s] <- %s",
      dataset, command_row_index(changed), r_quote_data(column),
      command_cell_values(after[changed])
    ))
  }
  commands
}
