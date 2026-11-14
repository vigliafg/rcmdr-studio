# Report Studio ---------------------------------------------------------------
#
# The Report Studio is an authoring environment for R Markdown and knitr
# documents.  It shares the document model with the Script tab: the same
# `state$document` buffer, the same registry and the same knit engine.  The
# fast Markdown preview never executes code; the knit does, exactly as R
# Markdown requires.

# Preview --------------------------------------------------------------------

.report_preview_cache <- new.env(parent = emptyenv())
.report_preview_cache$entries <- list()

#' Clear the Markdown preview cache
#' @keywords internal
report_preview_clear <- function() {
  .report_preview_cache$entries <- list()
  invisible(NULL)
}

report_preview_lookup <- function(key) {
  for (entry in .report_preview_cache$entries) {
    if (identical(entry$key, key)) return(entry$result)
  }
  NULL
}

report_preview_store <- function(key, result, limit = 8L) {
  entries <- c(list(list(key = key, result = result)),
               .report_preview_cache$entries)
  .report_preview_cache$entries <- utils::head(entries, max(1L, limit))
  invisible(result)
}

report_preview_chunk_html <- function(chunk) {
  label <- chunk$label %||% ""
  heading <- if (nzchar(label)) {
    sprintf("%s: %s", tr("Chunk"), label)
  } else {
    tr("Code chunk")
  }
  htmltools::tags$div(
    class = "rcmdr-report-chunk",
    htmltools::tags$div(class = "rcmdr-report-chunk-label", heading),
    htmltools::tags$pre(htmltools::tags$code(chunk$code %||% ""))
  )
}

#' Fast Markdown preview
#'
#' The preview is deliberately not a knit: YAML is rendered as a heading block
#' and every code chunk becomes a labelled placeholder.  No code is executed.
#' @keywords internal
report_preview_markdown <- function(text, mode = "rmd") {
  text <- paste(text, collapse = "\n")
  front <- document_front_matter(text)
  chunks <- document_chunks(text, mode)
  empty <- list(
    html = "", front = front, chunks = chunks,
    outline = document_outline(text, mode), error = NULL
  )
  if (!nzchar(trimws(text))) {
    empty$html <- htmltools::tags$p(
      class = "text-muted", tr("The document is empty.")
    )
    return(empty)
  }

  if (identical(mode, "r")) {
    empty$html <- htmltools::tags$pre(class = "rcmdr-report-source", text)
    return(empty)
  }
  if (identical(mode, "rnw")) {
    empty$html <- htmltools::tagList(
      htmltools::tags$p(
        class = "text-muted small",
        tr("LaTeX documents are previewed after knitting. The fast preview is available for R Markdown.")
      ),
      htmltools::tags$pre(class = "rcmdr-report-source", text)
    )
    return(empty)
  }

  lines <- document_lines(text)
  out <- character()
  title <- front$values$title %||% ""
  if (nzchar(title)) {
    out <- c(out, sprintf("# %s", title), "")
    meta <- c(front$values$author, front$values$date)
    meta <- as.character(meta[!vapply(meta, is.null, logical(1))])
    meta <- meta[nzchar(meta)]
    if (length(meta) > 0L) {
      out <- c(out, sprintf("*%s*", paste(meta, collapse = " - ")), "")
    }
  }

  i <- 1L
  while (i <= length(lines)) {
    if (!is.null(front$bounds) && i >= front$bounds[[1L]] &&
        i <= front$bounds[[2L]]) {
      i <- front$bounds[[2L]] + 1L
      next
    }
    hit <- which(chunks$start == i)
    if (length(hit) == 1L) {
      chunk <- chunks[hit, , drop = FALSE]
      out <- c(out, as.character(report_preview_chunk_html(chunk)))
      i <- chunk$end[[1L]] + 1L
      next
    }
    out <- c(out, lines[[i]])
    i <- i + 1L
  }

  html <- tryCatch(
    preview_markdown(paste(out, collapse = "\n")),
    error = function(e) {
      paste0("<p class=\"text-danger\">", htmltools::htmlEscape(conditionMessage(e)),
             "</p>")
    }
  )
  list(
    html = htmltools::HTML(html),
    front = front,
    chunks = chunks,
    outline = document_outline(text, mode),
    error = NULL
  )
}

#' Cached Markdown preview
#' @keywords internal
report_preview <- function(text, mode = "rmd", limit = 8L) {
  text <- paste(text, collapse = "\n")
  key <- paste(mode, text, sep = "\n---\n")
  cached <- report_preview_lookup(key)
  if (!is.null(cached)) return(cached)
  result <- tryCatch(
    report_preview_markdown(text, mode),
    error = function(e) {
      list(html = htmltools::tags$p(class = "text-danger",
                                    conditionMessage(e)),
           front = document_front_matter(text), chunks = document_chunks(text, mode),
           outline = document_outline(text, mode), error = conditionMessage(e))
    }
  )
  report_preview_store(key, result, limit = limit)
  result
}

# Executable cells -----------------------------------------------------------

