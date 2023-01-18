#' Count preferential ballots using an STV method
#'
#' The `votes` parameter is as described in [condorcet()]
#' with the following additional semantics.
#'
#' By default the preferences are not allowed to contain duplicates per ballot.
#' However, if the argument `equal.ranking` is set to `TRUE`, ballots are allowed
#' to have the same ranking for multiple candidates. The desired format is such
#' that for each preference $i$ that does not have any duplicate, there must be
#' exactly $i – 1$ preferences $j$ with $0 < j < i$. For example, valid ordered
#' preferences are `1; 1; 3; 4; …`, or `1; 2; 3; 3; 3; 6; …`, but NOT `1; 1; 2;
#' 3; …`, or NOT `1; 2; 3; 3; 3; 5; 6; …`. If the data contain such invalid
#' votes, they are automatically corrected and a warning is issued by calling
#' the `correct.ranking` function.
#'
#' If equal ranking is not allowed (`equal.ranking = FALSE`), the argument
#' `invalid.partial` can be used to make ballots containing duplicates or gaps
#' partially valid. If it is `TRUE`, a ballot is considered valid up to a
#' preference that is in normal case not allowed. For example, ballots `1; 2; 3;
#' 4; 4; 6` or `1; 2; 3; 5; 6; 7` would be both converted into `1; 2; 3; 0; 0;
#' 0`, because the ballots contain valid ranking only up to the third
#' preference.
#' 
#' By default, ties in the STV algorithm are resolved using the forwards
#' tie-breaking method, see Newland and Briton (Section 5.2.5). Argument `ties`
#' can be set to ”b” in order to use the backwards tie-breaking method, see
#' O’Neill (2004). In addition, both methods are complemented by the following
#' “ordered” method: Prior to the STV election candidates are ordered by the
#' number of first preferences. Equal ranks are resolved by moving to the number
#' of second preferences, then third and so on. Remaining ties are broken by
#' random draws. Such complete ordering is used to break any tie that cannot be
#' resolved by the forwards or backwards method. If there is at least one tie
#' during the processing, the output contains a row indicating in which count a
#' tie-break happened (see the `ties` element in the Value section for an
#' explanation of the symbols).
#' 
#' The ordered tiebreaking described above can be analysed from outside of the
#' `stv` function by using the `ordered.tiebreak` function for viewing the
#' a-priori ordering (the highest number is the best and lowest is the worst).
#' Such ranking is produced by comparing candidates along the columns of the
#' matrix returned by `ordered.preferences`.
#'
#' @param votes an array with one column per candidate and one row per ballot,
#'   as described in [condorcet()]
#' @param nseats the number of seats to be filled in this election
#' @param eps fuzz-factor when comparing fractional votes.  The default of 0.001
#'   is preserved from the legacy code, injecting substantial validity hazards
#'   into the codebase.  We have not attempted to mitigate any of these hazards
#'   in `SafeVote v1.0.0`.  We prefer instead to retain backwards-compatibility
#'   with the legacy code in `vote_2.3-2` in the knowledge that, even if these
#'   hazards were adequately addressed, the resulting code is unlikely to be
#'   reliable at replicating the results of any other implementation of any of
#'   the many variants of "STV" counting methods.  Please see the description of
#'   the `a53_hil` dataset in this package for some preliminary findings on the
#'   magnitude of the vote-count-variances which may be injected by differing
#'   implementations of broadly-similar "STV" counting methods.
#' @param equal.ranking if `TRUE`, equal preferences are allowed.
#' @param invalid.partial `TRUE` if ballots which do not specify a complete
#'   ranking of candidates are informal (aka "invalid") *i.e.* ignored
#'   (with a warning).  Default is `FALSE`.
#' @param fsep column-separator for output
#' @param ties vector of tie-breaking methods: `'f'` for forward, `'b'` for
#'   backward
#' @param quota.hare `TRUE` if Hare quota, `FALSE` if Droop quota (default)
#' @param constant.quota `TRUE` if quota is held constant.  Over-rides
#'   `quota.hare`. Default is `FALSE`
#' @param win.by.elim `TRUE` (default) if the quota is waived when there are no
#'   more candidates than vacant seats.  Note: there is no lower limit when the
#'   quota is waived, so a candidate may be elected on zero votes.
#' @param group.nseats number of seats reserved to members of a group
#' @param group.members vector of members of the group with reserved seats
#' @param complete.ranking is `TRUE` by default.  This parameter is retained
#'   solely for backwards compatibility with [vote::stv()]. It has no effect on
#'   elections in which `nseats` is explicitly specified in the call to
#'   [SafeVote::stv()].
#' @param verbose `TRUE` for diagnostic output
#' @param seed integer seed for tie-breaking.  Warning: if non-`NULL`, the PRNG
#'   for R is reseeded prior to *every* random tie-break among the
#'   possibly-elected candidates.  We have preserved this functionality in this
#'   branch to allow regression against the legacy codebase of [vote::stv()]. In
#'   [SafeVote::stv()] the default value for seed is `NULL` rather than the
#'   legacy value of 1234, to mitigate the validity hazard of PRNG reseedings
#'   during a stochastic experiment.
#' @param quiet `TRUE` to suppress console output
#' @param digits number of significant digits in the output table
#' @param backwards.compatible `TRUE` to regress against vote2_3.2 by
#'   disabling $margins, $fuzz, $rankingTable, $safeRank
#' @param safety number of standard deviations on vote-counts, when producing a
#'   safeRank by clustering near-ties in a complete ranking
#' @param ... undocumented intent (preserved from legacy code)
#'
#' @return object of class `vote.stv`.  Note: the winning margins in this object
#'   are valid for the elected candidates and their (total) ranking, but must be
#'   adjusted within tiegroups to be valid for the candidates' (possibly
#'   partial) safeRank.
#' @export
#'
#' @examples data(food_election)
#' @examples stv(food_election, safety = 0.0)
#' @examples stv(food_election, nseats = 2)
#'
stv <-
  function(votes,
           nseats = NULL,
           eps = 0.001,
           equal.ranking = FALSE,
           fsep = "\t",
           ties = c("f", "b"),
           quota.hare = FALSE,
           constant.quota = FALSE,
           win.by.elim = TRUE,
           group.nseats = NULL,
           group.members = NULL,
           complete.ranking = FALSE,
           invalid.partial = FALSE,
           verbose = FALSE,
           seed = NULL,
           quiet = FALSE,
           digits = 3,
           backwards.compatible = FALSE,
           safety = 1.0,
           ...) {
    if (verbose && !quiet) {
      cat("\nSingle transferable vote count")
      if (equal.ranking)
        cat(" with equal preferences")
      cat("\n===================================")
      if (equal.ranking)
        cat("==================")
      cat("\n")
    }
    
    ## Prepare by finding names of candidates, setting up vector w of
    ## vote weights and list of elected candidates,
    ## and declaring a vector of candidate ranks (recorded in order of
    ## selection, with deletions occupying the lowest ranks)
    votes <- prepare.votes(votes, fsep = fsep)
    nc <- ncol(votes)
    cnames <- colnames(votes)
    ## a complete ranking in STV should (arguably) be "ranked from the top"
    ## i.e. there should be no eliminations
    nseats <- check.nseats(
      nseats,
      ncandidates = nc,
      default = ifelse(complete.ranking && !backwards.compatible,
                       nc, floor(nc / 2)),
      complete.ranking = complete.ranking
    )
    
    ## retain a copy of the initial value of nseats  
    nseats.initial <- nseats
    
    ## check groups (if used)
    use.marking <- FALSE
    if (!is.null(group.nseats)) {
      ## number of candidates to be elected from a group
      if (is.null(group.members)) {
        stop(
          "If group.nseats is given, argument group.members must be ",
          "used to mark members of the group."
        )
      }
      if (group.nseats > nseats) {
        warning(paste(
          "group.nseats must be <= nseats. ",
          "Adjusting group.nseats to ",
          nseats,
          "."
        ))
        group.nseats <- nseats
      }
      if (length(group.members) < group.nseats) {
        warning(
          paste(
            "There are fewer group members than group.nseats. ",
            "Adjusting group.nseats to ",
            length(group.members),
            "."
          )
        )
        group.nseats <- length(group.members)
      }
      if (!is.numeric(group.members)) {
        ## convert names to indices
        gind <- match(group.members, cnames)
        if (any(is.na(gind))) {
          warning(
            paste(
              "Group member(s) ",
              paste(group.members[is.na(gind)], collapse = ", "),
              " not found in the set of candidates, ",
              "therefore removed from the group."
            )
          )
          gind <- gind[!is.na(gind)]
        }
        group.members <- gind
      }
      ## now group memebers are given as indices
      group.members <-
        unique(group.members[group.members <= nc &
                               group.members > 0])
      use.marking <- TRUE
    } else {
      group.nseats <- 0
      group.members <- c()
    }
    
    elected <- NULL
    eliminated <- NULL
    
    ##
    ## The next step is to remove invalid votes. A vote is invalid if
    ## the preferences are not numbered in consecutively increasing order.
    ## A warning is printed out for each invalid vote, but the votes are
    ## not counted. If necessary, it is possible to correct errors in the
    ## original x matrix.
    ##
    ## If x is generated from an excel spreadsheet, then the jth vote will
    ## be in row (j-1) of the spreadsheet.
    ##
    
    if (verbose && !quiet) {
      cat("Number of votes cast is", nrow(votes), "\n")
    }
    corvotes <- votes
    corrected.votes <- NULL
    
    if (equal.ranking) {
      corvotes <- correct.ranking(votes, partial = FALSE, quiet = quiet)
    } else {
      if (invalid.partial) {
        corvotes <- correct.ranking(votes, partial = TRUE, quiet = quiet)
      }
      
      x <-
        check.votes(corvotes,
                    "stv",
                    equal.ranking = equal.ranking,
                    quiet = quiet)
      corrected <-
        which(rowSums(corvotes != votes) > 0 &
                rownames(votes) %in% rownames(x))
      
      if (length(corrected) > 0) {
        corrected.votes <-
          list(
            original = votes[corrected, ],
            new = corvotes[corrected,],
            index = as.numeric(corrected)
          )
      }
      
    }
    
    nvotes <- nrow(x)
    if (is.null(nvotes) || nvotes == 0) {
      stop("There must be more than one valid ballot to run STV.")
    }
    w <- rep(1, nvotes)
    
    ## Create elimination ranking
    tie.method <- match.arg(ties)
    tie.method.name <- c(f = "forwards", b = "backwards")
    otb <- ordered.tiebreak(x, seed)
    
    if (use.marking) {
      if (verbose && !quiet) {
        cat("Number of reserved seats is", group.nseats, "\n")
        cat("Eligible for reserved seats:",
            paste(cnames[group.members], collapse = ", "),
            "\n")
      }
      group.nseats.orig <- group.nseats
    }
    
    ## initialize results
    result.pref <-
      result.elect <-
      matrix(
        NA,
        ncol = nc,
        nrow = 0,
        dimnames = list(NULL, cnames)
      )
    result.quota <-
      result.ties <-
      c()
    result.ranks <- rep(NA, nc)
    names(result.ranks) <- cnames
    if (!backwards.compatible) {
      result.margins <- rep(NA, nc)
      names(result.margins) <- cnames
    }
    orig.x <- x
    
    ##
    ## the main loop
    ##
    if (verbose && !quiet) {
      cat("\nList of first preferences in STV counts: \n")
    }
    
    count <- 0
    inPlay <- rep(TRUE, nc)
    ## elect or eliminate one candidate per execution of the loop, with an
    ## early exit if all seats are filled
    while ((nseats > 0) && any(inPlay)) {
      ## calculate quota and total first preference votes
      count <- count + 1
      ## split 1st prefs if there is more than one first ranking on a ballot
      A <- (x == 1) / rowSums(x == 1) 
      A[is.na(A)] <- 0
      uij <- w * A
      vcast <- apply(uij, 2, sum)
      names(vcast) <- cnames
      if (!constant.quota || count == 1) {
        ## Quota calculation: either Hare (when quota.hare is TRUE) or Droop

        ## This is legacy code, with undocumented intent.  *Possibly* the only
        ## intent is to avoid a quota ever being recorded as a negative number
        ## (due to floating point roundoff errors).  However if this is the
        ## only intent, then it would be better to test for this case explicitly
        ## and shift the quota up to 0.0 if it ever becomes negative.
        
        ## Another possible intent is to ensure that a candidate must be clearly above the quota
        ## in order to be elected.  This seems unlikely, because I would expect a candidate
        ## who has 100 first-preference votes in the first round with quota 100
        ## to be elected in this round.
        
        ## Another possible intent is to ensure that, even in elections with
        ## large numbers of voters and many rounds, candidates must meet the
        ## quota to be electable -- despite the vagaries of floating-point
        ## roundoff.  This seems a likely intent but would be exceedingly
        ## difficult to achieve in R, in Python 3, or in any other language
        ## which does not offer fixed-precision arithmetic. It would also be
        ## very difficult to achieve in Java or C or Scheme, except when
        ## implementing an stv specification which explicitly defines a fixed
        ## precision (e.g. 3 decimal digits) and therefore allows the
        ## implementer to avoid the performance-pitfalls and
        ## implementation-difficulties of unbounded-precision arithmetic.
        
        ## As a "hack improvement" to this legacy code, it might be considered
        ## appropriate to add eps/2 when computing the quotas, rather than full
        ## eps.  This would reserve half of the roundoff "fuzz" budget for the
        ## calculation of transfer votes.  The idea here is that a 
        ## candidate on 2/3 votes may be computed as somewhat less than
        ## 0.6666665, due to floating point roundoff; and such a candidate
        ## would still be within eps of the quota if if were computed as
        ## 2/3 + eps/2 rather than the approx 0.6676666 resulting from the
        ## 2/3 + eps calculation in the legacy code below.
        
        ## I have left this legacy code unchanged, in part to preserve backwards
        ## compatibility, but mostly because *all* implementations of stv are
        ## sui generis -- they will almost surely fail some cross-validations
        ## with other implementations of the same natural-language specification
        ## of an "STV ballot-counting process".

        quota <- if (quota.hare)
          sum(vcast) / nseats + eps
        else
          sum(vcast) / (nseats + 1) + eps
        stopifnot(quota > 0)  ## note: when sum(vcast) == 0, quota is eps
      }
      result.quota <- c(result.quota, quota)
      result.pref <- rbind(result.pref, vcast)
      result.elect <- rbind(result.elect, rep(0, nc))
      tie <- 0
      if (verbose && !quiet) {
        cat("\nCount:" , count, "\n")
        df <-
          data.frame(QUOTA = round(quota, 3), t(round(vcast[vcast != 0], 3)))
        rownames(df) <- count
        print(df)
      }
      
      ## if leading candidate exceeds quota, declare elected and adjust weights
      ##
      ## mark candidate for elimination in subsequent counting
      ##
      ## if the number of remaining candidates is less than or equal
      ## to the number of seats, then select the one with the
      ## largest vcast, no matter if quota is exceeded
      ##
      vmax <- max(vcast)
      
      ## Restrict attention to in-play candidates (with max votes if they're
      ## not group members).  Note that in a corner case, ic will include
      ## candidates with zero votes.
      ic <-
        (1:nc)[(inPlay & (vcast == vmax)) | ((1:nc) %in% group.members)]
      
      D <-
        colSums(abs(result.elect)) == 0  # set of hopeful candidates
      if (use.marking) {
        Dm <- D
        Dm[-group.members] <-
          FALSE  # set of hopeful marked candidates
      }
      
      ## With win.by.elim, or with (backwards.compatible && constant.quota),
      ## elected candidates need not reach quota when filling the last seats.
      ##
      ## In a corner case: a candidate who receives no votes may be elected.
      ##
      ## The clause "!(! ic %in% group.members && nseats == group.nseats)" was
      ## recoded Nov 2022 to avoid throwing an error when group.members is NULL
      ## and ic is not a singleton.  Another recoding is necessary if the intent
      ## is to avoid electing a group member on zero votes, in cases where vmax
      ## is greater than 0 due to some non-group candidate being in play but 
      ## below quota.
      ##
      ## TODO: review for correctness, against a specification of how the corner
      ## cases should be handled.
      ##
      ## TODO: regress against the results of actual elections, to assess
      ## validity with respect to the actual STV ballot-counting method employed
      ## in those elections.  For example, the [Dublin West 2002
      ## results](https://en.wikipedia.org/wiki/Dublin_West_(D%C3%A1il_constituency)
      ## show markedly different vote-transfers to those of [stv()] in the second
      ## round. The list of elected candidates is identical, and the vote totals
      ## in round 1 are identical; but [stv()] is inexact in its calculations of
      ## the margins of victory, and its vote-totals are at significant variance
      ## to the official vote-totals.
      ##
      ## Note that the `vmax` terms in each of the three disjunctive clauses of
      ## the following guard ensure that a non-group candidate must receive at
      ## least one vote (even if it's only a last-preference!) in order to be
      ## elected. This implies that seats may remain unfilled, even if there are
      ## at least as many candidates as seats.
      
      if ((vmax >= quota &&
           !(!any(ic %in% group.members) &&
             (nseats == group.nseats))) ||
          ((win.by.elim || (backwards.compatible && constant.quota))
           && sum(D) <= nseats) ||
          (use.marking &&
           any(ic %in% group.members) &&
           (sum(Dm) <= group.nseats || sum(D) - sum(Dm) == 0))) {
        
        if (use.marking && length(ic) > 1 && sum(Dm) <= group.nseats) {
          ## if a tiebreak, choose marked candidates if needed
          ic <- ic[ic %in% group.members]
        }
        
        if (length(ic) > 1) {
          ## tie
          ic <- solveTiebreak(tie.method, result.pref, ic, otb,
                              elim = FALSE)
          tie <- 1
          tie <- tie + (attr(ic, "ordered") == TRUE)
          tie <- tie + (attr(ic, "sampled") == TRUE)
        }
        surplus <- if (vmax > quota)
          (vmax - quota) / vmax
        else
          0
        index <-
          (x[, ic] == 1) ## ballots where ic has the first preference
        w[index] <- uij[index, ic] * surplus ## update weights
        if (equal.ranking) {
          w[index] <-
            w[index] +
            rowSums(uij[index, , drop = FALSE]) -
            uij[index, ic]
        }
        
        ## reduce number of seats available
        nseats <- nseats - 1
        if (use.marking && ic %in% group.members) {
          group.nseats <- group.nseats - 1
        }
        elected <- c(elected, cnames[ic])
        result.elect[count, ic] <- 1
        
        result.ranks[ic] <- length(elected)
        if (!backwards.compatible) {
          wm <- winnerMargin(vcast[inPlay])
          ## sanity test on tie-breaking method: ic must have maximal votes
          stopifnot(vcast[ic] == vcast[names(wm[1])])
          result.margins[ic] <- wm[2]  ## note: margin may be NA
        }
        inPlay[ic] <- FALSE
        if (verbose && !quiet) {
          cat("Candidate", cnames[ic], "elected")
          if (!backwards.compatible) {
            cat(" with margin", result.margins[ic])
          }
          if (tie > 0) {
            cat(" using", tie.method.name[tie.method])
            if (tie == 2)
              cat(" & ordered")
            cat(" tie-breaking method ")
            if (tie > 2)
              cat("(sampled)")
          }
          cat("\n")
        }
      } else {
        ## no candidate reaches quota, and at least one can be eliminated
        stopifnot(any(D))
        elim.select <- D
        if (use.marking &&
            (nseats == group.nseats ||
             sum(Dm) <= group.nseats)) {
          elim.select <- elim.select & !Dm
        }
        ## sanity test for a corner case on Dm (group member gets no votes)
        stopifnot(any(elim.select)) 
        vmin <- min(vcast[elim.select])
        ic <- (1:nc)[vcast == vmin & elim.select]
        stopifnot(length(ic) > 0)  ## sanity test
        
        if (length(ic) > 1) {
          ## tie
          ic <-
            solveTiebreak(tie.method, result.pref, ic, otb,
                          elim = TRUE)
          tie <- 1
          tie <- tie + (attr(ic, "ordered") == TRUE)
          tie <- tie + (attr(ic, "sampled") == TRUE)
        }
        result.elect[count, ic] <- -1
        eliminated <- c(eliminated, cnames[ic])
        nEliminated <- length(eliminated)
        result.ranks[ic] <- nc - nEliminated + 1
        
        lm <- loserMargin(vcast[inPlay])
        ## sanity test on tie-breaking method: ic must have minimal votes
        stopifnot(vcast[ic] == vcast[names(lm[1])])
        if (!backwards.compatible) {
          result.margins[ic] <- lm[2] ## note: margin may be NA
        }
        inPlay[ic] <- FALSE
        
        if (verbose && !quiet) {
          cat("Candidate",
              cnames[ic],
              "eliminated")
          if (!backwards.compatible) {
            cat(" with margin", result.margins[ic])
          }
          if (tie > 0) {
            cat(" using", tie.method.name[tie.method])
            if (tie == 2)
              cat(" & ordered")
            cat(" tie-breaking method ")
            if (tie > 2)
              cat("(sampled)")
          }
          cat("\n")
        }
      }
      
      result.ties <- c(result.ties, tie)
      
      stopifnot(length(ic) == 1)  ## sanity test
      ## shift votes for voters who voted for ic
      jp <- x[, ic]
      for (i in which(jp > 0)) {
        index <- x[i, ] > jp[i]
        x[i, index] <- x[i, index] - 1
      }
      x[, ic] <- 0
      
    }
    
    rownames(result.pref) <- 1:count
    partialResult <- structure(
      list(
        elected = elected,
        preferences = result.pref,
        quotas = result.quota,
        elect.elim = result.elect,
        equal.pref.allowed = equal.ranking,
        ties = translate.ties(result.ties, tie.method),
        data = orig.x,
        invalid.votes =
          votes[setdiff(rownames(votes), rownames(x)), , drop = FALSE],
        corrected.votes = corrected.votes,
        reserved.seats = if (use.marking)
          group.nseats.orig
        else
          NULL,
        group.members = if (use.marking)
          group.members
        else
          NULL
      )
    )
    if (!backwards.compatible) {
      partialResult$nseats = nseats.initial
      partialResult$ranking = result.ranks
      partialResult$margins = result.margins
      partialResult$fuzz = safety * sqrt(nrow(orig.x))
      crt <- completeRankingTable(partialResult,
                                  quiet = quiet,
                                  verbose = verbose)
      result <- partialResult
      result$ranking <- crt$ranking
      result$margins <- crt$Margin
      result$rankingTable = crt
      sr <- crt$SafeRank  ## extract from rankingTable for convenience
      names(sr) <- row.names(crt)
      result$safeRank = sr
      attr(result, "class") <- append("SafeVote.stv", class(result))
    } else {
      result <- partialResult
      attr(result, "class") <- "vote.stv"
    }
    
    if (!quiet) {
      print(summary(result, digits = digits))
    }
    invisible(result)
  }

