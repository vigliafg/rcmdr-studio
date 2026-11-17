# Contract sweep over every dialog: the UI must render, on_ok() must not
# throw, and the result must be a well-formed dialog result.  This does not
# prove that each control maps to the right argument (that is per-dialog), but
# it catches renamed inputs, broken namespaces and crashes.

contract_fields <- function(html) {
  fields <- list()
  for (tag in regmatches(html, gregexpr("<input[^>]*>", html, perl = TRUE))[[1L]]) {
    if (!grepl('id="', tag)) next
    id <- sub('.*id="([^"]*)".*', "\\1", tag)
    type <- if (grepl('type="([^"]*)"', tag)) {
      sub('.*type="([^"]*)".*', "\\1", tag)
    } else {
      "text"
    }
    value <- if (grepl('value="([^"]*)"', tag)) {
      sub('.*value="([^"]*)".*', "\\1", tag)
    } else {
      ""
    }
    fields[[id]] <- list(type = type, value = value,
                         checked = grepl("checked", tag, fixed = TRUE))
  }
  selects <- regmatches(
    html, gregexpr("(?s)<select[^>]*>.*?</select>", html, perl = TRUE)
  )[[1L]]
  for (sel in selects) {
    id <- sub('.*id="([^"]*)".*', "\\1", sel)
    options <- regmatches(
      sel, gregexpr("<option[^>]*>[^<]*", sel, perl = TRUE)
    )[[1L]]
    values <- sub('.*value="([^"]*)".*', "\\1", options)
    selected <- grep("selected", options)
    value <- if (length(selected) > 0L) {
      values[[selected[[1L]]]]
    } else if (length(values) > 0L) {
      values[[1L]]
    } else {
      ""
    }
    fields[[id]] <- list(type = "select", value = value, checked = FALSE)
  }
  textareas <- regmatches(
    html, gregexpr("(?s)<textarea[^>]*>.*?</textarea>", html, perl = TRUE)
  )[[1L]]
  for (area in textareas) {
    id <- sub('.*id="([^"]*)".*', "\\1", area)
    fields[[id]] <- list(type = "textarea", value = "", checked = FALSE)
  }
  fields
}

contract_input <- function(fields, dialog) {
  prefix <- paste0(dialog, "_")
  input <- list()
  for (id in names(fields)) {
    if (!startsWith(id, prefix)) next
    field <- fields[[id]]
    value <- switch(field$type,
      checkbox = field$checked,
      radio = if (isTRUE(field$checked)) field$value else NULL,
      field$value
    )
    if (!is.null(value)) input[[sub(paste0("^", prefix), "", id)]] <- value
  }
  input
}

contract_state <- function() {
  env <- new.env()
  env$Dataset <- data.frame(
    y = c(1, 2, 3, 4, 5, 6, 7, 8),
    x = c(2, 4, 6, 8, 10, 12, 14, 16),
    z = c(1, 1, 2, 2, 3, 3, 4, 4),
    g = factor(rep(c("a", "b"), 4L)),
    c = letters[1:8],
    stringsAsFactors = FALSE
  )
  env$LinearModel.1 <- stats::lm(y ~ x, data = env$Dataset)
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  active_model(state, "LinearModel.1")
  state
}