#' Run one chunk without touching the document
#'
#' The command is executed through [run_command()] with `log = FALSE`, so the
#' document is not modified and the auto-append feature cannot duplicate the
#' chunk.  The structured history still records the run.
#' @keywords internal
report_run_cell <- function(state, chunk_id, text = NULL, mode = NULL) {
  text <- text %||% document_text(state)
  mode <- mode %||% document_mode(state)
  chunk <- document_chunk_by_id(text, chunk_id, mode)
  if (is.null(chunk)) {
    return(list(id = chunk_id, status = "missing",
                error = tr("The chunk is not available."), output = character()))
  }
  code <- chunk$code[[1L]]
  if (!nzchar(trimws(code))) {
    output <- list(
      id = chunk_id, code = "", status = "empty", output = character(),
      messages = character(), warnings = character(), error = NULL,
      plot_url = NULL, time = Sys.time()
    )
    state$cell_outputs[[chunk_id]] <- output
    if (is.function(session_trim)) session_trim(state)
    return(output)
  }
  before <- length(state$plots %||% list())
  started <- Sys.time()
  result <- tryCatch(
    run_command(state, code, log = FALSE, source = "report"),
    error = function(e) list(status = "error", error = conditionMessage(e),
                             output = character(), messages = character(),
                             warnings = character())
  )
  plot_url <- NULL
  if (length(state$plots %||% list()) > before) {
    plot_url <- state$plots[[length(state$plots)]]$url
  }
  output <- list(
    id = chunk_id,
    code = code,
    status = result$status %||% "ok",
    output = result$output %||% character(),
    messages = result$messages %||% character(),
    warnings = result$warnings %||% character(),
    error = result$error %||% NULL,
    plot_url = plot_url,
    time = Sys.time(),
    duration_ms = as.numeric(difftime(Sys.time(), started, units = "secs")) * 1000
  )
  state$cell_outputs[[chunk_id]] <- output
  if (is.function(session_trim)) session_trim(state)
  output
}

#' Run all chunks, optionally up to one
#' @keywords internal
report_run_all_cells <- function(state, text = NULL, mode = NULL,
                                 up_to = NULL) {
  text <- text %||% document_text(state)
  mode <- mode %||% document_mode(state)
  chunks <- document_chunks(text, mode)
  if (nrow(chunks) == 0L) return(invisible(list()))
  ids <- chunks$id
  if (!is.null(up_to)) {
    index <- match(up_to, ids)
    if (!is.na(index)) ids <- ids[seq_len(index)]
  }
  results <- lapply(ids, function(id) report_run_cell(state, id, text, mode))
  names(results) <- ids
  invisible(results)
}

#' Status of the cells
#' @keywords internal
report_cell_status <- function(state, id) {
  state$cell_outputs[[id]] %||% NULL
}

# Contextual insertion -------------------------------------------------------

report_insert_block <- function(state, block) {
  block <- paste(block, collapse = "\n")
  text <- document_text(state)
  mode <- document_mode(state)
  if (identical(mode, "rnw") && grepl("\\\\end\\{document\\}", text)) {
    position <- regexpr("\\\\end\\{document\\}", text)
    before <- substr(text, 1L, position - 1L)
    after <- substr(text, position, nchar(text))
    separator <- if (!nzchar(before) || endsWith(before, "\n")) "" else "\n"
    text <- paste0(before, separator, block, "\n\n", after)
    document_set_text(state, text)
  } else {
    document_set_text(state, document_append_block(text, block))
  }
  invisible(TRUE)
}

#' Insert prose in the document
#' @keywords internal
report_insert_text <- function(state, text, level = NULL) {
  text <- paste(text, collapse = "\n")
  if (!is.null(level)) {
    text <- paste0(strrep("#", max(1L, min(6L, as.integer(level)))), " ",
                   text)
  }
  report_insert_block(state, text)
}

#' Insert an executable chunk
#' @keywords internal
report_insert_chunk <- function(state, code, label = NULL,
                                options = character()) {
  document_append_chunk(
    state, code, document_mode(state),
    label = label %||% "", options = options
  )
  invisible(TRUE)
}

#' Find a structured history entry
#' @keywords internal
report_history_entry <- function(state, id = NULL) {
  entries <- state$history %||% list()
  if (length(entries) == 0L) return(NULL)
  if (is.null(id) || !nzchar(id)) return(entries[[length(entries)]])
  ids <- vapply(entries, function(entry) entry$id %||% "", character(1))
  index <- match(id, ids)
  if (is.na(index)) NULL else entries[[index]]
}

#' Insert the output of a history step as a literal block
#' @keywords internal
report_insert_output <- function(state, history_id = NULL) {
  entry <- report_history_entry(state, history_id)
  if (is.null(entry)) stop("There is no command output to insert.", call. = FALSE)
  output <- entry$output %||% character()
  if (length(output) == 0L || !nzchar(trimws(paste(output, collapse = "\n")))) {
    stop("The selected step has no captured output.", call. = FALSE)
  }
  block <- c(
    sprintf("### Output: `%s`", entry$command %||% ""),
    "",
    "```",
    output,
    "```"
  )
  report_insert_block(state, block)
  invisible(TRUE)
}

report_plot_entry <- function(state, key = NULL) {
  plots <- state$plots %||% list()
  if (length(plots) == 0L) return(NULL)
  if (is.null(key) || (is.numeric(key) && length(key) == 1L && is.na(key))) {
    return(plots[[length(plots)]])
  }
  if (is.numeric(key)) {
    key <- as.integer(key)
    if (key < 1L || key > length(plots)) return(NULL)
    return(plots[[key]])
  }
  key <- as.character(key)
  ids <- vapply(plots, function(plot) plot$id %||% "", character(1))
  index <- match(key, ids)
  if (!is.na(index)) return(plots[[index]])
  # The selector stores the gallery index when the plot has no id.
  if (grepl("^[0-9]+$", key)) {
    index <- as.integer(key)
    if (index >= 1L && index <= length(plots)) return(plots[[index]])
  }
  NULL
}