#' Find a winner and their margin of victory
#'
#' @param votes cleaned ballots
#'
#' @return length-2 vector: the index of a winning candidate, and their margin
#'         of victory (0 if a tie, NA if no losers)
#'
winnerMargin <- function(votes) {
  stopifnot(length(votes) > 0)
  winner <- which(votes == max(votes))
  ## random tie-break (no-op if length(winner)==1)
  winner <- winner[[sample(length(winner), 1)]]
  if (length(votes) > length(winner)) {
    margin <- max(votes) - max(votes[-winner])
  } else {
    margin <- NA
  }
  return(c(winner, margin))
}

#' Find a loser and their margin of victory
#'
#' @param votes cleaned ballots
#'
#' @return length-2 vector: the index of a losing candidate, and their margin
#'         of loss (0 if a tie, NA if no winners)
#'
loserMargin <- function(votes) {
  stopifnot(length(votes) > 0)
  loser <- which(votes == min(votes))
  ## random tie-break
  loser <- loser[[sample(length(loser), 1)]]
  if (length(votes) > length(loser)) {
    margin <- min(votes[-loser]) - min(votes)
  } else {
    margin <- NA
  }
  return(c(loser, margin))
}

#' Undocumented internal method from original code
#'
#' @param ties undocumented
#' @param method 'f' for forward, 'b' for backward
#'
#' @return undocumented
#'
translate.ties <- function(ties, method) {
  ties.char <- ifelse(ties == 0, "", method)
  ties.char <- ifelse(ties > 1, paste0(ties.char, "o"), ties.char)
  ties.char <- ifelse(ties > 2, paste0(ties.char, "s"), ties.char)
  names(ties.char) <- 1:length(ties)
  return(ties.char)
}

