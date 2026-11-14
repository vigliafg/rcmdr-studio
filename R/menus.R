# Menu definitions ----------------------------------------------------------
#
# Rcmdr's Rcmdr-menus.txt remains the source of truth for the menu structure.
# The file is parsed into a tree; the Shiny sidebar renders that tree, and the
# server registers one observer per leaf.  Leaves whose command has not been
# ported yet are disabled with an "in porting" tooltip, which gives an
# incremental release path without editing the menu file.

#' Read an Rcmdr menu definition file
#'
#' @param path Path to `Rcmdr-menus.txt`.
#' @return A data frame with one row per definition and columns `type`, `menu`,
#'   `kind`, `label`, `command`, `activation` and `install`.
#' @export
read_rcmdr_menus <- function(path = system.file("etc", "Rcmdr-menus.txt",
                                                package = "RcmdrShiny")) {
  if (!file.exists(path)) {
    stop(sprintf("Menu file not found: %s", path), call. = FALSE)
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

  rows <- lapply(lines, parse_menu_line)
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0L) {
    return(empty_menu_definitions())
  }
  do.call(rbind, rows)
}

parse_menu_line <- function(line) {
  tokens <- regmatches(line, gregexpr('"([^"]*)"|\\S+', line, perl = TRUE))[[1L]]
  tokens <- sub('^"(.*)"$', "\\1", tokens)

  type <- if (length(tokens) > 0L) tokens[[1L]] else ""
  if (!type %in% c("menu", "item", "remove")) return(NULL)
  minimum <- if (identical(type, "remove")) 2L else 4L
  if (length(tokens) < minimum) return(NULL)

  fields <- rep("", 7L)
  fields[seq_len(min(length(tokens), 7L))] <- tokens[seq_len(min(length(tokens), 7L))]

  data.frame(
    type = fields[[1L]],
    menu = fields[[2L]],
    kind = fields[[3L]],
    label = fields[[4L]],
    command = fields[[5L]],
    activation = fields[[6L]],
    install = fields[[7L]],
    stringsAsFactors = FALSE
  )
}

empty_menu_definitions <- function() {
  data.frame(
    type = character(), menu = character(), kind = character(),
    label = character(), command = character(), activation = character(),
    install = character(), stringsAsFactors = FALSE
  )
}

insert_menu_row <- function(definitions, row, after = 0L) {
  n <- nrow(definitions)
  after <- max(0L, min(as.integer(after), n))
  before <- if (after > 0L) definitions[seq_len(after), , drop = FALSE] else {
    definitions[0L, , drop = FALSE]
  }
  rest <- if (after < n) definitions[seq.int(after + 1L, n), , drop = FALSE] else {
    definitions[0L, , drop = FALSE]
  }
  rbind(before, row, rest)
}

# Remove a menu (or a command) and its descendants.  Mirrors Rcmdr's
# `removeMenus()`: a definition can be removed either by menu id or by the
# command it points to.
remove_menu_rows <- function(definitions, what) {
  if (is.null(what) || !nzchar(what) || nrow(definitions) == 0L) {
    return(definitions)
  }
  children <- unique(definitions$menu[
    definitions$type == "menu" & definitions$kind == what
  ])
  keep <- !(definitions$menu == what | definitions$command == what)
  definitions <- definitions[keep, , drop = FALSE]
  for (child in children) {
    definitions <- remove_menu_rows(definitions, child)
  }
  definitions
}

