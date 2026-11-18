# Shared UI components -------------------------------------------------------
#
# Small, dependency-free components used by the Studio shell.  They are kept
# deliberately thin: the visual identity lives in app_css(), the components
# wrap the markup and the Bootstrap classes.

#' A compact status pill
#' @keywords internal
status_pill <- function(label, status = c("ok", "warning", "error", "muted")) {
  status <- match.arg(status)
  htmltools::tags$span(class = paste0("rcmdr-status-pill rcmdr-status-", status),
                       label)
}

#' An empty-state block
#' @keywords internal
empty_state <- function(title, message = NULL, action = NULL) {
  htmltools::tags$div(
    class = "rcmdr-empty",
    htmltools::tags$div(class = "rcmdr-empty-title", title),
    if (!is.null(message)) htmltools::tags$p(class = "rcmdr-empty-text", message),
    action
  )
}

#' A metric card
#' @keywords internal
metric_card <- function(label, value, help = NULL) {
  htmltools::tags$div(
    class = "rcmdr-metric",
    htmltools::tags$div(class = "rcmdr-metric-label", label),
    htmltools::tags$div(class = "rcmdr-metric-value", value),
    if (!is.null(help)) htmltools::tags$div(class = "rcmdr-metric-help", help)
  )
}

#' A section card
#' @keywords internal
section_card <- function(title, body, collapsed = FALSE) {
  htmltools::tags$details(
    class = "rcmdr-section-card",
    open = if (isTRUE(collapsed)) NULL else "open",
    htmltools::tags$summary(title),
    htmltools::tags$div(class = "rcmdr-section-body", body)
  )
}

#' A collapsible group of settings
#'
#' Wraps [bslib::accordion()] with the Studio contract: one class, one heading
#' role per panel header (bslib emits a `div`) and a stable id when the server
#' needs to read which panels are open.  The heading semantics are what makes
#' the control navigable: a screen reader announces "Options, heading level 3,
#' collapsed, button".
#'
#' @param id Optional Shiny input id; it receives the open panel values.
#' @param ... Panels built with [settings_panel()].
#' @param open Panel values to open initially, or `TRUE` to open all.
#' @param multiple Allow more than one panel open at a time.
#' @param level Heading level, 1–6.  Dialogs usually want 3.
#' @param class Extra classes for the accordion.
#' @return A `<div>` tag.
#' @keywords internal
settings_accordion <- function(..., id = NULL, open = NULL, multiple = TRUE,
                               level = 3L, class = NULL) {
  level <- as.integer(level %||% 3L)[[1L]]
  if (is.na(level) || level < 1L || level > 6L) {
    stop("settings_accordion() level must be between 1 and 6.", call. = FALSE)
  }
  accordion <- bslib::accordion(
    ..., id = id, open = open, multiple = isTRUE(multiple),
    class = c("rcmdr-accordion", class)
  )

  items <- htmltools::tagQuery(accordion)$find(".accordion-item")$selectedTags()
  values <- vapply(items, function(item) {
    as.character(item$attribs$`data-value` %||% "")
  }, character(1))
  if (anyDuplicated(values)) {
    stop("settings_accordion() panel values must be unique.", call. = FALSE)
  }
  if (is.character(open)) {
    missing <- setdiff(open, values)
    if (length(missing) > 0L) {
      stop("settings_accordion() open values are not panels: ",
           paste(missing, collapse = ", "), call. = FALSE)
    }
  }

  htmltools::tagQuery(accordion)$
    find(".accordion-header")$
    each(function(header, i) {
      htmltools::tagAppendAttributes(
        header, role = "heading", `aria-level` = as.character(level)
      )
    })$
    allTags()
}