#' Undocumented internal method, renamed from 'solve.tiebreak' to avoid
#' confusion with generic solve()
#'
#' @param method undocumented
#' @param prefs undocumented
#' @param icans undocumented
#' @param ordered.ranking undocumented
#' @param elim undocumented
#'
#' @return undocumented
#'
solveTiebreak <- function(method,
                          prefs,
                          icans,
                          ordered.ranking = NULL,
                          elim = TRUE) {
  if (method == "f") {
    ## forwards
    ic <- forwards.tiebreak(prefs, icans, elim = elim)
  }
  else {
    ## backwards
    ic <- backwards.tiebreak(prefs, icans, elim = elim)
  }
  # solve remaining ties by ordered ranking
  sampled <- FALSE
  ordered <- FALSE
  if (length(ic) > 1) {
    ic <- ic[if (elim)
      which.min(ordered.ranking[ic])
      else
        which.max(ordered.ranking[ic])]
    sampled <- attr(ordered.ranking, "sampled")[ic]
    ordered <- TRUE
  }
  attr(ic, "sampled") <- sampled
  attr(ic, "ordered") <- ordered
  return(ic)
}

#' Undocumented internal method
#'
#' @param vmat undocumented
ordered.preferences <- function(vmat) {
  sapply(1:ncol(vmat),
         function(pref)
           apply(vmat, 2, function(f)
             sum(f == pref)))
}

