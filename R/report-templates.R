# Report templates -----------------------------------------------------------
#
# Templates are starting points for R Markdown documents.  They only use
# commands that the dialogs already generate; a template never adds a new
# statistical procedure.  Each template receives the active data set name and
# expands the `{{dataset}}` placeholder.

#' Identifier of the data set used by a template
#' @keywords internal
report_template_dataset <- function(dataset = NULL) {
  if (is.null(dataset) || !nzchar(dataset %||% "")) return("Dataset")
  if (!make.names(dataset) == dataset) return("Dataset")
  dataset
}

report_template_header <- function(title, output = "html_document") {
  c(
    "---",
    sprintf('title: "%s"', gsub('"', '\\\\"', title)),
    sprintf('date: "%s"', Sys.Date()),
    sprintf("output: %s", output),
    "---",
    ""
  )
}

#' Available report templates
#'
#' @return A named list of template descriptors.  Every descriptor has `id`,
#'   `title`, `description`, `mode` and `build(dataset, title)`.
#' @keywords internal
report_templates_builtin <- function() {
  list(
    analysis = list(
      id = "analysis",
      title = tr("Analysis report"),
      description = tr(
        "Context, data, descriptive statistics, graphs and conclusions."
      ),
      mode = "rmd",
      build = function(dataset = NULL, title = NULL) {
        dataset <- report_template_dataset(dataset)
        title <- title %||% tr("Analysis report")
        c(
          report_template_header(title),
          "## Context", "",
          "Describe the question and the data used in this report.", "",
          "## Data", "",
          "```{r data, echo=FALSE}",
          sprintf("str(%s)", dataset),
          "```", "",
          "## Descriptive statistics", "",
          "```{r summary}",
          sprintf("summary(%s)", dataset),
          "```", "",
          "## Graphs", "",
          "```{r graph, fig.width=6, fig.height=4}",
          sprintf("plot(%s)", dataset),
          "```", "",
          "## Conclusions", "",
          "Summarise the findings and note any limitation.", ""
        )
      }
    ),
    profile = list(
      id = "profile",
      title = tr("Data profile"),
      description = tr(
        "Structure, missing values, distributions and data quality."
      ),
      mode = "rmd",
      build = function(dataset = NULL, title = NULL) {
        dataset <- report_template_dataset(dataset)
        title <- title %||% tr("Data profile")
        c(
          report_template_header(title),
          "## Structure", "",
          "```{r structure}",
          sprintf("dim(%s)", dataset),
          sprintf("str(%s)", dataset),
          "```", "",
          "## Missing values", "",
          "```{r missing}",
          sprintf("colSums(is.na(%s))", dataset),
          "```", "",
          "## Distributions", "",
          "```{r distributions}",
          sprintf("summary(%s)", dataset),
          "```", "",
          "## Quality notes", "",
          "Record implausible values, duplicates and units here.", ""
        )
      }
    ),
    diagnostics = list(
      id = "diagnostics",
      title = tr("Model diagnostics"),
      description = tr(
        "Formula, summary, diagnostics and influence for the active model."
      ),
      mode = "rmd",
      build = function(dataset = NULL, title = NULL) {
        dataset <- report_template_dataset(dataset)
        title <- title %||% tr("Model diagnostics")
        c(
          report_template_header(title),
          "## Model", "",
          "```{r model}",
          "if (exists(\"LinearModel.1\")) {",
          "  summary(LinearModel.1)",
          "} else {",
          "  message(\"Fit a model first; the report will show it once available.\")",
          "}",
          "```", "",
          "## Diagnostics", "",
          "```{r diagnostics, fig.width=6, fig.height=4}",
          "if (exists(\"LinearModel.1\")) {",
          "  old <- par(mfrow = c(2, 2))",
          "  plot(LinearModel.1)",
          "  par(old)",
          "}",
          "```", "",
          "## Influence", "",
          "```{r influence}",
          "if (exists(\"LinearModel.1\")) {",
          "  print(influence.measures(LinearModel.1))",
          "}",
          "```", "",
          "## Interpretation", "",
          "Comment on residual behaviour and influential observations.", ""
        )
      }
    ),
    teaching = list(
      id = "teaching",
      title = tr("Teaching handout"),
      description = tr(
        "Objectives, worked commands, results and exercises."
      ),
      mode = "rmd",
      build = function(dataset = NULL, title = NULL) {
        dataset <- report_template_dataset(dataset)
        title <- title %||% tr("Teaching handout")
        c(
          report_template_header(title),
          "## Objectives", "",
          "- Read the data set.",
          "- Describe the main variables.",
          "- Interpret one graph.", "",
          "## Data", "",
          "```{r data}",
          sprintf("head(%s)", dataset),
          "```", "",
          "## Worked example", "",
          "```{r example}",
          sprintf("summary(%s)", dataset),
          "```", "",
          "## Exercises", "",
          "1. Describe the distribution of one numeric variable.",
          "2. Compare two groups with a graph.",
          "3. Write one sentence about what the graph shows.", ""
        )
      }
    ),
    survival = list(
      id = "survival",
      title = tr("Survival report"),
      description = tr(
        "Kaplan-Meier curve, Cox model and interpretation, when the survival package is available."
      ),
      mode = "rmd",
      build = function(dataset = NULL, title = NULL) {
        dataset <- report_template_dataset(dataset)
        title <- title %||% tr("Survival report")
        c(
          report_template_header(title),
          "## Data", "",
          "```{r survival-data}",
          "if (!requireNamespace(\"survival\", quietly = TRUE)) {",
          "  message(\"Install the survival package to run this template.\")",
          "}",
          "```", "",
          "## Kaplan-Meier curve", "",
          "```{r km, fig.width=6, fig.height=4, eval=FALSE}",
          "fit <- survival::survfit(survival::Surv(time, status) ~ 1,",
          sprintf("                           data = %s)", dataset),
          "plot(fit)",
          "```", "",
          "## Cox model", "",
          "```{r cox, eval=FALSE}",
          "cox <- survival::coxph(survival::Surv(time, status) ~ .,",
          sprintf("                        data = %s)", dataset),
          "summary(cox)",
          "```", "",
          "## Interpretation", "",
          "Comment on the estimated survival and the hazard ratios.", ""
        )
      }
    )
  )
}

