# Plugin API ----------------------------------------------------------------
#
# A plugin is a named collection of menu definitions, direct commands and
# Shiny dialog specifications.  Legacy Tk dialogs are deliberately not
# executed: plugins that depend on them are registered with a warning and
# their menu entries remain disabled.
#
# Two plugin shapes are supported:
#
#   * a script that calls RcmdrShiny.plugin();
#   * an installed package that exports rcmdrshiny_plugin().  Packages named
#     RcmdrShinyPlugin.* use this protocol; legacy RcmdrPlugin.* packages fall
#     back to the menus-only compatibility loader.

.plugin_registry <- new.env(parent = emptyenv())
.plugin_registry$plugins <- list()
.plugin_registry$version <- 0L

# Lazy loading and catalogue caches.  The registry version is the cache key:
# registering or unloading a plugin invalidates every derived catalogue with a
# single integer comparison.
.plugin_registry$pending <- list()
.plugin_registry$failures <- list()
.plugin_registry$conflicts <- list()
.plugin_registry$last_materialize_ms <- 0
.plugin_catalog_cache <- new.env(parent = emptyenv())
.plugin_catalog_cache$version <- NULL
.plugin_catalog_cache$value <- list()

plugin_catalog_reset <- function() {
  .plugin_catalog_cache$version <- NULL
  .plugin_catalog_cache$value <- list()
  invisible(NULL)
}

