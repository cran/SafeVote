#' Count votes using the Condorcet voting method.
#' 
#' The Condorcet method elects the candidate who wins a majority of the ranked
#' vote in every head to head election against each of the other candidates.
#' A Condorcet winner is a candidate who beats all other candidates
#' in pairwise comparisons. Analogously, a Condorcet loser is a candidate
#' who loses against all other candidates. Neither Condorcet winner nor loser
#' might exist.
#'
#' If the runoff argument is set to `TRUE` and no Condorcet winner exists,
#' two or more candidates with the most pairwise wins are selected and
#' the method is applied to such subset. If more than two candidates are in
#' such run-off, the selection is performed repeatedly, until either a winner
#' is selected or no more selection is possible.
#' 
#' The input data votes is structured the same way as for the [stv] method: 
#' Row `i` contains the preferences of voter `i` numbered 
#' `1; 2; : : : ; r; 0; 0; 0; 0`, in some order, while equal preferences
#' are allowed. The columns correspond to the candidates. The [dimnames] of
#' the columns are the names of the candidates; if these are not supplied
#' then the candidates are lettered `A, B, C, ...`. If the dataset 
#' contains missing values ([NA]), they are replaced by zeros.
#' 
#' If a ballot has equally-ranked candidates, its rankings are tested for
#' validity: for each preference \eqn{i} which does not have any duplicate,
#' there are exactly \eqn{i - 1} preferences \eqn{j} with \eqn{0 < j < i}. If
#' any ballot `x` fails this validity test, it is automatically corrected (aka
#' "converted") into a valid ballot using `x <- rank(x, ties.method = "min")`,
#' and a warning is issued.
#'
#' This method also computes a Borda ranking of all candidates, using
#' tournament-style scoring.  This ranking is "fuzzed" into a `safeRank`, with
#' approximately 1 s.d. of fuzz when `safety=1.0` and voter preferences are
#' i.u.d.  A warning is thrown if a `safeRank` violates the (extended) Condorcet
#' principle: that Candidate \eqn{i} is more highly ranked than Candidate
#' \eqn{j} only if a majority of voters agree with this.
#' 
#' @param votes A [matrix] or [data.frame] containing the votes. Rows correspond
#'   to the votes, columns correspond to the candidates. If `votes` is a
#'   character string, it is interpreted as a file name from which the votes are
#'   to be read. See
#'   [below](https://cthombor.github.io/SafeVote/reference/condorcet#details).
#' @param runoff Logical. If [TRUE] and no Condorcet winner exists, the election
#'   goes into a run-off, see
#'   [below](https://cthombor.github.io/SafeVote/reference/condorcet#details).
#' @param nseats the number of seats to be filled in this election
#' @param safety Parameter for a clustering heuristic on a total ranking of
#' the candidates.  Conjecture: the default of `1.0` ensures a separation
#' of one s.d. between clusters, when `votes` are i.u.d. permutations on the
#' candidates.
#' @param fsep If `votes` is a file name, this argument gives the column
#' separator in the file.
#' @param quiet If [TRUE] no output is printed.
#' @param ... Undocumented intent (preserved from legacy code)
#'
#' @return Object of class `SafeVote.condorcet`
#' @export
#'
#' @examples {
#' data(food_election)
#' condorcet(food_election)
#' }