#' Undocumented internal method
#'
#' @param vmat undocumented
#' @param seed undocumented
ordered.tiebreak <- function(vmat, seed = NULL) {
  ## Create elimination ranking using ordered tie-breaking element
  ## ij in matrix nij is the number of j-th preferences for
  ## candidate i
  nij <- ordered.preferences(vmat)
  ## ranking for each preference
  nij.ranking <- apply(nij, 2, rank, ties.method = "min")
  rnk <- nij.ranking[, 1]
  dpl <- duplicated(rnk) | duplicated(rnk, fromLast = TRUE)
  sampled <- rep(FALSE, length(rnk))
  ## resolve ranking duplicates by moving to the next column
  if (any(dpl)) {
    if (!is.null(seed))
      ## TODO: consider using a difficult-to-predict dithering method which
      ## favours different candidates in each round, rather than always using
      ## the same sequence of "random" numbers to break every tie.  See Sched 1A
      ## of New Zealand's Local Electoral Regulations 2001.  See also Hill,
      ## "Implementing STV by Meek’s method", Voting matters, Issue 22.
      
      ## TODO: stv() should use a private PRNG, to maintain
      ## backwards-compatibility and modifiability, and to avoid side-effects on
      ## subsequent or concurrent (interleaved) uses of R's interpreter.
      set.seed(seed)
    for (pref in 1:ncol(vmat)) {
      if (!pref %in% rnk[dpl])
        next
      j <- 2
      rnk[rnk == pref] <- NA
      while (any(is.na(rnk))) {
        ## which candidates to resolve
        in.game <- is.na(rnk)
        ## if we moved across all columns and there are still
        ## duplicates, determine the rank randomly
        if (j > ncol(nij)) {
          rnk[in.game] <- sample(sum(in.game)) + pref - 1
          sampled <- sampled | in.game
          break
        }
        rnk[in.game] <-
          rank(nij.ranking[in.game, j], ties.method = "min") +
          pref - 1
        dplj <-
          rnk == pref &
          (duplicated(rnk) |
             duplicated(rnk, fromLast = TRUE))
        rnk[dplj] <- NA
        j <- j + 1
      }
    }
  }
  attr(rnk, "sampled") <- sampled
  return(rnk)
}