# Failures are recorded instead of aborting the whole load: one broken plugin
# must not prevent the application from starting.
plugin_record_failure <- function(name, stage, message) {
  .plugin_registry$failures[[length(.plugin_registry$failures) + 1L]] <- list(
    name = as.character(name %||% "<inline>")[[1L]],
    stage = as.character(stage %||% "load")[[1L]],
    message = as.character(message %||% "")[[1L]],
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
  invisible(NULL)
}

#' Plugin loading failures
#'
#' @return A data frame with `name`, `stage`, `message` and `time`.
#' @keywords internal
plugin_failures <- function() {
  failures <- .plugin_registry$failures
  if (length(failures) == 0L) {
    return(data.frame(
      name = character(), stage = character(), message = character(),
      time = character(), stringsAsFactors = FALSE
    ))
  }
  data.frame(
    name = vapply(failures, function(failure) failure$name, character(1)),
    stage = vapply(failures, function(failure) failure$stage, character(1)),
    message = vapply(failures, function(failure) failure$message, character(1)),
    time = vapply(failures, function(failure) failure$time, character(1)),
    stringsAsFactors = FALSE
  )
}

plugin_clear_failures <- function() {
  .plugin_registry$failures <- list()
  invisible(NULL)
}

plugin_record_conflict <- function(plugin, kind, entries, source = "plugin") {
  entries <- as.character(entries)
  entries <- entries[nzchar(entries)]
  if (length(entries) == 0L) return(invisible(NULL))
  .plugin_registry$conflicts[[length(.plugin_registry$conflicts) + 1L]] <- list(
    plugin = as.character(plugin)[[1L]],
    kind = as.character(kind)[[1L]],
    entries = entries,
    source = as.character(source)[[1L]],
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
  invisible(NULL)
}

#' Plugin registration conflicts
#'
#' @return A data frame with `plugin`, `kind`, `entries`, `source` and `time`.
#' @keywords internal
plugin_conflicts <- function() {
  conflicts <- .plugin_registry$conflicts
  if (length(conflicts) == 0L) {
    return(data.frame(
      plugin = character(), kind = character(), entries = character(),
      source = character(), time = character(), stringsAsFactors = FALSE
    ))
  }
  data.frame(
    plugin = vapply(conflicts, function(item) item$plugin, character(1)),
    kind = vapply(conflicts, function(item) item$kind, character(1)),
    entries = vapply(conflicts, function(item) {
      paste(item$entries, collapse = ", ")
    }, character(1)),
    source = vapply(conflicts, function(item) item$source, character(1)),
    time = vapply(conflicts, function(item) item$time, character(1)),
    stringsAsFactors = FALSE
  )
}

plugin_clear_conflicts <- function() {
  .plugin_registry$conflicts <- list()
  invisible(NULL)
}

#' Installed RcmdrShiny plugin packages
#'
#' @param lib.loc Optional library location.
#' @return A character vector of package names.
#' @keywords internal
installed_plugin_packages <- function(lib.loc = NULL) {
  installed <- tryCatch(
    rownames(utils::installed.packages(lib.loc = lib.loc)),
    error = function(e) character()
  )
  sort(installed[grepl("^RcmdrShinyPlugin\\.", installed)])
}

#' Plugins saved in the preferences
#'
#' @param path Optional preferences file.
#' @return A character vector of package names or script paths.
#' @keywords internal
saved_plugin_selection <- function(path = preferences_default_file()) {
  value <- tryCatch(preferences_peek(path)$plugins,
                    error = function(e) NULL)
  if (!is.character(value)) return(character())
  unique(value[nzchar(value)])
}

#' Resolve the plugins to load at startup
#'
#' `NULL` means "use the saved selection", `character()` means "none", and a
#' vector means "only these".
#' @keywords internal
resolve_startup_plugins <- function(plugins, saved = character()) {
  if (is.null(plugins)) return(as.character(saved))
  as.character(plugins)
}

plugin_label <- function(plugin) {
  if (is.character(plugin) && length(plugin) == 1L) return(plugin)
  if (is.list(plugin) && !is.null(plugin$name)) {
    return(as.character(plugin$name)[[1L]])
  }
  "<inline>"
}

plugin_catalog_cached <- function(name, build) {
  version <- .plugin_registry$version
  if (!identical(.plugin_catalog_cache$version, version)) {
    .plugin_catalog_cache$version <- version
    .plugin_catalog_cache$value <- list()
  }
  if (!is.null(.plugin_catalog_cache$value[[name]])) {
    return(.plugin_catalog_cache$value[[name]])
  }
  value <- build()
  .plugin_catalog_cache$value[[name]] <- value
  value
}

# Predicates provided by the core activation environment.  Plugin predicates
# may not shadow these unless the plugin is registered with `replace = TRUE`.
.base_predicate_names <- c(
  "activeDataSetP", "activeModelP", "dataSetsP", "numericP",
  "numericPositiveP", "factorsP", "characterP", "twoLevelFactorsP",
  "discreteNumericP", "modelsP", "glmP", "lmP", "aovModelsP", "AOVModelsP",
  "coxphP", "survregP", "highOrderTermsP", "nonFactorsP",
  "twoOrMoreLevelFactorsP", "AbscontDistrsP", "DiscreteDistrsP",
  "hclustSolutionsP", "modelCapability",
  "CoefficientsP", "PredictorsP", "packageAvailable", "getRcmdr",
  "listPlugins", "rglLoaded", "rgl.cur", "dev.cur", "MarkdownP", "knitrP",
  "manualTranslationP"
)


#' Create a plugin dialog specification
#'
#' Wraps the internal dialog specification so that plugin authors do not need
#' to use unexported functions.
#'
#' @param id Command name used in the plugin menu file.
#' @param title Dialog title.
#' @param ui Function `function(state, memory)` returning the dialog UI.
#' @param on_ok Function `function(input, state)` returning a list with
#'   `commands`, `error`, `memory`, `activate_dataset` or `activate_model`.
#' @param on_open Optional function called before the dialog opens.
#' @param observers Optional function registering Shiny observers.
#' @param size Modal size (`"s"`, `"m"` or `"l"`).
#' @param help Optional R help topic.
#' @param help_package Optional package for the help topic.
#' @return A dialog specification accepted by [RcmdrShiny.plugin()].
#' @export
plugin_dialog <- function(id, title, ui, on_ok, on_open = NULL,
                          observers = NULL, size = "l",
                          help = NULL, help_package = NULL,
                          help_topic = NULL) {
  dialog_spec(id, title, ui, on_ok, on_open, observers, size,
              help, help_package, help_topic)
}

#' Register an RcmdrShiny plugin
#'
#' @param name Unique plugin name.
#' @param menus Either a path to an Rcmdr-style `menus.txt` file or a data
#'   frame returned by [read_rcmdr_menus()].
#' @param dialogs Named list of [plugin_dialog()] specifications.
#' @param commands Named list of direct command functions.  Each function is
#'   called with the application state.
#' @param description Optional description.
#' @param version Optional version string.
#' @param predicates Named list of activation predicates.  Each predicate is a
#'   function of zero arguments, or of the application state, that returns a
#'   logical value and can be used in the `activation` column of plugin menu
#'   entries.
#' @param replace Replace an existing plugin with the same name and allow
#'   command, dialog or predicate names to override earlier definitions.
#' @param help Path to a directory containing `index.yml` and Markdown topics.
#' @param aliases Named character vector mapping a plugin command id to a core
#'   command id.  The plugin menu entry keeps its label but opens the core
#'   dialog or runs the core direct command.
#' @return The registered plugin, invisibly.
#' @export
RcmdrShiny.plugin <- function(name, menus = NULL, dialogs = list(),
                              commands = list(), description = NULL,
                              version = NULL, tcltk = FALSE,
                              predicates = list(), replace = FALSE,
                              help = NULL, aliases = NULL,
                              api_version = NULL) {
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("Plugin `name` must be a single non-empty string.", call. = FALSE)
  }
  api_version <- as.integer(api_version %||% plugin_api_version())
  if (is.na(api_version) || api_version < 1L ||
      api_version > plugin_api_version()) {
    stop(sprintf("Unsupported plugin API version: %s", api_version),
         call. = FALSE)
  }

  if (is.character(menus) && length(menus) == 1L) {
    if (!file.exists(menus)) {
      stop(sprintf("Plugin menu file not found: %s", menus), call. = FALSE)
    }
    menus <- read_rcmdr_menus(menus)
  }
  if (!is.null(menus) && !is.data.frame(menus)) {
    stop("Plugin `menus` must be a path or a menu data frame.", call. = FALSE)
  }

  if (!is.list(dialogs)) stop("Plugin `dialogs` must be a list.", call. = FALSE)
  dialog_names <- names(dialogs)
  if (length(dialogs) == 0L) {
    dialog_names <- character()
  } else if (is.null(dialog_names) || any(!nzchar(dialog_names))) {
    dialog_names <- paste0("dialog", seq_along(dialogs))
  }
  dialogs <- lapply(seq_along(dialogs), function(i) {
    dialog <- dialogs[[i]]
    if (is.function(dialog)) {
      stop("Plugin dialogs must be created with plugin_dialog().",
           call. = FALSE)
    }
    if (!is.list(dialog) || is.null(dialog$ui) || is.null(dialog$on_ok)) {
      stop(sprintf("Invalid plugin dialog '%s'.", dialog_names[[i]]),
           call. = FALSE)
    }
    dialog$id <- dialog$id %||% dialog_names[[i]]
    dialog
  })
  names(dialogs) <- dialog_names

  if (!is.list(commands)) stop("Plugin `commands` must be a list.", call. = FALSE)
  bad <- !vapply(commands, is.function, logical(1))
  if (any(bad)) {
    stop(sprintf("Plugin commands must be functions: %s",
                 paste(names(commands)[bad], collapse = ", ")), call. = FALSE)
  }

  if (!is.list(predicates)) {
    stop("Plugin `predicates` must be a named list.", call. = FALSE)
  }
  if (length(predicates) > 0L &&
      (is.null(names(predicates)) || any(!nzchar(names(predicates))))) {
    stop("Plugin predicates must be named.", call. = FALSE)
  }
  bad <- !vapply(predicates, is.function, logical(1))
  if (any(bad)) {
    stop(sprintf("Plugin predicates must be functions: %s",
                 paste(names(predicates)[bad], collapse = ", ")), call. = FALSE)
  }

  if (!is.null(aliases)) {
    if (!is.character(aliases) || is.null(names(aliases)) ||
        any(!nzchar(names(aliases))) || any(!nzchar(aliases))) {
      stop("Plugin `aliases` must be a named character vector.", call. = FALSE)
    }
    aliases <- stats::setNames(unname(aliases), names(aliases))
  }

  check_conflicts <- function(names, kind, base_names) {
    if (length(names) == 0L) return(invisible(NULL))
    others <- unlist(lapply(.plugin_registry$plugins, function(plugin) {
      if (identical(plugin$name, name)) character() else names(plugin[[kind]])
    }), use.names = FALSE)
    base_clashes <- intersect(names, base_names)
    plugin_clashes <- intersect(names, others)
    if (length(base_clashes) > 0L && !isTRUE(replace)) {
      stop(sprintf(
        "Plugin '%s' %s already defined by the core: %s. Use replace = TRUE to override.",
        name, kind, paste(base_clashes, collapse = ", ")
      ), call. = FALSE)
    }
    if (length(base_clashes) > 0L) {
      plugin_record_conflict(name, kind, base_clashes, source = "core")
    }
    if (length(plugin_clashes) > 0L) {
      plugin_record_conflict(name, kind, plugin_clashes, source = "plugin")
      if (!isTRUE(replace)) {
        warning(sprintf(
          "Plugin '%s' overrides %s from an earlier plugin: %s.",
          name, kind, paste(plugin_clashes, collapse = ", ")
        ), call. = FALSE)
      }
    }
    invisible(NULL)
  }

  check_conflicts(names(commands), "commands", names(base_direct_commands()))
  check_conflicts(names(dialogs), "dialogs", names(base_dialog_catalog()))
  check_conflicts(
    names(predicates), "predicates",
    c(.base_predicate_names,
      unlist(lapply(.plugin_registry$plugins, function(plugin) {
        if (identical(plugin$name, name)) character() else names(plugin$predicates)
      }), use.names = FALSE))
  )

  plugin <- list(
    name = name,
    menus = menus,
    dialogs = dialogs,
    commands = commands,
    description = description,
    version = version,
    tcltk = isTRUE(tcltk),
    predicates = predicates,
    help = help,
    aliases = aliases,
    api_version = api_version,
    module_id = plugin_module_id(name)
  )
  if (isTRUE(tcltk)) {
    warning(
      sprintf("Plugin '%s' uses legacy Tk dialogs; only its direct commands are supported.",
              name),
      call. = FALSE
    )
  }

  .plugin_registry$plugins[[name]] <- plugin
  .plugin_registry$version <- .plugin_registry$version + 1L
  plugin_catalog_reset()
  .implemented_commands_cache$names <- NULL
  .implemented_commands_cache$dialog_ids <- NULL
  .implemented_commands_cache$dialog_revision <- NULL
  .model_capabilities_cache$table <- NULL

  if (!is.null(help)) {
    if (is.character(help) && length(help) == 1L && dir.exists(help)) {
      help_load_directory(help, package = name)
    } else if (is.character(help) && length(help) == 1L) {
      warning(sprintf("Plugin '%s' help directory not found: %s", name, help),
              call. = FALSE)
    }
  }

  invisible(plugin)
}

#' List registered plugins
#' @return A character vector of plugin names.
#' @export
list_plugins <- function() {
  names(.plugin_registry$plugins)
}

#' Remove all registered plugins
#'
#' Intended for tests and for restarting a session with a clean plugin set.
#' @return Invisibly, `NULL`.
#' @export
unload_plugins <- function() {
  for (name in names(.plugin_registry$plugins)) {
    try(help_unregister(name), silent = TRUE)
  }
  .plugin_registry$plugins <- list()
  .plugin_registry$pending <- list()
  .plugin_registry$failures <- list()
  .plugin_registry$conflicts <- list()
  .plugin_registry$last_materialize_ms <- 0
  .plugin_registry$version <- .plugin_registry$version + 1L
  if (is.function(plugin_extensions_reset)) plugin_extensions_reset()
  plugin_catalog_reset()
  .implemented_commands_cache$names <- NULL
  .implemented_commands_cache$dialog_ids <- NULL
  .implemented_commands_cache$dialog_revision <- NULL
  .model_capabilities_cache$table <- NULL
  invisible(NULL)
}

#' Load a plugin script
#'
#' The script is sourced in a new environment and should call
#' [RcmdrShiny.plugin()].  Plugin menus are available after restarting the
#' application (or when the plugin is loaded before [run()]).
#'
#' @param file Path to an R script.
#' @return Invisibly, the names of registered plugins.
#' @export
load_plugin <- function(file) {
  if (!is.character(file) || length(file) != 1L || !file.exists(file)) {
    stop(sprintf("Plugin file not found: %s", file), call. = FALSE)
  }
  environment <- new.env(parent = globalenv())
  sys.source(file, envir = environment, keep.source = FALSE)
  invisible(list_plugins())
}

#' Load an Rcmdr plugin package
#'
#' Supports two package protocols:
#'
#' * `RcmdrShinyPlugin.*` (and any package that exports `rcmdrshiny_plugin()`):
#'   the namespace is loaded and `rcmdrshiny_plugin()` registers the plugin.
#'   The function may either register the plugin itself and return it, or
#'   return a plugin specification (or a list of specifications) to register.
#' * legacy `RcmdrPlugin.*`: `etc/menus.txt` is read and registered with a
#'   warning.  Because legacy menus call Tk dialog functions, their entries
#'   are not executed.
#'
#' @param package Installed package name.
#' @param lib.loc Optional library location.
#' @return Invisibly, the plugin object (or the value returned by
#'   `rcmdrshiny_plugin()`).
#' @export
load_plugin_package <- function(package, lib.loc = NULL) {
  if (!requireNamespace(package, quietly = TRUE, lib.loc = lib.loc)) {
    stop(sprintf("Package '%s' is not installed.", package), call. = FALSE)
  }

  namespace <- asNamespace(package)
  if (exists("rcmdrshiny_plugin", envir = namespace, inherits = FALSE)) {
    result <- load_plugin_namespace(namespace, package)
    register_plugin_help(package, lib.loc = lib.loc)
    return(invisible(result))
  }

  menus_path <- system.file("etc", "rcmdrshiny-menus.txt",
                            package = package, lib.loc = lib.loc)
  if (nzchar(menus_path) && file.exists(menus_path)) {
    plugin <- RcmdrShiny.plugin(
      name = package,
      menus = read_rcmdr_menus(menus_path),
      description = utils::packageDescription(package, lib.loc = lib.loc)$Title,
      version = as.character(utils::packageVersion(package, lib.loc = lib.loc))
    )
    register_plugin_help(package, lib.loc = lib.loc)
    return(invisible(plugin))
  }

  legacy_path <- system.file("etc", "menus.txt", package = package,
                             lib.loc = lib.loc)
  if (!nzchar(legacy_path) || !file.exists(legacy_path)) {
    stop(sprintf(
      "Package '%s' is neither an RcmdrShiny plugin nor a legacy Rcmdr plugin.",
      package
    ), call. = FALSE)
  }
  RcmdrShiny.plugin(
    name = package,
    menus = read_rcmdr_menus(legacy_path),
    description = utils::packageDescription(package, lib.loc = lib.loc)$Title,
    version = as.character(utils::packageVersion(package, lib.loc = lib.loc)),
    tcltk = TRUE
  )
}

# Register the plugin exposed by a package namespace.  Kept separate so that
# the protocol can be tested without installing a package.
#' @keywords internal
load_plugin_namespace <- function(namespace, package) {
  loader <- get("rcmdrshiny_plugin", envir = namespace, inherits = FALSE)
  before <- names(.plugin_registry$plugins)
  result <- loader()
  after <- names(.plugin_registry$plugins)

  if (length(setdiff(after, before)) > 0L) {
    return(invisible(result))
  }

  register_spec <- function(spec) {
    if (is.list(spec) && !is.null(spec$name)) {
      do.call(RcmdrShiny.plugin, spec)
      return(invisible(TRUE))
    }
    FALSE
  }

  if (register_spec(result)) return(invisible(result))

  if (is.list(result) && length(result) > 0L &&
      all(vapply(result, function(spec) {
        is.list(spec) && !is.null(spec$name)
      }, logical(1)))) {
    for (spec in result) do.call(RcmdrShiny.plugin, spec)
    return(invisible(result))
  }

  stop(sprintf(
    "Package '%s' exports rcmdrshiny_plugin() but it did not register a plugin.",
    package
  ), call. = FALSE)
}

#' Load plugins from files or packages
#' @keywords internal
load_plugins <- function(plugins, lazy = NULL) {
  if (is.null(plugins)) return(invisible(list_plugins()))
  if (is.null(lazy)) lazy <- isTRUE(getOption("RcmdrShiny.lazy_plugins", FALSE))
  if (isTRUE(lazy)) {
    .plugin_registry$pending <- c(.plugin_registry$pending, as.list(plugins))
    return(invisible(list_plugins()))
  }
  load_plugins_now(plugins)
}

load_plugins_now <- function(plugins) {
  for (plugin in plugins) {
    label <- plugin_label(plugin)
    tryCatch({
      if (is.character(plugin) && length(plugin) == 1L && file.exists(plugin)) {
        load_plugin(plugin)
      } else if (is.character(plugin) && length(plugin) == 1L) {
        load_plugin_package(plugin)
      } else if (is.list(plugin)) {
        do.call(RcmdrShiny.plugin, plugin)
      } else {
        stop("Plugins must be file paths, package names or argument lists.",
             call. = FALSE)
      }
    }, error = function(e) {
      plugin_record_failure(label, "load", conditionMessage(e))
    })
  }
  invisible(list_plugins())
}

#' Load any plugin left by lazy loading
#' @keywords internal
plugins_ensure_loaded <- function() {
  pending <- .plugin_registry$pending
  if (length(pending) == 0L) return(invisible(FALSE))
  .plugin_registry$pending <- list()
  started <- proc.time()[["elapsed"]]
  load_plugins_now(pending)
  .plugin_registry$last_materialize_ms <-
    (proc.time()[["elapsed"]] - started) * 1000
  invisible(TRUE)
}

#' Pending plugins queued for lazy loading
#' @keywords internal
plugins_pending <- function() {
  vapply(.plugin_registry$pending, function(plugin) {
    if (is.character(plugin) && length(plugin) == 1L) plugin else "<inline>"
  }, character(1))
}

#' Menu definitions including plugin menus
#' @keywords internal
plugin_menu_definitions <- function() {
  plugins_ensure_loaded()
  plugin_catalog_cached("menus", function() {
    plugin_menu_definitions_build()
  })
}

plugin_menu_definitions_build <- function() {
  definitions <- read_rcmdr_menus()
  for (plugin in .plugin_registry$plugins) {
    if (!is.null(plugin$menus)) {
      definitions <- merge_menu_definitions(
        definitions, plugin$menus, source = plugin$name
      )
    }
  }

  menu_ids <- definitions$menu[definitions$type == "menu"]
  duplicates <- unique(menu_ids[duplicated(menu_ids)])
  if (length(duplicates) > 0L) {
    warning(sprintf("Duplicate menu names after loading plugins: %s; their entries are merged.",
                    paste(duplicates, collapse = ", ")), call. = FALSE)
  }
  definitions
}

#' Predicates supplied by registered plugins
#' @keywords internal
plugin_predicates <- function() {
  plugins_ensure_loaded()
  predicates <- list()
  for (plugin in .plugin_registry$plugins) {
    for (name in names(plugin$predicates)) {
      predicates[[name]] <- plugin$predicates[[name]]
    }
  }
  predicates
}

#' @keywords internal
plugin_commands <- function() {
  plugins_ensure_loaded()
  commands <- list()
  for (plugin in .plugin_registry$plugins) {
    for (name in names(plugin$commands)) {
      command <- plugin$commands[[name]]
      commands[[name]] <- if (length(formals(command)) == 0L) {
        (function(fn) function(state) fn())(command)
      } else {
        command
      }
    }
  }
  commands
}

#' @keywords internal
plugin_dialogs <- function() {
  plugins_ensure_loaded()
  dialogs <- list()
  for (plugin in .plugin_registry$plugins) {
    for (name in names(plugin$dialogs)) {
      dialogs[[name]] <- plugin$dialogs[[name]]
    }
  }
  dialogs
}

#' Command aliases supplied by registered plugins
#'
#' Returns a named character vector mapping plugin command ids to the core
#' command that implements them.  Earlier plugins win when two plugins map the
#' same alias.
#'
#' @return A named character vector.
#' @keywords internal
plugin_aliases <- function() {
  plugins_ensure_loaded()
  aliases <- character()
  for (plugin in .plugin_registry$plugins) {
    for (alias in names(plugin$aliases %||% character())) {
      if (!alias %in% names(aliases)) {
        aliases[[alias]] <- plugin$aliases[[alias]]
      }
    }
  }
  aliases
}


#' Dialog for choosing and loading plugin packages or scripts
#' @keywords internal
load_plugins_dialog <- function() {
  id <- "loadPlugins"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Manage Rcmdr Plug-in(s)"), help = "library",
    preview = FALSE,
    ui = function(state, memory) {
      packages <- installed_plugin_packages()
      saved <- saved_plugin_selection()
      selected <- intersect(packages, saved)
      scripts <- setdiff(saved, packages)
      htmltools::tagList(
        if (length(packages) > 0L) {
          htmltools::tagList(
            htmltools::tags$p(htmltools::tags$strong(tr("Installed plugins"))),
            checkboxes_input(
              ns("plugins"), stats::setNames(packages, packages),
              selected = selected, ncol = 1L
            )
          )
        } else {
          help_text(tr("No RcmdrShiny plugin packages are installed."))
        },
        if (length(scripts) > 0L) {
          htmltools::tags$p(
            htmltools::tags$strong(tr("Saved plugin scripts: ")),
            paste(scripts, collapse = ", ")
          )
        },
        file_input(
          ns("file"), tr("Add a plugin script:"), memory$file %||% "",
          filetypes = c("R", "r")
        ),
        checkbox_input(ns("remember"), tr("Remember this script"), TRUE),
        help_text(tr(
          "Checked plugins and scripts are saved in your preferences. Applying unloads and reloads the selection for this session; reload the page (F5) to see the new menus."
        )),
        if (length(list_plugins()) > 0L) {
          htmltools::tags$p(
            htmltools::tags$strong(tr("Loaded now:")),
            paste(list_plugins(), collapse = ", ")
          )
        }
      )
    },
    observers = function(input, output, session, state, refresh) {
      roots <- c(home = "~", wd = getwd(), root = "/")
      file_input_observers(
        input, session, ns("file"), roots,
        guard = function() identical(state$current_dialog, id),
        filetypes = c("R", "r")
      )
    },
    on_ok = function(input, state) {
      packages <- installed_plugin_packages()
      chosen <- packages[vapply(packages, function(package) {
        isTRUE(input[[ns(paste0("plugins_", package))]])
      }, logical(1))]
      saved <- saved_plugin_selection()
      scripts <- setdiff(saved, packages)
      file <- trim_blanks(input[[ns("file")]] %||% "")
      remember <- isTRUE(input[[ns("remember")]])
      if (nzchar(file)) {
        if (!file.exists(file)) {
          return(list(error = sprintf(tr("File not found: %s"), file)))
        }
        if (remember) scripts <- unique(c(scripts, file))
      }

      selection <- unique(c(chosen, scripts))
      state$options$plugins <- selection
      persisted <- tryCatch(preferences_save(state), error = function(e) FALSE)
      to_load <- unique(c(selection, if (nzchar(file)) file else character()))

      unload_plugins()
      load_plugins(to_load)
      failures <- plugin_failures()
      message <- if (nrow(failures) > 0L) {
        sprintf(tr("%d plugin(s) could not be loaded. See Home > Health."),
                nrow(failures))
      } else if (isTRUE(persisted)) {
        tr("Plugin selection saved. Reload the page (F5) to see its menus.")
      } else {
        tr("Plugin selection applied for this session. Reload the page (F5) to see its menus.")
      }
      list(memory = list(file = file), message = message)
    }
  )
}
