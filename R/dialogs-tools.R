# Tools and file dialogs ----------------------------------------------------

#' Options dialog
#' @keywords internal
options_dialog <- function() {
  id <- "Options"
  ns <- function(x) paste0(id, "_", x)

  defaults <- list(
    digits = 7L,
    width = 80L,
    stringsAsFactors = TRUE,
    edit_threshold = 10000L,
    use_markdown = FALSE,
    use_knitr = FALSE,
    ui_mode = "studio",
    theme = "system",
    density = "compact",
    language = current_language()
  )

  dialog_spec(
    id = id,
    title = tr("Options"),
    help = "options",
    preview = FALSE,
    ui = function(state, memory) {
      m <- utils::modifyList(defaults, memory %||% list())

      settings_accordion(
        id = ns("settings"),
        open = "Interface",
        settings_panel(
          "Interface",
          segmented_input(
            ns("ui_mode"), tr("Interface mode"),
            c("Studio" = "studio", "Classic" = "classic"),
            m$ui_mode
          ),
          selectInput(
            ns("theme"), tr("Theme"),
            choices = theme_choices(),
            selected = m$theme %||% "system",
            width = "100%"
          ),
          selectInput(
            ns("language"), tr("Language"),
            choices = stats::setNames(
              available_languages(),
              toupper(available_languages())
            ),
            selected = m$language %||% current_language(),
            width = "100%"
          ),
          segmented_input(
            ns("density"), tr("Density"),
            ui_density_choices(),
            m$density %||% ui_density(state)
          ),
          help_text(tr(
            "Compact keeps more fields on the screen; Comfortable restores the wider spacing. Studio mode adds the Home, Charts and Console workspaces; Classic mode keeps the original tabs."
          ))
        ),
        settings_panel(
          "Output",
          number_input(ns("digits"), tr("Number of significant digits:"),
                       m$digits, min = 1, max = 22, step = 1),
          number_input(ns("width"), tr("Output width (characters):"),
                       m$width, min = 40, max = 300, step = 1)
        ),
        settings_panel(
          "Data",
          number_input(
            ns("edit_threshold"), tr("Maximum cells for interactive editing:"),
            m$edit_threshold, min = 0, max = 1e7, step = 1000
          ),
          switch_input(
            ns("stringsAsFactors"),
            tr("Convert character variables to factors when importing"),
            m$stringsAsFactors
          ),
          help_text(
            tr("The editing threshold applies to the active data set; set it to 0 to disable the editor.")
          )
        ),
        settings_panel(
          "Documents",
          switch_input(
            ns("use_markdown"), tr("Show the R Markdown document commands"),
            isTRUE(m$use_markdown)
          ),
          switch_input(
            ns("use_knitr"), tr("Show the knitr document commands"),
            isTRUE(m$use_knitr)
          ),
          help_text(tr(
            "The document commands are always available from the Script tab; these options keep the corresponding File and Edit entries visible after a restart."
          ))
        ),
        settings_panel(
          "Optional extensions",
          chart_ext_ui(heading = FALSE),
          grid = FALSE
        )
      )
    },
    on_ok = function(input, state) {
      digits <- as.integer(input[[ns("digits")]] %||% 7)
      width <- as.integer(input[[ns("width")]] %||% 80)
      threshold <- as.numeric(input[[ns("edit_threshold")]] %||% 10000)
      stringsAsFactors <- isTRUE(input[[ns("stringsAsFactors")]])

      # Inline errors: the runtime opens every accordion panel and focuses the
      # first invalid field, so a problem in a closed panel is never hidden.
      field_errors <- list()
      if (is.na(digits) || digits < 1 || digits > 22) {
        field_errors$digits <-
          tr("The number of digits must be between 1 and 22.")
      }
      if (is.na(width) || width < 40 || width > 300) {
        field_errors$width <-
          tr("The output width must be between 40 and 300.")
      }
      if (is.na(threshold) || threshold < 0) {
        field_errors$edit_threshold <-
          tr("The editing threshold cannot be negative.")
      }
      if (length(field_errors) > 0L) return(list(field_errors = field_errors))

      state$options$digits <- digits
      state$options$width <- width
      state$options$edit_threshold <- threshold
      state$options$stringsAsFactors <- stringsAsFactors
      state$options$use_markdown <- isTRUE(input[[ns("use_markdown")]])
      state$options$use_knitr <- isTRUE(input[[ns("use_knitr")]])
      state$options$ui_mode <- input[[ns("ui_mode")]] %||% "studio"
      state$options$theme <- input[[ns("theme")]] %||% "system"
      state$options$density <- set_ui_density(
        state, input[[ns("density")]] %||% ui_density(state)
      )
      language <- i18n_normalize(
        input[[ns("language")]] %||% current_language()
      )
      base::options(digits = digits, width = width)
      state_touch(state)

      if (!is.null(state$session)) {
        # The hidden preference inputs drive the existing observers: the Ace
        # editor follows the palette and the language observer refreshes the
        # menus and the help without duplicating that logic here.
        try(shiny::updateSelectInput(state$session, "theme",
                                     selected = state$options$theme),
            silent = TRUE)
        try(shiny::updateSelectInput(state$session, "language",
                                     selected = language),
            silent = TRUE)
        state$session$sendCustomMessage("rcmdr-theme", list(
          theme = state$options$theme,
          density = ui_density(state)
        ))
      }
      if (is.function(state$persist_preferences)) state$persist_preferences()

      list(
        memory = list(
          digits = digits, width = width,
          stringsAsFactors = stringsAsFactors,
          edit_threshold = threshold,
          ui_mode = state$options$ui_mode,
          theme = state$options$theme,
          density = ui_density(state),
          language = language
        )
      )
    }
  )
}

