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

#' Run the benchmark suite
#'
#' @param quick When `TRUE`, use small sizes for a smoke run.
#' @return A data frame with `scenario`, `rows` and `elapsed_ms`.
#' @keywords internal
benchmark_suite <- function(quick = FALSE) {
  sizes <- if (isTRUE(quick)) c(1000L, 5000L) else c(10000L, 100000L)
  rows <- list(
    benchmark_startup(),
    benchmark_import(sizes[[1L]]),
    benchmark_import(sizes[[2L]]),
    benchmark_grid(sizes[[1L]]),
    benchmark_history(if (isTRUE(quick)) 50L else 100L),
    benchmark_plots(if (isTRUE(quick)) 25L else 50L),
    benchmark_help()
  )
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
                 "50 plot registrations", "help index rebuild"),
    budget_ms = c(3000, 1500, 3000, 3000, 15000, 500, 500, 500, 500,
                  500, 500, 5000),
    stringsAsFactors = FALSE
  )
}