#' Copy a session plot next to the report and insert it
#' @keywords internal
report_insert_plot <- function(state, key = NULL, caption = NULL,
                               width = "100%") {
  plot <- report_plot_entry(state, key)
  if (is.null(plot)) stop("There is no plot to insert.", call. = FALSE)
  file <- plot$file %||% ""
  if (!nzchar(file) || !file.exists(file)) {
    stop("The plot file is not available.", call. = FALSE)
  }
  directory <- state$report_dir
  if (is.null(directory) || !nzchar(directory)) {
    directory <- file.path(tempdir(), "rcmdrshiny-report")
  }
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  name <- paste0("plot-", format(Sys.time(), "%Y%m%d%H%M%S"), "-",
                 basename(file))
  target <- file.path(directory, name)
  file.copy(file, target, overwrite = TRUE)
  block <- c(
    if (!is.null(caption) && nzchar(caption)) c(sprintf("*%s*", caption), ""),
    "```{r echo=FALSE, out.width=\"100%\"}",
    sprintf("knitr::include_graphics(%s)", encodeString(target, quote = "\"")),
    "```"
  )
  report_insert_block(state, block)
  invisible(target)
}

#' Insert a table rendered at authoring time
#' @keywords internal
report_insert_table <- function(state, object = NULL, caption = NULL,
                                rows = 20L) {
  if (is.null(object)) object <- dataset(state)
  if (is.character(object) && length(object) == 1L &&
      exists(object, envir = state$env, inherits = FALSE)) {
    object <- get(object, envir = state$env, inherits = FALSE)
  }
  if (is.null(object)) stop("There is no table to insert.", call. = FALSE)
  if (is.data.frame(object)) object <- utils::head(object, as.integer(rows))
  text <- if (requireNamespace("knitr", quietly = TRUE)) {
    paste(utils::capture.output(knitr::kable(object)), collapse = "\n")
  } else {
    paste(utils::capture.output(print(object)), collapse = "\n")
  }
  block <- c(
    if (!is.null(caption) && nzchar(caption)) c(sprintf("*%s*", caption), ""),
    text
  )
  report_insert_block(state, block)
  invisible(TRUE)
}

#' Insert a data profile chunk
#' @keywords internal
report_insert_data_profile <- function(state, dataset_name = NULL) {
  name <- dataset_name %||% active_dataset(state)
  if (is.null(name)) stop("There is no active data set.", call. = FALSE)
  block <- c(
    "## Data profile", "",
    "```{r data-profile}",
    sprintf("dim(%s)", name),
    sprintf("str(%s)", name),
    sprintf("colSums(is.na(%s))", name),
    "```"
  )
  report_insert_block(state, block)
  invisible(TRUE)
}

#' Insert a model summary chunk
#' @keywords internal
report_insert_model_summary <- function(state, model = NULL) {
  name <- model %||% state$active_model
  if (is.null(name) || !exists(name, envir = state$env, inherits = FALSE)) {
    stop("There is no active model.", call. = FALSE)
  }
  block <- c(
    sprintf("## Model `%s`", name), "",
    "```{r model-summary}",
    sprintf("summary(%s)", name),
    "```"
  )
  report_insert_block(state, block)
  invisible(TRUE)
}

#' Insert a history step as a reproducible chunk
#' @keywords internal
report_insert_history_step <- function(state, history_id = NULL) {
  entry <- report_history_entry(state, history_id)
  if (is.null(entry)) stop("There is no history step to insert.", call. = FALSE)
  report_insert_chunk(state, entry$command %||% "", label = "history")
  invisible(TRUE)
}

# UI -------------------------------------------------------------------------

report_document_choices <- function(state) {
  table <- document_list(state)
  if (nrow(table) == 0L) return(character())
  labels <- sprintf(
    "%s%s", table$title,
    ifelse(table$dirty, " *", "")
  )
  stats::setNames(table$id, labels)
}