#' Change working directory dialog
#' @keywords internal
setwd_dialog <- function() {
  id <- "Setwd"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id,
    title = tr("Change working directory"),
    help = "setwd",
    ui = function(state, memory) {
      m <- utils::modifyList(list(path = getwd()), memory %||% list())
      htmltools::tagList(
        dir_input(ns("path"), tr("Working directory:"), m$path),
        help_text(tr("The command setwd() is added to the script."))
      )
    },
    observers = function(input, output, session, state, refresh) {
      roots <- c(home = "~", wd = getwd(), root = "/")
      dir_input_observers(
        input, session, ns("path"), roots,
        guard = function() identical(state$current_dialog, id)
      )
    },
    on_ok = function(input, state) {
      path <- trim_blanks(input[[ns("path")]] %||% "")
      if (!nzchar(path)) return(list(error = tr("You must select a directory.")))
      if (!dir.exists(path)) {
        return(list(error = sprintf(tr("Directory not found: %s"), path)))
      }
      path <- normalizePath(path, winslash = "/", mustWork = FALSE)
      list(
        commands = sprintf("setwd(%s)", quote_string(path)),
        memory = list(path = path)
      )
    }
  )
}

#' Open a script file dialog
#' @keywords internal
load_script_dialog <- function() {
  id <- "loadLog"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id,
    title = tr("Open Script File"),
    help = "source",
    ui = function(state, memory) {
      m <- utils::modifyList(list(path = ""), memory %||% list())
      htmltools::tagList(
        file_input(
          ns("path"), tr("Script file:"), m$path,
          placeholder = "/path/to/script.R",
          filetypes = c("R", "r", "txt")
        ),
        help_text(tr("The file replaces the contents of the Script tab."))
      )
    },
    observers = function(input, output, session, state, refresh) {
      roots <- c(home = "~", wd = getwd(), root = "/")
      file_input_observers(
        input, session, ns("path"), roots,
        guard = function() identical(state$current_dialog, id),
        filetypes = c("R", "r", "txt")
      )
    },
    on_ok = function(input, state) {
      path <- trim_blanks(input[[ns("path")]] %||% "")
      if (!nzchar(path)) return(list(error = tr("You must select a file.")))
      if (!file.exists(path)) {
        return(list(error = sprintf(tr("File not found: %s"), path)))
      }
      lines <- tryCatch(
        readLines(path, warn = FALSE, encoding = "UTF-8"),
        error = function(e) e
      )
      if (inherits(lines, "error")) {
        return(list(error = conditionMessage(lines)))
      }
      text <- paste(lines, collapse = "\n")
      document_set_text(state, text)
      document_set_mode(state, "r")
      list(
        script = text,
        memory = list(path = path)
      )
    }
  )
}

