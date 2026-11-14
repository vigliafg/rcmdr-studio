# Menu registry ---------------------------------------------------------------
#
# The menu is defined by immutable identifiers, not by row position.  A
# `menu_id` identifies a group, an `item_id` identifies a leaf, and the
# `command_id` still points to the existing engine command.  Reordering or
# renaming a label never changes the identifiers used by the DOM, favourites or
# tests.

menu_registry_version <- function() 1L

menu_slug <- function(x) {
  x <- as.character(x %||% "")
  x <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", x, perl = TRUE)
  x <- gsub("[^A-Za-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  tolower(x)
}

menu_dom_id <- function(item_id) {
  paste0("menu_item_", gsub("[^A-Za-z0-9_]", "_", item_id))
}

menu_named_value <- function(values, key, default = NULL) {
  if (is.null(key) || length(key) == 0L || is.na(key)) return(default)
  value <- unname(values[key])
  if (length(value) == 0L || is.na(value[[1L]])) default else value[[1L]]
}

# -- constructors ------------------------------------------------------------

menu_group <- function(id, parent = NULL, label = NULL, order = 100L,
                       module = "core", icon = NULL, legacy_ids = character()) {
  list(
    type = "group",
    id = as.character(id),
    parent = if (is.null(parent) || !nzchar(parent)) NULL else as.character(parent),
    label = label %||% id,
    order = as.integer(order %||% 100L),
    module = as.character(module),
    icon = icon %||% NULL,
    legacy_ids = as.character(legacy_ids %||% character())
  )
}

menu_item <- function(id, parent, label, command, activation = "",
                      install = "", order = 100L, module = "core",
                      help_topic = NULL, workflow = NULL,
                      legacy_ids = character()) {
  list(
    type = "item",
    id = as.character(id),
    parent = as.character(parent),
    label = label,
    command = command,
    activation = activation %||% "",
    install = install %||% "",
    order = as.integer(order %||% 100L),
    module = as.character(module),
    help_topic = help_topic %||% NULL,
    workflow = workflow %||% NULL,
    legacy_ids = as.character(legacy_ids %||% character())
  )
}

menu_separator <- function(parent, order = 100L, module = "core") {
  list(
    type = "separator",
    id = NULL,
    parent = as.character(parent),
    order = as.integer(order %||% 100L),
    module = as.character(module)
  )
}

menu_remove <- function(target, module = "core",
                        kind = c("auto", "command", "menu", "module_items"),
                        source_module = "core") {
  list(
    type = "remove",
    target = as.character(target),
    module = as.character(module),
    kind = match.arg(kind),
    source_module = as.character(source_module %||% "core")
  )
}

# -- registry ----------------------------------------------------------------

menu_registry_new <- function() {
  list(
    version = menu_registry_version(),
    groups = list(),
    items = list(),
    removes = list(),
    modules = character()
  )
}

menu_registry_add <- function(registry, entries) {
  if (is.null(entries)) return(registry)
  if (!is.list(entries)) stop("Menu entries must be a list.", call. = FALSE)
  if (!is.null(entries$type)) entries <- list(entries)
  for (entry in entries) {
    if (is.null(entry) || is.null(entry$type)) next
    if (identical(entry$type, "group")) {
      key <- entry$id
      if (!is.null(registry$groups[[key]])) {
        key <- paste0(key, ".__duplicate_", length(registry$groups) + 1L)
      }
      registry$groups[[key]] <- entry
    } else if (identical(entry$type, "item")) {
      key <- entry$id
      if (!is.null(registry$items[[key]])) {
        key <- paste0(key, ".__duplicate_", length(registry$items) + 1L)
      }
      registry$items[[key]] <- entry
    } else if (identical(entry$type, "separator")) {
      registry$items[[length(registry$items) + 1L]] <- entry
    } else if (identical(entry$type, "remove")) {
      registry$removes[[length(registry$removes) + 1L]] <- entry
    }
    module <- entry$module %||% "core"
    if (!module %in% registry$modules) {
      registry$modules <- c(registry$modules, module)
    }
  }
  registry
}

#' Parse a menu registry fragment
#'
#' @param value A list with `groups`, `items` and `removes`, or a YAML/JSON
#'   string, or a path to a YAML file.
#' @param module Module id used as default.
#' @return A list of menu entries.
#' @keywords internal
menu_registry_parse <- function(value, module = "core") {
  if (is.character(value) && length(value) == 1L && file.exists(value)) {
    value <- paste(readLines(value, warn = FALSE, encoding = "UTF-8"),
                   collapse = "\n")
  }
  if (is.character(value)) {
    value <- help_yaml_parse(value)
  }
  if (!is.list(value)) stop("Invalid menu registry fragment.", call. = FALSE)

  module <- as.character(value$module %||% module)
  entries <- list()

  for (group in value$groups %||% list()) {
    id <- group$id %||% NULL
    if (is.null(id) || !nzchar(id)) next
    entries[[length(entries) + 1L]] <- menu_group(
      id = id,
      parent = group$parent %||% NULL,
      label = group$label %||% id,
      order = group$order %||% 100L,
      module = group$module %||% module,
      icon = group$icon %||% NULL,
      legacy_ids = group$legacy_ids %||% character()
    )
  }

  for (item in value$items %||% list()) {
    id <- item$id %||% NULL
    parent <- item$parent %||% NULL
    if (is.null(id) || !nzchar(id) || is.null(parent) || !nzchar(parent)) next
    if (identical(tolower(as.character(item$kind %||% "item")), "separator")) {
      entries[[length(entries) + 1L]] <- menu_separator(
        parent = parent, order = item$order %||% 100L,
        module = item$module %||% module
      )
      next
    }
    entries[[length(entries) + 1L]] <- menu_item(
      id = id,
      parent = parent,
      label = item$label %||% id,
      command = item$command %||% "",
      activation = item$activation %||% "",
      install = item$install %||% "",
      order = item$order %||% 100L,
      module = item$module %||% module,
      help_topic = item$help_topic %||% NULL,
      workflow = item$workflow %||% NULL,
      legacy_ids = item$legacy_ids %||% character()
    )
  }

  for (remove in value$removes %||% list()) {
    if (is.character(remove)) {
      entries[[length(entries) + 1L]] <- menu_remove(remove, module = module)
    } else if (is.list(remove) && !is.null(remove$target)) {
      entries[[length(entries) + 1L]] <- menu_remove(
        remove$target, module = remove$module %||% module,
        kind = remove$kind %||% "auto",
        source_module = remove$source_module %||% "core"
      )
    }
  }

  entries
}

menu_registry_load <- function(path, module = "core") {
  menu_registry_add(menu_registry_new(),
                    menu_registry_parse(path, module = module))
}

menu_registry_merge <- function(registry, fragment, module = "core") {
  entries <- if (is.character(fragment) || is.list(fragment) &&
                 !is.null(fragment$type)) {
    if (is.character(fragment)) {
      menu_registry_parse(fragment, module = module)
    } else {
      list(fragment)
    }
  } else {
    menu_registry_parse(fragment, module = module)
  }
  # A module attaches to core groups; it does not redeclare them.  The core
  # group keeps its label, order and icon, while module items are still added.
  entries <- Filter(function(entry) {
    !(identical(entry$type, "group") &&
        entry$id %in% names(registry$groups))
  }, entries)
  menu_registry_add(registry, entries)
}

# -- validation --------------------------------------------------------------

menu_registry_validate <- function(registry, commands = NULL, dialogs = NULL,
                                   known_groups = NULL) {
  problems <- character()
  groups <- registry$groups %||% list()
  items <- registry$items %||% list()

  group_ids <- vapply(groups, function(group) group$id %||% "", character(1))
  if (anyDuplicated(group_ids)) {
    problems <- c(problems,
                  sprintf("Duplicate menu ids: %s",
                          paste(unique(group_ids[duplicated(group_ids)]),
                                collapse = ", ")))
  }
  item_ids <- vapply(items, function(item) item$id %||% "", character(1))
  item_ids <- item_ids[nzchar(item_ids)]
  if (anyDuplicated(item_ids)) {
    problems <- c(problems,
                  sprintf("Duplicate item ids: %s",
                          paste(unique(item_ids[duplicated(item_ids)]),
                                collapse = ", ")))
  }

  # Parents must be a declared group, except for top-level groups.
  for (group in groups) {
    if (!is.null(group$parent) && nzchar(group$parent) &&
        !group$parent %in% c(group_ids, known_groups %||% character())) {
      problems <- c(problems,
                    sprintf("Menu '%s' has unknown parent '%s'.",
                            group$id, group$parent))
    }
  }
  for (item in items) {
    if (identical(item$type, "separator")) next
    if (!is.null(item$parent) && nzchar(item$parent) &&
        !item$parent %in% c(group_ids, known_groups %||% character())) {
      problems <- c(problems,
                    sprintf("Item '%s' has unknown parent '%s'.",
                            item$id, item$parent))
    }
    if (!nzchar(item$command %||% "")) {
      problems <- c(problems, sprintf("Item '%s' has no command.", item$id))
    }
  }

  # Cycle detection: walk each parent chain.
  parents <- stats::setNames(
    vapply(groups, function(group) group$parent %||% "", character(1)),
    group_ids
  )
  for (id in group_ids) {
    seen <- character()
    current <- id
    while (nzchar(current) && current %in% group_ids) {
      if (current %in% seen) {
        problems <- c(problems, sprintf("Menu cycle through '%s'.", id))
        break
      }
      seen <- c(seen, current)
      current <- parents[[current]] %||% ""
    }
  }

  if (!is.null(commands)) {
    for (item in items) {
      if (identical(item$type, "separator")) next
      if (nzchar(item$command %||% "") && !item$command %in% commands) {
        problems <- c(problems,
                      sprintf("Item '%s' points to unknown command '%s'.",
                              item$id, item$command))
      }
    }
  }
  if (!is.null(dialogs)) {
    for (item in items) {
      if (identical(item$type, "separator")) next
      id <- item$command %||% ""
      if (nzchar(id) && id %in% names(dialogs)) next
    }
  }

  list(ok = length(problems) == 0L, problems = unique(problems))
}

# -- tree --------------------------------------------------------------------

menu_registry_children <- function(registry, parent = NULL) {
  groups <- Filter(function(group) {
    identical(group$parent %||% NULL, parent)
  }, registry$groups)
  items <- Filter(function(item) {
    identical(item$parent %||% NULL, parent)
  }, registry$items)
  entries <- c(groups, items)
  if (length(entries) == 0L) return(entries)
  orders <- vapply(entries, function(entry) entry$order %||% 100L, integer(1))
  labels <- vapply(entries, function(entry) entry$label %||% "", character(1))
  entries[order(orders, labels)]
}

menu_registry_tree <- function(registry) {
  build <- function(parent, path) {
    entries <- menu_registry_children(registry, parent)
    lapply(entries, function(entry) {
      if (identical(entry$type, "separator")) {
        return(list(type = "separator", key = NULL, path = path))
      }
      if (identical(entry$type, "group")) {
        node_path <- c(path, entry$label)
        list(
          type = "menu",
          id = entry$id,
          menu_id = entry$id,
          label = entry$label,
          key = entry$id,
          icon = entry$icon %||% NULL,
          module_id = entry$module %||% "core",
          path = node_path,
          children = build(entry$id, node_path)
        )
      } else {
        node_path <- c(path, entry$label)
        list(
          type = "item",
          id = entry$id,
          item_id = entry$id,
          menu_id = entry$parent,
          label = entry$label,
          command = entry$command,
          key = menu_dom_id(entry$id),
          path = node_path,
          activation = entry$activation %||% "",
          install = entry$install %||% "",
          module_id = entry$module %||% "core",
          help_topic = entry$help_topic %||% NULL,
          workflow = entry$workflow %||% NULL
        )
      }
    })
  }
  build(NULL, character())
}

# -- default registry --------------------------------------------------------

menu_registry_default_file <- function() {
  candidates <- c(
    system.file("menus", "core.yml", package = "RcmdrShiny"),
    file.path("inst", "menus", "core.yml"),
    file.path(getwd(), "inst", "menus", "core.yml")
  )
  for (candidate in candidates) {
    if (nzchar(candidate) && file.exists(candidate)) return(candidate)
  }
  ""
}

menu_module_slug <- function(name) {
  name <- sub("^RcmdrShinyPlugin\\.", "", name)
  tolower(gsub("[^A-Za-z0-9]+", "_", name))
}

menu_registry_module_files <- function() {
  registered <- list_plugins()
  if (length(registered) == 0L) return(character())

  # First-party modules keep their fragment next to the plugin package.  In
  # the source tree they are under plugins/<pkg>/inst/menus; installed packages
  # expose the same path through system.file().
  files <- unlist(lapply(registered, function(package) {
    candidates <- c(
      file.path("plugins", package, "inst", "menus", "module.yml"),
      file.path(getwd(), "plugins", package, "inst", "menus", "module.yml"),
      system.file("menus", "module.yml", package = package)
    )
    candidate <- candidates[nzchar(candidates) & file.exists(candidates)]
    if (length(candidate) == 0L) character() else candidate[[1L]]
  }), use.names = FALSE)
  unique(files)
}

menu_legacy_id_map <- function(registry = NULL) {
  registry <- registry %||% tryCatch(menu_registry_cached(), error = function(e) NULL)
  if (is.null(registry)) return(character())
  ids <- character()
  for (group in registry$groups) {
    for (legacy in group$legacy_ids %||% character()) {
      if (nzchar(legacy)) ids[[legacy]] <- group$id
    }
  }
  ids
}

menu_migrate_ids <- function(ids) {
  if (length(ids) == 0L) return(character())
  map <- menu_legacy_id_map()
  if (length(map) == 0L) return(ids)
  vapply(ids, function(id) {
    mapped <- menu_named_value(map, id, "")
    if (!nzchar(mapped)) mapped <- menu_named_value(map, tolower(id), "")
    if (nzchar(mapped)) mapped else id
  }, character(1), USE.NAMES = FALSE)
}

menu_registry_core_ids <- function(registry) {
  ids <- stats::setNames(
    vapply(registry$groups, function(group) group$id, character(1)),
    vapply(registry$groups, function(group) {
      legacy <- group$legacy_ids %||% character()
      if (length(legacy) == 0L) "" else legacy[[1L]]
    }, character(1))
  )
  ids[nzchar(names(ids))]
}

menu_registry_cached <- function(force = FALSE) {
  core_file <- menu_registry_default_file()
  module_files <- menu_registry_module_files()
  stamps <- file.info(c(core_file, module_files))$mtime
  key <- paste(c(core_file, .plugin_registry$version %||% 0L,
                 format(stamps, "%Y%m%d%H%M%OS6")), collapse = "|")
  if (!isTRUE(force) && !is.null(.menu_registry_cache$key) &&
      identical(.menu_registry_cache$key, key)) {
    return(.menu_registry_cache$value)
  }
  path <- menu_registry_default_file()
  if (!nzchar(path)) return(NULL)
  registry <- menu_registry_load(path, module = "core")
  module_files <- menu_registry_module_files()
  loaded_modules <- character()
  module_for_file <- function(file) {
    normalized <- gsub("\\\\", "/", normalizePath(file, mustWork = FALSE))
    for (package in list_plugins()) {
      if (grepl(paste0("/", package, "/"), normalized, fixed = TRUE)) {
        return(menu_module_slug(package))
      }
    }
    sub("\\.yml$", "", basename(file))
  }
  for (file in module_files) {
    module <- module_for_file(file)
    registry <- menu_registry_merge(registry, file, module = module)
    loaded_modules <- c(loaded_modules, module)
  }

  # Menus registered programmatically (test plugins, scripts) still work: their
  # legacy definitions are converted with the same stable-id rules.
  core_ids <- menu_registry_core_ids(registry)
  core_groups <- names(registry$groups)
  for (name in list_plugins()) {
    module <- menu_module_slug(name)
    if (module %in% loaded_modules) next
    plugin <- .plugin_registry$plugins[[name]]
    if (is.null(plugin$menus) || nrow(plugin$menus) == 0L) next
    fragment <- menu_registry_from_legacy(
      plugin$menus, module = module,
      known_ids = core_ids, known_groups = core_groups
    )
    registry <- menu_registry_add(registry, c(
      unname(fragment$groups), unname(fragment$items),
      unname(fragment$removes)
    ))
  }
  registry <- menu_registry_apply_removes(registry)
  .menu_registry_cache$key <- key
  .menu_registry_cache$value <- registry
  registry
}

.menu_registry_cache <- new.env(parent = emptyenv())
.menu_registry_cache$key <- NULL
.menu_registry_cache$value <- NULL

menu_registry_reset <- function() {
  .menu_registry_cache$key <- NULL
  .menu_registry_cache$value <- NULL
  invisible(NULL)
}

menu_registry_apply_removes <- function(registry) {
  removes <- registry$removes %||% list()
  if (length(removes) == 0L) return(registry)
  command_removals <- Filter(function(remove) {
    identical(remove$kind, "command")
  }, removes)
  menus <- unique(unlist(lapply(removes, function(remove) {
    if (identical(remove$kind, "menu")) remove$target else character()
  }), use.names = FALSE))
  auto <- unique(unlist(lapply(removes, function(remove) {
    if (!identical(remove$kind, "auto")) character() else remove$target
  }), use.names = FALSE))
  menus <- unique(c(menus, auto[auto %in% names(registry$groups)]))
  auto_commands <- auto[auto %in% vapply(registry$items,
    function(item) item$command %||% "", character(1))]
  if (length(auto_commands) > 0L) {
    command_removals <- c(command_removals, lapply(auto_commands, function(target) {
      menu_remove(target, kind = "command", source_module = "core")
    }))
  }

  # Removing a group removes its descendants too.
  repeat {
    descendants <- vapply(registry$groups, function(group) {
      (group$parent %||% "") %in% menus
    }, logical(1))
    new_menus <- names(registry$groups)[descendants]
    new_menus <- setdiff(new_menus, menus)
    if (length(new_menus) == 0L) break
    menus <- c(menus, new_menus)
  }

  # A first-party module may replace the core contents of a menu without
  # removing the menu itself; this is how EZR installs its own File menu.
  module_removals <- Filter(function(remove) {
    identical(remove$kind, "module_items")
  }, removes)
  for (remove in module_removals) {
    subtree <- remove$target
    repeat {
      children <- vapply(registry$groups, function(group) {
        (group$parent %||% "") %in% subtree
      }, logical(1))
      new_children <- names(registry$groups)[children]
      new_children <- setdiff(new_children, subtree)
      if (length(new_children) == 0L) break
      subtree <- c(subtree, new_children)
    }
    keep <- !vapply(registry$items, function(item) {
      (item$parent %||% "") %in% subtree &&
        identical(item$module %||% "core",
                  remove$source_module %||% "core")
    }, logical(1))
    registry$items <- registry$items[keep]
  }

  keep_items <- vapply(registry$items, function(item) {
    removed_by_command <- any(vapply(command_removals, function(remove) {
      identical(item$command %||% "", remove$target) &&
        identical(item$module %||% "core",
                  remove$source_module %||% "core")
    }, logical(1)))
    !removed_by_command && !(item$parent %||% "") %in% menus
  }, logical(1))
  registry$items <- registry$items[keep_items]

  keep_groups <- vapply(registry$groups, function(group) {
    !group$id %in% menus
  }, logical(1))
  registry$groups <- registry$groups[keep_groups]
  registry
}

# -- legacy conversion -------------------------------------------------------

# Top-level legacy menus are mapped to the curated shell.  The mapping is also
# used when a plugin attaches to a core menu.
menu_legacy_root_map <- function() {
  c(
    filemenu = "menu.file",
    editmenu = "menu.edit",
    datamenu = "menu.data",
    dat = "menu.data",
    data = "menu.data",
    statisticsmenu = "menu.analyze",
    statmed = "menu.analyze",
    statmedgraph = "menu.graphs",
    graphsmenu = "menu.graphs",
    modelsmenu = "menu.analyze.models",
    distributionsmenu = "menu.analyze.distributions",
    toolsmenu = "menu.utilities",
    helpmenu = "menu.help",
    designmenu = "menu.analyze.design",
    exportmenu = "menu.file.export",
    factominermenu = "menu.analyze.factominer",
    kmg2menu = "menu.graphs.km",
    rocmenu = "menu.analyze.roc",
    demosmenu = "menu.utilities.demos",
    estadisticauvigomenu = "menu.analyze.teachstat",
    qcmenu = "menu.analyze.quality",
    originalmenu = "menu.utilities.ezr_original"
  )
}

menu_legacy_root_labels <- function() {
  c(
    "file" = "menu.file",
    "edit" = "menu.edit",
    "data" = "menu.data",
    "active data set" = "menu.data",
    "statistics" = "menu.analyze",
    "statistical analysis" = "menu.analyze",
    "graphs" = "menu.graphs",
    "graphs and tables" = "menu.graphs",
    "models" = "menu.analyze.models",
    "distributions" = "menu.analyze.distributions",
    "tools" = "menu.utilities",
    "help" = "menu.help",
    "design" = "menu.analyze.design",
    "export" = "menu.file.export",
    "factominer" = "menu.analyze.factominer",
    "kmggplot2" = "menu.graphs.km",
    "roc" = "menu.analyze.roc",
    "demos" = "menu.utilities.demos",
    "basic statistics" = "menu.analyze.teachstat",
    "quality control" = "menu.analyze.quality",
    "original menu" = "menu.utilities.ezr_original"
  )
}

menu_registry_from_legacy <- function(definitions, module = "core",
                                      root_map = menu_legacy_root_map(),
                                      known_ids = NULL, known_groups = NULL) {
  if (is.null(definitions) || nrow(definitions) == 0L) {
    return(menu_registry_new())
  }
  registry <- menu_registry_new()
  menu_rows <- definitions[definitions$type == "menu", , drop = FALSE]
  item_rows <- definitions[definitions$type == "item", , drop = FALSE]

  # Legacy menu rows store the menu name in `menu` and the parent in `kind`.
  # The human label comes from the cascade item that points to the menu.
  cascade_labels <- stats::setNames(
    vapply(item_rows$label, as.character, character(1)),
    vapply(item_rows$command, as.character, character(1))
  )
  cascade_labels <- cascade_labels[nzchar(names(cascade_labels))]

  ids <- character()
  if (!is.null(known_ids)) {
    ids <- as.character(known_ids)
    names(ids) <- names(known_ids)
    ids <- ids[nzchar(names(ids))]
  }
  for (i in seq_len(nrow(menu_rows))) {
    name <- menu_rows$menu[[i]]
    if (nzchar(name) && !name %in% names(ids)) ids[[name]] <- ""
  }
  lower_ids <- stats::setNames(as.character(ids), tolower(names(ids)))
  lower_ids <- lower_ids[!names(lower_ids) %in% names(ids)]
  ids <- c(ids, lower_ids)

  lookup_id <- function(name) {
    value <- menu_named_value(ids, name, "")
    if (!nzchar(value)) value <- menu_named_value(ids, tolower(name), "")
    value
  }

  resolve_menu <- function(name) {
    value <- lookup_id(name)
    if (nzchar(value)) return(value)
    row <- menu_rows[menu_rows$menu == name, , drop = FALSE]
    if (nrow(row) == 0L) return("")
    parent <- row$kind[[1L]]
    slug <- menu_slug(name)
    key <- tolower(gsub("[^A-Za-z0-9]", "", name))
    if (identical(parent, "topMenu")) {
      mapped <- menu_named_value(root_map, key, "")
      if (!nzchar(mapped)) {
        mapped <- menu_named_value(
          menu_legacy_root_labels(),
          tolower(trimws(cascade_labels[[name]] %||% "")), ""
        )
      }
      if (!nzchar(mapped)) {
        mapped <- paste0("menu.", if (identical(module, "core")) "" else
          paste0(module, "."), slug)
      }
      ids[[name]] <<- mapped
      ids[[tolower(name)]] <<- mapped
      return(mapped)
    }
    parent_id <- resolve_menu(parent)
    if (!nzchar(parent_id)) parent_id <- "menu.misc"
    candidate <- paste0(parent_id, ".", slug)
    ids[[name]] <<- candidate
    ids[[tolower(name)]] <<- candidate
    candidate
  }

  for (i in seq_len(nrow(menu_rows))) resolve_menu(menu_rows$menu[[i]])

  top_labels <- c(
    "menu.file" = "File", "menu.edit" = "Edit", "menu.data" = "Data",
    "menu.analyze" = "Analyze", "menu.graphs" = "Graphs",
    "menu.reports" = "Reports", "menu.view" = "View",
    "menu.utilities" = "Utilities", "menu.help" = "Help"
  )
  top_order <- c(
    "menu.file" = 10L, "menu.edit" = 20L, "menu.data" = 30L,
    "menu.transform" = 35L, "menu.analyze" = 40L, "menu.graphs" = 50L,
    "menu.reports" = 60L, "menu.view" = 70L, "menu.utilities" = 80L,
    "menu.help" = 90L
  )
  order_base <- if (identical(module, "core")) 1000L else 5000L

  for (i in seq_len(nrow(menu_rows))) {
    name <- menu_rows$menu[[i]]
    id <- lookup_id(name)
    if (!nzchar(id)) next
    parent <- menu_rows$kind[[i]]
    parent_id <- NULL
    if (!identical(parent, "topMenu")) {
      parent_id <- lookup_id(parent)
      if (!nzchar(parent_id)) parent_id <- NULL
    }
    if (is.null(parent_id)) {
      candidate <- sub("\\.[^.]+$", "", id)
      if (!identical(candidate, id) &&
          candidate %in% c(known_groups %||% character(),
                           names(registry$groups))) {
        parent_id <- candidate
      }
    }
    label <- cascade_labels[[name]] %||% name
    if (id %in% names(top_labels)) label <- top_labels[[id]]
    fallback_order <- if (is.null(parent_id) && !id %in% names(top_order)) {
      70L + i
    } else {
      order_base + i
    }
    order <- menu_named_value(top_order, id, fallback_order)
    registry <- menu_registry_add(registry, list(menu_group(
      id = id, parent = parent_id, label = label, order = order,
      module = module, legacy_ids = name
    )))
  }

  item_ids <- character()
  for (i in seq_len(nrow(item_rows))) {
    row <- item_rows[i, , drop = FALSE]
    parent <- lookup_id(row$menu[[1L]])
    if (!nzchar(parent)) next
    if (identical(row$kind[[1L]], "cascade")) next
    base <- paste0(
      "item.", module, ".", menu_slug(parent), ".",
      menu_slug(row$command[[1L]] %||% row$label[[1L]])
    )
    item_id <- base
    counter <- 2L
    while (item_id %in% item_ids) {
      item_id <- paste0(base, "_", counter)
      counter <- counter + 1L
    }
    item_ids <- c(item_ids, item_id)
    if (identical(row$kind[[1L]], "separator")) {
      registry <- menu_registry_add(registry, list(menu_separator(
        parent = parent, order = order_base + i, module = module
      )))
      next
    }
    registry <- menu_registry_add(registry, list(menu_item(
      id = item_id, parent = parent, label = row$label[[1L]],
      command = row$command[[1L]], activation = row$activation[[1L]],
      install = row$install[[1L]], order = order_base + i, module = module,
      legacy_ids = row$command[[1L]]
    )))
  }

  remove_rows <- definitions[definitions$type == "remove", , drop = FALSE]
  for (i in seq_len(nrow(remove_rows))) {
    target <- remove_rows$menu[[i]]
    if (!nzchar(target)) next
    target_id <- menu_named_value(known_ids %||% character(), target, "")
    if (nzchar(target_id)) {
      # First-party modules augment the curated shell; they do not delete a
      # whole core menu.  Removing individual commands is still supported.
      next
    } else {
      registry <- menu_registry_add(registry, list(menu_remove(
        target = target, module = module, kind = "command",
        source_module = "core"
      )))
    }
  }

  registry
}

menu_registry_curate <- function(registry) {
  # Top-level groups that make the shell closer to SPSS/Minitab and less like
  # the historical Rcmdr tree.
  add_group <- function(id, parent, label, order) {
    if (!id %in% names(registry$groups)) {
      registry$groups[[id]] <<- menu_group(
        id = id, parent = parent, label = label, order = order
      )
    }
  }
  add_group("menu.transform", NULL, "Transform", 35L)
  add_group("menu.reports", NULL, "Reports", 60L)
  add_group("menu.reports.document", "menu.reports", "Document", 10L)
  add_group("menu.reports.author", "menu.reports", "Author", 20L)
  add_group("menu.reports.knit", "menu.reports", "Knit", 30L)
  add_group("menu.reports.export", "menu.reports", "Export", 40L)
  add_group("menu.file.new", "menu.file", "New", 10L)
  add_group("menu.file.open", "menu.file", "Open", 20L)
  add_group("menu.file.save", "menu.file", "Save", 30L)
  add_group("menu.file.save.as", "menu.file.save", "Save as", 50L)
  add_group("menu.file.export", "menu.file", "Export", 40L)

  # Variables are transformations, not a top-level Data concern.
  if (!is.null(registry$groups[["menu.data.variables_menu"]])) {
    registry$groups[["menu.data.variables_menu"]]$parent <- "menu.transform"
    registry$groups[["menu.data.variables_menu"]]$label <- "Variables"
    registry$groups[["menu.data.variables_menu"]]$order <- 10L
  }

  report_document <- c("loadRmd", "loadRnw", "saveRmd", "saveRmdAs",
                       "saveRnw", "saveRnwAs", "newRmd", "newRnw")
  report_author <- c("setBibliography", "editMarkdown", "editKnitr",
                     "removeLastRmdBlock", "removeLastRmdSection",
                     "removeLastRnwBlock", "insertSection", "insertChunk")
  report_knit <- c("compileRmd", "compileRnw")
  report_export <- c("exportReport")

  move <- function(commands, parent) {
    for (id in names(registry$items)) {
      item <- registry$items[[id]]
      if (identical(item$type, "separator")) next
      if ((item$command %||% "") %in% commands) {
        item$parent <- parent
        item$workflow <- "report"
        registry$items[[id]] <<- item
      }
    }
  }
  move(report_document, "menu.reports.document")
  move(report_author, "menu.reports.author")
  move(report_knit, "menu.reports.knit")
  move(report_export, "menu.reports.export")

  # One Save menu with one item per format; "Save as" stays available as a
  # nested group instead of a flat list of near-duplicates.
  move_labels <- function(commands, parent, labels = NULL, order = NULL) {
    for (id in names(registry$items)) {
      item <- registry$items[[id]]
      if (identical(item$type, "separator")) next
      command <- item$command %||% ""
      if (!command %in% commands) next
      item$parent <- parent
      if (!is.null(labels) && command %in% names(labels)) {
        item$label <- labels[[command]]
      }
      if (!is.null(order) && command %in% names(order)) {
        item$order <- as.integer(order[[command]])
      }
      registry$items[[id]] <<- item
    }
  }

  move_labels(
    c("newDataSet", "newRmd", "newRnw"), "menu.file.new",
    labels = c(newDataSet = "Data set...", newRmd = "R Markdown document...",
               newRnw = "knitr document..."),
    order = c(newDataSet = 10L, newRmd = 20L, newRnw = 30L)
  )
  move_labels(
    c("loadLog", "loadRmd", "loadRnw", "loadDataSet", "loadDataFromPackage"),
    "menu.file.open",
    labels = c(loadLog = "Script...", loadRmd = "R Markdown...",
               loadRnw = "knitr...", loadDataSet = "Workspace...",
               loadDataFromPackage = "Data set from package..."),
    order = c(loadLog = 10L, loadRmd = 20L, loadRnw = 30L,
              loadDataSet = 40L, loadDataFromPackage = 50L)
  )
  move_labels(
    c("saveDataSet", "saveLog", "saveRmd", "saveRnw", "saveWorkspace"),
    "menu.file.save",
    labels = c(saveDataSet = "Data set...", saveLog = "Script...",
               saveRmd = "Report (R Markdown)...",
               saveRnw = "Report (knitr)...",
               saveWorkspace = "Workspace..."),
    order = c(saveDataSet = 10L, saveLog = 20L, saveRmd = 30L,
              saveRnw = 40L, saveWorkspace = 50L)
  )
  move_labels(
    c("saveLogAs", "saveRmdAs", "saveRnwAs", "saveWorkspaceAs",
      "saveOutputAs"),
    "menu.file.save.as",
    labels = c(saveLogAs = "Script as...", saveRmdAs = "R Markdown as...",
               saveRnwAs = "knitr as...", saveWorkspaceAs = "Workspace as...",
               saveOutputAs = "Output as..."),
    order = c(saveLogAs = 10L, saveRmdAs = 20L, saveRnwAs = 30L,
              saveWorkspaceAs = 40L, saveOutputAs = 50L)
  )
  move_labels(
    c("saveOutput", "exportReport"), "menu.file.export",
    labels = c(saveOutput = "Output...", exportReport = "Report bundle..."),
    order = c(saveOutput = 10L, exportReport = 20L)
  )
  registry$groups[["menu.file.save.as"]]$order <- 60L
  if (!is.null(registry$groups[["menu.file.exit_menu"]])) {
    registry$groups[["menu.file.exit_menu"]]$order <- 90L
  }

  # Readable, stable ids for the flagship Save entries.
  rename <- c(
    saveDataSet = "file.save.data",
    saveLog = "file.save.script",
    saveRmd = "file.save.rmd",
    saveRnw = "file.save.rnw",
    saveWorkspace = "file.save.workspace",
    saveLogAs = "file.save.script_as",
    saveRmdAs = "file.save.rmd_as",
    saveRnwAs = "file.save.rnw_as",
    saveWorkspaceAs = "file.save.workspace_as",
    saveOutputAs = "file.save.output_as",
    saveOutput = "file.export.output",
    exportReport = "file.export.report"
  )
  for (id in names(registry$items)) {
    item <- registry$items[[id]]
    if (identical(item$type, "separator")) next
    new_id <- menu_named_value(rename, item$command %||% "", "")
    if (!nzchar(new_id) || new_id %in% names(registry$items)) next
    item$id <- new_id
    registry$items[[new_id]] <- item
    registry$items[[id]] <- NULL
  }
  registry$items <- Filter(function(item) {
    !(identical(item$type, "separator") &&
        identical(item$parent %||% "", "menu.file"))
  }, registry$items)

  # Drop groups that have no leaves after curation.
  repeat {
    has_child <- vapply(registry$groups, function(group) {
      any(vapply(registry$items, function(item) {
        identical(item$parent %||% "", group$id)
      }, logical(1))) ||
        any(vapply(registry$groups, function(child) {
          identical(child$parent %||% "", group$id)
        }, logical(1)))
    }, logical(1))
    empty <- names(registry$groups)[!has_child & !vapply(
      registry$groups, function(group) is.null(group$parent), logical(1)
    )]
    if (length(empty) == 0L) break
    registry$groups <- registry$groups[!names(registry$groups) %in% empty]
  }

  registry
}

menu_registry_to_yaml <- function(registry, module = NULL) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("The 'yaml' package is required to write a menu registry.",
         call. = FALSE)
  }
  groups <- lapply(registry$groups, function(group) {
    list(
      id = group$id,
      parent = group$parent %||% "",
      label = group$label,
      order = group$order,
      module = group$module,
      legacy_ids = as.list(group$legacy_ids %||% character())
    )
  })
  items <- lapply(registry$items, function(item) {
    if (identical(item$type, "separator")) {
      return(list(kind = "separator", parent = item$parent,
                  order = item$order, module = item$module))
    }
    list(
      id = item$id,
      parent = item$parent,
      label = item$label,
      command = item$command,
      activation = item$activation %||% "",
      install = item$install %||% "",
      order = item$order,
      module = item$module,
      legacy_ids = as.list(item$legacy_ids %||% character())
    )
  })
  removes <- lapply(registry$removes, function(remove) {
    list(target = remove$target, module = remove$module, kind = remove$kind,
         source_module = remove$source_module %||% "core")
  })
  yaml::as.yaml(list(
    version = registry$version,
    module = module %||% "core",
    groups = unname(groups),
    items = unname(items),
    removes = unname(removes)
  ))
}
