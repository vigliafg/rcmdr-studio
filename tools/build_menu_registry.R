#!/usr/bin/env Rscript
# Generate the first version of the stable menu registry from the legacy
# Rcmdr menu files.
#
# The generated files are a starting point: curation of labels, order and
# grouping continues in inst/menus/core.yml and the module fragments.
#
# Usage:
#   Rscript tools/build_menu_registry.R
#   Rscript tools/build_menu_registry.R --check

script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  hit <- grep("^--file=", args, value = TRUE)
  if (length(hit) == 0L) return("tools")
  dirname(normalizePath(sub("^--file=", "", hit[[1L]])))
}

root <- normalizePath(file.path(script_path(), ".."), mustWork = TRUE)
if (!dir.exists(file.path(root, "R"))) {
  stop("Run this script from the package root.", call. = FALSE)
}
pkgload::load_all(root, quiet = TRUE)

check_only <- "--check" %in% commandArgs(trailingOnly = TRUE)

core <- read_rcmdr_menus(file.path(root, "inst", "etc", "Rcmdr-menus.txt"))
core_registry <- menu_registry_from_legacy(core, module = "core")
core_registry <- menu_registry_curate(core_registry)
core_validation <- menu_registry_validate(core_registry)
if (!core_validation$ok) {
  stop("Core registry is invalid:\n",
       paste0("  - ", core_validation$problems, collapse = "\n"), call. = FALSE)
}

core_ids <- stats::setNames(
  vapply(core_registry$groups, function(group) group$id, character(1)),
  vapply(core_registry$groups, function(group) {
    legacy <- group$legacy_ids %||% character()
    if (length(legacy) == 0L) "" else legacy[[1L]]
  }, character(1))
)
core_ids <- core_ids[nzchar(names(core_ids))]
core_groups <- names(core_registry$groups)

core_dir <- file.path(root, "inst", "menus")
dir.create(core_dir, recursive = TRUE, showWarnings = FALSE)
core_file <- file.path(core_dir, "core.yml")
core_yaml <- menu_registry_to_yaml(core_registry, module = "core")

plugin_root <- file.path(root, "plugins")
plugins <- list.dirs(plugin_root, recursive = FALSE, full.names = TRUE)
plugins <- plugins[file.exists(file.path(plugins, "DESCRIPTION"))]

module_files <- character()
for (plugin in plugins) {
  menu_file <- file.path(plugin, "inst", "etc", "rcmdrshiny-menus.txt")
  if (!file.exists(menu_file)) next
  module <- sub("^RcmdrShinyPlugin\\.", "", basename(plugin))
  module <- tolower(gsub("[^A-Za-z0-9]+", "_", module))
  definitions <- read_rcmdr_menus(menu_file)
  registry <- menu_registry_from_legacy(
    definitions, module = module,
    known_ids = core_ids, known_groups = core_groups
  )
  validation <- menu_registry_validate(registry, known_groups = core_groups)
  if (!validation$ok) {
    warning(sprintf("Module '%s' has registry problems:\n%s", module,
                    paste0("  - ", validation$problems, collapse = "\n")),
            call. = FALSE)
  }
  out_dir <- file.path(plugin, "inst", "menus")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_file <- file.path(out_dir, "module.yml")
  module_files <- c(module_files, out_file)
  if (!check_only) {
    writeLines(menu_registry_to_yaml(registry, module = module), out_file)
  }
  cat(sprintf("Module %-14s groups %3d items %3d removes %d\n", module,
              length(registry$groups), length(registry$items),
              length(registry$removes)))
}

if (!check_only) {
  writeLines(core_yaml, core_file)
}

cat(sprintf("Core groups: %d, items: %d, removes: %d\n",
            length(core_registry$groups), length(core_registry$items),
            length(core_registry$removes)))
cat("Top-level groups:\n")
top <- Filter(function(group) is.null(group$parent), core_registry$groups)
for (group in top) {
  cat(sprintf("  %-24s %s\n", group$id, group$label))
}
cat(sprintf("%s %s\n", if (check_only) "Checked" else "Wrote", core_file))
if (!check_only) cat("Wrote", length(module_files), "module files\n")