#' Report Studio toolbar
#' @keywords internal
report_studio_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "rcmdr-toolbar rcmdr-report-toolbar",
      htmltools::div(
        class = "d-flex gap-2 align-items-end flex-wrap",
        uiOutput("report_document_ui", inline = TRUE),
        actionButton("report_new", tr("New"), class = "btn-sm btn-outline-secondary"),
        actionButton("report_template", tr("Template"),
                     class = "btn-sm btn-outline-secondary"),
        actionButton("report_open", tr("Open"), class = "btn-sm btn-outline-secondary"),
        actionButton("report_save", tr("Save"), class = "btn-sm btn-outline-secondary"),
        actionButton("report_save_as", tr("Save as"),
                     class = "btn-sm btn-outline-secondary"),
        actionButton("report_yaml", tr("YAML..."),
                     class = "btn-sm btn-outline-secondary"),
        htmltools::div(
          class = "d-flex gap-1 align-items-end",
          selectInput(
            "report_knit_format", NULL,
            choices = c("HTML" = "html", "PDF" = "pdf", "Word" = "word"),
            width = "110px"
          ),
          actionButton("report_knit", tr("Knit"),
                       class = "btn-sm btn-primary")
        )
      ),
      uiOutput("report_status_ui")
    ),
    uiOutput("report_recovery_ui"),
    htmltools::div(
      class = "row g-2 rcmdr-report-workspace",
      htmltools::div(
        class = "col-xl-3",
        htmltools::div(
          class = "rcmdr-section-card",
          htmltools::tags$h6(tr("Outline")),
          uiOutput("report_outline")
        ),
        htmltools::div(
          class = "rcmdr-section-card",
          htmltools::tags$h6(tr("Chunks")),
          htmltools::div(
            class = "d-flex gap-1 flex-wrap mb-2",
            actionButton("report_run_all", tr("Run all"),
                         class = "btn-sm btn-outline-primary")
          ),
          uiOutput("report_chunks")
        ),
        htmltools::div(
          class = "rcmdr-section-card",
          htmltools::tags$h6(tr("Templates")),
          report_template_gallery_ui(compact = TRUE)
        )
      ),
      htmltools::div(
        class = "col-xl-5",
        htmltools::div(
          class = "rcmdr-section-card",
          htmltools::tags$h6(tr("Editor")),
          uiOutput("report_editor_ui"),
          htmltools::tags$details(
            class = "rcmdr-report-insert mt-2",
            htmltools::tags$summary(tr("Insert")),
            htmltools::div(
              class = "row g-2",
              htmltools::div(
                class = "col-sm-6",
                uiOutput("report_history_select_ui")
              ),
              htmltools::div(
                class = "col-sm-6",
                uiOutput("report_plot_select_ui")
              ),
              htmltools::div(
                class = "col-12 d-flex gap-1 flex-wrap",
                actionButton("report_insert_output", tr("Output"),
                             class = "btn-sm btn-outline-secondary"),
                actionButton("report_insert_plot", tr("Plot"),
                             class = "btn-sm btn-outline-secondary"),
                actionButton("report_insert_history", tr("History step"),
                             class = "btn-sm btn-outline-secondary"),
                actionButton("report_insert_table", tr("Table"),
                             class = "btn-sm btn-outline-secondary"),
                actionButton("report_insert_profile", tr("Data profile"),
                             class = "btn-sm btn-outline-secondary"),
                actionButton("report_insert_model", tr("Model summary"),
                             class = "btn-sm btn-outline-secondary"),
                actionButton("report_insert_section", tr("Section"),
                             class = "btn-sm btn-outline-secondary"),
                actionButton("report_insert_chunk", tr("Chunk"),
                             class = "btn-sm btn-outline-secondary")
              )
            )
          )
        )
      ),
      htmltools::div(
        class = "col-xl-4",
        htmltools::div(
          class = "rcmdr-section-card rcmdr-report-preview-card",
          htmltools::div(
            class = "d-flex justify-content-between align-items-center",
            htmltools::tags$h6(tr("Preview")),
            radioButtons(
              "report_preview_mode", NULL,
              choices = c("Markdown" = "markdown", "HTML" = "html",
                          "Source" = "source"),
              selected = "markdown", inline = TRUE
            )
          ),
          uiOutput("report_preview_message"),
          htmltools::div(class = "rcmdr-report-preview", uiOutput("report_preview"))
        ),
        htmltools::div(
          class = "rcmdr-section-card",
          htmltools::tags$h6(tr("Knit history")),
          uiOutput("report_knit_history")
        )
      )
    ),
    htmltools::div(
      class = "visually-hidden",
      downloadButton("report_download_knit", tr("Download report")),
      downloadButton("report_download_source", tr("Download source"))
    )
  )
}

report_cell_card <- function(chunk, output) {
  status <- output$status %||% "idle"
  badge <- switch(
    status,
    ok = htmltools::tags$span(class = "badge bg-success", tr("ok")),
    error = htmltools::tags$span(class = "badge bg-danger", tr("error")),
    empty = htmltools::tags$span(class = "badge bg-secondary", tr("empty")),
    missing = htmltools::tags$span(class = "badge bg-warning text-dark",
                                   tr("missing")),
    htmltools::tags$span(class = "badge bg-light text-dark", tr("not run"))
  )
  body <- NULL
  if (!is.null(output)) {
    lines <- c(output$output %||% character(), output$messages %||% character())
    body <- htmltools::tags$details(
      class = "rcmdr-cell-output",
      htmltools::tags$summary(tr("Output")),
      if (length(lines) > 0L) htmltools::tags$pre(paste(lines, collapse = "\n")),
      if (!is.null(output$plot_url) && nzchar(output$plot_url)) {
        htmltools::tags$img(src = output$plot_url, alt = tr("Cell plot"),
                            class = "rcmdr-cell-plot")
      },
      if (!is.null(output$error)) {
        htmltools::tags$p(class = "text-danger small mb-0", output$error)
      }
    )
  }
  htmltools::div(
    class = "rcmdr-cell-card",
    htmltools::div(
      class = "d-flex justify-content-between align-items-center gap-2",
      htmltools::tags$span(
        class = "small",
        if (nzchar(chunk$label %||% "")) chunk$label else chunk$id
      ),
      htmltools::div(
        class = "d-flex gap-1 align-items-center",
        badge,
        htmltools::tags$a(
          href = "#", class = "btn btn-sm btn-outline-primary",
          onclick = sprintf(
            "Shiny.setInputValue('report_chunk_action', {id: '%s', action: 'run'}, {priority: 'event'}); return false;",
            chunk$id
          ),
          tr("Run")
        ),
        htmltools::tags$a(
          href = "#", class = "btn btn-sm btn-outline-secondary",
          onclick = sprintf(
            "Shiny.setInputValue('report_chunk_action', {id: '%s', action: 'run_to'}, {priority: 'event'}); return false;",
            chunk$id
          ),
          tr("Run to here")
        )
      )
    ),
    body
  )
}

# Dialogs --------------------------------------------------------------------

