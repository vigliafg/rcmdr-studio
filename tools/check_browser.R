#!/usr/bin/env Rscript
# Is there a browser that can actually load a page?
#
# The e2e suite and the screenshot tool need a headless browser.  A Chrome
# binary on PATH is not enough: in a container the network stack can be
# present but unable to navigate to http(s), while about:blank and data: URLs
# still work.  This probe tells the two cases apart.
#
# Usage:
#   Rscript tools/check_browser.R

required <- c("chromote", "httpuv")
missing <- required[!vapply(required, requireNamespace, logical(1),
                            quietly = TRUE)]
if (length(missing) > 0L) {
  cat("missing packages:", paste(missing, collapse = ", "), "\n")
  quit(status = 2L)
}

# Containers usually need these; they are harmless on a desktop.
chromote::set_chrome_args(c(
  "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"
))

server <- httpuv::startServer("127.0.0.1", 0L, list(
  call = function(req) {
    list(
      status = 200L,
      headers = list("Content-Type" = "text/html; charset=utf-8"),
      body = "<!doctype html><title>browser probe</title><h1>ok</h1>"
    )
  }
))
on.exit(httpuv::stopServer(server), add = TRUE)
port <- server$getPort()
url <- sprintf("http://127.0.0.1:%d/", port)

session <- chromote::ChromoteSession$new()
on.exit(session$close(), add = TRUE)

probe <- function(label, target, expected = NULL) {
  started <- Sys.time()
  error <- NULL
  title <- NULL
  tryCatch(
    {
      session$Page$navigate(target, wait_ = TRUE)
      title <- session$Runtime$evaluate("document.title")$result$value
    },
    error = function(e) error <<- conditionMessage(e)
  )
  elapsed <- round(as.numeric(difftime(Sys.time(), started, units = "secs")),
                   1)
  ok <- is.null(error) &&
    (is.null(expected) || identical(title, expected) || !nzchar(title))
  if (ok) {
    cat(sprintf("%-18s ok (%.1fs)\n", label, elapsed))
  } else {
    detail <- if (!is.null(error)) error else sprintf("title=%s", title)
    cat(sprintf("%-18s FAILED (%.1fs): %s\n", label, elapsed, detail))
  }
  ok
}

cat("chrome:", chromote::find_chrome(), "\n")
ok <- c(
  blank = probe("about:blank", "about:blank"),
  data = probe("data URL", "data:text/html,<title>ok</title>", "ok"),
  http = probe("local http", url, "browser probe")
)

if (isTRUE(ok[["http"]])) {
  cat("browser ready for the e2e suite.\n")
  quit(status = 0L)
}

cat("\nThe browser cannot navigate to http(s) in this environment.\n")
cat("The e2e suite and tools/help_screenshots.R stay unavailable; run them\n")
cat("on a desktop session or a container with a working network namespace.\n")
quit(status = 1L)
