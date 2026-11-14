# Shared helpers for the Report Studio tests -------------------------------

report_test_state <- function() {
  env <- new.env(parent = globalenv())
  env$D <- data.frame(
    y = 1:6,
    x = c(2, 4, 6, 8, 10, 12),
    g = factor(rep(c("a", "b"), 3)),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")
  state$plot_dir <- tempfile("rcmdr-report-plots-")
  dir.create(state$plot_dir)
  state$plot_prefix <- "plots"
  state$knit_dir <- tempfile("rcmdr-report-knit-")
  dir.create(state$knit_dir)
  state$autosave_dir <- tempfile("rcmdr-report-autosave-")
  dir.create(state$autosave_dir)
  state$report_dir <- tempfile("rcmdr-report-files-")
  dir.create(state$report_dir)
  state
}

report_fake_plot <- function(state, title = "Plot") {
  file <- tempfile(fileext = ".png")
  grDevices::png(file, width = 300, height = 200)
  plot(1:3, 1:3, main = title)
  grDevices::dev.off()
  plot_register(state, list(
    file = file, url = "", code = "plot(1:3)", time = Sys.time()
  ))
  file
}

report_sample_document <- function(state, mode = "rmd") {
  document_create(
    state, mode = mode, title = "Test report",
    text = c(
      "---", 'title: "Test report"', "output: html_document", "---", "",
      "## Context", "",
      "Text before the chunk.", "",
      "```{r summary}", "summary(D)", "```", "",
      "## Results", "",
      "```{r second}", "mean(D$y)", "```", ""
    ),
    dirty = FALSE
  )
}