#' Undocumented internal method
#'
#' @param prefs undocumented
#' @param icans undocumented
#' @param elim undocumented
forwards.tiebreak <- function(prefs, icans, elim = TRUE) {
  if (!elim)
    prefs <- -prefs
  if (is.null(dim(prefs)))
    dim(prefs) <- c(1, length(prefs))
  rnk <- t(apply(prefs, 1, rank, ties.method = "min"))
  if (is.null(dim(rnk)))
    dim(rnk) <- c(1, length(rnk))
  i <- 0
  icv <- rep(FALSE, ncol(prefs))
  icv[icans] <- TRUE
  while (i < nrow(rnk) && length(icans) > 1) {
    i <- i + 1
    ic.rnk <- rnk[i, icans]
    icans <- which(icv & (rnk[i,] == min(ic.rnk)))
  }
  return(icans)
}

#' Undocumented internal method
#'
#' @param prefs undocumented
#' @param icans undocumented
#' @param elim undocumented
backwards.tiebreak <- function(prefs, icans, elim = TRUE) {
  if (!elim)
    prefs <- -prefs
  if (is.null(dim(prefs)))
    dim(prefs) <- c(1, length(prefs))
  rnk <- t(apply(prefs, 1, rank, ties.method = "min"))
  if (is.null(dim(rnk)))
    dim(rnk) <- c(1, length(rnk))
  i <- nrow(rnk)
  icv <- rep(FALSE, ncol(prefs))
  icv[icans] <- TRUE
  while (i > 1 && length(icans) > 1) {
    i <- i - 1
    ic.rnk <- rnk[i, icans]
    icans <- which(icv & (rnk[i,] == min(ic.rnk)))
  }
  return(icans)
}

