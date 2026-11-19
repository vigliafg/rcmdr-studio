#!/usr/bin/env Rscript
# Generate the local thumbnails of the Chart Studio example gallery.
#
# The images are built from the bundled sample data with the same renderer the
# preview uses.  No network, no third-party image: the gallery is offline and
# the examples stay reproducible.
#
# Usage:
#   Rscript tools/build_chart_examples.R
#   Rscript tools/build_chart_examples.R --check

args <- commandArgs(trailingOnly = TRUE)
check <- "--check" %in% args

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required to build the example thumbnails.", call. = FALSE)
}
pkgload::load_all(".", quiet = TRUE)

output_dir <- file.path("inst", "www", "chart-examples")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

manifest_file <- file.path(output_dir, "manifest.tsv")
entries <- list()

for (example in chart_examples()) {
  if (!chart_example_available(example)) next

  state <- AppState(new.env(parent = globalenv()))
  data <- chart_example_data(example)
  if (is.null(data)) {
    stop(sprintf("Example %s has no data.", example$id), call. = FALSE)
  }
  assign(example$data_name, data, envir = state$env)
  active_dataset(state, example$data_name)

  spec <- chart_example_spec(example)
  problems <- chart_spec_validate(spec, state)
  if (length(problems) > 0L) {
    stop(sprintf("Example %s is invalid: %s", example$id,
                 paste(problems, collapse = " ")), call. = FALSE)
  }

  result <- preview_plot(state, chart_spec_command(spec),
                         width = 640, height = 400)
  if (!is.null(result$error) || is.null(result$file) ||
      !file.exists(result$file)) {
    stop(sprintf("Example %s could not be rendered: %s", example$id,
                 result$error %||% "no file"), call. = FALSE)
  }

  target <- file.path(output_dir, paste0(example$id, ".png"))
  if (!file.copy(result$file, target, overwrite = TRUE)) {
    stop(sprintf("Could not write %s.", target), call. = FALSE)
  }
  entries[[length(entries) + 1L]] <- data.frame(
    id = example$id,
    file = paste0(example$id, ".png"),
    bytes = file.info(target)$size,
    md5 = unname(tools::md5sum(target)),
    stringsAsFactors = FALSE
  )
  cat(sprintf("built %-22s %6d bytes\n", example$id,
              file.info(target)$size))
}

manifest <- do.call(rbind, entries)
manifest <- manifest[order(manifest$id), , drop = FALSE]
rownames(manifest) <- NULL

if (check) {
  if (!file.exists(manifest_file)) {
    stop("The manifest is missing. Run without --check first.", call. = FALSE)
  }
  current <- utils::read.delim(manifest_file, stringsAsFactors = FALSE)
  if (!setequal(current$id, manifest$id)) {
    stop("The example manifest does not match the registry. Rebuild it.",
         call. = FALSE)
  }
  missing <- manifest$file[!file.exists(file.path(output_dir, manifest$file))]
  if (length(missing) > 0L) {
    stop(sprintf("Missing example thumbnails: %s",
                 paste(missing, collapse = ", ")), call. = FALSE)
  }
  cat("example thumbnails are up to date\n")
} else {
  utils::write.table(manifest, manifest_file, sep = "\t", quote = FALSE,
                     row.names = FALSE)
  cat(sprintf("wrote %s with %d examples\n", manifest_file, nrow(manifest)))
}