#' Load an R data file dialog
#' @keywords internal
load_dataset_dialog <- function() {
  id <- "loadDataSet"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id,
    title = tr("Load Data Set"),
    help = "load",
    ui = function(state, memory) {
      m <- utils::modifyList(
        list(path = "", name = ""),
        memory %||% list()
      )
      htmltools::tagList(
        file_input(
          ns("path"), tr("File path:"), m$path,
          placeholder = "/path/to/data.RData",
          filetypes = c("RData", "rda", "rds", "RDA", "RDATA", "RDS")
        ),
        entry_input(
          ns("name"), tr("Name for the data set (RDS files only):"), m$name,
          placeholder = "Dataset"
        ),
        help_text(tr(
          "RData/RDA files are loaded with load(); RDS files are read with readRDS() and assigned to the name you enter."
        ))
      )
    },
    observers = function(input, output, session, state, refresh) {
      roots <- c(home = "~", wd = getwd(), root = "/")
      file_input_observers(
        input, session, ns("path"), roots,
        guard = function() identical(state$current_dialog, id),
        filetypes = c("RData", "rda", "rds", "RDA", "RDATA", "RDS")
      )
    },
    on_ok = function(input, state) {
      path <- trim_blanks(input[[ns("path")]] %||% "")
      name <- trim_blanks(input[[ns("name")]] %||% "")
      if (!nzchar(path)) return(list(error = tr("You must select a file.")))
      if (!file.exists(path)) {
        return(list(error = sprintf(tr("File not found: %s"), path)))
      }

      extension <- tolower(tools::file_ext(path))

      if (identical(extension, "rds")) {
        object <- tryCatch(readRDS(path), error = function(e) e)
        if (inherits(object, "error")) {
          return(list(error = conditionMessage(object)))
        }
        if (!is.data.frame(object)) {
          return(list(error = tr("The RDS file does not contain a data frame.")))
        }
        if (!nzchar(name)) {
          name <- make.names(tools::file_path_sans_ext(basename(path)))
        }
        if (!is_valid_name(name)) {
          return(list(error = sprintf(tr('"%s" is not a valid name.'), name)))
        }
        if (exists(name, envir = state$env, inherits = FALSE)) {
          return(list(error = sprintf(
            tr("An object named '%s' already exists. Choose another name."), name
          )))
        }
        return(list(
          commands = sprintf("%s <- readRDS(%s)", name, quote_string(path)),
          activate_dataset = name,
          memory = list(path = path, name = name)
        ))
      }

      # RData / RDA: inspect the file first, then load it through run_command()
      # so that the operation is recorded in the script.
      probe <- new.env(parent = emptyenv())
      loaded <- tryCatch(
        load(path, envir = probe),
        error = function(e) e
      )
      if (inherits(loaded, "error")) {
        return(list(error = conditionMessage(loaded)))
      }
      objects <- loaded
      data_frames <- objects[vapply(objects, function(object) {
        is.data.frame(get(object, envir = probe))
      }, logical(1))]
      if (length(data_frames) == 0L) {
        return(list(error = tr("The file does not contain a data frame.")))
      }

      list(
        commands = sprintf("load(%s)", quote_string(path)),
        activate_dataset = data_frames[[1L]],
        memory = list(path = path, name = name)
      )
    }
  )
}
