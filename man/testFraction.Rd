% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/saferank.R
\name{testFraction}
\alias{testFraction}
\title{Bootstrapping experiment, with fractional counts of a ballot box.}
\usage{
testFraction(
  votes = NULL,
  astart = NULL,
  ainc = NULL,
  arep = NULL,
  trep = NULL,
  rankMethod = "safeRank",
  countMethod = "stv",
  countArgs = list(),
  exptName = NULL,
  equiet = FALSE,
  everbose = FALSE
)
}
\arguments{
\item{votes}{A numeric matrix: one row per ballot, one column per candidate}

\item{astart}{Starting number of ballots (min 2)}

\item{ainc}{Number of ballots to be added in each step. Must be non-negative.}

\item{arep}{Number of repetitions of the test on each step. Required to be
non-'NULL' if 'ainc=0' && is.null(trep)'.}

\item{trep}{Limit on the total number of simulated elections. Required to be
non-'NULL' if 'ainc=0 && is.null(arep)'.}

\item{rankMethod}{"safeRank" (default), "elected", or "rank".  "rank" is
a total ranking of the candidates, with ties broken at random.  "elected"
assigns rank=1 to elected candidates, rank=2 for eliminated candidates.}

\item{countMethod}{countMethod "stv" (default) or "condorcet"}

\item{countArgs}{List of args to be passed to 'countMethod' (in addition to
'votes')}

\item{exptName}{stem-name of experimental units \emph{e.g.} "E".  If 'NULL', then
a 3-character string of capital letters is chosen at random.}

\item{equiet}{'TRUE' to suppress all experimental output}

\item{everbose}{'TRUE' to produce diagnostic output from the experiment}
}
\value{
SafeRankExpt object of experimental results.
}
\description{
Starting from some number ('astart') of randomly-selected ballots, an
increasingly-large collection of randomly-selected ballots are counted. The
ballots are chosen independently without replacement for each experimental
unit; if you want to count decreasingly-sized portions of a single sample of
ballots, use \code{\link[=testDeletions]{testDeletions()}}.
}
\examples{
data(food_election)
testFraction(food_election, countMethod="condorcet",
             countArgs=list(safety=0.5,complete.ranking=TRUE))
testFraction(dublin_west, astart=20, ainc=10, arep=2, trep=3, 
             countMethod="stv", rankMethod="elected", equiet=FALSE)
}
