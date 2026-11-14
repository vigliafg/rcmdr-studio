\name{help_errors}
\alias{error_help_topic}
\alias{error_help_suggestion}
\alias{error_help_link_ui}
\title{Map an R error to a help topic}
\description{
Conservative mapping from well-known R error messages to the help topic that
most likely explains them.
}
\usage{
error_help_topic(message, language = NULL)

error_help_suggestion(message, language = NULL)

error_help_link_ui(message, language = NULL, label = NULL)
}
\arguments{
  \item{message}{Error message, or a character vector of messages.}
  \item{language}{Language code used for the topic title.}
  \item{label}{Optional link label.}
}
\details{
Patterns cover missing objects, missing packages or functions, factor
conversion, missing values, pandoc and knit failures, file errors, memory
problems and singular fits.  When no pattern matches, the functions return
\code{NULL} rather than a generic link.
}
\value{
\code{error_help_topic()} returns a topic id or \code{NULL}.
\code{error_help_suggestion()} returns a list with \code{id} and \code{title},
or \code{NULL}.  \code{error_help_link_ui()} returns an \code{<a>} tag or
\code{NULL}.
}
\seealso{\code{\link{help}}, \code{\link{help_center_ui}}}
\keyword{utilities}
