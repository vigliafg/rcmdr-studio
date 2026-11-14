# Shared helpers for the Chart Studio tests --------------------------------

chart_test_state <- function() {
  env <- new.env(parent = globalenv())
  env$D <- data.frame(
    y = 1:6,
    x = c(2, 4, 6, 8, 10, 12),
    g = factor(rep(c("a", "b"), 3)),
    g2 = factor(rep(c("c", "d", "c"), 2)),
    s = letters[1:6],
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")
  state
}