#' summary() method for a SafeVote result
#'
#' @param object undocumented, legacy code
#' @param ... undocumented
#' @param digits undocumented
#' @return data.frame summarising `object`, for use by `print` method
#' @export
#'
summary.SafeVote.stv <- function(object, ..., digits = 3) {
  
  ## The following function is of undocumented origin.  The intent of the code
  ## is apparently to introduce a "fuzz" on float-to-integer automagic
  ## conversions which is right-sized: large enough that programmer-intended
  ## integral values appear to have been computed by integer arithmetic, but not
  ## so large that any values which "really are" non-integral are ever
  ## inappropriately rounded to the nearest integer in a printout. All "fuzzing"
  ## regimes (including the ones found in various versions of Basic and Python)
  ## have the potential to distort results -- especially if the programmer has
  ## attempted to emulate integer arithmetic using "fuzzed" floating-point
  ## values. One fundamental problem is that the limited-precision mantissa of a
  ## double-precision float is mostly occupied by the significant digits of a
  ## large integer value, leaving very little headroom for "fuzzing".  Also,
  ## subtracting two floating-point numbers which are nearly equal to each other
  ## may result in a result with surprisingly-low precision, in a phenomenon
  ## sometimes called "catastrophic cancellation" [Goldberg
  ## (1991)](https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html).
  decimalplaces <- function(x) {
    ifelse(abs(x - round(x)) > .Machine$double.eps ^ 0.5,
           nchar(sub(
             '^\\d+\\.', '', sub('0+$', '', as.character(x))
           )),
           0)
  }
  ## TODO: consider using formattable::formattable() instead of this function.
  ## Note that formattable::formattable() is imported by view.stv().  See
  ## https://stackoverflow.com/questions/3443687/formatting-decimal-places-in-r

  backwards.compatible <- is.null(object$nseats)
  
  ncounts <- nrow(object$preferences)
  df <- data.frame(matrix(
    NA,
    nrow = ncol(object$preferences) + 4,
    ncol = 2 * ncounts - 1
  ),
  stringsAsFactors = FALSE)
  rownames(df) <- c("Quota",
                    colnames(object$preferences),
                    "Tie-breaks",
                    "Elected",
                    "Eliminated")
  colnames(df)[1] <- 1
  idxcols <- 1
  if (ncounts > 1) {
    colnames(df)[2:ncol(df)] <-
      paste0(rep(2:ncounts, each = 2), c("-trans", ""))
    idxcols <- c(idxcols, seq(3, ncol(df), by = 2))
  }
  df["Quota", idxcols] <- object$quotas
  df[2:(nrow(df) - 3), idxcols] <- t(object$preferences)
  ## calculate transfers
  pref <- object$preferences
  ## remove quotas for winners and compute difference
  where.winner <- which(rowSums(object$elect.elim == 1) == 1)
  pref[where.winner, ] <-
    pref[where.winner, ] -
    object$elect.elim[where.winner, ] * object$quotas[where.winner]
  if (ncounts > 1) {
    tmp <- t(object$preferences[2:nrow(object$preferences), ] -
               pref[1:(nrow(pref) - 1), ])
    if (nrow(tmp) == 1) {
      tmp <- as.numeric(tmp)  ## because of R weirdness with
      ## vectors and matrices (when there are just two counts)
    }
    df[2:(nrow(df) - 3), seq(2, ncol(df), by = 2)] <- tmp
  }
  ## format the right number of digits
  df[1:(nrow(df) - 3), ] <-
    apply(df[1:(nrow(df) - 3), , drop = FALSE], 2,
          function(d) {
            ifelse(!is.na(d),
                   format(round(d, digits),
                          nsmall =
                            min(digits,
                                max(
                                  decimalplaces(round(d[!is.na(d)], digits))
                                  
                                ))),
                   "")
          })
  where.elim <- which(rowSums(object$elect.elim == -1) == 1)
  cnames <- colnames(object$elect.elim)
  for (i in 1:ncounts) {
    if (i %in% where.winner) {
      ## Recoded Nov 22 from ... cnames[which(object$elect.elim[i,]==1)]
      elected <- cnames[object$elect.elim[i, ] == 1]
      df["Elected", idxcols[i]] <-
        paste(elected, collapse = ", ")
      for (can in elected) {
        if (idxcols[i] + 2 <= ncol(df)) {
          df[can, (idxcols[i] + 2):ncol(df)] <- NA
          
        }
      }
      
    }
    if (i %in%  where.elim) {
      ## Recoded Nov 22 from ... cnames[which(object$elect.elim[i,]==-1)]
      eliminated <- cnames[object$elect.elim[i, ] == -1]
      df["Eliminated", idxcols[i]] <-
        paste(eliminated, collapse = ", ")
      for (can in eliminated) {
        if (idxcols[i] + 2 <=  ncol(df)) {
          df[can, (idxcols[i] + 2):ncol(df)] <- NA
        }
      }
    }
  }
  
  if (any(object$ties != "")) {
    df["Tie-breaks", seq(1, ncol(df), by = 2)] <- object$ties
  }
  else {
    ## Recoded Nov 22 from ... df[-which(rownames(df) == "Tie-breaks")...
    df <- df[-(rownames(df) == "Tie-breaks"), , drop = FALSE]
  }
  if (!is.null(object$reserved.seats)) {
    rownames(df)[object$group.members + 1] <-
      paste0(rownames(df)[object$group.members + 1], "*")
  }
  df[is.na(df)] <- ""
  class(df) <- c('summary.SafeVote.stv', class(df))
  attr(df, "number.of.votes") <- nrow(object$data)
  attr(df, "number.of.invalid.votes") <-
    nrow(object$invalid.votes)
  attr(df, "number.of.candidates") <- ncol(object$preferences)
  attr(df, "number.of.seats") <- object$nseats
  if (!backwards.compatible) {
    attr(df, "number.of.seats.unfilled") <-
      object$nseats - length(object$elected)
  }
  if (!is.null(object$reserved.seats)) {
    attr(df, "reserved.seats") <- object$reserved.seats
    attr(df, "reservation.eligible") <- object$group.members
  }
  attr(df, "equal.pref.allowed") <- object$equal.pref.allowed
  attr(df, "rankingTable") <- object$rankingTable
  attr(df, "fuzz") <- object$fuzz
  return(df)
}

#' print() method for a summary() of a SafeVote result
#'
#' @param x election results
#' @param ... args to be passed to kable()
#' @return no return value, called for side-effect of printing to console
#'
#' @export
print.summary.SafeVote.stv <- function(x, ...) {
  cat("\nResults of Single transferable vote")
  if (attr(x, "equal.pref.allowed"))
    cat(" with equal preferences")
  cat("\n===================================")
  if (attr(x, "equal.pref.allowed"))
    cat("=======================")
  
  election.info(x)

  if (!is.null(attr(x, "number.of.seats.unfilled"))) {
    cat(paste0("Number of unfilled seats: ",
        attr(x, "number.of.seats.unfilled"),
        "\n"))
  }
  if (!is.null(attr(x, "reserved.seats"))) {
    cat("Number of reserved seats:\t",
        attr(x, "reserved.seats"),
        "\n")
    cat("Eligible for reserved seats:\t",
        length(attr(x, "reservation.eligible")), "\n")
  }
  if (!is.null(attr(x, "rankingTable"))) {
    cat("\nFuzz on safeRank:\t", attr(x, "fuzz"))
    cat("\nComplete ranking:")
    print(knitr::kable(attr(x, "rankingTable"),
                       align = c("r", "l", "c", "r", "l"), ...))
  }
  
  cat("\nVote transfers:")
  print(knitr::kable(x, align = 'r', ...))
  
  cat("\nElected:",
      paste(x['Elected', x['Elected', ] != ""], collapse = ", "),
      "\n\n")
}

