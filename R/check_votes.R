#' read a set of ballots in .HIL format
#' 
#' [rangevoting.org/TidemanData.html](https://rangevoting.org/TidemanData.html):
#' The data are in a format developed by David Hill. The first line contains the
#' number of candidates and the number to be elected. (Many but not all
#' elections were multi-winner.) In subsequent lines that represent ballot
#' papers, the first number is always 1. (The format was designed for a counting
#' program that treats the first number as the number of instances of the
#' ordering of the candidates on the line.) Next on these lines is a sequence of
#' numbers representing a voter's reported ranking: The number of the candidate
#' ranked first, the number of the candidate ranked second, and so on. The end
#' of the reported ranking is signaled by a zero. A zero at the beginning of the
#' ranking is a signal that the list of ballot papers has ended. Next come the
#' names of the candidates, each in parentheses, as required by the counting
#' program, and finally the name of the election.
#'
#' @param filnm name of a file in .HIL format
#' @param quiet suppress diagnostic output 
#'
#' @return a matrix with one row per ballot, one column per candidate, with
#'   named rows and columns, and with attributes "nseats" and "ename"
#' @export
#' 
#' @importFrom stringr str_split_1
#'
readHil <- function(filnm, quiet=FALSE){
  
  rankToPref <- function(hilrank, nc) {
    # input is a 0-terminated vector of candidate names
    # output is a length-nc vector of voter preferences (integers)
    stopifnot(length(hilrank) == nc+1)
    if (length(which(hilrank == 0)) != 1) {
      stop(paste(
        "\nInvalid .HIL file:",
        "ballot is recorded as (",
        hilrank,
        ") but must end with a 0"
      ))
    }
    if (hilrank[1] == 0) {
      warning("\nBlank ballot paper")
      ranking <- integer(0)
    } else {
      ranking <- hilrank[1:(which(hilrank == 0) - 1)]
      if ((length(ranking) != length(unique(ranking))) ||
          (length(ranking) > nc) ||
          (max(ranking) > nc) ||
          (min(ranking) < 1)) {
        stop(
          paste(
            "\nInvalid .HIL file:",
            "ballot (",
            hilrank,
            ") is an ambiguous preference-ranking of the",
            nc,
            "candidates"
          )
        )
      }
    }
    ## from Rankcluster:::convertSingleRank
    prefs <- rep(0, nc)
    ind <- ranking[ranking > 0]
    for (i in ind) {
      prefs[i] <- which(ranking == i)
    }
    return(prefs)
  }
  
  if (is.character(filnm)) {
    data <- utils::read.csv(file = filnm, sep=" ", header=FALSE)
  }
  
  ## first row contains number of candidates and seats
  firstRow <- data[1, ]
  nc <- as.numeric(firstRow[1])
  nseats <- as.numeric(firstRow[2])
  if (!quiet) {
    cat(
      paste0(
        "\n",
        filnm,
        " : ncandidates = ",
        nc,
        ", nseats = ",
        nseats,
        ", nballots = ",
        nrow(data) - 3
      )
    )
  }
  if (is.na(nc) || (nc < 1) || is.na(nseats) || (nseats < 1)) {
    stop(paste(
      "\nInvalid .HIL file:",
      "invalid number of candidates",
      nc,
      "or seats",
      nseats
    ))
  }
  
  ## re-read file, with nc+2 columns.  Ballots are encoded with a leading
  ## repetition-count, a preference-ordered vector of candidates, and a
  ## trailing 0.
  if (is.character(filnm)) {
    data <- utils::read.csv(file = filnm, sep=" ", header=FALSE,
                            col.names = c(0:(nc+1)),
                            colClasses = rep("character", nc+1))
  }
  
  ## last row contains candidate names and the name of the election
  names <- as.list(data[nrow(data), ])
  cnames <- names[1:nc]
  electionName <- names[[nc+1]]

  if (length(cnames) != nc) {
    stop(
      paste(
        "\nInvalid .HIL file:",
        "number of candidates is",
        nc,
        "but",
        length(cnames),
        "candidate names are specified"
      )
    )
  }
  
  if (!quiet) {
    cat("\nName of election, as recorded in file: ", electionName)
  }
  
  # omit drive from election name
  electionNameSplit <- stringr::str_split_1(electionName,"[:]") 
  ename1 <- toupper(electionNameSplit[length(electionNameSplit)])

  # omit drive, path, and extension from filnm
  filnmSplit <- stringr::str_split_1(filnm, "[:/.]")
  ename2 <- toupper(filnmSplit[length(filnmSplit)-1]) 
  
  if (ename1 != ename2) {
    warning(paste(
      "\nInvalid .HIL file:",
      "filnm is",
      filnm,
      "but the election name is",
      electionName
    ))
  }
  if (length(ename2) > length(ename1)) {
    ename <- ename2
  } else {
    ename <- ename1
  }
  
  ## penultimate row should be 0
  penultimateRow <- as.list(data[nrow(data) - 1, ])
  if (penultimateRow[1] != 0) {
    stop(paste(
      "\nInvalid .HIL file:",
      "penultimate row should be 0 but is",
      penultimateRow
    ))
  }
  
  x <- data[2:(nrow(data) - 2), ] # stripping rows
  
  if (any(x[, 1] != 1)) {
    stop(
      paste(
        "\nUnsupported option in .HIL file:",
        "all ballot-repetition counts must be 1, but min =",
        min(x[, 1]),
        "and max =",
        max(x[, 1])
      )
    )
  }
  
  # retain the last column of x for the trailing 0 in each row
  x <- x[paste0("X", c(1:(nc + 1)))] 
  x <- sapply(x, as.numeric)
  votes <- t(apply(x, 1, rankToPref, nc=nc))
  colnames(votes) <- cnames
  votes <- as.matrix(prepare.votes(votes))
  attr(votes, "nseats") <- nseats
  attr(votes, "ename") <- ename
  return(votes)
}