#' Merge plugin menu definitions into a base menu
#'
#' Implements the insertion rules of Rcmdr's `processMenus()`: menu and item
#' rows are appended to their parent menu, top-level cascades are placed before
#' Tools and Help, and `remove` rows delete a menu or command with its
#' descendants.
#'
#' @param definitions Base menu data frame.
#' @param additions Plugin menu data frame.
#' @param source Optional plugin name used in error messages.
#' @return A merged menu data frame.
#' @keywords internal
merge_menu_definitions <- function(definitions, additions, source = NULL) {
  if (is.null(additions) || nrow(additions) == 0L) return(definitions)
  where <- if (is.null(source)) "" else sprintf(" in plugin '%s'", source)

  find_menu <- function(menu) {
    rows <- which(definitions$type == "menu" & definitions$menu == menu)
    if (length(rows) == 0L) {
      warning(sprintf("Plugin menu refers to unknown parent menu '%s'%s; entry skipped.",
                      menu, where), call. = FALSE)
      return(NA_integer_)
    }
    max(rows)
  }

  for (i in seq_len(nrow(additions))) {
    row <- additions[i, , drop = FALSE]

    if (identical(row$type, "remove")) {
      definitions <- remove_menu_rows(definitions, row$menu)
      next
    }

    if (identical(row$type, "menu")) {
      parent <- row$kind
      after <- if (!nzchar(parent) || identical(parent, "topMenu")) {
        0L
      } else {
        find_menu(parent)
      }
      if (!is.na(after)) definitions <- insert_menu_row(definitions, row, after)
      next
    }

    if (!identical(row$type, "item")) {
      stop(sprintf("Unrecognised plugin menu type '%s'%s.",
                   row$type, where), call. = FALSE)
    }

    if (row$kind %in% c("command", "separator")) {
      siblings <- which(
        definitions$menu == row$menu &
          definitions$kind %in% c("command", "separator")
      )
      after <- if (length(siblings) > 0L) {
        max(siblings)
      } else {
        find_menu(row$menu)
      }
      # A separator can be anchored after a given command.
      if (identical(row$kind, "separator") && nzchar(row$command)) {
        anchor <- which(definitions$command == row$command)
        if (length(anchor) == 0L) {
          warning(sprintf("Plugin separator refers to unknown command '%s'%s; entry skipped.",
                          row$command, where), call. = FALSE)
          after <- NA_integer_
        } else {
          after <- max(anchor)
        }
      }
      if (!is.na(after)) definitions <- insert_menu_row(definitions, row, after)
    } else if (identical(row$kind, "cascade")) {
      if (identical(row$menu, "topMenu")) {
        siblings <- which(
          definitions$kind == "cascade" &
            definitions$menu == "topMenu" &
            !definitions$command %in% c("toolsMenu", "helpMenu")
        )
        after <- if (length(siblings) > 0L) max(siblings) else 0L
      } else {
        siblings <- which(
          (definitions$kind == "cascade" & definitions$menu == row$menu) |
            definitions$command == row$menu
        )
        if (length(siblings) == 0L) {
          warning(sprintf("Plugin cascade refers to unknown parent menu '%s'%s; entry skipped.",
                          row$menu, where), call. = FALSE)
          after <- NA_integer_
        } else {
          after <- max(siblings)
        }
      }
      if (!is.na(after)) definitions <- insert_menu_row(definitions, row, after)
    } else {
      stop(sprintf("Unrecognised plugin menu operation '%s'%s.",
                   row$kind, where), call. = FALSE)
    }
  }

  definitions
}

#' Build the menu tree
#'
#' @param definitions Data frame returned by [read_rcmdr_menus()].  Defaults to
#'   the core menus plus all registered plugin menus.
#' @return A list of top-level menu nodes.
#' @export
menu_tree <- function(definitions = NULL) {
  if (is.null(definitions)) {
    registry <- tryCatch(menu_registry_cached(), error = function(e) NULL)
    if (!is.null(registry)) return(menu_registry_tree(registry))
    definitions <- plugin_menu_definitions()
  }
  counter <- new.env(parent = emptyenv())
  counter$n <- 0L
  build_menu_children(definitions, "topMenu", path = character(), counter = counter)
}

build_menu_children <- function(definitions, menu, path = character(),
                                counter = NULL) {
  if (is.null(counter)) {
    counter <- new.env(parent = emptyenv())
    counter$n <- 0L
  }
  rows <- which(definitions$type == "item" & definitions$menu == menu)
  nodes <- vector("list", length(rows))

  for (i in seq_along(rows)) {
    row <- definitions[rows[[i]], , drop = FALSE]
    counter$n <- counter$n + 1L
    key <- sprintf("menu_item_%d", counter$n)
    node_path <- c(path, row$label)

    if (identical(row$kind, "separator")) {
      nodes[[i]] <- list(type = "separator", key = key, path = node_path)
    } else if (identical(row$kind, "cascade")) {
      nodes[[i]] <- list(
        type = "menu",
        id = row$command,
        label = row$label,
        key = key,
        path = node_path,
        children = build_menu_children(definitions, row$command, node_path,
                                       counter = counter)
      )
    } else {
      nodes[[i]] <- list(
        type = "item",
        id = row$command,
        label = row$label,
        command = row$command,
        key = key,
        path = node_path,
        activation = row$activation,
        install = row$install
      )
    }
  }
  nodes
}