#' One panel of a settings accordion
#'
#' The title is a plain string when possible, so bslib can use it as the panel
#' value; pass `value` explicitly when the title needs markup.  The body is
#' wrapped in the shared field grid unless `grid = FALSE`.
#'
#' @param title Visible title, plain text or tags.
#' @param ... Body content.
#' @param value Unique panel value.  Defaults to `title` when it is a string.
#' @param icon Optional icon name from [rcmdr_icon_paths()].
#' @param badge Optional badge label (or a ready badge tag).
#' @param grid Wrap the body in [field_grid()].
#' @return A `bslib_accordion_panel`.
#' @keywords internal
settings_panel <- function(title, ..., value = NULL, icon = NULL,
                           badge = NULL, grid = TRUE) {
  if (is.null(value)) {
    if (!is.character(title) || length(title) != 1L || !nzchar(title)) {
      stop("settings_panel() needs a plain `value` when the title is markup.",
           call. = FALSE)
    }
    value <- title
  }
  body <- htmltools::tagList(...)
  if (isTRUE(grid)) body <- field_grid(body)

  heading <- htmltools::tagList(
    if (!is.null(icon)) {
      htmltools::tags$span(
        class = "rcmdr-accordion-icon", rcmdr_icon(icon, 16)
      )
    },
    htmltools::tags$span(class = "rcmdr-accordion-title", title),
    if (!is.null(badge)) settings_badge(badge)
  )

  bslib::accordion_panel(title = heading, body, value = value)
}

#' @keywords internal
settings_badge <- function(badge) {
  if (is.character(badge)) badge(badge) else badge
}

#' A titled group inside a panel
#'
#' Not collapsible: it gives a hierarchy to a long panel without nesting one
#' accordion inside another.  Use it for the semantic groups that share a
#' panel.
#'
#' @param title Group title.
#' @param ... Fields.
#' @param help Optional note under the fields.
#' @return A `<div>` tag.
#' @keywords internal
settings_group <- function(title, ..., help = NULL) {
  htmltools::div(
    class = "rcmdr-settings-group",
    htmltools::tags$div(
      class = "rcmdr-settings-group-title",
      role = "heading", `aria-level` = "4", title
    ),
    field_grid(...),
    if (!is.null(help)) htmltools::tags$p(class = "form-text", help)
  )
}

#' A read-only code preview
#' @keywords internal
code_preview <- function(code, language = "r", copy = TRUE) {
  code <- paste(code %||% "", collapse = "\n")
  htmltools::tags$div(
    class = "rcmdr-code-preview",
    htmltools::tags$pre(
      class = "rcmdr-code",
      htmltools::tags$code(`data-language` = language, code)
    ),
    if (isTRUE(copy) && nzchar(code)) {
      htmltools::tags$button(
        type = "button", class = "btn btn-sm btn-outline-secondary rcmdr-copy",
        `data-rcmdr-copy` = code,
        onclick = "rcmdrCopy(this.getAttribute('data-rcmdr-copy')); return false;",
        tr("Copy")
      )
    }
  )
}

#' A two-column split view
#' @keywords internal
split_view <- function(left, right, proportions = c(2, 3)) {
  proportions <- rep_len(proportions, 2L)
  total <- sum(proportions)
  widths <- round(12 * proportions / total)
  htmltools::tags$div(
    class = "row g-3 rcmdr-split",
    htmltools::tags$div(class = paste0("col-lg-", widths[[1L]]), left),
    htmltools::tags$div(class = paste0("col-lg-", widths[[2L]]), right)
  )
}