#' generic view() for classes defined in this package
#'
#' @param object election object to be viewed
#' @param ... additional parameters, passed to formattable::formattable()
#'
#' @return html-formatted object, with side-effect in RStudio's Viewer pane
#' @export
view <- function(object, ...) {
  UseMethod("view")
}

#' view method for the result of an stv() ballot-count
#' @param object object to be viewed
#' @param ... additional parameters, passed to formattable::formattable()
#'
#' @return html-formatted object
#' @import formattable 
#' @export
#'
view.SafeVote.stv <- function(object, ...) {
  s <- summary(object)
  formatter <-
    list(
      formattable::area(row = 2:(nrow(s) - 2),
                        col = seq(1, ncol(s), by = 2)) ~
        formattable::color_text("red", "red"),
      formattable::area(row = 1, col = seq(1, ncol(s), by = 2)) ~
        formattable::color_text("blue", "blue")
      ## Quota = color_text("blue", "blue")  # comment from legacy code
    )
  formattable::formattable(s, formatter, ...)
}

#' visualisation of joint and marginal distributions in STV preferences
#'
#' @param x STV results to be visualised
#' @param xpref,ypref candidates shown in a joint distribution plot
#' @param all.pref plot the joint distribution of two preferences (if
#'   `all.pref=FALSE`) or the marginal distribution of all preferences (if
#'   `all.pref=TRUE`).
#' @param proportion The joint distribution can be shown either as proportions
#'   (if `proportion=TRUE`) or raw vote counts (if `proportion=FALSE`).
#' @param ... args passed to fields::image.plot()
#'
#' @return image object, with side-effect in RStudio Plots pane
#' @importFrom grDevices hcl.colors
#' @importFrom graphics axis mtext text par
#' @importFrom fields image.plot
#' @export
#' 
image.SafeVote.stv <- function(x,
                               xpref = 2,
                               ypref = 1,
                               all.pref = FALSE,
                               proportion = TRUE,
                               ...) {
  stopifnot(requireNamespace("ggplot2", quietly = TRUE))
  
  # Declaring temps for data.table calls.  Warning: overloads rank()
  # https://www.r-bloggers.com/2019/08/no-visible-binding-for-global-variable/
  voter <- rank <- NULL 
  
  xd <- x$data
  nc <- ncol(xd)
  if (all.pref) {
    nij <- ordered.preferences(xd)[nc:1, ]
    image.plot(
      x = 1:nc,
      y = 1:nc,
      t(nij),
      axes = FALSE,
      xlab = "",
      ylab = "",
      col = grDevices::hcl.colors(12, "YlOrRd", rev = TRUE),
      ...
    )
    graphics::axis(3, at = 1:nc, labels = 1:nc)
    graphics::axis(
      2,
      at = 1:nc,
      labels = rev(colnames(xd)),
      tick = FALSE,
      las = 2
    )
    graphics::mtext("Ranking", side = 1, line = 0.5)
  } else {
    xdt <- data.table(xd)
    xdt[, voter := 1:nrow(xd)]
    xdtl <- data.table::melt(
      xdt,
      id.vars = "voter",
      variable.name = "candidate",
      value.name = "rank"
    )
    xdtl <- xdtl[rank %in% c(xpref, ypref)]
    if (sum(duplicated(xdtl[, c("voter", "rank"), with = FALSE])) > 0) {
      stop("Sorry, the image function is not available for ballots",
           "with equal preferences.")
    }
    xdtw <- dcast(xdtl, voter ~ rank, value.var = "candidate")
    setnames(xdtw, as.character(xpref), "xpref")
    setnames(xdtw, as.character(ypref), "ypref")
    ctbl <- table(xdtw[, ypref], xdtw[, xpref])
    if (proportion) {
      ctbl <- ctbl / rowSums(ctbl)
      ctbl[is.na(ctbl)] <- 0
    }
    fields::image.plot(
      x = 1:nc,
      y = 1:nc,
      t(ctbl[nc:1, ]),
      axes = FALSE,
      xlab = "",
      ylab = "",
      col = grDevices::hcl.colors(12, "YlOrRd", rev = TRUE),
      ...
    )
    graphics::axis(
      2,
      at = nc:1,
      labels = rownames(ctbl),
      tick = FALSE,
      las = 1
    )
    graphics::text(
      1:nc,
      y = graphics::par("usr")[4],
      labels = colnames(ctbl),
      xpd = NA,
      srt = 45,
      adj = 0
    )
    graphics::mtext(paste("Preference", ypref),
          side = 4,
          line = 0.1)
    graphics::mtext(paste("Preference", xpref),
          side = 1,
          line = 0.5)
  }
}

#' plot() method for the result of an stv() ballot-count
#'
#' The `plot` function shows the evolution of the total score for each candidate
#' as well as the quota. 
#'
#' @param x stv results
#' @param xlab,ylab axis labels
#' @param point.size diameter of elected/eliminated points
#' @param ... params for generic plot()
#' @return graphics object, with side-effect in RStudio's Plots pane
#' @export
plot.SafeVote.stv <-
  function(x,
           xlab = "Count",
           ylab = "Preferences",
           point.size = 2,
           ...) {
    stopifnot(requireNamespace("ggplot2", quietly = TRUE))
    
    ## Declare temp objects for use by data.table
    Count <- value <- selection <-
      i.value <- count.select <- Candidate <-
      i.Count <- NULL
    
    ## Plot evolution of the preferences

    ## prepare data in the long format
    df <- data.table(x$preferences)
    df[, Count := 1:nrow(df)]
    dfl <-
      data.table::melt(df, id.vars = "Count", variable.name = "Candidate")
    dfl <- rbind(dfl, dfl[Count == 1][, Count := 0]) ## add Count 0
    ## with initial values dataset for plotting the quota
    dfq <- data.table(
      Count = 1:length(x$quotas),
      value = x$quotas,
      Candidate = "Quota"
    )
    
    ## dataset for plotting points of elected and eliminated candidates
    dfe <-
      data.table::melt(
        data.table(Count = 1:nrow(x$elect.elim), x$elect.elim),
        id.vars = "Count",
        variable.name = "Candidate"
      )
    dfe <- dfe[value != 0]
    dfe[, selection := ifelse(value > 0, "elected", "eliminated")]
    dfe <- dfe[dfl, value := i.value, on = c("Count", "Candidate")]
    
    ## remove data after candidates are selected
    dfl[dfe, count.select := i.Count, on = "Candidate"]
    dfl <- dfl[is.na(count.select) | Count <= count.select]
    
    ## create plots
    g <- ggplot2::ggplot(dfl,
                         ggplot2::aes(
                           x = as.factor(Count),
                           y = value,
                           color = Candidate,
                           group = Candidate
                         )) +
      ggplot2::geom_line()
    g <- g + ggplot2::geom_line(data = dfq,
                                ggplot2::aes(x = as.factor(Count)),
                                color = "black") +
      ggplot2::xlab(xlab) + ggplot2::ylab(ylab)
    g <- g + ggplot2::geom_point(data = dfe,
                                 ggplot2::aes(shape = selection),
                                 size = point.size) +
      ggplot2::ylim(range(0, max(dfl$value, dfq$value)))
    g <- g + ggplot2::annotate(
      geom = "text",
      x = as.factor(1),
      y = dfq[Count == 1, value],
      label = "Quota",
      hjust = "right"
    )
    g
  }

