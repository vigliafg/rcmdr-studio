# Shared helpers for the Workbench tests --------------------------------

workbench_test_state <- function() {
  env <- new.env(parent = globalenv())
  env$D <- data.frame(
    y = c(2, 1, 4, 3, 7, 6, 9, 8),
    x = c(2, 4, 6, 8, 10, 12, 14, 16),
    g = factor(rep(c("a", "b"), 4)),
    stringsAsFactors = FALSE
  )
  env$fit <- stats::lm(y ~ x, data = env$D)
  env$gfit <- stats::glm(g ~ x, data = env$D, family = stats::binomial())
  state <- AppState(env = env)
  active_dataset(state, "D")
  state
}

workbench_sample_script <- function() {
  paste(
    "# Data preparation",
    "D$z <- D$x * 2",
    "",
    "# Model",
    "fit2 <- lm(y ~ x, data = D)",
    "",
    "summary(fit2)",
    sep = "\n"
  )
}
