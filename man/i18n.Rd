\name{i18n}
\alias{i18n_set_language}
\alias{i18n_parse_po}
\title{Session language and PO catalogues}
\description{
Set the language used by \code{tr()} without restarting R and read gettext
\code{.po} catalogues into a named character vector.
}
\usage{
i18n_set_language(language = "en")

i18n_parse_po(path)
}
\arguments{
  \item{language}{Language code, for example \code{"en"} or \code{"it"}.}
  \item{path}{Path to a gettext \code{.po} file.}
}
\details{
\code{i18n_set_language()} stores the choice in the
\code{RcmdrShiny.language} option and in the \code{LANGUAGE} environment
variable.  \code{tr()} consults an in-process catalogue before falling back to
gettext, so menus, help topics and server messages rendered after the change
use the new language.

\code{i18n_parse_po()} joins multiline entries, unescapes quoted strings and
skips entries marked \code{fuzzy}.  The Studio-specific strings live in a small
TSV overlay; see \code{tools/audit_i18n.R} for the audit.
}
\value{
\code{i18n_set_language()} returns the normalized code, invisibly.
\code{i18n_parse_po()} returns a named character vector.
}
\seealso{\code{\link{tr}}, \code{\link{available_languages}}}
\keyword{utilities}