#' parameter-checking method for nseats (internal)
#'
#' @param nseats initially-specified number of seats to be filled in an election
#' @param ncandidates the number of candidates standing for election
#' @param default the return value of this function when nseats=NULL
#' @param mcan a deprecated name for nseats
#' @param complete.ranking when TRUE, the return value is in 1..ncandidates
#'   When FALSE, the return value is in 1..ncandidates-1 (for backwards
#'   compatibility)
#'
#' @return a valid non-NULL value for the number of seats to be filled
#'
check.nseats <- function(nseats = NULL, ncandidates, default=1, mcan = NULL,
                         complete.ranking = FALSE) {
  if(!is.null(mcan)) {
    if(is.null(nseats)) nseats <- mcan
    warning("Argument mcan is deprecated and will be removed in the future.", 
            "Use nseats instead. Using nseats = ", nseats)
  }
  if(is.null(nseats)) return(default)
  if( (nseats < 1 || nseats > ncandidates) ) {
    warning("Adjusting nseats (originally ", nseats, 
            ") to be in 1..", ncandidates
            )
    nseats <- max(1, min(nseats, ncandidates))
  }
  return(nseats)
}

#' undocumented internal method
#' @param record,equal.ranking,... undocumented
#' @return undocumented
check.votes.stv <- function(record, equal.ranking = FALSE, ...) {
  if(any(! (record %in% 0:length(record))) || ! 1 %in% record) {
    return(FALSE)
  }
  if(!equal.ranking){
    z <- sort(diff(c(0, diff(sort(c(0, record))), 1)))
    return(z[length(record)] == 0 && z[length(record) + 1] == 1)
  }
  # check for equal ranking
  return(all(record[record > 0] == rank(record[record > 0], 
                                        ties.method = "min")))
}

#' undocumented internal method
#' @param record,...  undocumented
#' @return undocumented
check.votes.condorcet <- function(record, ...) {
  if(any(! (record %in% 0:length(record))) || ! 1 %in% record) return(FALSE)
  should.be <- rank(record[record > 0], ties.method = "min")
  return(all(record[record > 0] == should.be))
}

#' undocumented internal method
#' @param record,... undocumented
#' @return undocumented
check.votes.approval <- function(record, ...) {
  return(all(record %in% c(1,0)))
}

#' undocumented internal method
#' @param record,... undocumented
#' @return undocumented
check.votes.plurality <- function(record, ...) {
  return(all(record %in% c(1,0)) && sum(record) == 1)
}

#' undocumented internal method
#' @param record,max.score,... undocumented
#' @return undocumented
check.votes.score <- function(record, max.score, ...) {
  return(all(record %in% 0:max.score))
}

#' undocumented internal method
#' @param record,... undocumented
#' @return undocumented
check.votes.tworound.runoff <- function(record, ...) {
  return(check.votes.stv(record, ...))
}

#' undocumented internal method
#' @param x,method,... undocumented
#' @return undocumented
is.valid.vote <- function(x, method, ...) {
  return(apply(x, 1, paste0("check.votes.", method), ...))
}

#' undocumented internal method
#' @param x,quiet,... undocumented
#' @return undocumented
check.votes <- function(x, ..., quiet = FALSE) {
  ok <- is.valid.vote(x, ...)
  if (any(!ok) && !quiet)
    cat(
      "Detected ",
      sum(!ok),
      "invalid votes. Number of valid votes is",
      sum(ok),
      ".\nUse invalid.votes(...) function to view discarded records.\n"
    )
  attr(x, "invalidVotes") <- x[!ok,] 
  return(x[ok,])
}

