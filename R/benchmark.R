# Benchmark helpers ----------------------------------------------------------
#
# The benchmark suite is intentionally small and dependency-free: it times the
# paths that the Studio UI exercises on every session, with a focus on the
# regressions that are easy to introduce (menu rebuild, help index, grid page,
# output caps).  It is not a micro-benchmark: one run is enough to compare
# against the documented budget.

#' Time one expression
#'
#' @param expr Expression to evaluate.
#' @return A list with `elapsed_ms` and `value`.
#' @keywords internal
benchmark_time <- function(expr) {
  started <- proc.time()[["elapsed"]]
  value <- force(expr)
  list(elapsed_ms = (proc.time()[["elapsed"]] - started) * 1000,
       value = value)
}

#' Benchmark the cold application shell
#' @keywords internal
benchmark_startup <- function() {
  time <- benchmark_time({
    ui <- app_ui()
    tree <- menu_tree()
    list(ui = ui, tree = tree)
  })
  data.frame(
    scenario = "startup shell", rows = NA_integer_,
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Benchmark CSV import at a given size
#' @keywords internal
benchmark_import <- function(rows = 10000L) {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  data <- data.frame(
    x = stats::rnorm(rows),
    y = stats::rnorm(rows),
    group = sample(letters[1:4], rows, replace = TRUE),
    stringsAsFactors = FALSE
  )
  utils::write.csv(data, path, row.names = FALSE)
  time <- benchmark_time(utils::read.csv(path, stringsAsFactors = TRUE))
  data.frame(
    scenario = sprintf("import CSV %d rows", rows), rows = as.integer(rows),
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Benchmark a grid page
#' @keywords internal
benchmark_grid <- function(rows = 10000L) {
  data <- data.frame(
    x = stats::rnorm(rows), y = stats::rnorm(rows),
    group = sample(letters[1:4], rows, replace = TRUE)
  )
  state <- AppState(new.env())
  state$env$bench <- data
  dataset_register(state, "bench")
  active_dataset(state, "bench")
  page <- utils::head(data, 25L)
  time <- benchmark_time({
    if (requireNamespace("DT", quietly = TRUE)) {
      DT::datatable(page, options = list(pageLength = 25L))
    } else {
      page
    }
  })
  data.frame(
    scenario = sprintf("grid page %d rows", rows), rows = as.integer(rows),
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' A synthetic data frame for the grid benchmarks
#'
#' Five columns: two numeric, one integer, one factor and one character.  That
#' is the shape the documented payload figures assume.
#' @keywords internal
benchmark_data_frame <- function(rows = 10000L) {
  rows <- as.integer(rows)
  data.frame(
    id = seq_len(rows),
    x = stats::rnorm(rows),
    y = stats::rnorm(rows),
    group = sample(letters[1:8], rows, replace = TRUE),
    label = sprintf("row-%06d", seq_len(rows)),
    stringsAsFactors = FALSE
  )
}

#' Widget payload in bytes
#'
#' Shiny serializes an htmlwidget to JSON before sending it.  For a data frame
#' the JSON size is what the browser has to download, so it is the honest
#' number behind the client/server decision.  `jsonlite` is an htmlwidgets
#' dependency; when it is missing the estimate falls back to the in-memory
#' size and says so.
#' @keywords internal
benchmark_payload_bytes <- function(data) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    return(as.numeric(object.size(jsonlite::toJSON(
      data, dataframe = "columns", null = "null", na = "null",
      auto_unbox = TRUE
    ))))
  }
  as.numeric(object.size(data))
}

#' Benchmark the Data Studio grid at a set of sizes
#'
#' Measures the first view (frame, DT widget and the payload Shiny would send),
#' a numeric filter over the frame and a one-page TSV copy.  The result is the
#' table behind `docs/upgrades/QA-DATA.md`.
#'
#' @param sizes Row counts to measure.
#' @return A data frame with one row per size.
#' @keywords internal
benchmark_data_scale <- function(sizes = c(10000L, 50000L, 100000L)) {
  rows <- lapply(as.integer(sizes), function(size) {
    df <- benchmark_data_frame(size)
    frame <- data_grid_frame(df)
    build <- benchmark_time(
      widget <- DT::datatable(
        frame, options = list(pageLength = 25L, scrollX = TRUE)
      )
    )
    client <- benchmark_time(benchmark_payload_bytes(widget$x$data))
    page <- utils::head(frame, 25L)
    server <- benchmark_time(benchmark_payload_bytes(page))
    filter <- benchmark_time({
      keep <- !is.na(frame$x) & frame$x > 0
      frame[keep, , drop = FALSE]
    })
    state <- AppState(new.env())
    state$env$bench <- df
    dataset_register(state, "bench")
    active_dataset(state, "bench")
    copy_frame <- utils::head(frame, 1000L)
    set_data_selection(state, rows = copy_frame$.row_id)
    copy <- benchmark_time(selection_tsv(state, copy_frame))
    data.frame(
      rows = size,
      cells = size * ncol(df),
      dataframe_mb = as.numeric(object.size(df)) / 1024^2,
      grid_mb = as.numeric(object.size(frame)) / 1024^2,
      build_ms = unname(build$elapsed_ms),
      client_kb = as.numeric(client$value) / 1024,
      client_json_ms = unname(client$elapsed_ms),
      server_kb = as.numeric(server$value) / 1024,
      filter_ms = unname(filter$elapsed_ms),
      copy_ms = unname(copy$elapsed_ms),
      first_view_ms = unname(build$elapsed_ms + client$elapsed_ms),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Benchmark the grid first view for the benchmark suite
#' @keywords internal
benchmark_data_grid <- function(rows = 10000L) {
  scale <- benchmark_data_scale(rows)
  data.frame(
    scenario = sprintf("data grid %d rows", as.integer(rows)),
    rows = as.integer(rows),
    elapsed_ms = scale$first_view_ms[[1L]],
    stringsAsFactors = FALSE
  )
}

#' Benchmark history growth and trimming
#' @keywords internal
benchmark_history <- function(commands = 100L) {
  state <- AppState(new.env())
  state$options$history_length <- 200L
  time <- benchmark_time({
    for (i in seq_len(commands)) {
      history_add(state, history_entry(
        NULL, Sys.time(), "benchmark", sprintf("summary(x%d)", i)
      ))
    }
    length(state$history)
  })
  data.frame(
    scenario = sprintf("%d history entries", commands),
    rows = as.integer(commands),
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Benchmark the plot gallery cap
#' @keywords internal
benchmark_plots <- function(plots = 50L) {
  state <- AppState(new.env())
  state$options$max_plots <- 10L
  time <- benchmark_time({
    for (i in seq_len(plots)) {
      plot_register(state, list(id = sprintf("plot-%04d", i), file = NULL,
                                title = NULL, spec = NULL, pinned = FALSE))
    }
    length(state$plots)
  })
  data.frame(
    scenario = sprintf("%d plot registrations", plots),
    rows = as.integer(plots),
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Benchmark the help index
#' @keywords internal
benchmark_help <- function() {
  time <- benchmark_time(help_index_cached(force = TRUE))
  data.frame(
    scenario = "help index rebuild", rows = NA_integer_,
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Benchmark loading one or more plugins
#' @keywords internal
benchmark_plugin_load <- function(packages, scenario = NULL) {
  installed <- intersect(packages, installed_plugin_packages())
  if (length(installed) == 0L) return(NULL)
  unload_plugins()
  menu_registry_reset()
  on.exit(unload_plugins(), add = TRUE)

  time <- benchmark_time({
    for (package in installed) {
      tryCatch(suppressWarnings(load_plugin_package(package)),
               error = function(e) NULL)
    }
    length(list_plugins())
  })
  data.frame(
    scenario = scenario %||% sprintf("load %d plugin(s)", length(installed)),
    rows = as.integer(length(installed)),
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Benchmark the first catalogue after deferred loading
#' @keywords internal
benchmark_plugin_deferred <- function(packages) {
  installed <- intersect(packages, installed_plugin_packages())
  if (length(installed) == 0L) return(NULL)
  old <- getOption("RcmdrShiny.lazy_plugins")
  options(RcmdrShiny.lazy_plugins = TRUE)
  on.exit({
    options(RcmdrShiny.lazy_plugins = old)
    unload_plugins()
  }, add = TRUE)
  unload_plugins()
  menu_registry_reset()
  load_plugins(as.list(installed), lazy = TRUE)

  time <- benchmark_time({
    tree <- menu_tree()
    length(tree)
  })
  data.frame(
    scenario = "first catalogue after deferred loading",
    rows = as.integer(length(installed)),
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Benchmark a warm menu tree with plugins loaded
#' @keywords internal
benchmark_plugin_tree <- function(packages, scenario = "menu tree warm") {
  installed <- intersect(packages, installed_plugin_packages())
  if (length(installed) == 0L) return(NULL)
  unload_plugins()
  menu_registry_reset()
  on.exit(unload_plugins(), add = TRUE)
  for (package in installed) {
    tryCatch(suppressWarnings(load_plugin_package(package)),
             error = function(e) NULL)
  }
  invisible(menu_tree())

  time <- benchmark_time(length(menu_tree()))
  data.frame(
    scenario = scenario, rows = as.integer(length(installed)),
    elapsed_ms = unname(time$elapsed_ms), stringsAsFactors = FALSE
  )
}

#' Run the benchmark suite
#'
#' @param quick When `TRUE`, use small sizes for a smoke run.
#' @return A data frame with `scenario`, `rows` and `elapsed_ms`.
#' @keywords internal
benchmark_suite <- function(quick = FALSE) {
  sizes <- if (isTRUE(quick)) c(1000L, 5000L) else c(10000L, 100000L)
  installed <- installed_plugin_packages()
  one <- if ("RcmdrShinyPlugin.Export" %in% installed) {
    "RcmdrShinyPlugin.Export"
  } else if (length(installed) > 0L) {
    installed[[1L]]
  } else {
    character()
  }
  plugin_rows <- Filter(Negate(is.null), list(
    if (length(one) > 0L) benchmark_plugin_load(one, "load 1 plugin"),
    if (length(one) > 0L) benchmark_plugin_tree(one, "menu tree warm")
  ))
  if (!isTRUE(quick) && length(installed) > 1L) {
    plugin_rows <- c(plugin_rows, Filter(Negate(is.null), list(
      benchmark_plugin_load(installed, "load all plugins"),
      benchmark_plugin_deferred(installed)
    )))
  }
  rows <- c(
    list(
      benchmark_startup(),
      benchmark_import(sizes[[1L]]),
      benchmark_import(sizes[[2L]]),
      benchmark_grid(sizes[[1L]]),
      benchmark_history(if (isTRUE(quick)) 50L else 100L),
      benchmark_plots(if (isTRUE(quick)) 25L else 50L),
      benchmark_help()
    ),
    plugin_rows
  )
  if (!isTRUE(quick)) {
    rows <- c(rows, list(
      benchmark_data_grid(10000L),
      benchmark_data_grid(50000L),
      benchmark_data_grid(100000L)
    ))
  }
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

#' Documented budgets in milliseconds
#' @keywords internal
benchmark_budgets <- function() {
  data.frame(
    scenario = c("startup shell", "import CSV 1000 rows",
                 "import CSV 5000 rows", "import CSV 10000 rows",
                 "import CSV 100000 rows", "grid page 1000 rows",
                 "grid page 10000 rows", "50 history entries",
                 "100 history entries", "25 plot registrations",
                 "50 plot registrations", "help index rebuild",
                 "load 1 plugin", "load all plugins",
                 "first catalogue after deferred loading",
                 "menu tree warm", "data grid 10000 rows",
                 "data grid 50000 rows", "data grid 100000 rows"),
    budget_ms = c(3000, 1500, 3000, 3000, 15000, 500, 500, 500, 500,
                  500, 500, 5000, 6000, 15000, 15000, 4000,
                  1000, 1500, 2500),
    stringsAsFactors = FALSE
  )
}