#' Flatten the menu tree to its leaves
#'
#' @param tree Menu tree returned by [menu_tree()].
#' @return A data frame with one row per command item.
#' @export
menu_leaves <- function(tree) {
  rows <- list()
  walk <- function(nodes) {
    for (node in nodes) {
      if (node$type == "menu") {
        walk(node$children)
      } else if (node$type == "item") {
        rows[[length(rows) + 1L]] <<- data.frame(
          key = node$key,
          item_id = node$item_id %||% node$command,
          menu_id = node$menu_id %||% NA_character_,
          module_id = node$module_id %||% "core",
          command = node$command,
          label = node$label,
          path = paste(node$path, collapse = " > "),
          activation = node$activation,
          install = node$install,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  walk(tree)
  if (length(rows) == 0L) {
    return(data.frame(
      key = character(), item_id = character(), menu_id = character(),
      module_id = character(), command = character(), label = character(),
      path = character(), activation = character(), install = character(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

# Rendering -----------------------------------------------------------------

#' Render the menu tree as HTML
#'
#' @param tree Menu tree returned by [menu_tree()].
#' @param status Function taking a menu item node and returning one of
#'   `"enabled"`, `"porting"`, `"inactive"` or `"hidden"`.
#' @keywords internal
menu_ui <- function(tree, status = function(node) "enabled",
                    favorites = character(), expanded = NULL, query = "") {
  htmltools::tags$div(
    class = "rcmdr-menu",
    lapply(tree, menu_node_ui, status = status, favorites = favorites,
           expanded = expanded, query = query)
  )
}

#' Render the top-level menubar
#'
#' @param tree Menu tree returned by [menu_tree()].
#' @param status Function returning the state of a leaf.
#' @param favorites Favourite command ids.
#' @param expanded Expanded nested menu ids.
#' @param query Optional search query.
#' @keywords internal
menubar_ui <- function(tree, status = function(node) "enabled",
                       favorites = character(), expanded = NULL,
                       query = "") {
  htmltools::tags$nav(
    class = "rcmdr-menubar",
    role = "navigation",
    `aria-label` = tr("Application menus"),
    lapply(tree, menubar_top_ui, status = status, favorites = favorites,
           expanded = expanded, query = query)
  )
}

menubar_top_ui <- function(node, status = function(node) "enabled",
                           favorites = character(), expanded = NULL,
                           query = "") {
  if (identical(node$type, "separator")) return(NULL)
  if (!identical(node$type, "menu")) {
    return(menu_node_ui(node, status = status, favorites = favorites,
                        expanded = expanded, query = query))
  }
  htmltools::tags$details(
    class = "rcmdr-menubar-group",
    htmltools::tags$summary(menu_label(node$label)),
    htmltools::tags$div(
      class = "rcmdr-menubar-dropdown",
      lapply(node$children, menu_node_ui, status = status,
             favorites = favorites, expanded = expanded, query = query)
    )
  )
}

menu_node_ui <- function(node, status = function(node) "enabled",
                         favorites = character(), expanded = NULL,
                         query = "") {
  if (identical(node$type, "separator")) {
    return(htmltools::tags$hr(class = "my-1"))
  }

  if (identical(node$type, "menu")) {
    children <- lapply(node$children, menu_node_ui, status = status,
                       favorites = favorites, expanded = expanded,
                       query = query)
    return(htmltools::tags$details(
      class = "rcmdr-menu-group",
      `data-menu-id` = node$id,
      open = if (!is.null(expanded) && node$id %in% expanded) "open" else NULL,
      htmltools::tags$summary(menu_label(node$label)),
      htmltools::tags$div(class = "rcmdr-menu-children", children)
    ))
  }

  state <- status(node)
  if (identical(state, "hidden")) return(NULL)

  if (identical(state, "enabled")) {
    htmltools::tags$div(
      class = "rcmdr-menu-row",
      actionLink(
        node$key,
        htmltools::tagList(
          menu_highlight(menu_label(node$label), query)
        ),
        class = "rcmdr-menu-item"
      ),
      menu_star_ui(node$command, node$command %in% favorites)
    )
  } else {
    tooltip <- if (identical(state, "porting")) {
      tr("In porting")
    } else {
      tr("Not available for the current data set")
    }
    htmltools::tags$div(
      class = "rcmdr-menu-row",
      htmltools::tags$span(
        class = "rcmdr-menu-item disabled",
        title = tooltip,
        menu_highlight(menu_label(node$label), query)
      )
    )
  }
}

# Navigation helpers ---------------------------------------------------------

#' Path of a command in the menu tree
#'
#' @param command Command identifier.
#' @param tree Optional menu tree.
#' @return A character vector of labels, or `character()` when the command is
#'   not part of a menu.
#' @keywords internal
menu_command_path <- function(command, tree = menu_tree()) {
  if (is.null(command) || !nzchar(command)) return(character())
  leaves <- menu_leaves(tree)
  index <- match(command, leaves$command)
  if (is.na(index)) return(character())
  strsplit(leaves$path[[index]], " > ", fixed = TRUE)[[1L]]
}

#' Breadcrumb parts for a dialog
#' @keywords internal
dialog_breadcrumb_parts <- function(id) {
  menu_command_path(id)
}

#' Toggle a menu favourite
#' @keywords internal
menu_favorite_toggle <- function(state, command) {
  if (is.null(command) || !nzchar(command)) return(invisible(FALSE))
  favorites <- state$menu_favorites %||% character()
  if (command %in% favorites) {
    state$menu_favorites <- setdiff(favorites, command)
    value <- FALSE
  } else {
    state$menu_favorites <- unique(c(command, favorites))
    value <- TRUE
  }
  state_touch(state)
  invisible(value)
}

#' Favourite commands
#' @keywords internal
menu_favorite_ids <- function(state) state$menu_favorites %||% character()

#' Record a recently used command
#' @keywords internal
menu_recent_add <- function(state, command) {
  if (is.null(command) || !nzchar(command)) return(invisible(NULL))
  limit <- max(1L, as.integer(state$options$menu_recent_length %||% 8L))
  recents <- c(command, setdiff(state$menu_recents %||% character(), command))
  state$menu_recents <- utils::head(recents, limit)
  state_touch(state)
  invisible(state$menu_recents)
}

#' Recently used commands
#' @keywords internal
menu_recent_ids <- function(state) state$menu_recents %||% character()

#' Expand or collapse the entire menu tree
#' @keywords internal
menu_set_expanded <- function(state, commands = NULL, expand = TRUE) {
  if (is.null(commands)) {
    tree <- menu_tree()
    commands <- unlist(lapply(tree, function(node) {
      if (identical(node$type, "menu")) node$id else NULL
    }), use.names = FALSE)
  }
  if (isTRUE(expand)) {
    state$menu_expanded <- unique(c(state$menu_expanded %||% character(),
                                    commands))
  } else {
    state$menu_expanded <- setdiff(state$menu_expanded %||% character(),
                                   commands)
  }
  state_touch(state)
  invisible(state$menu_expanded)
}

#' Toggle one menu group
#' @keywords internal
menu_toggle_expanded <- function(state, id, open = NULL) {
  if (is.null(id) || !nzchar(id)) return(invisible(NULL))
  current <- state$menu_expanded %||% character()
  should_open <- if (is.null(open)) !(id %in% current) else isTRUE(open)
  state$menu_expanded <- if (should_open) unique(c(id, current)) else
    setdiff(current, id)
  state_touch(state)
  invisible(state$menu_expanded)
}

#' Highlight a query in a menu label
#' @keywords internal
menu_highlight <- function(text, query) {
  text <- text %||% ""
  query <- trimws(query %||% "")
  if (!nzchar(query) || !nzchar(text)) return(text)
  escaped <- paste0(
    "\\Q",
    gsub("\\\\E", "\\\\\\\\E", query, perl = TRUE),
    "\\E"
  )
  hit <- regexpr(escaped, text, ignore.case = TRUE, perl = TRUE)[[1L]]
  if (hit < 0L) return(text)
  before <- substr(text, 1L, hit - 1L)
  match <- substr(text, hit, hit + nchar(query) - 1L)
  after <- substr(text, hit + nchar(query), nchar(text))
  htmltools::tagList(
    before,
    htmltools::tags$mark(class = "rcmdr-menu-mark", match),
    after
  )
}

menu_star_ui <- function(command, favorite = FALSE) {
  htmltools::tags$button(
    type = "button",
    class = paste("rcmdr-menu-star", if (isTRUE(favorite)) "active"),
    title = if (isTRUE(favorite)) tr("Remove from favourites") else
      tr("Add to favourites"),
    `aria-label` = if (isTRUE(favorite)) tr("Remove from favourites") else
      tr("Add to favourites"),
    `aria-pressed` = if (isTRUE(favorite)) "true" else "false",
    onclick = sprintf(
      "event.stopPropagation(); Shiny.setInputValue('menu_favorite', {command: '%s'}, {priority: 'event'}); return false;",
      command
    ),
    if (isTRUE(favorite)) "\u2605" else "\u2606"
  )
}

menu_shortcut_link <- function(row, label) {
  command <- row$command %||% ""
  htmltools::tags$a(
    class = "rcmdr-menu-item",
    href = "#",
    onclick = sprintf(
      "Shiny.setInputValue('menu_command', '%s', {priority: 'event'}); return false;",
      gsub("'", "\\\\'", command)
    ),
    label
  )
}

menu_flat_item_ui <- function(row, status, query = "", favorite = FALSE) {
  label <- htmltools::tagList(
    menu_highlight(row$label, query),
    htmltools::tags$span(class = "rcmdr-menu-flat-path", row$path)
  )
  if (identical(status, "enabled")) {
    htmltools::tags$div(
      class = "rcmdr-menu-row",
      actionLink(row$key, label, class = "rcmdr-menu-item"),
      menu_star_ui(row$command, favorite)
    )
  } else {
    htmltools::tags$div(
      class = "rcmdr-menu-row",
      htmltools::tags$div(
        class = "rcmdr-menu-item disabled",
        title = if (identical(status, "porting")) {
          tr("In porting")
        } else {
          tr("Not available for the current data set")
        },
        label
      )
    )
  }
}

#' Favourites and recents sections for the sidebar
#' @keywords internal
menu_sections_ui <- function(state, leaves = NULL) {
  favorites <- menu_favorite_ids(state)
  recents <- menu_recent_ids(state)
  if (length(favorites) == 0L && length(recents) == 0L) return(NULL)
  if (is.null(leaves)) leaves <- menu_leaves(menu_tree())
  section <- function(title, commands) {
    commands <- commands[commands %in% leaves$command]
    if (length(commands) == 0L) return(NULL)
    htmltools::tags$details(
      class = "rcmdr-menu-group rcmdr-menu-shortcut-group", open = "open",
      htmltools::tags$summary(title),
      htmltools::tags$div(
        class = "rcmdr-menu-children",
        lapply(commands, function(command) {
          index <- match(command, leaves$command)
          row <- leaves[index, , drop = FALSE]
          htmltools::tags$div(
            class = "rcmdr-menu-row",
            menu_shortcut_link(row, row$label),
            menu_star_ui(row$command, row$command %in% favorites)
          )
        })
      )
    )
  }
  htmltools::tagList(
    htmltools::tags$div(
      class = "rcmdr-menu-shortcuts",
      section(tr("Favourites"), favorites),
      section(tr("Recent"), setdiff(recents, favorites))
    )
  )
}

#' All menu groups, for expand/collapse
#' @keywords internal
menu_group_ids <- function(tree = menu_tree()) {
  ids <- character()
  walk <- function(nodes) {
    for (node in nodes) {
      if (identical(node$type, "menu")) {
        ids <<- c(ids, node$id)
        walk(node$children)
      }
    }
  }
  walk(tree)
  ids
}