condorcet <-
  function(votes,
           runoff = FALSE,
           nseats = 1,
           safety = 1.0,
           fsep = '\t',
           quiet = FALSE,
           ...) {
    compare.two.candidates <- function(v1, v2) {
    i.wins <- sum(v1 < v2)
    j.wins <- sum(v1 > v2)
    c(i.wins > j.wins, i.wins < j.wins, i.wins, j.wins)
  }
  
  compute.wins <- function(dat, ncan, cnam) {
    p <-
      array(0,
            dim = c(ncan, ncan, 2),
            dimnames = list(cnam, cnam, list("Wins", "Prefs")))
    for (i in 1:(ncan - 1)) {
      for (j in ((i + 1):ncan)) {
        pair.run <- compare.two.candidates(dat[, i], dat[, j])
        p[i, j, "Wins"] <- pair.run[1]
        p[i, j, "Prefs"] <- pair.run[3]
        p[j, i, "Wins"] <- pair.run[2]
        p[j, i, "Prefs"] <- pair.run[4]
      }
    }
    p
  }
  
  stopifnot(nseats==1) ## TODO: implement nseats > 1
  
  votes <- prepare.votes(votes, fsep = fsep)
  nc <- ncol(votes)
  cnames <- colnames(votes)
  
  corvotes <- correct.ranking(votes, quiet = quiet)
  
  x <- check.votes(corvotes, "condorcet", quiet = quiet)
  
  corrected <-
    which(rowSums(corvotes != votes) > 0 &
            rownames(votes) %in% rownames(x))
  corrected.votes <- NULL
  if (length(corrected) > 0) {
    corrected.votes <-
      list(original = votes[corrected, ],
           new = corvotes[corrected,],
           index = as.numeric(corrected))
  }
  check.nseats(1, ncol(x))
  x2 <- x
  x2[x2 == 0] <-
    max(x2) + 1 # unranked candidates are lowest= preference
  points <- compute.wins(x2, nc, cnames)
  cdc.winner <-
    apply(points[, , "Wins"], 1, function(p)
      sum(p) == nc - 1)
  cdc.loser  <-
    apply(points[, , "Wins"], 2, function(p)
      sum(p) == nc - 1)
  cdc.scores <-
    points[, , "Prefs"]     # Strength of a pairwise preference
  runoff.winner <- ro.part <- ro.part.first <- NULL
  if (sum(cdc.winner) == 0 && runoff) {
    # run-off
    nwins <- rowSums(points[, , "Wins"])
    winner.exists <- FALSE
    cand.names <- cnames
    ncro <- nc
    while (!winner.exists) {
      most.wins <- nwins == max(nwins)
      if (sum(most.wins) < 2) {
        # second most wins
        most.wins <-
          (most.wins ||
             (nwins == max(nwins[nwins < max(nwins)]) && nwins > 0))
      }
      ro.part <- cand.names[most.wins]
      ## keep the list of the original run-off participants
      if (is.null(ro.part.first))
        ro.part.first <- ro.part
      ## run-off must have less candidates than the original set
      if (length(ro.part) == ncro || length(ro.part) <= 1) {
        if (length(ro.part) == 1)
          runoff.winner <- ro.part
        ## only one run-off participant
        break
      }
      if (sum(most.wins) == 2) {
        ## run-off between two candidates
        ##         
        ## Recoded Nov 22 to avoid some nasty corner cases with NA.  Previously 
        ##  
        ## pair.run <- compare.two.candidates(x2[, which(most.wins)[1]], 
        ##                                    x2[, which(most.wins)[2]])
        ## runoff.winner<-cand.names[which(most.wins)[which(pair.run == TRUE)]]
        ##
        ## See Section 4.5.8 of https://adv-r.hadley.nz/subsetting.html
        pair.run <-
          compare.two.candidates(x2[, most.wins[1]], x2[, most.wins[2]])
        runoff.winner <- cand.names[most.wins[pair.run]]
      } else {
        # run-off between more than two candidates
        x3 <- x2[, most.wins]
        p.runoff <- compute.wins(x3, ncol(x3), colnames(x3))
        runoff.winner <-
          colnames(x3)[apply(p.runoff[, , "Wins"], 1,
                             function(p)
                               sum(p) == ncol(x3) - 1)]
      }
      if (length(runoff.winner) > 0) {
        winner.exists <- TRUE
        break
      }
      if (sum(most.wins) == 2)
        break
      nwins <- rowSums(p.runoff[, , "Wins"])
      x2 <- x3
      cand.names <- colnames(x2)
      ncro <- ncol(x2)
    }
  }
  
  tScore <- rowSums(cdc.scores) # tournament scoring
  tRank <- rank(-tScore, ties.method = "min")
  tMargin <-
    sapply(
      tScore,
      FUN = function(x) {
        if (length(which(tScore < x)) == 0)
          NA
        else
          x - max(tScore[tScore < x])
      }
    )
  ## the lowest-preference candidate(s) have a margin of 0, not NA
  tMargin[which(is.na(tMargin))] <- 0
      
  nv <- nrow(x2)
  fuzz <- safety * (nc-1) * sqrt(nv) / 2
  ## safety == 1.0 puts a "fuzz" of approx 1 s.d. on each Borda score,
  ## when votes are i.u.d. permutations.
  
  ## iterative clustering, in decreasing order of bordaScore
  safeRank <- tRank
  sortedTScore <- sort(tScore, decreasing = TRUE)
  for (i in 2:nc) {
    if ((sortedTScore[i - 1] - sortedTScore[i]) < fuzz) {
      ## uprank the candidate with i-th highest score
      safeRank[names(sortedTScore[i])] <-
        safeRank[names(sortedTScore[i - 1])]
    }
  }
 
  ## An extension of Condorcet's criterion to partial rankings:
  ## * Candidate i is more highly ranked than Candidate j
  ## * only if a majority of voters agree with this.
  for (i in 1:nc) {
    for (j in 1:nc) {
      if (safeRank[i] < safeRank[j]) {
        # i ranked higher than j
        if (!quiet && (cdc.scores[i, j] < cdc.scores[j, i])) {
          cat(
            "\nCondorcet violation: safeRank of",
            cnames[i],
            "is above",
            cnames[j],
            "but",
            cdc.scores[j, i],
            "ballots prefer",
            cnames[j],
            "and only",
            cdc.scores[i, j],
            "ballots prefer",
            cnames[i],
            "\n"
          )
        }
      }
    }
  }
  
  ## We require a total ranking of the candidates, when computing margin
  ## adjustments within tie-groups. This table is also a nice presentation of
  ## safeRank and margins
  rankingTable <- data.frame(
    TotalRank =  rank(-tScore, ties.method = "random"),
    SafeRank = safeRank,
    Margin = tMargin
  )
  
  result <-
    structure(
      list(
        elected = if (sum(cdc.winner) > 0)
          cnames[cdc.winner]
        else
          NULL,
        totals = points[, , "Wins"],
        scores = points[, , "Prefs"],
        ranking = tRank,
        margins = tMargin,
        safeRank = safeRank,
        rankingTable = rankingTable,
        fuzz = fuzz,
        data = x,
        invalid.votes = votes[setdiff(rownames(votes), rownames(x)),
                              , drop = FALSE],
        nseats = nseats,
        corrected.votes = corrected.votes,
        loser = if (sum(cdc.loser) > 0)
          cnames[cdc.loser]
        else
          NULL,
        runoff.winner = if (length(runoff.winner) > 0)
          runoff.winner
        else
          NULL,
        runoff.participants = ro.part.first
      ),
      class = "SafeVote.condorcet"
    )
  ##TODO define and use explicit constructors for SafeVote objects
  
  if (!quiet)
    print(summary(result))
  invisible(result)
}

