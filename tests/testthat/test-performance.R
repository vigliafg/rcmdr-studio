# P7.9 to P7.12: lazy plugins, caches, trimming and benchmarks.

test_that("plugins can be queued and loaded lazily", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  load_plugins(list(list(
    name = "lazy-test",
    commands = list(lazyCommand = function(state) NULL)
  )), lazy = TRUE)

  expect_false("lazy-test" %in% list_plugins())
  expect_equal(plugins_pending(), "<inline>")

  commands <- plugin_commands()
  expect_true("lazyCommand" %in% names(commands))
  expect_true("lazy-test" %in% list_plugins())
  expect_equal(plugins_pending(), character())
})

test_that("the plugin catalogue is cached until the registry changes", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  first <- plugin_menu_definitions()
  second <- plugin_menu_definitions()
  expect_identical(first, second)

  menus <- data.frame(
    type = c("menu", "item"), menu = c("cacheMenu", "cacheMenu"),
    kind = c("topMenu", "command"), label = c("", "Cache command"),
    command = c("cacheMenu", "cacheCommand"),
    activation = c("", ""), install = c("", ""),
    stringsAsFactors = FALSE
  )
  RcmdrShiny.plugin(name = "cache-test", menus = menus,
                    commands = list(cacheCommand = function(state) NULL))
  third <- plugin_menu_definitions()
  expect_false(identical(first, third))
})

test_that("the help index is reused until its registry changes", {
  first <- help_index_cached()
  second <- help_index_cached()
  expect_identical(first, second)
  expect_true(is.list(first))
})

test_that("cache stats describe every process-level cache", {
  menu_registry_cached(force = TRUE)
  help_index_cached()
  plugin_menu_definitions()
  stats <- cache_stats()
  expect_true(all(c("menu registry", "help index", "plugin catalog") %in%
                    stats$cache))
  expect_true(all(c("cache", "key", "entries", "ready") %in% names(stats)))
  expect_true(any(stats$ready))
  expect_match(paste(cache_summary(), collapse = " "), "menu registry")

  cache_clear()
  cleared <- cache_stats()
  expect_false(any(cleared$ready))
})

test_that("session_trim enforces every secondary cap", {
  state <- AppState(new.env())
  state$options$script_output_cells <- 3L
  state$options$knit_history_length <- 2L
  state$options$menu_recent_length <- 2L

  state$script_outputs <- stats::setNames(as.list(seq_len(8L)),
                                          paste0("cell-", seq_len(8L)))
  state$cell_outputs <- stats::setNames(as.list(seq_len(8L)),
                                        paste0("chunk-", seq_len(8L)))
  state$knit_history <- as.list(seq_len(5L))
  state$recent_commands <- paste0("command-", seq_len(10L))

  session_trim(state)
  expect_equal(length(state$script_outputs), 3L)
  expect_equal(names(state$script_outputs), paste0("cell-", 6:8))
  expect_equal(length(state$cell_outputs), 3L)
  expect_equal(length(state$knit_history), 2L)
  expect_equal(length(state$recent_commands), 6L)
})

test_that("trim_state caps output and messages", {
  state <- AppState(new.env())
  state$options$max_output_lines <- 4L
  state$output <- paste0("line-", seq_len(10L))
  state$messages <- paste0("message-", seq_len(10L))
  trim_state(state)
  expect_equal(state$output, paste0("line-", 7:10))
  expect_equal(state$messages, paste0("message-", 7:10))
})

test_that("the benchmark suite runs at smoke sizes", {
  skip_on_cran()
  result <- benchmark_suite(quick = TRUE)
  expect_s3_class(result, "data.frame")
  # The quick suite adds two plugin rows only when at least one plugin package
  # is installed, so the count depends on the machine, not on the package.
  expected_rows <- 7L + if (length(installed_plugin_packages()) > 0L) 2L else 0L
  expect_equal(nrow(result), expected_rows)
  expect_true(all(c("scenario", "rows", "elapsed_ms") %in% names(result)))
  expect_true(all(result$elapsed_ms >= 0))
  expect_true(all(c("startup shell", "help index rebuild") %in%
                    result$scenario))
  budgets <- benchmark_budgets()
  expect_true(all(result$scenario %in% budgets$scenario))
})

test_that("the large data benchmark reports the documented measures", {
  skip_on_cran()
  scale <- benchmark_data_scale(10000L)
  expect_s3_class(scale, "data.frame")
  expect_equal(scale$rows, 10000L)
  expect_equal(scale$cells, 50000)
  expect_true(all(c("dataframe_mb", "grid_mb", "build_ms", "client_kb",
                    "client_json_ms", "server_kb", "filter_ms", "copy_ms",
                    "first_view_ms") %in% names(scale)))
  # The whole point of the threshold: the client payload follows the rows,
  # the server page does not.
  expect_gt(scale$client_kb, 100)
  expect_lt(scale$server_kb, 10)
  expect_gt(scale$first_view_ms, 0)
  expect_gte(scale$grid_mb, scale$dataframe_mb)
})