#' Two panes with a keyboard-accessible separator
#'
#' The desktop counterpart of [split_view()]: the user can move the divider
#' with the pointer or with the arrow keys, and the size is written to the
#' session preferences.  `orientation = "horizontal"` places the panes side by
#' side and draws a vertical separator; `"vertical"` stacks them.
#'
#' The separator follows the WAI-ARIA window splitter pattern: `role` is
#' `separator`, the arrows move it, `Home` and `End` go to the minimum and the
#' maximum, and `Enter`, `Space` or a double click restore the initial size.
#' At the layout breakpoints the panes collapse to one column and the separator
#' leaves the tab order, so a 200% zoom has nothing to drag.
#'
#' @param id Stable id, also the key of the saved size.
#' @param first,second Pane content.
#' @param orientation `"horizontal"` (side by side) or `"vertical"`.
#' @param initial Initial share of the first pane, 0–1.
#' @param min Minimum width (or height) of the first pane, in pixels.
#' @param min_second Minimum size of the second pane, in pixels; used by the
#'   client when it clamps a drag.
#' @param class Extra classes for the grid container.
#' @param label Accessible name of the separator.
#' @return A `<div>` tag.
#' @keywords internal
split_pane <- function(id, first, second,
                       orientation = c("horizontal", "vertical"),
                       initial = 0.5, min = 260, min_second = 260,
                       class = NULL, label = tr("Resize panels")) {
  orientation <- match.arg(orientation)
  ratio <- layout_initial(id, initial)
  pct <- round(ratio * 100, 2)
  aria_orientation <- if (identical(orientation, "horizontal")) {
    "vertical"
  } else {
    "horizontal"
  }
  first_id <- paste0("rcmdr-split-first-", id)
  second_id <- paste0("rcmdr-split-second-", id)
  htmltools::div(
    id = paste0(id, "_split"),
    class = c("rcmdr-splitter", paste0("rcmdr-splitter-", orientation), class),
    style = sprintf(
      "--rcmdr-split-first: %.2f%%; --rcmdr-split-min: %dpx;",
      pct, as.integer(min)
    ),
    `data-rcmdr-split` = id,
    `data-rcmdr-split-orientation` = orientation,
    htmltools::div(
      id = first_id, class = "rcmdr-splitter-pane rcmdr-splitter-first", first
    ),
    htmltools::div(
      class = "rcmdr-splitter-divider",
      role = "separator",
      tabindex = "0",
      `aria-orientation` = aria_orientation,
      `aria-label` = label,
      `aria-controls` = paste(first_id, second_id),
      `aria-valuemin` = "10",
      `aria-valuemax` = "90",
      `aria-valuenow` = sprintf("%.0f", pct),
      `aria-valuetext` = sprintf("%.0f%%", pct),
      `data-rcmdr-split-input` = paste0(id, "_size"),
      `data-rcmdr-split-default` = sprintf("%.2f", round(initial * 100, 2)),
      `data-rcmdr-split-min` = as.character(as.integer(min)),
      `data-rcmdr-split-min-second` = as.character(as.integer(min_second)),
      htmltools::tags$span(class = "rcmdr-splitter-grip", `aria-hidden` = "true")
    ),
    htmltools::div(
      id = second_id, class = "rcmdr-splitter-pane rcmdr-splitter-second", second
    )
  )
}