#' Template identifiers
#' @keywords internal
report_template_ids <- function() names(report_templates())

#' Choices for a template selector
#' @keywords internal
report_template_choices <- function() {
  templates <- report_templates()
  stats::setNames(
    vapply(templates, function(template) template$id, character(1)),
    vapply(templates, function(template) template$title, character(1))
  )
}

#' Descriptor of one template
#' @keywords internal
report_template <- function(id) report_templates()[[id]]

#' Expand a template into document text
#' @keywords internal
report_template_text <- function(id, dataset = NULL, title = NULL) {
  template <- report_template(id)
  if (is.null(template)) stop(sprintf("Unknown template: %s", id), call. = FALSE)
  template$build(dataset = dataset, title = title)
}

#' Create a document from a template
#' @keywords internal
report_template_apply <- function(state, id, dataset = NULL, title = NULL) {
  template <- report_template(id)
  if (is.null(template)) stop(sprintf("Unknown template: %s", id), call. = FALSE)
  dataset <- dataset %||% active_dataset(state)
  title <- title %||% template$title
  text <- report_template_text(id, dataset, title)
  document_create(
    state, mode = template$mode, title = title,
    text = document_join(text), dirty = TRUE, activate = TRUE
  )
  invisible(TRUE)
}

#' Template card gallery
#' @keywords internal
report_template_gallery_ui <- function(compact = FALSE) {
  templates <- report_templates()
  htmltools::div(
    class = if (isTRUE(compact)) "rcmdr-template-list" else "rcmdr-template-grid",
    lapply(templates, function(template) {
      htmltools::tags$a(
        href = "#",
        class = "rcmdr-template-card",
        onclick = sprintf(
          "Shiny.setInputValue('report_template_action', '%s', {priority: 'event'}); return false;",
          template$id
        ),
        htmltools::tags$strong(template$title),
        htmltools::tags$p(class = "small text-muted mb-0",
                          template$description)
      )
    })
  )
}


# Plugin report templates are additive.  A built-in template always wins by id.
report_templates <- function() {
  registry <- report_templates_builtin()
  extras <- tryCatch(plugin_report_templates(), error = function(e) list())
  for (id in names(extras)) {
    if (!id %in% names(registry)) registry[[id]] <- extras[[id]]
  }
  registry
}
