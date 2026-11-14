#!/usr/bin/env Rscript
# P7.11 benchmark suite.
#
#   Rscript tests/benchmarks/benchmark.R            # full sizes
#   Rscript tests/benchmarks/benchmark.R --quick    # smoke sizes
#   Rscript tests/benchmarks/benchmark.R --csv out.csv
#
# The budgets live in R/benchmark.R (benchmark_budgets()).  Results above the
# budget are reported, not fatal: machine speed varies and the purpose is to
# catch regressions between releases.

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(file_arg) > 0L) {
  normalizePath(file.path(dirname(sub("^--file=", "", file_arg[[1L]])),
                          "..", ".."), mustWork = FALSE)
} else {
  getwd()
}
if (!dir.exists(file.path(root, "R"))) root <- getwd()
pkgload::load_all(root, quiet = TRUE)

quick <- "--quick" %in% args
csv_index <- match("--csv", args)
csv <- if (!is.na(csv_index) && length(args) >= csv_index + 1L) {
  args[[csv_index + 1L]]
} else {
  NULL
}

result <- benchmark_suite(quick = quick)
budgets <- benchmark_budgets()
result$budget_ms <- budgets$budget_ms[match(result$scenario, budgets$scenario)]
result$within_budget <- is.na(result$budget_ms) |
  result$elapsed_ms <= result$budget_ms

print(result, row.names = FALSE)
if (any(!result$within_budget)) {
  message("Some scenarios exceeded the documented budget.")
}
if (!is.null(csv)) {
  utils::write.csv(result, csv, row.names = FALSE)
  message("Wrote ", csv)
}
