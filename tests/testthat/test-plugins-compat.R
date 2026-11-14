# P7.16: first-party module contract, checked on all 15 plugins.
#
# These are not external compatibility tests.  The bundled plugins are
# maintained with the application; the tests make sure every module fragment
# stays inside the stable menu contract and keeps its commands reachable.

plugin_compat_root <- function() {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."),
                        mustWork = TRUE)
  if (!dir.exists(file.path(root, "plugins"))) {
    skip("The first-party plugin sources are not installed with the package.")
  }
  root
}

plugin_compat_dirs <- function() {
  root <- plugin_compat_root()
  directories <- list.dirs(file.path(root, "plugins"), recursive = FALSE,
                           full.names = TRUE)
  directories[file.exists(file.path(directories, "DESCRIPTION"))]
}

test_that("the repository ships exactly the 15 first-party modules", {
  directories <- plugin_compat_dirs()
  expect_length(directories, 15L)
  packages <- basename(directories)
  expect_true(all(startsWith(packages, "RcmdrShinyPlugin.")))
  expect_equal(anyDuplicated(packages), 0L)
})

test_that("every module has a package, a registration hook and a fragment", {
  for (directory in plugin_compat_dirs()) {
    package <- basename(directory)
    description <- read.dcf(file.path(directory, "DESCRIPTION"))
    expect_equal(unname(description[1L, "Package"]), package)
    expect_match(description[1L, "Imports"], "RcmdrShiny")
    expect_true(file.exists(file.path(directory, "inst", "menus",
                                      "module.yml")))

    plugin_sources <- list.files(file.path(directory, "R"), pattern = "\\.R$",
                                 full.names = TRUE)
    text <- paste(unlist(lapply(plugin_sources, readLines, warn = FALSE)),
                  collapse = "\n")
    expect_match(text, "rcmdrshiny_plugin", fixed = TRUE)
  }
})

test_that("every module fragment validates against the core registry", {
  root <- plugin_compat_root()
  core <- menu_registry_load(file.path(root, "inst", "menus", "core.yml"),
                             module = "core")
  core_groups <- names(core$groups)

  legacy_files <- c(
    file.path(root, "inst", "etc", "Rcmdr-menus.txt"),
    list.files(file.path(root, "plugins"), pattern = "rcmdrshiny-menus\\.txt$",
               recursive = TRUE, full.names = TRUE)
  )
  legacy <- lapply(legacy_files, read_rcmdr_menus)
  allowed <- unique(unlist(lapply(legacy, function(definitions) {
    definitions$command[definitions$type == "item" &
                          definitions$kind == "command"]
  }), use.names = FALSE))
  allowed <- allowed[nzchar(allowed)]

  for (directory in plugin_compat_dirs()) {
    package <- basename(directory)
    module <- plugin_module_id(package)
    fragment <- menu_registry_parse(
      file.path(directory, "inst", "menus", "module.yml"), module = module
    )
    validation <- menu_registry_validate(
      fragment, commands = allowed, known_groups = core_groups
    )
    expect_true(
      validation$ok,
      info = paste(package, paste(validation$problems, collapse = "; "))
    )

    # A module never removes a whole core menu.
    for (entry in fragment$removes) {
      expect_false(entry$kind %in% c("menu", "module_items"))
      expect_false(entry$target %in% core_groups)
    }

    # New groups belong to the module namespace or extend a core group.
    for (entry in fragment$groups) {
      parent <- entry$parent %||% ""
      if (nzchar(parent)) expect_true(parent %in% core_groups ||
                                        startsWith(parent, "menu."))
    }
  }
})

test_that("installed modules load without duplicate DOM keys", {
  installed <- Filter(function(package) {
    requireNamespace(package, quietly = TRUE)
  }, basename(plugin_compat_dirs()))
  if (length(installed) == 0L) {
    skip("No first-party plugin package is installed.")
  }

  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  for (package in installed) {
    expect_no_error(suppressWarnings(load_plugin_package(package)))
  }
  leaves <- menu_leaves(menu_tree())
  expect_equal(anyDuplicated(leaves$key), 0L)
  expect_true(all(nzchar(leaves$item_id)))
  expect_equal(anyDuplicated(leaves$item_id), 0L)
})