#' Summary method for condorcet() results
#'
#' @param object of type SafeVote.condorcet
#' @param ... undocumented, currently unused
#'
#' @return [data.frame] object
#' @export
summary.SafeVote.condorcet <- function(object, ...) {
    df <- data.frame(object$totals, stringsAsFactors=FALSE)
    df$Total <- rowSums(object$totals)
    attr(df, "align") <- rep("r", ncol(df))

    df$Score <- rowSums(object$scores) # tournament-style scoring
    df$BordaRank <- object$ranking # based on Score (not Total)
    df$margin <- object$margins
    df$SafeRank <- object$safeRank
    attr(df, "fuzz") <- object$fuzz

    if(!is.null(object$elected)) {
        df$Winner <- rep("", nrow(df))
        df[object$elected, "Winner"] <- "x"
        attr(df, "align") <- c(attr(df, "align"), "c")
    }
    if(!is.null(object$loser)) {
        df$Loser <- rep("", nrow(df))
        df[object$loser, "Loser"] <- "x"
        attr(df, "align") <- c(attr(df, "align"), "c")
    }
    if (!is.null(object$runoff.participants)) {
      df$Runoff <- rep("", nrow(df))
      df[setdiff(object$runoff.participants,
                 object$runoff.winner),
         "Runoff"] <- "o"
      if (!is.null(object$runoff.winner))
        df[object$runoff.winner, "Runoff"] <- "x"
      attr(df, "align") <- c(attr(df, "align"), "c")
    }
    attr(df, "number.of.votes") <- nrow(object$data)
    attr(df, "number.of.invalid.votes") <- nrow(object$invalid.votes)
    attr(df, "number.of.candidates") <- nrow(object$totals)
    attr(df, "number.of.seats") <- object$nseats
    attr(df, "condorcet.winner") <- object$elected
    attr(df, "condorcet.loser") <- object$loser
    attr(df, "runoff.winner") <- object$runoff.winner
    attr(df, "runoff.participants") <- object$runoff.participants

    class(df) <- c('summary.SafeVote.condorcet', class(df))
    return(df)
}