report_yaml_dialog <- function() {
  id <- "reportYaml"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Document metadata"), help = "report-studio",
    preview = FALSE,
    ui = function(state, memory) {
      values <- document_front_matter_values(state)
      values <- utils::modifyList(values, memory %||% list())
      output <- values$output %||% "html_document"
      if (!is.character(output)) output <- "html_document"
      theme <- values$theme %||% "default"
      htmltools::tagList(
        entry_input(ns("title"), tr("Title:"),
                    values$title %||% document_title(state)),
        entry_input(ns("author"), tr("Author:"), values$author %||% ""),
        entry_input(ns("date"), tr("Date:"),
                    values$date %||% as.character(Sys.Date())),
        selectInput(
          ns("output"), tr("Output"),
          choices = c("HTML" = "html_document", "PDF" = "pdf_document",
                      "Word" = "word_document", "GitHub" = "github_document"),
          selected = output, width = "100%"
        ),
        checkbox_input(ns("toc"), tr("Table of contents"),
                       isTRUE(values$toc)),
        selectInput(
          ns("theme"), tr("Theme"),
          choices = c("Default" = "default", "Cosmo" = "cosmo",
                      "Flatly" = "flatly", "Journal" = "journal",
                      "Readable" = "readable", "Spacelab" = "spacelab",
                      "United" = "united", "Yeti" = "yeti"),
          selected = theme, width = "100%"
        ),
        entry_input(ns("bibliography"), tr("Bibliography file:"),
                    values$bibliography %||% "",
                    placeholder = "/path/to/references.bib"),
        checkbox_input(ns("link_citations"), tr("Link citations"),
                       isTRUE(values[["link-citations"]])),
        help_text(tr(
          "Fields that are not shown here are preserved. The YAML front matter is rewritten conservatively."
        ))
      )
    },
    on_ok = function(input, state) {
      title <- trim_blanks(input[[ns("title")]] %||% "")
      if (!nzchar(title)) return(list(error = tr("Enter a document title.")))
      bibliography <- trim_blanks(input[[ns("bibliography")]] %||% "")
      if (nzchar(bibliography) && !file.exists(bibliography)) {
        return(list(error = sprintf(tr("File not found: %s"), bibliography)))
      }
      theme <- input[[ns("theme")]] %||% "default"
      values <- list(
        title = title,
        author = trim_blanks(input[[ns("author")]] %||% ""),
        date = trim_blanks(input[[ns("date")]] %||% ""),
        output = input[[ns("output")]] %||% "html_document",
        toc = isTRUE(input[[ns("toc")]]),
        theme = if (identical(theme, "default")) NULL else theme,
        bibliography = if (nzchar(bibliography)) bibliography else NULL,
        `link-citations` = if (isTRUE(input[[ns("link_citations")]])) {
          TRUE
        } else {
          NULL
        }
      )
      document_set_front_matter(state, values)
      list(
        script = document_text(state),
        tab = tr("Report"),
        memory = list(title = title, author = values$author),
        message = tr("Document metadata updated.")
      )
    }
  )
}

report_template_dialog <- function() {
  id <- "reportTemplate"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("New report from template"), help = "report-studio",
    preview = FALSE,
    ui = function(state, memory) {
      registry <- dataset_registry(state)
      choices <- if (nrow(registry) == 0L) {
        stats::setNames("", tr("<none>"))
      } else {
        stats::setNames(registry$name, registry$name)
      }
      selected <- memory$dataset %||% active_dataset(state) %||%
        if (nrow(registry) > 0L) registry$name[[1L]] else ""
      htmltools::tagList(
        selectInput(
          ns("template"), tr("Template"),
          choices = report_template_choices(),
          selected = memory$template %||% "analysis", width = "100%"
        ),
        entry_input(ns("title"), tr("Document title:"),
                    memory$title %||% tr("Analysis report")),
        selectInput(ns("dataset"), tr("Data set"), choices = choices,
                    selected = selected, width = "100%"),
        help_text(tr(
          "The template only uses commands that the dialogs already generate."
        ))
      )
    },
    on_ok = function(input, state) {
      template_id <- input[[ns("template")]] %||% "analysis"
      title <- trim_blanks(input[[ns("title")]] %||% "")
      dataset <- input[[ns("dataset")]] %||% active_dataset(state)
      if (!nzchar(title)) return(list(error = tr("Enter a document title.")))
      result <- tryCatch(
        report_template_apply(state, template_id, dataset, title),
        error = function(e) e
      )
      if (inherits(result, "error")) {
        return(list(error = conditionMessage(result)))
      }
      list(
        script = document_text(state),
        tab = tr("Report"),
        memory = list(template = template_id, title = title,
                      dataset = dataset),
        message = tr("Report created from template.")
      )
    }
  )
}

#' Report Studio dialog catalogue
#' @keywords internal
report_studio_dialogs <- function() {
  list(
    reportYaml = report_yaml_dialog(),
    reportTemplate = report_template_dialog()
  )
}

# Server ---------------------------------------------------------------------

report_history_choices <- function(state, limit = 20L) {
  entries <- state$history %||% list()
  if (length(entries) == 0L) return(stats::setNames("", tr("<none>")))
  entries <- utils::tail(entries, limit)
  ids <- vapply(entries, function(entry) entry$id %||% "", character(1))
  labels <- vapply(entries, function(entry) {
    command <- entry$command %||% ""
    if (nchar(command) > 46L) command <- paste0(substr(command, 1L, 43L), "...")
    command
  }, character(1))
  stats::setNames(ids, labels)
}

