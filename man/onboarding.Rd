\name{onboarding}
\alias{tour_steps}
\alias{tour_step}
\alias{tour_modal}
\alias{onboarding_checklist}
\alias{onboarding_progress}
\alias{onboarding_checklist_ui}
\title{Guided tour and first-run checklist}
\description{
The tour walks through the data, chart, report and palette areas without
running any command.  The checklist is derived from the session: data sets,
history, plots and documents.
}
\usage{
tour_steps()

tour_step(index = 1L)

tour_modal(step, index, total)

onboarding_checklist(state)

onboarding_progress(state)

onboarding_checklist_ui(state)
}
\arguments{
  \item{index}{Step number, starting at 1.}
  \item{step}{A step returned by \code{tour_step()}.}
  \item{total}{Total number of steps.}
  \item{state}{Application state created by \code{\link{AppState}}.}
}
\details{
\code{tour_steps()} returns four steps with a title, body, tab, highlight target
and help topic.  \code{tour_modal()} builds the Shiny modal with Back, Next,
Skip and Don't show again actions.  The \sQuote{don't show again} choice is kept
in the browser's local storage, so it survives a session restart.

\code{onboarding_checklist()} reports the first steps: import data, run a
summary, create a chart, create a report and save a project.  Project
persistence is gated by the \code{project} feature flag and is listed as
unavailable until the platform release enables it.
}
\value{
\code{tour_steps()} returns a list of steps; \code{tour_step()} one step or
\code{NULL}.  \code{tour_modal()} returns a Shiny modal dialog.
\code{onboarding_checklist()} returns a list of records;
\code{onboarding_progress()} returns \code{done}, \code{total} and
\code{percent}; \code{onboarding_checklist_ui()} returns a Shiny tag.
}
\seealso{\code{\link{help_center_ui}}, \code{\link{run_app}}}
\keyword{utilities}