#' Wire a split pane to the session preferences
#'
#' The client sends the new share on pointer release and on every arrow key;
#' the server validates it, stores it under `state$options$layouts` and asks
#' the app to persist.  Sizes are preferences, not project state: they do not
#' make a project dirty.
#'
#' @param id Split pane id used in [split_pane()].
#' @param input Shiny input.
#' @param state Application state.
#' @param persist Optional callback that writes the preferences file.
#' @return Invisibly, `NULL`.
#' @keywords internal
split_pane_server <- function(id, input, state, persist = NULL) {
  key <- paste0(id, "_size")
  shiny::observeEvent(input[[key]], {
    value <- layout_ratio(input[[key]])
    if (is.null(value)) return()
    layout_set(state, id, value)
    if (is.function(persist)) persist()
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  invisible(NULL)
}

#' Every split pane the application wires up
#' @keywords internal
split_pane_ids <- function() {
  c(
    "data_layout",
    "chart_layout",
    "report_outline_layout",
    "report_editor_layout"
  )
}

#' A studio toolbar
#'
#' A single row of filters and actions.  `left` and `right` are the two ends of
#' the bar; unnamed children go in the middle.  Named, it is announced as a
#' toolbar; unnamed, it is a plain group of controls.
#' @keywords internal
toolbar <- function(..., left = NULL, right = NULL, label = NULL) {
  htmltools::tags$div(
    class = "rcmdr-toolbar",
    role = if (is.null(label)) NULL else "toolbar",
    `aria-label` = label,
    left,
    ...,
    if (!is.null(right)) {
      htmltools::tags$div(class = "rcmdr-toolbar-end", right)
    }
  )
}

#' @keywords internal
studio_toolbar <- function(..., left = NULL, right = NULL, label = NULL) {
  toolbar(..., left = left, right = right, label = label)
}

#' A card heading with an optional end slot
#'
#' The heading of a card or of a small view: the title on the left, one
#' control or badge on the right.  It wraps as a unit, so a long title never
#' pushes the end slot off the card.
#' @keywords internal
card_head <- function(title, aside = NULL) {
  htmltools::tags$div(
    class = "rcmdr-card-head",
    title,
    if (!is.null(aside)) aside
  )
}

#' A wrapped row of actions
#'
#' The buttons of a card or a view travel together: they wrap as a group and
#' the gap is the spacing token.  `tight` is the compact row used inside a
#' card, where a full step of space would break the column rhythm.
#' @keywords internal
action_row <- function(..., tight = FALSE) {
  htmltools::tags$div(
    class = c("rcmdr-actions",
              if (isTRUE(tight)) "rcmdr-actions-tight"),
    ...
  )
}

#' A muted note
#'
#' One sentence of secondary text under a heading or beside a value.  It is the
#' view counterpart of `help_text()`: the same muted colour and small step,
#' without the form-group margins.
#' @keywords internal
note <- function(..., inline = FALSE) {
  tag <- if (isTRUE(inline)) htmltools::tags$span else htmltools::tags$p
  tag(
    class = if (isTRUE(inline)) {
      "rcmdr-note rcmdr-note-inline"
    } else {
      "rcmdr-note"
    },
    ...
  )
}

#' A short parameter tip
#'
#' A small question-mark button with a tooltip.  The trigger is a real
#' `<button>`, so it is reachable with `Tab` and the tip opens on focus as well
#' as on hover; `40-interactions.js` closes it with `Esc` without closing the
#' surrounding dialog.  It complements [help_text()]: use a tip for a parameter
#' that has no room for a permanent line of help, not for text that must always
#' be visible.
#'
#' @param text Explanation, already translated.
#' @param label Accessible name of the trigger.
#' @param placement One of `"top"`, `"right"`, `"bottom"`, `"left"`, `"auto"`.
#' @return A `<span>` wrapping a `bslib-tooltip` element.
#' @keywords internal
help_tip <- function(text, label = tr("More information"),
                     placement = c("top", "right", "bottom", "left", "auto")) {
  placement <- match.arg(placement)
  htmltools::tags$span(
    class = "rcmdr-help-tip",
    bslib::tooltip(
      htmltools::tags$button(
        type = "button",
        class = "rcmdr-help-tip-trigger",
        `aria-label` = label,
        rcmdr_icon("help", 14)
      ),
      text,
      placement = placement
    )
  )
}

#' A status badge
#'
#' A short label with a semantic colour.  The colour is never the only signal:
#' the label itself says what the state is, and the icon is decorative.
#'
#' @param label Visible text.
#' @param status One of `neutral`, `ok`, `warning`, `error`, `info`.
#' @param icon Optional icon name from [rcmdr_icon_paths()].
#' @param title Optional tooltip.
#' @return A `<span>` tag.
#' @keywords internal
badge <- function(label, status = c("neutral", "ok", "warning", "error", "info"),
                  icon = NULL, title = NULL) {
  status <- match.arg(status)
  htmltools::tags$span(
    class = paste0("rcmdr-badge rcmdr-badge-", status),
    title = title,
    if (!is.null(icon)) rcmdr_icon(icon, size = 12),
    label
  )
}

#' Dialog header
#'
#' The full `.modal-header` of a dialog: icon chip, title, category and the
#' close button.  It is injected into Shiny's own modal shell by
#' [modal_shell()], which is how the dialogs that are not in the catalogue get
#' the shared chrome; [shiny::modalDialog()] keeps its plain header otherwise.
#' @keywords internal
modal_header <- function(title, category = NULL, icon = NULL, close = TRUE,
                         close_label = tr("Close"), id = NULL) {
  htmltools::tags$div(
    class = "modal-header rcmdr-modal-header",
    if (!is.null(icon)) {
      htmltools::tags$span(class = "rcmdr-dialog-icon", rcmdr_icon(icon, 18))
    },
    htmltools::tags$div(
      class = "rcmdr-modal-heading",
      htmltools::tags$h4(class = "modal-title", id = id, title),
      if (!is.null(category) && nzchar(category)) {
        htmltools::tags$div(class = "rcmdr-dialog-category", category)
      }
    ),
    if (isTRUE(close)) {
      htmltools::tags$button(
        type = "button", class = "btn-close",
        `data-bs-dismiss` = "modal", `aria-label` = close_label
      )
    }
  )
}

#' Dialog footer
#'
#' The actions of a dialog.  The primary action is passed separately and
#' lands on the right, the way the eye reads a form: decide, then apply.
#' @keywords internal
modal_footer <- function(..., primary = NULL) {
  htmltools::tags$div(
    class = "modal-footer rcmdr-modal-footer",
    ...,
    if (!is.null(primary)) {
      htmltools::tags$div(class = "rcmdr-modal-primary", primary)
    }
  )
}

#' A dismiss button for a modal footer
#'
#' [shiny::modalButton()] writes the Bootstrap dismiss attributes but not a
#' size class, so a footer that mixes it with `btn-sm` actions has two heights.
#' This button carries both dismiss attributes (Bootstrap 4 and 5, as Shiny
#' does) and takes the same classes as its neighbours.
#' @keywords internal
modal_dismiss_button <- function(label = tr("Close"),
                                 class = "btn-sm btn-outline-secondary") {
  htmltools::tags$button(
    type = "button", class = c("btn", class),
    `data-dismiss` = "modal", `data-bs-dismiss` = "modal", label
  )
}

#' A Shiny modal with the shared chrome
#'
#' [shiny::modalDialog()] owns the shell — the id, the backdrop, the fade, the
#' size and the initialisation script — and writes its own plain header and
#' footer.  This helper keeps that shell and swaps the chrome: the header is
#' [modal_header()] and the footer is [modal_footer()].  The dialogs that are
#' not in the catalogue (palette, shortcuts, tour, project recovery) use it so
#' they read like every other dialog without giving up what Shiny's shell does.
#'
#' @param title Dialog title.
#' @param ... Body content.
#' @param category Small line under the title (the tour step, a family name).
#' @param icon Icon name from [rcmdr_icon_paths()].
#' @param footer Footer actions, in DOM order.
#' @param primary Actions grouped at the end of the footer.
#' @param size One of `"s"`, `"m"`, `"l"`, `"xl"`.
#' @param easyClose Let Esc and the backdrop close the dialog.
#' @param close Show the header close button.  Leave it off when the dialog
#'   wants an explicit decision, as the catalogue dialogs do.
#' @param close_label Accessible name of the close button.
#' @param id Id of the title element, used by `aria-labelledby`.
#' @return A modal dialog, ready for [shiny::showModal()].
#' @keywords internal
modal_shell <- function(title, ..., category = NULL, icon = NULL,
                        footer = NULL, primary = NULL,
                        size = c("m", "s", "l", "xl"), easyClose = FALSE,
                        close = FALSE, close_label = tr("Close"),
                        id = "rcmdr-modal-title") {
  size <- match.arg(size)
  body <- htmltools::tagList(...)
  header <- modal_header(title, category = category, icon = icon,
                         close = close, close_label = close_label, id = id)
  foot <- if (is.null(footer) && is.null(primary)) {
    NULL
  } else {
    modal_footer(footer, primary = primary)
  }
  # Shiny owns the shell; the header replaces the bare title, the footer
  # replaces the plain row, and the body keeps its scroll area.
  shell <- shiny::modalDialog(
    title = NULL, footer = NULL, size = size, easyClose = easyClose, body
  )
  shell <- htmltools::tagAppendAttributes(shell, `aria-labelledby` = id)
  query <- htmltools::tagQuery(shell)$find(".modal-content")$prepend(header)
  if (!is.null(foot)) query <- query$append(foot)
  query$allTags()
}

#' Tab strip
#'
#' A row of small tabs for hand-built views.  Each tab is a toggle button
#' (`aria-pressed`), not an ARIA tab, because the component does not implement
#' the arrow-key navigation the tab pattern promises.  With `payload = TRUE`
#' the input receives `{id, action}`, which is what a strip with close buttons
#' needs; otherwise it receives the value alone, the contract the simpler
#' consumers already use.
#'
#' @param id Shiny input to update.
#' @param tabs Named character vector: label = value.  The names are also the
#'   accessible names of the close buttons when `closable = TRUE`.
#' @param selected Value of the active tab.  Defaults to the first.
#' @param label Accessible name for the strip.
#' @param labels Optional list of tags, one per tab, when the label needs
#'   markup (a mode chip, a title, ...).  The names of `tabs` still provide
#'   the plain text.
#' @param payload When `TRUE`, send `{id, action}` instead of the bare value.
#' @param closable Add a close button to each tab.
#' @param close_label Accessible prefix for the close buttons.
#' @param trailing Optional tag after the last tab (a "new" button).
#' @param class Extra classes for the strip, for a component that builds on it.
#' @return A `<div>` tag, or `NULL` when `tabs` is empty.
#' @keywords internal
tabs_strip <- function(id, tabs, selected = NULL, label = NULL,
                       labels = NULL, payload = FALSE, closable = FALSE,
                       close_label = tr("Close"), trailing = NULL,
                       menus = NULL, class = NULL) {
  if (length(tabs) == 0L) return(NULL)
  if (is.null(names(tabs)) || any(!nzchar(names(tabs)))) {
    stop("tabs_strip() needs a named character vector: label = value.",
         call. = FALSE)
  }
  values <- unname(as.character(tabs))
  invalid <- !grepl("^[A-Za-z0-9_.-]+$", c(id, values))
  if (any(invalid)) {
    stop("tabs_strip() ids and values must be simple identifiers.",
         call. = FALSE)
  }
  if (!is.null(labels) && length(labels) != length(values)) {
    stop("tabs_strip() needs one label per tab.", call. = FALSE)
  }
  if (!is.null(menus) && length(menus) != length(values)) {
    stop("tabs_strip() needs one menu per tab.", call. = FALSE)
  }
  selected <- selected %||% values[[1L]]
  callback <- function(value, action) {
    if (isTRUE(payload)) {
      sprintf(
        "Shiny.setInputValue('%s', {id: '%s', action: '%s'}, {priority: 'event'});",
        id, value, action
      )
    } else {
      sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'});",
              id, value)
    }
  }
  htmltools::tags$div(
    class = c("rcmdr-tabs", class), role = "group", `aria-label` = label,
    lapply(seq_along(values), function(i) {
      active <- identical(values[[i]], selected)
      content <- if (is.null(labels)) names(tabs)[[i]] else labels[[i]]
      menu_tag <- if (is.null(menus)) NULL else menus[[i]]
      menu_id <- if (is.null(menu_tag)) NULL else menu_tag$attribs$id
      htmltools::tags$span(
        class = c("rcmdr-tabs-item", if (active) "active"),
        `data-value` = values[[i]],
        htmltools::tags$button(
          type = "button",
          class = "rcmdr-tabs-button",
          `aria-pressed` = if (active) "true" else "false",
          `data-rcmdr-context-menu` = menu_id,
          `data-rcmdr-menu-payload` =
            if (is.null(menu_id)) NULL else sprintf('{"id":"%s"}', values[[i]]),
          `aria-haspopup` = if (is.null(menu_id)) NULL else "menu",
          `aria-expanded` = if (is.null(menu_id)) NULL else "false",
          onclick = callback(values[[i]], "activate"),
          content
        ),
        if (isTRUE(closable)) {
          htmltools::tags$button(
            type = "button", class = "rcmdr-doc-close",
            title = close_label,
            `aria-label` = sprintf("%s %s", close_label, names(tabs)[[i]]),
            onclick = callback(values[[i]], "close"),
            "\u00d7"
          )
        },
        menu_tag
      )
    }),
    trailing
  )
}

#' A desktop context menu
#'
#' A hidden `role="menu"` panel.  The items inside are
#' [context_menu_item()] entries; the panel is opened by a target built with
#' [context_menu_target()], by the context-menu key, or by `Shift`+`F10`.
#' `40-interactions.js` keeps one menu open at a time, positions it inside the
#' viewport and returns the focus to the target when it closes.
#'
#' @param id Menu id, referenced by the target.
#' @param ... Items and separators.
#' @param label Accessible name of the menu.
#' @param class Extra classes.
#' @return A `<div>` tag.
#' @keywords internal
context_menu <- function(id, ..., label = tr("Actions"), class = NULL) {
  htmltools::div(
    id = id,
    class = c("rcmdr-context-menu", class),
    role = "menu",
    `aria-label` = label,
    tabindex = "-1",
    hidden = "hidden",
    ...
  )
}

#' One item of a context menu
#'
#' `click` names an existing action input (or any clickable element) and
#' clicks it, so the menu never carries a second implementation of an action.
#' `input` and `action` send the action to a Shiny input that already handles
#' it; the target supplies the rest of the payload through
#' [context_menu_target()].
#'
#' @param label Visible text.
#' @param click Optional id of the element to click.
#' @param input Optional Shiny input to update.
#' @param action Optional action name added to the payload.
#' @param danger Use the danger colour.
#' @param disabled Announce and draw the item as unavailable.
#' @return A `<button>` tag.
#' @keywords internal
context_menu_item <- function(label, click = NULL, input = NULL, action = NULL,
                              danger = FALSE, disabled = FALSE) {
  htmltools::tags$button(
    type = "button",
    class = c("rcmdr-context-menu-item",
              if (isTRUE(danger)) "rcmdr-context-menu-danger"),
    role = "menuitem",
    tabindex = "-1",
    `data-rcmdr-menu-click` = click,
    `data-rcmdr-menu-input` = input,
    `data-rcmdr-menu-action` = action,
    `aria-disabled` = if (isTRUE(disabled)) "true" else NULL,
    label
  )
}

#' A separator between context-menu groups
#' @keywords internal
context_menu_separator <- function() {
  htmltools::div(
    class = "rcmdr-context-menu-separator", role = "separator",
    `aria-hidden` = "true"
  )
}

#' Mark a region as the target of a context menu
#'
#' The target is focusable, so the menu is reachable without a pointer:
#' `Shift`+`F10` or the context-menu key opens it from the keyboard.  `payload`
#' is a JSON object the items merge with their own action; it is how one menu
#' can serve many cards without repeating the handlers.
#'
#' @param ... Content.
#' @param menu Menu id from [context_menu()].
#' @param payload JSON object with the target data.
#' @param label Accessible name of the target.
#' @param class Extra classes.
#' @param tag Tag to build, a `<div>` by default.
#' @param extra Named list of extra attributes.
#' @return A tag.
#' @keywords internal
context_menu_target <- function(..., menu, payload = "{}", label = NULL,
                                class = NULL,
                                tag = htmltools::tags$div,
                                extra = list()) {
  do.call(tag, c(
    list(
      class = c("rcmdr-context-target", class),
      tabindex = "0",
      `data-rcmdr-context-menu` = menu,
      `data-rcmdr-menu-payload` = payload,
      `aria-haspopup` = "menu",
      `aria-expanded` = "false",
      `aria-label` = label
    ),
    list(...),
    extra
  ))
}

#' A compact breadcrumb
#' @keywords internal
studio_breadcrumb <- function(parts) {
  parts <- parts[nzchar(parts)]
  if (length(parts) == 0L) return(NULL)
  htmltools::tags$nav(
    class = "rcmdr-breadcrumb", `aria-label` = tr("Breadcrumb"),
    htmltools::tags$ol(
      class = "breadcrumb mb-0",
      lapply(seq_along(parts), function(i) {
        htmltools::tags$li(
          class = paste("breadcrumb-item", if (i == length(parts)) "active"),
          parts[[i]]
        )
      })
    )
  )
}

# Icons ---------------------------------------------------------------------
#
# Dependency-free 24x24 stroke icons, drawn with the current text colour.  The
# names describe the role, not the drawing, so the set can be replaced without
# touching the callers.

#' Icon paths
#'
#' Named list of SVG children, one entry per icon. Each path is a string of
#' `<path>`, `<line>`, `<rect>` or `<circle>` elements in a 24x24 viewBox.
#'
#' @return A named list of character strings.
#' @keywords internal
rcmdr_icon_paths <- function() {
  list(
    sliders = paste0(
      '<line x1="4" y1="7" x2="20" y2="7"/>',
      '<line x1="4" y1="12" x2="20" y2="12"/>',
      '<line x1="4" y1="17" x2="20" y2="17"/>',
      '<circle cx="9" cy="7" r="2.1" fill="currentColor" stroke="none"/>',
      '<circle cx="15" cy="12" r="2.1" fill="currentColor" stroke="none"/>',
      '<circle cx="8" cy="17" r="2.1" fill="currentColor" stroke="none"/>'
    ),
    output = paste0(
      '<rect x="3" y="4" width="18" height="16" rx="2.5"/>',
      '<path d="M7 9h5M7 13h10M7 17h4"/>'
    ),
    chart = paste0(
      '<path d="M4 20h16"/>',
      '<path d="M7 20v-6M12 20V6M17 20v-9"/>'
    ),
    table = paste0(
      '<rect x="3" y="4" width="18" height="16" rx="2.5"/>',
      '<path d="M3 10h18M9.5 10v10"/>'
    ),
    doc = paste0(
      '<path d="M6 3.5h7.5L18 8v12.5H6z"/>',
      '<path d="M13.5 3.5V8H18"/>',
      '<path d="M9 12.5h6M9 16h6"/>'
    ),
    sun = paste0(
      '<circle cx="12" cy="12" r="4"/>',
      '<path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2',
      'M5.2 5.2l1.4 1.4M17.4 17.4l1.4 1.4',
      'M18.8 5.2l-1.4 1.4M6.6 17.4l-1.4 1.4"/>'
    ),
    moon = '<path d="M20.5 14.2A8.7 8.7 0 0 1 9.8 3.5a8.7 8.7 0 1 0 10.7 10.7z"/>',
    close = '<path d="M6 6l12 12M18 6L6 18"/>',
    help = paste0(
      '<circle cx="12" cy="12" r="9"/>',
      '<path d="M9.6 9.4a2.5 2.5 0 1 1 3.6 2.3c-.8.5-1.2 1-1.2 1.9"/>',
      '<circle cx="12" cy="17" r=".9" fill="currentColor" stroke="none"/>'
    ),
    code = '<path d="M8.5 6.5L3 12l5.5 5.5M15.5 6.5L21 12l-5.5 5.5"/>',
    chevron = '<path d="M6 9.5l6 6 6-6"/>',
    check = '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    copy = paste0(
      '<rect x="8" y="8" width="12" height="12" rx="2"/>',
      '<path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>'
    ),
    refresh = '<path d="M20 11a8 8 0 1 0-.6 4"/><path d="M20 4.5V11h-6"/>',
    search = '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4 4"/>',
    plus = '<path d="M12 5v14M5 12h14"/>',
    minus = '<path d="M5 12h14"/>'
  )
}

#' Inline SVG icon
#'
#' @param name One of `names(rcmdr_icon_paths())`.
#' @param size Square size in pixels.
#' @param title Accessible name. When `NULL` the icon is decorative: it is
#'   hidden from assistive technology and the surrounding text carries the
#'   meaning.
#' @return An `<svg>` tag.
#' @keywords internal
rcmdr_icon <- function(name, size = 16, title = NULL) {
  paths <- rcmdr_icon_paths()
  name <- match.arg(name, names(paths))
  size <- as.integer(size %||% 16L)[[1L]]
  htmltools::tags$svg(
    xmlns = "http://www.w3.org/2000/svg",
    class = "rcmdr-icon",
    width = size, height = size, viewBox = "0 0 24 24",
    fill = "none", stroke = "currentColor", `stroke-width` = 1.7,
    `stroke-linecap` = "round", `stroke-linejoin` = "round",
    focusable = "false",
    role = if (is.null(title)) NULL else "img",
    `aria-hidden` = if (is.null(title)) "true" else NULL,
    `aria-label` = title,
    htmltools::HTML(paths[[name]])
  )
}