#' Extracts the invalid.votes member (if any) from the result of a count
#'
#' This method was added Jan 2022 -- it was named in a warning message but had
#' apparently either never been implemented, or had been "lost" through
#' versioning.
#'
#' @param x value returned by stv, condorcet, approval, plurality, or score
#'
#' @return matrix with one column per candidate and one row per invalid
#'   ballot
#' @export
#'
invalid.votes <- function(x) {
  if ("invalid.votes" %in% names(x)) {
    return(x$invalid.votes)
  } else {
    warning(paste("\nThere is no invalid.votes member in these results.",
                  "\nUse invalid.votes(stv(dataSetName,quiet=TRUE))",
                  "to list the ballots",
                  "in dataSetName which are invalid for stv()"))
    return(NULL)
  }
}

#' undocumented internal method
#' @param x,max.score,... undocumented
#' @return undocumented
assemble.args.for.check.score <- function(x, max.score = NULL, ...) {
  if(is.null(max.score)  || max.score < 1) max.score <- max(x)
  return(list(max.score=max.score))
}

#' undocumented internal method
#' @param x,equal.ranking,... undocumented
#' @return undocumented
assemble.args.for.check.stv <- function(x, equal.ranking = FALSE, ...) {
  return(list(equal.ranking=equal.ranking))
}

#' Coerce input 'data' into a matrix
#' @param data possibly a .csv file, possibly an R object
#' @param fsep separation character for .csv e.g. tab or comma
#' @return a matrix with one row per ballot, one column per candidate, with
#'   named rows and columns
#' @importFrom utils read.table
prepare.votes <- function(data, fsep="\n") {
  if (is.character(data)) {
    data <- utils::read.table(file = data, header = TRUE, 
                              sep=fsep, row.names = NULL)
  }
  x <- as.matrix(data)
  x[is.na(x)] <- 0
  if (is.null(colnames(x))) {
    warning("Candidate names not supplied, dummy names used instead.")
    colnames(x) <- LETTERS[1:ncol(x)]
  }
  if (is.null(rownames(x))) {
    rownames(x) <- 1:nrow(x)
  }
  return(x)
}

#' Amend ballots with equal or incomplete preferences 
#' 
#' The 'correct.ranking' function returns a modified set of ballots.  Its
#' argument 'partial' determines if ballots are partially set to '0' ('TRUE'),
#' or if it is a complete re-ranking, as allowed when 'equal.ranking = TRUE'. It
#' can be used by calling it explicitly. It is called by 'stv' if 'equal.ranking
#' = TRUE' or 'invalid.partial = TRUE'. It is also called from within the
#' 'condorcet' function with the default value ('FALSE') for 'partial', i.e.
#' interpreting any '0' as a last= preference.
#' 
#' @param votes original contents of ballot box
#' @param partial if 'FALSE' (default), each ballot is interpreted, if possible,
#'   as a complete (but not necessarily total) ranking of the candidates.  If
#'   'TRUE', a ballot will contain a '0' on unranked candidates.
#' @param quiet suppress diagnostics
#' @return corrected ballots
correct.ranking <- function(votes,
                            partial = FALSE,
                            quiet = FALSE) {
  do.rank <- function(x) {
    res <- rep(0, length(x))
    res[x > 0] <- rank(x[x > 0], ties.method = "min")
    res
  }
  do.partial <- function(x) {
    d <- diff(sort(c(0, x))) # handle gaps in ranking
    if (any(d > 1)) {
      r <- x[names(d[d > 1][1])]
      x[x >= r] <- 0
    }
    d <- which(duplicated(x) & x > 0)
    if (length(d) > 0)
      x[x >= min(x[d])] <- 0
    return(x)
  }
  if (partial) {
    fct <- do.partial
    wrn <- "partially corrected (some may be still invalid)"
  } else {
    fct <- do.rank
    wrn <- "corrected to comply with the required format"
  }
  if (partial)
    do.partial
  else
    do.rank
  v <- t(apply(votes, 1, fct))
  dif <- rowSums(v != votes)
  if (any(dif > 0) && !quiet) {
    if (sum(dif > 0) <= 10) {
      warning("\nBallots ",
              paste(which(dif > 0), collapse = ", "),
              " were ",
              wrn,
              ".\n")
    } else {
      warning(paste("\n", sum(dif > 0), "ballots were ", wrn, ".\n"))
    }
  }
  colnames(v) <- colnames(votes)
  rownames(v) <- rownames(votes)
  return(v)
}

#' Remove a candidate, amending ballot papers as required
#' 
#' @param votes ballot box
#' @param can candidate to be removed
#' @param quiet suppress diagnostics
#' @return amended ballot box
#' 
remove.candidate <- function(votes, can, quiet = TRUE) {
  if (!all(can %in% colnames(votes)) ||
      (is.numeric(can) && !all(can %in% 1:nrow(votes))))
    stop("Value(s) of can not found in the set of candidates.")
  if (is.numeric(can))
    votes <- votes[, -can, drop = FALSE]
  else
    votes <- votes[, !colnames(votes) %in% can]
  return(correct.ranking(votes, quiet = quiet))
}