#' print method for summary.SafeVote.condorcet
#'
#' @param x object of type summary.SafeVote.condorcet
#' @param ... parameters passed to generic [print]
#'
#' @return textual description of `x`
#' @export
print.summary.SafeVote.condorcet <- function(x, ...) {
  cat("\nResults of Condorcet voting")
  cat("\n===========================")
  
  election.info(x)  # prints x in a human-readable format
  
  print(knitr::kable(x, align = attr(x, "align"), ...))
  
  sortedBordaScore <- sort(x$Score, decreasing = TRUE)
  bordaGaps <- sortedBordaScore - append(sortedBordaScore[-1], 0)
  cat("\nsafeRank fuzz on Borda scores:", attr(x, "fuzz"))
  cat(
    "\nGaps in Borda scores: min",
    min(bordaGaps),
    "mean",
    mean(bordaGaps),
    "max",
    max(bordaGaps),
    "; all",
    sort(bordaGaps)
  )
  
  if (is.null(attr(x, "condorcet.winner")))
    cat("\nThere is no condorcet winner (no candidate won over all other candidates).")
  else
    cat("\nCondorcet winner:", attr(x, "condorcet.winner"))
  if (is.null(attr(x, "condorcet.loser")))
    cat("\nThere is no condorcet loser (no candidate lost to all other candidates).")
  else
    cat("\nCondorcet loser:", attr(x, "condorcet.loser"))
  if (!is.null(attr(x, "runoff.winner")))
    cat("\nRun-off winner:", attr(x, "runoff.winner"))
  
  cat("\n\n")
  
}

#' view method for SafeVote.condorcet
#' 
#' @param object of type SafeVote.condorcet
#' @param ... see [view.SafeVote.approval] 
#'
#' @return view object
#' @export
view.SafeVote.condorcet <- function(object, ...) {
    view.SafeVote.approval(object, ...)
}

#' The image function visualizes the joint distribution of two preferences
#' (if `all.pref=FALSE`) given `xpref` and `ypref`, as well as the marginal
#' distribution of all preferences (if `all.pref=TRUE`). The joint distribution
#' can be shown as proportions (if `proportion=TRUE`) or raw vote counts
#' (if `proportion=FALSE`).
#' 
#' @param x object of type SafeVote.condorcet
#' @param ... See arguments for [image.SafeVote.stv], especially `xpref`,
#'   `ypref`, `all.pref` and `proportion`.
#' @return image object, with side-effect in RStudio Plots pane
#' @export
image.SafeVote.condorcet <- function(x, ...) {
    image.SafeVote.stv(x, ...)
}