report_plot_choices <- function(state, limit = 20L) {
  plots <- state$plots %||% list()
  if (length(plots) == 0L) return(stats::setNames("", tr("<none>")))
  indexes <- seq.int(max(1L, length(plots) - limit + 1L), length(plots))
  labels <- vapply(indexes, function(index) {
    plot <- plots[[index]]
    sprintf("%s (%s)", plot_title(plot), index)
  }, character(1))
  stats::setNames(as.character(indexes), labels)
}

#' Report Studio server
#' @keywords internal
report_studio_server <- function(input, output, session, state, refresh,
                                 tick = NULL) {
  report_revision <- reactiveVal(0L)
  tick_reactive <- if (is.function(tick)) tick else reactiveVal(0L)
  app_tick <- function() tick_reactive()

  bump <- function(global = FALSE) {
    report_revision(report_revision() + 1L)
    if (isTRUE(global)) refresh()
    invisible(NULL)
  }

  current_text <- function() {
    value <- isolate(input$report_editor)
    if (!is.null(value) && !identical(value, document_text(state))) {
      document_set_text(state, value)
    }
    document_text(state)
  }

  # -- editor --------------------------------------------------------------

  output$report_editor_ui <- renderUI({
    htmltools::div(
      id = "report_editor_ui",
      shinyAce::aceEditor(
        "report_editor",
        value = isolate(document_text(state)),
        mode = document_ace_mode(document_mode(state)),
        theme = "textmate", height = "520px", fontSize = 13,
        selectionId = "report_editor_selection", autoComplete = "enabled"
      )
    )
  })

  observeEvent(input$report_editor, {
    value <- input$report_editor %||% ""
    if (!identical(value, document_text(state))) {
      document_set_text(state, value)
      report_revision(report_revision() + 1L)
    }
  }, ignoreInit = TRUE)

  # Keep the two editors in sync without touching the document on every tick.
  sync_timer <- reactiveTimer(1500)
  observeEvent(list(sync_timer(), tick_reactive()), {
    value <- document_text(state)
    if (!identical(isolate(input$report_editor), value)) {
      shinyAce::updateAceEditor(
        session, "report_editor", value = value,
        mode = document_ace_mode(document_mode(state))
      )
    }
  }, ignoreInit = TRUE)

  text_debounced <- debounce(reactive({
    report_revision()
    tick_reactive()
    document_text(state)
  }), 400)

  # -- documents -----------------------------------------------------------

  output$report_document_ui <- renderUI({
    report_revision()
    app_tick()
    choices <- report_document_choices(state)
    if (length(choices) == 0L) return(NULL)
    htmltools::div(
      class = "d-flex gap-1 align-items-end",
      selectInput(
        "report_document", NULL, choices = choices,
        selected = state$active_document %||% "", width = "220px"
      ),
      actionButton("report_document_close", tr("Close"),
                   class = "btn-sm btn-outline-secondary")
    )
  })

  observeEvent(input$report_document, {
    id <- input$report_document %||% ""
    if (nzchar(id) && !identical(id, state$active_document)) {
      document_activate(state, id)
      report_preview_clear()
      refresh()
      bump()
    }
  }, ignoreInit = TRUE)

  observeEvent(input$report_document_close, {
    if (!is.null(state$active_document)) {
      document_close(state, state$active_document)
      refresh()
      bump()
    }
  }, ignoreInit = TRUE)

  # -- outline and chunks --------------------------------------------------

  output$report_outline <- renderUI({
    text_debounced()
    outline <- document_outline(document_text(state), document_mode(state))
    if (nrow(outline) == 0L) {
      return(help_text(tr("No headings yet. Add a section to build the outline.")))
    }
    htmltools::div(
      class = "rcmdr-report-outline",
      lapply(seq_len(nrow(outline)), function(i) {
        row <- outline[i, , drop = FALSE]
        htmltools::tags$a(
          href = "#",
          class = sprintf("rcmdr-outline-level-%d", row$level),
          onclick = sprintf(
            "window.rcmdrReportGoto(%d); return false;", row$line - 1L
          ),
          row$title
        )
      })
    )
  })

  output$report_chunks <- renderUI({
    text_debounced()
    chunks <- document_chunks(document_text(state), document_mode(state))
    if (nrow(chunks) == 0L) {
      return(help_text(tr("No chunks yet.")))
    }
    htmltools::div(
      class = "rcmdr-cell-list",
      lapply(seq_len(nrow(chunks)), function(i) {
        chunk <- chunks[i, , drop = FALSE]
        report_cell_card(chunk, report_cell_status(state, chunk$id[[1L]]))
      })
    )
  })

  observeEvent(input$report_chunk_action, {
    action <- input$report_chunk_action$action %||% ""
    id <- input$report_chunk_action$id %||% ""
    if (!nzchar(id)) return()
    if (identical(action, "run")) {
      report_run_cell(state, id, current_text(), document_mode(state))
      report_revision(report_revision() + 1L)
      refresh()
    } else if (identical(action, "run_to")) {
      report_run_all_cells(state, current_text(), document_mode(state),
                           up_to = id)
      bump(global = TRUE)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$report_run_all, {
    report_run_all_cells(state, current_text(), document_mode(state))
    bump(global = TRUE)
  }, ignoreInit = TRUE)

  # -- preview -------------------------------------------------------------

  output$report_preview_message <- renderUI({
    mode <- input$report_preview_mode %||% "markdown"
    if (identical(mode, "markdown")) {
      return(help_text(tr(
        "Fast preview: code is not executed. Knit to run the chunks."
      )))
    }
    if (identical(mode, "html")) {
      return(help_text(tr(
        "HTML preview shows the last knit of this document."
      )))
    }
    help_text(tr("Source view of the current document."))
  })

  output$report_preview <- renderUI({
    report_revision()
    tick_reactive()
    mode <- input$report_preview_mode %||% "markdown"
    if (identical(mode, "html")) {
      result <- state$knit_result
      if (is.null(result) || is.null(result$url) || !nzchar(result$url)) {
        return(htmltools::tags$p(
          class = "text-muted",
          tr("No HTML preview yet. Use Knit to build the report.")
        ))
      }
      return(htmltools::tags$iframe(
        src = result$url,
        style = "width:100%;height:60vh;border:1px solid #dde2e8;"
      ))
    }
    if (identical(mode, "source")) {
      return(htmltools::tags$pre(
        class = "rcmdr-report-source", document_text(state)
      ))
    }
    preview <- report_preview(
      document_text(state), document_mode(state),
      limit = state$options$report_preview_cache %||% 8L
    )
    preview$html
  })

  # -- status --------------------------------------------------------------

  output$report_status_ui <- renderUI({
    report_revision()
    tick_reactive()
    htmltools::div(
      class = "rcmdr-report-status small text-muted mt-2",
      htmltools::tags$span(
        class = if (document_dirty(state)) "text-warning" else "text-success",
        if (document_dirty(state)) tr("Unsaved changes") else tr("Saved")
      ),
      htmltools::tags$span(" | "),
      htmltools::tags$span(document_title(state)),
      if (!is.null(state$autosave_time)) {
        htmltools::tagList(
          htmltools::tags$span(" | "),
          htmltools::tags$span(sprintf(
            tr("autosave %s"), format(state$autosave_time, "%H:%M:%S")
          ))
        )
      },
      if (!is.null(state$knit_result)) {
        htmltools::tagList(
          htmltools::tags$span(" | "),
          htmltools::tags$span(sprintf(
            tr("knit %s %s"),
            toupper(state$knit_result$format %||% ""),
            format(state$knit_result$time %||% Sys.time(), "%H:%M:%S")
          ))
        )
      }
    )
  })

  output$report_recovery_ui <- renderUI({
    recoveries <- state$recoveries %||% list()
    if (is.data.frame(recoveries)) {
      if (nrow(recoveries) == 0L) return(NULL)
      label <- recoveries$title[[1L]]
      path <- recoveries$path[[1L]]
      return(htmltools::div(
        class = "alert alert-warning d-flex justify-content-between align-items-center",
        htmltools::tags$span(sprintf(
          tr("Unsaved work found for %s."), label
        )),
        htmltools::tags$a(
          href = "#", class = "btn btn-sm btn-warning",
          onclick = sprintf(
            "Shiny.setInputValue('report_recover_action', %s, {priority: 'event'}); return false;",
            encodeString(path, quote = "\"")
          ),
          tr("Recover")
        )
      ))
    }
    recoveries
  })

  observeEvent(input$report_recover_action, {
    path <- input$report_recover_action
    if (is.null(path) || !nzchar(path)) return()
    tryCatch(document_recover(state, path), error = function(e) {
      showNotification(conditionMessage(e), type = "error", duration = 6)
    })
    report_preview_clear()
    bump(global = TRUE)
  }, ignoreInit = TRUE)

  # -- insert --------------------------------------------------------------

  output$report_history_select_ui <- renderUI({
    tick_reactive()
    selectInput("report_history_id", tr("History step"),
                choices = report_history_choices(state), width = "100%")
  })

  output$report_plot_select_ui <- renderUI({
    tick_reactive()
    selectInput("report_plot_id", tr("Plot"),
                choices = report_plot_choices(state), width = "100%")
  })

  insert_ok <- function(expr) {
    result <- tryCatch(expr, error = function(e) e)
    if (inherits(result, "error")) {
      showNotification(conditionMessage(result), type = "error", duration = 6)
      return(FALSE)
    }
    report_preview_clear()
    bump(global = TRUE)
    TRUE
  }

  observeEvent(input$report_insert_output, {
    insert_ok(report_insert_output(state, input$report_history_id))
  }, ignoreInit = TRUE)

  observeEvent(input$report_insert_plot, {
    insert_ok(report_insert_plot(state, input$report_plot_id))
  }, ignoreInit = TRUE)

  observeEvent(input$report_insert_history, {
    insert_ok(report_insert_history_step(state, input$report_history_id))
  }, ignoreInit = TRUE)

  observeEvent(input$report_insert_table, {
    insert_ok(report_insert_table(state))
  }, ignoreInit = TRUE)

  observeEvent(input$report_insert_profile, {
    insert_ok(report_insert_data_profile(state))
  }, ignoreInit = TRUE)

  observeEvent(input$report_insert_model, {
    insert_ok(report_insert_model_summary(state))
  }, ignoreInit = TRUE)

  observeEvent(input$report_insert_section, {
    state$open_dialog("insertSection")
  }, ignoreInit = TRUE)

  observeEvent(input$report_insert_chunk, {
    state$open_dialog("insertChunk")
  }, ignoreInit = TRUE)

  # -- documents and templates --------------------------------------------

  observeEvent(input$report_template_action, {
    id <- input$report_template_action %||% ""
    if (!nzchar(id)) return()
    result <- tryCatch(
      report_template_apply(state, id, active_dataset(state)),
      error = function(e) e
    )
    if (inherits(result, "error")) {
      showNotification(conditionMessage(result), type = "error", duration = 6)
      return()
    }
    report_preview_clear()
    bump(global = TRUE)
  }, ignoreInit = TRUE)

  observeEvent(input$report_new, {
    state$open_dialog("newRmd")
  }, ignoreInit = TRUE)

  observeEvent(input$report_template, {
    state$open_dialog("reportTemplate")
  }, ignoreInit = TRUE)

  observeEvent(input$report_open, {
    mode <- document_mode(state)
    state$open_dialog(if (identical(mode, "rnw")) "loadRnw" else "loadRmd")
  }, ignoreInit = TRUE)

  observeEvent(input$report_save, {
    current_text()
    mode <- document_mode(state)
    if (identical(mode, "r")) {
      showNotification(
        tr("Switch to an R Markdown or knitr document to save it."),
        type = "warning", duration = 5
      )
      return()
    }
    path <- document_path(state)
    if (is.null(path) || !nzchar(path)) {
      state$open_dialog(if (identical(mode, "rnw")) "saveRnwAs" else "saveRmdAs")
      return()
    }
    result <- tryCatch(document_save(state, path), error = function(e) e)
    if (inherits(result, "error")) {
      showNotification(conditionMessage(result), type = "error", duration = 6)
    } else {
      showNotification(sprintf(tr("Saved %s."), basename(path)),
                       type = "message", duration = 3)
      bump()
    }
  }, ignoreInit = TRUE)

  observeEvent(input$report_save_as, {
    current_text()
    mode <- document_mode(state)
    state$open_dialog(if (identical(mode, "rnw")) "saveRnwAs" else "saveRmdAs")
  }, ignoreInit = TRUE)

  observeEvent(input$report_yaml, {
    state$open_dialog("reportYaml")
  }, ignoreInit = TRUE)

  # -- knit ----------------------------------------------------------------

  observeEvent(input$report_knit, {
    current_text()
    format <- input$report_knit_format %||% "html"
    mode <- document_mode(state)
    if (identical(mode, "r")) {
      showNotification(
        tr("Switch to an R Markdown or knitr document first."),
        type = "warning", duration = 5
      )
      return()
    }
    if (!document_format_available(format, mode)) {
      showNotification(document_format_reason(format, mode),
                       type = "error", duration = 8)
      return()
    }
    showNotification(
      sprintf(tr("Knitting the document as %s..."), toupper(format)),
      type = "message", duration = 3
    )
    state$busy <- TRUE
    result <- tryCatch(document_knit(state, format), error = function(e) e)
    state$busy <- FALSE
    if (inherits(result, "error")) {
      showNotification(conditionMessage(result), type = "error", duration = 10)
    } else {
      showNotification(
        sprintf(tr("Document knitted: %s."), basename(result$file)),
        type = "message", duration = 5
      )
    }
    bump(global = TRUE)
  }, ignoreInit = TRUE)

  output$report_knit_history <- renderUI({
    tick_reactive()
    history <- state$knit_history %||% list()
    if (length(history) == 0L) {
      return(help_text(tr("No knit yet.")))
    }
    htmltools::div(
      class = "rcmdr-knit-history",
      lapply(utils::head(history, 8L), function(entry) {
        htmltools::div(
          class = "rcmdr-knit-entry small",
          htmltools::tags$span(
            class = if (identical(entry$status, "ok")) {
              "text-success"
            } else {
              "text-danger"
            },
            sprintf("%s %s", toupper(entry$format %||% ""),
                    if (identical(entry$status, "ok")) tr("ok") else tr("error"))
          ),
          htmltools::tags$span(" "),
          htmltools::tags$span(format(entry$time %||% Sys.time(), "%H:%M:%S")),
          if (!is.null(entry$duration_ms) && !is.na(entry$duration_ms)) {
            htmltools::tags$span(sprintf(" - %.1f s", entry$duration_ms / 1000))
          },
          if (identical(entry$status, "ok") && !is.null(entry$url) &&
              nzchar(entry$url)) {
            htmltools::tagList(
              htmltools::tags$span(" - "),
              htmltools::tags$a(href = entry$url, target = "_blank",
                                tr("Open"))
            )
          },
          if (!is.null(entry$error) && nzchar(entry$error)) {
            htmltools::tags$p(class = "text-danger mb-0", entry$error)
          }
        )
      })
    )
  })

  output$report_download_knit <- downloadHandler(
    filename = function() {
      basename(state$knit_result$file %||% "report.html")
    },
    content = function(file) {
      req(state$knit_result)
      file.copy(state$knit_result$file, file, overwrite = TRUE)
    }
  )

  output$report_download_source <- downloadHandler(
    filename = function() {
      mode <- document_mode(state)
      paste0("RcmdrShiny-report-", Sys.Date(), ".", document_extension(mode))
    },
    content = function(file) {
      writeLines(current_text(), file, useBytes = TRUE)
    }
  )

  # -- autosave and recovery ----------------------------------------------

  autosave_timer <- reactiveTimer(state$options$autosave_interval %||% 30000L)
  observeEvent(autosave_timer(), {
    if (document_dirty(state)) {
      document_autosave(state)
      report_revision(report_revision() + 1L)
    }
  }, ignoreInit = TRUE)

  state$recoveries <- tryCatch(
    document_recoveries(state),
    error = function(e) data.frame(path = character(), title = character(),
                                   time = character(), stringsAsFactors = FALSE)
  )

  invisible(NULL)
}
