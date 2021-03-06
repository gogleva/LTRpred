% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotFamily.R
\name{plotFamily}
\alias{plotFamily}
\title{Visualize the Superfamily distribution of predicted LTR retrotransposons}
\usage{
plotFamily(data, xlab = "\\nAnnotated Superfamily Name",
  ylab = "Predicted LTR retrotransposons (count)\\n",
  main = "Superfamily distribution of predicted LTR retrotransposons",
  legend.title = "Superfamily", annotation = "Dfam")
}
\arguments{
\item{data}{\code{data.frame} returned by \code{\link[LTRpred]{LTRpred}}.}

\item{xlab}{label of the x-axis.}

\item{ylab}{label of the y-axis.}

\item{main}{title text.}

\item{legend.title}{text of the legend title.}

\item{annotation}{which database has been used to generate annotation queries when running \code{\link[LTRpred]{LTRpred}}? 
Either \code{annotation = "Dfam"} or \code{annotation = "Repbase"}.}
}
\description{
Plot the Superfamily distribution of predicted LTR retrotransposons of
annotations generated via Dfam or Repbase query.
}
\examples{
# example prediction file generated by LTRpred 
pred.file <- system.file("Athaliana_TAIR10_chr_all_LTRpred_DataSheet.csv", package = "LTRlearn")
# read LTRpred generated prediction file (data sheet)
pred <- LTRpred::read.ltrpred(pred.file)

# visualize superfamily distribution
plotFamily(pred)
}
\seealso{
\code{\link[LTRpred]{LTRpred}}, \code{\link[LTRpred]{read.ltrpred}}, \code{\link[LTRpred]{dfam.query}}, \code{\link[LTRpred]{repbase.query}}
}
\author{
Hajk-Georg Drost
}
