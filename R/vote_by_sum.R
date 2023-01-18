#' Count votes using the approval method
#'
#' See https://arxiv.org/abs/2102.05801
#' 
#' @param votes,nseats,fsep,quiet,...  undocumented
#'
#' @return  undocumented
#' @export
approval <-
  function(votes,
           nseats = 1,
           fsep = '\t',
           quiet = FALSE,
           ...) {
    votes <- prepare.votes(votes, fsep = fsep)
    x <- check.votes(votes, "approval", quiet = quiet)
    nseats <- check.nseats(nseats, ncol(x), ...)
    res <- sumOfVotes(x)
    elected <- names(rev(sort(res))[1:nseats])
    result <- structure(list(
      elected = elected,
      totals = res,
      data = x,
      invalid.votes = 
        votes[setdiff(rownames(votes), rownames(x)), , drop = FALSE],
      nseats = nseats
    ),
    class = "vote.approval")
    if (!quiet)
      print(summary(result))
    invisible(result)
  }

#' Count votes using the plurality method
#'
#' See https://arxiv.org/abs/2102.05801
#' 
#' @param votes,nseats,fsep,quiet,...  undocumented
#'
#' @return  undocumented
#' @export
plurality <-
  function(votes,
           nseats = 1,
           fsep = '\t',
           quiet = FALSE,
           ...) {
    votes <- prepare.votes(votes, fsep = fsep)
    x <- check.votes(votes, "plurality", quiet = quiet)
    nseats <- check.nseats(nseats, ncol(x), ...)
    res <- sumOfVotes(x)
    elected <- names(rev(sort(res))[1:nseats])
    result <- structure(list(
      elected = elected,
      totals = res,
      data = x,
      invalid.votes = 
        votes[setdiff(rownames(votes), rownames(x)), , drop = FALSE],
      nseats = nseats
    ),
    class = "vote.plurality")
    if (!quiet)
      print(summary(result))
    invisible(result)
  }

#' Count votes using the score (or range) method.
#' 
#' See https://arxiv.org/abs/2102.05801
#'
#' @param votes,nseats,max.score,larger.wins,fsep,quiet,...  undocumented
#'
#' @return  undocumented
#' @export
score <-
  function(votes,
           nseats = 1,
           max.score = NULL,
           larger.wins = TRUE,
           fsep = '\t',
           quiet = FALSE,
           ...) {
    votes <- prepare.votes(votes, fsep = fsep)
    if (is.null(max.score) || max.score < 1) {
      max.score <- max(votes)
      warning("Invalid max.score. Set to observed maximum: ", max.score)
    }
    x <- check.votes(votes, "score", max.score, quiet = quiet)
    nseats <- check.nseats(nseats, ncol(x), ...)
    res <- sumOfVotes(x)
    elected <- names(sort(res, decreasing = larger.wins)[1:nseats])
    result <-
      structure(
        list(
          elected = elected,
          totals = res,
          larger.wins = larger.wins,
          data = x,
          invalid.votes = 
            votes[setdiff(rownames(votes), rownames(x)), , drop = FALSE],
          nseats = nseats
        ),
        class = "vote.score"
      )
    if (!quiet)
      print(summary(result))
    invisible(result)
  }

#' internal method, computes column-sums
#'
#' Renamed from 'sum.votes' to avoid confusion with the generic sum()
#' 
#' @param votes ballots are rows, candidates are columns
#'
#' @return vector of votes for each candidate
sumOfVotes <- function(votes) {
  vtot <- apply(votes, 2, sum)
  return (vtot)
}

#' summarises vote-totals for subsequent printing
#'
#' @param object vector of total votes per candidate
#' @param larger.wins TRUE if candidates are "voted in" rather than voted-out
#' @param reorder TRUE if output data.frame columns should be in rank-order
#'
#' @return a data.frame with three columns and nc+1 rows, where
#'   nc is the number of candidates.  The first column contains candidate
#'   names and a final entry named "Sum".  The second column contains
#'   vote totals. The third column is a vector of chars which indicate
#'   whether the candidate has been elected.  The data.frame has four named
#'   attributes carrying election parameters.
#'   
#'   TODO: refactor into a modern dialect of R, perhaps by defining a
#'   constructor for an election_info S3 object with a summary method and a
#'   print method
.summary.SafeVote <-
  function(object,
           larger.wins = TRUE,
           reorder = TRUE) {
    df <-
      data.frame(
        Candidate = names(object$totals),
        Total = object$totals,
        Elected = "",
        stringsAsFactors = FALSE
      )
    if (reorder) {
      df <- df[order(df$Total, decreasing = larger.wins), ]
    }
    df[object$elected, "Elected"] <- "x"
    rownames(df) <- NULL
  df <- rbind(df, c('', sum(df$Total), ''))
  rownames(df)[nrow(df)] <- "Sum"
  attr(df, "align") <- c("l", "r", "c")
  attr(df, "number.of.votes") <- nrow(object$data)
  attr(df, "number.of.invalid.votes") <- nrow(object$invalid.votes)
  attr(df, "number.of.candidates") <- length(object$totals)
  # attr(df, "number.of.seats") <- length(object$elected)
  
  # Amended Dec 2022.  Will cause regressions on vote.2_3.2 to fail on elections
  # which do not fill all available seats
  attr(df, "number.of.seats") <- object$nseats

  return(df)
}

