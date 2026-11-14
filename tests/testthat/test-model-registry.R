# Model registry ------------------------------------------------------------

test_that("model classes are recognised without copying the objects", {
  expect_true(model_is_object(stats::lm(y ~ x, data = data.frame(y = 1:4, x = 1:4))))
  expect_true(model_is_object(stats::glm(c(0, 1, 0, 1) ~ 1,
                                         family = stats::binomial())))
  expect_false(model_is_object(data.frame(x = 1)))
  expect_false(model_is_object(NULL))
})

test_that("the registry reports formula, family, data, n and fit statistics", {
  state <- workbench_test_state()
  table <- model_registry(state)
  expect_true(all(c("fit", "gfit") %in% table$name))
  expect_true(all(c("name", "class", "formula", "family", "data", "n",
                    "aic", "bic", "r2", "active") %in% names(table)))

  fit <- table[table$name == "fit", , drop = FALSE]
  expect_match(fit$class[[1L]], "lm")
  expect_match(fit$formula[[1L]], "y ~ x")
  expect_equal(fit$n[[1L]], 8L)
  expect_true(is.finite(fit$aic[[1L]]))
  expect_true(fit$r2[[1L]] > 0.8)

  gfit <- table[table$name == "gfit", , drop = FALSE]
  expect_equal(gfit$family[[1L]], "binomial")
  expect_true(is.na(gfit$r2[[1L]]))
})

test_that("the registry is sorted by AIC and marks the active model", {
  state <- workbench_test_state()
  active_model(state, "fit")
  table <- model_registry(state)
  expect_true(table$active[table$name == "fit"])
  aic <- table$aic[!is.na(table$aic)]
  expect_equal(aic, sort(aic))
})

test_that("models can be looked up by name", {
  state <- workbench_test_state()
  row <- model_find(state, "gfit")
  expect_equal(row$name[[1L]], "gfit")
  expect_null(model_find(state, "missing"))
})

test_that("an empty session has an empty registry", {
  state <- AppState(env = new.env())
  expect_equal(nrow(model_registry(state)), 0L)
})

test_that("the default dialog follows the model class", {
  expect_equal(model_default_dialog(stats::lm(y ~ x, data = data.frame(y = 1:4, x = 1:4))),
               "linearModel")
  expect_equal(model_default_dialog(stats::glm(c(0, 1, 0, 1) ~ 1,
                                               family = stats::binomial())),
               "generalizedLinearModel")
  expect_null(model_default_dialog(data.frame(x = 1)))
})

test_that("the history entry that fitted a model can be found", {
  state <- workbench_test_state()
  set_dialog_memory(state, "linearModel", list(model_name = "fit"))
  run_command(state, "fit <- lm(y ~ x, data = D)", source = "dialog",
              dialog_id = "linearModel",
              dialog_memory = list(model_name = "fit"))
  entry <- model_history_entry(state, "fit")
  expect_false(is.null(entry))
  expect_equal(entry$dialog_id, "linearModel")

  fresh <- workbench_test_state()
  expect_null(model_history_entry(fresh, "fit"))
})
