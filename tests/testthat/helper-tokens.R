# Shared parsers for the design token tests ------------------------------------

token_css <- function() as.character(app_css())

palette_names <- c("light", "light-warm", "light-cool", "dark", "dark-dim",
                   "dark-graphite", "contrast")

# Each `body.rcmdr-<palette> { ... }` block as a named character vector of
# token values, keyed by the full custom property name.
palette_tokens <- function(css = token_css()) {
  blocks <- regmatches(
    css,
    gregexpr("body\\.rcmdr-[a-z-]+\\s*\\{[^}]*\\}", css, perl = TRUE)
  )[[1]]
  # TRE (the default engine) lets `.` cross newlines: the blocks are multiline.
  names <- sub("^body\\.rcmdr-([a-z-]+)\\s*\\{.*$", "\\1", blocks)
  keep <- names %in% palette_names
  blocks <- blocks[keep]
  names <- names[keep]
  values <- lapply(blocks, function(block) {
    pairs <- regmatches(
      block,
      gregexpr("--rcmdr-[a-z0-9-]+\\s*:\\s*[^;]+", block, perl = TRUE)
    )[[1]]
    keys <- trimws(sub("\\s*:.*$", "", pairs))
    stats::setNames(trimws(sub("^[^:]+:\\s*", "", pairs)), keys)
  })
  stats::setNames(values, names)
}

hex_to_rgb <- function(hex) {
  hex <- sub("^#", "", trimws(hex))
  if (nchar(hex) == 3L) {
    hex <- paste(rep(strsplit(hex, "")[[1]], each = 2L), collapse = "")
  }
  strtoi(substring(hex, c(1L, 3L, 5L), c(2L, 4L, 6L)), 16L) / 255
}

relative_luminance <- function(rgb) {
  channel <- ifelse(rgb <= 0.03928, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  sum(c(0.2126, 0.7152, 0.0722) * channel)
}

# WCAG 2.1 contrast ratio between two `#rrggbb` colours.
contrast_ratio <- function(fg, bg) {
  a <- relative_luminance(hex_to_rgb(fg))
  b <- relative_luminance(hex_to_rgb(bg))
  (max(a, b) + 0.05) / (min(a, b) + 0.05)
}