#' internal method to analyse the partial results of an stv() ballot count, to
#' discover a complete ranking of all candidates.  The ranking may depend on the
#' value of nseats, because this affects how votes are transferred.
#'
#' @param object partial results
#' @param quiet TRUE to suppress console output
#' @param verbose TRUE to produce diagnostic output
#'
#' @return data.frame with columns TotalRank, Margin, Candidate, Elected,
#'   SafeRank
#' 
completeRankingTable <- function(object, quiet, verbose) {
  cand.in.play <- colSums(abs(object$elect.elim)) == 0
  ## list the eliminated candidates in reverse order of elimination
  eliminated <- rev(names(unlist(
    apply(object$elect.elim, 1, function(r)
      which(r < 0))
  )))
  ranking <- object$ranking
  loseMargins <- object$margins[eliminated]
  winMargins = object$margins
  
  ## Candidates who were neither elected nor eliminated are ranked by their
  ## position in the last round
  if (any(cand.in.play)) {
    lastRound <-
      object$preferences[nrow(object$preferences), cand.in.play]
    ranking[cand.in.play] <-
      length(object$elected) + rank(-lastRound, ties.method = "random")
    if (verbose && !quiet) {
      cat("\nRanking of unelected uneliminated candidates in a final round:\n")
      print(ranking[cand.in.play])
    }
    lastRound <- lastRound[order(ranking[cand.in.play])]
    winMarg <- lastRound - c(lastRound[-1], NA)
    ## The winning margin of the last in-play candidate is the losing margin of
    ## the first-eliminated candidate (if any).
    if (length(loseMargins) > 0) {
      winMarg[length(winMarg)] <- loseMargins[1]
    } else {
      ## if no candidate has been eliminated, the winning margin of the last
      ## in-play candidate is their number of votes in the last round
      winMarg[length(winMarg)] <- lastRound[length(lastRound)]
    }
    ## Copy winMarg into the matching positions of winMargins
    winMargins[names(cand.in.play)[cand.in.play]
               [order(ranking[cand.in.play])]] <- winMarg
  } else {  ## all candidates have been either elected or eliminated
    if (any(is.na(winMargins))) {
      ## If a candidate had been elected unopposed, their winning margin is the
      ## losing margin of the first-eliminated candidate (if any).
      unopposed <- names(which(is.na(winMargins)))
      ## Sanity check: impossible to have multiple candidates elected unopposed!
      stopifnot(length(unopposed) == 1)
      if (length(loseMargins) > 0) {
        winMargins[unopposed] <- loseMargins[1]
      } else {
        ## If all candidates have been elected, the winning margin of the last
        ## candidate to be elected is their number of votes in the last round
        winMargins[unopposed] <- 
          object$preferences[nrow(object$preferences), unopposed]
        if (winMargins[unopposed] == 0) {
          ## I have found no discussion of this case in the literature on stv,
          ## but a candidate might be elected on zero votes -- if quotas are
          ## ever waived e.g. when there are "reserved seats" in the sense of
          ## vote2.3-2 or (as in STV 1.0.3) there are no more candidates in play
          ## than open seats to be filled.
          if (!quiet) {
            cat("\n", unopposed, "was elected despite having zero votes.")
          }
        }
      }
    }
  }
  
  ## Push the loseMargin of each eliminated candidate (other than the
  ## highest-ranked one) into the winMargin of the next-higher ranked candidate
  ## (if any) among the eliminated candidates.
  if (length(loseMargins) > 1) {
    winMargins[eliminated] <- c(loseMargins[-1], NA) 
  }
  
  ## The winning margin of the first candidate (if any) to be eliminated is
  ## their number of votes in the round when they were eliminated
  if (length(eliminated) > 0) {
    firstElim <- eliminated[1]
    winMargins[firstElim] <-
      object$preferences[[which(object$elect.elim[, firstElim] == -1),
                          firstElim]]
  }
  
  ## Corner case: a candidate may have been elected on NA votes in the final
  ## round, after one or more eliminations of candidates on 0 votes.
  if (any(is.na(winMargins))) {
    stopifnot(sum(is.na(winMargins)) == 1)
    winMargins[which(is.na(winMargins))] <- 0
  }
  
  ## Sanity checks: winMargins are non-negative and ranking is total
  stopifnot(!any(is.na(winMargins)) || !any(winMargins < 0))
  stopifnot(!any(sort(ranking) != c(1:length(ranking))))
  
  ## Iterative 1-d clustering to produce a "safe" ranking
  safeRank <- ranking[order(ranking)]
  rmargs <- winMargins[order(ranking)]
  for (i in 2:length(ranking)) {
    if (is.na(rmargs[i - 1])) {
      stop("NA margin at rank ", i)
    } else {
      if (rmargs[i - 1] < object$fuzz) {
        safeRank[i] <- safeRank[i - 1]
      }
    }
  }
  ## Rearrange safeRank into canonical order (as on ballots)
  safeRank <- safeRank[names(ranking)]
  
  result <-
    data.frame(
      TotalRank = ranking,
      SafeRank = safeRank,
      Margin = winMargins
    )

  return(result)
}