#' summary method for approval results
#'
#' @param object,... undocumented
#'
#' @return undocumented
#' @export
summary.SafeVote.approval <- function(object, ...) {
  df <- .summary.SafeVote(object)
  class(df) <- c('summary.SafeVote.approval', class(df))
  return(df)
}

#' prints the basic results of an election
#'
#' @param x basic election results, as named attributes of an R structure or
#'   object
#' 
#' @return data.frame : an invisible copy of the printed results
#' 
#' TODO: refactor into a modern dialect of R, e.g. defining a constructor for an
#'   election_info S3 object with a print method
election.info <- function(x) {
  df <-
    data.frame(sapply(c(
      "number.of.votes",
      "number.of.invalid.votes",
      "number.of.candidates",
      "number.of.seats"
    ),
    function(a)
      attr(x, a)))
  
  rownames(df) <-
    c(
      "Number of valid votes:",
      "Number of invalid votes:",
      "Number of candidates:",
      "Number of seats:"
    )
  colnames(df) <- NULL
  print(df)
}

#' .print method for summary object
#'
#' @param x,... undocumented
#'
#' @return undocumented
.print.summary.SafeVote <- function(x, ...) {
  election.info(x)
  print(kable(x, align = attr(x, "align"), ...))
  cat("\nElected:",
      paste(x$Candidate[trimws(x$Elected) == "x"],
            collapse = ", "),
      "\n\n")
}

#' print method for summary object
#'
#' @param x,... undocumented
#'
#' @return undocumented
#' @export
print.summary.SafeVote.approval <- function(x, ...) {
  cat("\nResults of Approval voting")
  cat("\n==========================")
  .print.summary.SafeVote(x, ...)
}

#' view method for approval object
#'
#' @param object,... undocumented 
#'
#' @return undocumented
#' @export
view.SafeVote.approval <- function(object, ...) {
  s <- summary(object)
  col_formatter <-
    formatter("span",
              style =
                x ~ style(
                  background =
                    ifelse(x %in% s$Candidate[trimws(s$Elected) == "x"],
                           "lightgreen",
                           "transparent")
                  # width = "20px" # doesn't work
                ))
  formattable(s, list(Candidate = col_formatter), ...)
}


#' summary method for plurality object
#'
#' @param object,... undocumented 
#'
#' @return descriptive dataframe
#' @export
summary.SafeVote.plurality <- function(object, ...) {
  df <- .summary.SafeVote(object)
  class(df) <- c('summary.SafeVote.plurality', class(df))
  return(df)
}

#' print method for summary of plurality object
#'
#' @param x,... undocumented
#'
#' @return undocumented
#' @export
print.summary.SafeVote.plurality <- function(x, ...) {
  cat("\nResults of Plurality voting")
  cat("\n===========================")
  .print.summary.SafeVote(x, ...)
}

#' view method for plurality object
#'
#' @param object,... undocumented
#'
#' @return undocumented
#' @export
view.SafeVote.plurality <- function(object, ...) {
  view.SafeVote.approval(object, ...)
}

#' summary method for score object
#'
#' @param object,... undocumented 
#'
#' @return undocumented
#' @export
summary.SafeVote.score <- function(object, ...) {
  df <- .summary.SafeVote(object, larger.wins=object$larger.wins)
  class(df) <- c('summary.SafeVote.score', class(df))
  return(df)
}

#' print method for summary.score object
#'
#' @param x,... undocumented
#'
#' @return undocumented
#' @export
print.summary.SafeVote.score <- function(x, ...) {
  cat("\nResults of Score voting")
  cat("\n=======================")
  .print.summary.SafeVote(x, ...)
}

#' view method for score object
#'
#' @param object,... undocumented
#'
#' @return undocumented
#' @export
view.SafeVote.score <- function(object, ...) {
  view.SafeVote.approval(object, ...) 
}