test_that("every dialog renders and returns a well-formed result", {
  ids <- dialog_ids()
  expect_gt(length(ids), 200L)
  expect_equal(anyDuplicated(ids), 0L)

  state <- contract_state()
  problems <- character()

  for (id in ids) {
    spec <- get_dialog_spec(id)
    if (is.null(spec)) {
      problems <- c(problems, sprintf("%s: no spec", id))
      next
    }
    if (!inherits(spec, "RcmdrShinyDialog")) {
      problems <- c(problems, sprintf("%s: wrong class", id))
      next
    }

    html <- tryCatch(as.character(spec$ui(state, list())),
                     error = function(e) e)
    if (inherits(html, "error")) {
      problems <- c(problems, sprintf("%s: ui error: %s", id,
                                      conditionMessage(html)))
      next
    }
    if (!nzchar(html)) {
      problems <- c(problems, sprintf("%s: empty ui", id))
      next
    }

    input <- contract_input(contract_fields(html), id)
    result <- tryCatch(spec$on_ok(input, state), error = function(e) e)
    if (inherits(result, "error")) {
      problems <- c(problems, sprintf("%s: on_ok error: %s", id,
                                      conditionMessage(result)))
      next
    }
    if (!is.list(result) || length(result) == 0L) {
      problems <- c(problems, sprintf("%s: empty result", id))
      next
    }

    commands <- result$commands %||% character()
    if (length(commands) > 0L &&
        (!is.character(commands) || anyNA(commands) ||
         any(!nzchar(commands)))) {
      problems <- c(problems, sprintf("%s: malformed commands", id))
    }
    if (!is.null(result$error) &&
        (!is.character(result$error) || !nzchar(result$error[[1L]]))) {
      problems <- c(problems, sprintf("%s: empty error", id))
    }
    if (!is.null(result$memory) && !is.list(result$memory)) {
      problems <- c(problems, sprintf("%s: memory is not a list", id))
    }
  }

  expect_equal(problems, character(),
               info = paste(utils::head(problems, 20L), collapse = "\n"))
})

test_that("workflow memory keys are consumed by their dialogs", {
  state <- contract_state()
  for (workflow in workflow_registry()) {
    for (step in workflow$steps) {
      if (is.null(step$dialog)) next
      spec <- get_dialog_spec(step$dialog)
      if (is.null(spec)) next
      memory <- if (is.function(step$memory)) {
        tryCatch(step$memory(state), error = function(e) list())
      } else {
        step$memory %||% list()
      }
      unknown <- dialog_memory_unknown_keys(step$dialog, memory, state)
      expect_equal(
        unknown, character(),
        info = sprintf("%s/%s (%s)", workflow$id, step$id, step$dialog)
      )
    }
  }
})

test_that("strict memory mode warns about unknown keys", {
  state <- contract_state()
  old <- getOption("RcmdrShiny.strict_memory")
  options(RcmdrShiny.strict_memory = TRUE)
  on.exit(options(RcmdrShiny.strict_memory = old), add = TRUE)

  expect_warning(
    set_dialog_memory(state, "linearModel",
                      list(model_name = "M", lhs = "y", rhs = "x",
                           bogus = 1)),
    "bogus"
  )
  expect_silent(set_dialog_memory(
    state, "linearModel",
    list(model_name = "M", lhs = "y", rhs = "x")
  ))
  expect_silent(set_dialog_memory(state, "Histogram", list(variable = "y")))
})

test_that("every dialog renders the shared header and footer", {
  state <- contract_state()
  problems <- character()
  for (id in dialog_ids()) {
    spec <- get_dialog_spec(id)
    if (is.null(spec)) next
    html <- tryCatch(as.character(dialog_modal(spec)), error = function(e) e)
    if (inherits(html, "error")) {
      problems <- c(problems, sprintf("%s: %s", id, conditionMessage(html)))
      next
    }
    needed <- c(
      'class="modal-header rcmdr-modal-header"',
      'class="rcmdr-dialog-icon"',
      'id="rcmdr-dialog-title"',
      'aria-labelledby="rcmdr-dialog-title"',
      'class="modal-footer rcmdr-modal-footer"',
      'id="dialog_ok"',
      'id="dialog_cancel"'
    )
    missing <- needed[!vapply(needed, grepl, logical(1), x = html,
                              fixed = TRUE)]
    if (length(missing) > 0L) {
      problems <- c(problems, sprintf("%s: %s", id,
                                      paste(missing, collapse = ", ")))
    }
  }
  expect_equal(problems, character())
})
