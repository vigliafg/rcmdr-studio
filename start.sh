#!/usr/bin/env bash
#
# Launch RcmdrShiny Studio from this working copy.
#
#   ./start.sh
#
# The sources in this folder are loaded with pkgload when it is available, so
# the script runs the code as it is in the working tree; otherwise an installed
# RcmdrShiny package is used.
#
# Environment variables:
#   RCMDRSHINY_PORT     port to listen on; if it is busy the next free port is
#                       used (default: a random free port chosen by Shiny)
#   RCMDRSHINY_HOST     interface to bind to (default: 127.0.0.1)
#   RCMDRSHINY_BROWSER  TRUE (default) / FALSE, whether to open a browser
#
# Examples:
#   ./start.sh
#   RCMDRSHINY_PORT=3838 ./start.sh
#   RCMDRSHINY_BROWSER=FALSE ./start.sh

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

die() {
  printf 'start.sh: %s\n' "$*" >&2
  exit 1
}

command -v Rscript >/dev/null 2>&1 ||
  die "Rscript not found: install R >= 4.1 from https://cran.r-project.org/."

[[ -f DESCRIPTION ]] ||
  die "DESCRIPTION not found: run start.sh from the RcmdrShiny source folder."

# A port is free when nothing answers on the loopback interface.
port_is_free() {
  ! (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null
}

# First free port at or above the requested one, searching port_span ports.
resolve_port() {
  local candidate="$1"
  local last=$(( $1 + $2 ))
  while (( candidate <= last )); do
    if port_is_free "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
    candidate=$(( candidate + 1 ))
  done
  return 1
}

port="${RCMDRSHINY_PORT:-}"
if [[ -n "$port" ]]; then
  [[ "$port" =~ ^[0-9]+$ ]] || die "RCMDRSHINY_PORT must be a number, got '$port'."
  requested_port="$port"
  port_span=50
  port="$(resolve_port "$requested_port" "$port_span")" ||
    die "No free port found between $requested_port and $(( requested_port + port_span ))."
  if [[ "$port" != "$requested_port" ]]; then
    printf 'start.sh: port %s is busy, using %s instead.\n' \
      "$requested_port" "$port" >&2
  fi
  export RCMDRSHINY_PORT="$port"
fi

Rscript --vanilla -e "$(cat <<'RS'
port <- trimws(Sys.getenv("RCMDRSHINY_PORT"))
host <- trimws(Sys.getenv("RCMDRSHINY_HOST"))
browser <- tolower(trimws(Sys.getenv("RCMDRSHINY_BROWSER", "TRUE")))
open_browser <- !browser %in% c("", "0", "false", "no", "off")

if (nzchar(port) && !grepl("^[0-9]+$", port)) {
  stop("RCMDRSHINY_PORT must be a number, got '", port, "'.", call. = FALSE)
}

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop(
    "The 'shiny' package is required. Install the dependencies with:\n",
    "  Rscript -e 'install.packages(\".\", repos = NULL, type = \"source\")'",
    call. = FALSE
  )
}

if (requireNamespace("pkgload", quietly = TRUE)) {
  message("Loading RcmdrShiny from the working copy (", getwd(), ") ...")
  pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
} else if (requireNamespace("RcmdrShiny", quietly = TRUE)) {
  message("pkgload not installed: using the installed RcmdrShiny package ...")
  library(RcmdrShiny)
} else {
  stop(
    "Neither 'pkgload' nor an installed 'RcmdrShiny' package was found.\n",
    "Install either one, for example:\n",
    "  Rscript -e 'install.packages(c(\"pkgload\", \"shiny\", \"shinyWidgets\", \"bslib\", \"DT\", ",
    "\"shinyAce\", \"shinyFiles\", \"rhandsontable\", \"RcmdrMisc\"))'\n",
    "or install this package:\n",
    "  Rscript -e 'install.packages(\".\", repos = NULL, type = \"source\")'",
    call. = FALSE
  )
}

run_args <- list(launch.browser = open_browser)
if (nzchar(port)) run_args$port <- as.integer(port)
if (nzchar(host)) run_args$host <- host

message("Starting RcmdrShiny Studio ...")
do.call(RcmdrShiny::run, run_args)
RS
)"
