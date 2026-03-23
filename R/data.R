#' Sample data for testing SafeVote
#'   
#' @title Food Election
#' @docType data
#' @format A data frame with 20 observations and 5 candidates (Oranges, 
#'   Pears, Chocolate, Strawberries, Sweets). Each record corresponds to 
#'   one ballot with ranking for each of the candidates. 
#' @keywords datasets
"food_election"

#' @title Dublin West
#' @docType data
#' @description Dataset containing ranked votes for the Dublin West constituency
#'   in 2002, Ireland.
#' @seealso [Wikipedia](https://en.wikipedia.org/wiki/Dublin_West#2002_general_election)
#' @format A data frame with 29988 observations and 9 candidates. Each record 
#' corresponds to one ballot with candidates being ranked between 1 and 9 with 
#' zeros allowed.
#' @keywords datasets
"dublin_west"

#' @title Dublin West vote count
#' @docType data
#' @format A copy of the output of the stv() method of vote 2.5-2,
#'   when it produces a complete ranking of candidates standing
#'   in the Dublin West election of 2002.  The runtime of that count
#'   is approximately 2 minutes on my laptop, making it painful to
#'   regress against vote::stv(dublin_west, complete.ranking = TRUE).
#' @keywords dataset
"dublin_west_vote_count"

#' @title Dublin West vote count, identifying the top 3 candidates
#' @docType data
#' @format A copy of the output of the stv() method of vote 2.5-2,
#'   when it tallies the ballots of candidates standing in the Dublin 
#'   West election of 2002.  The runtime of that count is approximately 2 
#'   minutes on my laptop, making it painful to regress against 
#'   vote::stv(dublin_west, nseats = 3, complete.ranking = TRUE).
#' @keywords testing
"dublin_west_vote_count_3seats"

#' @title IMS Election
#' @docType data
#' @description Datasets containing anonymized votes for a past Council 
#' election of the Institute of Mathematical Statistics (IMS). The dataset 
#' ims_election is the original dataset used with single transferable vote, 
#' where candidate names have been changed.
#' @format A data frame with 620 observations and 10 candidates (names were 
#' made up). Each record corresponds to one ballot. The IMS Council voting 
#' is done using the STV method, and thus the ims_election dataset contains 
#' ballots with candidates being ranked between 1 and 10 with zeros allowed.
#' @keywords datasets
"ims_election"

#' @title IMS STV
#' @docType data
#' @description Copy of ims_election, included for backwards compatibility.
#' @format A data frame with 620 observations and 10 candidates (names were 
#' made up). Each record corresponds to one ballot. The IMS Council voting 
#' is done using the STV method, and thus the ims_election dataset contains 
#' ballots with candidates being ranked between 1 and 10 with zeros allowed.
#' @keywords datasets
"ims_stv"

#' @title IMS Approval
#' @docType data
#' @description Modified version of ims_election, for use in approval voting.
#' @format A data frame with 620 observations and 10 candidates (names were 
#' made up). Each record corresponds to one ballot, with 0 indicating
#' disapproval of a candidate and 1 indicating approval.
#' @keywords datasets
"ims_approval"

#' @title IMS Score
#' @docType data
#' @description Modified version of ims_election, for use in score voting.
#' @format A data frame with 620 observations and 10 candidates (names were 
#' made up). Each record corresponds to one ballot, with higher values
#' indicating the more-preferred candidates.
#' @keywords datasets
"ims_score"

#' @title IMS Plurality
#' @docType data
#' @description Modified version of ims_election, for use in plurality voting.
#' @format A data frame with 620 observations and 10 candidates (names were 
#' made up). Each record corresponds to one ballot, with 1 against
#' the voter's most-preferred candidate and 0 against all other candidates.
#' @keywords datasets
"ims_plurality"

#' @title Yale Faculty Senate 2016
#' @docType data
#' @description This data follows the structure of a 2016 Yale
#'   Faculty Senate election, with candidate names anonymised and permuted.
#'   Imported to SafeVote from [STV v1.0.2](https://github.com/jayemerson/STV),
#'   after applying the 'STV::cleanBallots' method to remove the ten empty
#'   rows.
#' @format A data frame with 479 observations and 44 candidates. 
#' @keywords datasets
"yale_ballots"

#' @title UK Labour Party Leader 2010
#' @docType data
#' @description These are the ballots cast by Labour MPs and MEPs in an election
#'   of their party's leader in 2010, as published by the Manchester Guardian.
#'   The names of the electors have been suppressed in this file, but are
#'   available at rangevoting.org,
#'   along with extensive commentary on the election.
#' @format A data frame with 266 observations and 5 candidates.
#' @keywords datasets
"uk_labour_2010"

#' @title Tideman a3_hil
#' @docType data
#' @description This data is one of 87 sets of ballots from the Tideman data
#'   collection, as curated by The Center for Range Voting.
#'
#'   This set of ballots was collected in 1987 by Nicolaus Tideman, with support
#'   from NSF grant SES86-18328. "The data are records of ballots from elections
#'   of British organizations (mostly trade unions using PR-STV or IRV voting)
#'   in which the voters ranked the candidates. The data were gathered under a
#'   stipulation that the organizations involved would remain anonymous."
#'
#'   The ballots were encoded in David Hill's format, and have been converted to
#'   the preference-vector format of this package.  The archival file
#'   A4.HIL at rangevoting.org contains eight blank ballot
#'   papers (1, 616, 619, 620, 685, 686, 687, 688) which we have retained. This
#'   set may be counted by 'stv(a3_hil,nseats=attr(a3_hil,"nseats"))'.
#'   
#' @format A data frame with attribute "nseats" = 7, consisting of 989
#'   observations and 15 candidates.
#' @keywords datasets
"a3_hil"

#' @title Tideman a4_hil
#' @docType data
#' @description This data is one of 87 sets of ballots from the Tideman data
#'   collection, as curated by The Center for Range Voting. The ballots were
#'   archived in David Hill's format, and have been converted to the
#'   preference-vector format of this package.
#'
#'   This set of ballots was collected in 1987 by Nicolaus Tideman, with support
#'   from NSF grant SES86-18328. "The data are records of ballots from elections
#'   of British organizations (mostly trade unions using PR-STV or IRV voting)
#'   in which the voters ranked the candidates. The data were gathered under a
#'   stipulation that the organizations involved would remain anonymous."
#' @format A data frame with attribute "nseats" = 2, consisting of 43
#'   observations and 14 candidates.
#' @keywords datasets
"a4_hil"

#' @title Tideman a53_hil
#' @docType data
#' @description This data is one of 87 sets of ballots from the Tideman data
#'   collection, as curated by The Center for Range Voting.
#' 
#'   This set of ballots was collected in 1988 by Nicolaus Tideman, with support
#'   from NSF grant SES86-18328. "The data are records of ballots from elections
#'   of British organizations (mostly trade unions using PR-STV or IRV voting)
#'   in which the voters ranked the candidates. The data were gathered under a
#'   stipulation that the organizations involved would remain anonymous."
#'
#'   The ballots were encoded in David Hill's format, and have been converted to
#'   the preference-vector format of this package.  Candidates have been renamed
#'   to letters of the alphabet, for ease of comparison with Table 3 of Tideman
#'   (2000). Note: the DOI for this article is 10.1023/A:1005082925477, with an
#'   embedded colon which isn't handled by the usual DOI-to-URL conversions.
#'   
#'   As noted in this table, it is a very close race between candidates D, F,
#'   and B in the final rounds of a Meek count of 'a53_hil'.  
#'   
#'   Tideman's implementation of Meek's method excludes B (on 59.02 votes), then
#'   elects D in the final round (on 88.33 votes) with a margin of 0.95 votes
#'   ahead of F (on 87.38 votes).  
#'   
#'   In v1.0, 'stv(a53.hil,quota.hare=TRUE)' excludes F (on 56.418 votes), then
#'   elects D in the final round (on 79.705 votes) with a winning margin of
#'   0.747 votes ahead of B (on 78.958 votes). The result of the election is the
#'   same but the vote counts and winning margins differ significantly; so we
#'   conclude that 'stv(quota.hare=TRUE)' in SafeVote v1.0 is *not* a reliable
#'   proxy for Tideman's implementation of Meek's algorithm.
#'   
#'   Future researchers may wish to adjust the quota calculation of 'vote.stv()'
#'   so that it is no longer biased upward by a "fuzz" of 0.001, to see if this
#'   change significantly reduces the discrepancies with Tideman's
#'   implementation of Meek.
#'   
#'   It would be unreasonable to expect an exact replication of results from two
#'   different implementations of an STV method.  We leave it to future
#'   researchers to develop a formal specification, so that it would be possible
#'   to verify the correctness of an implementation.  We also leave it to future
#'   researchers to develop a set of test cases with appropriate levels of
#'   tolerance for the vagaries of floating-point roundoff in optimised (or even
#'   unoptimised!) compilations of the same code on different computing systems.
#'   We suggest that 'a53_hil' be included in any such test set.
#'   
#'   We note in passing that B.A. Wichmann, in "Checking two STV programs",
#'   Voting Matters 11, 2000, discussed the cross-validation exercise he
#'   conducted between the ERBS implementation of its voting rules and the
#'   Church of England's implementation of its voting rules.  In both cases, he
#'   discovered ambiguities in the specification as well as defects in the
#'   implementation.
#' @format A data frame with attribute "nseats" = 4, consisting of 460
#'   observations and 10 candidates.
#' @keywords datasets
"a53_hil"

#' @title Results of Gisborne Local Elections 2022
#' @docType data
#' @format Results of [three STV elections in Gisborne, New Zealand, in
#'   2022](https://www.gdc.govt.nz/council/mayor-and-councillors/Local-body-elections/2022-local-elections).
#'   The results for each count of the ballots (progress, preliminary, and
#'   final) include quotas, keep values, non-transferable votes(NTV), and the
#'   number of the round in which each candidate was elected or eliminated.
#' @keywords datasets
"gisborne2022"

#' @title Results of Auckland Local Elections 2022
#' @docType data
#' @format A data frame with 1076 observations and 13 variables.  These are the
#'   vote totals and rank-ordering of candidates in the progress and final
#'   results of [STV elections in Auckland, New Zealand, in
#'   2022](https://voteauckland.co.nz/en/past-local-elections-by-elections/2022-local-elections-results.html).
#'   "Progress results include votes returned up until Friday 7 October. Special
#'   votes and votes hand delivered by 12 noon on Saturday 8 October are not
#'   included... Final count includes all votes, including special votes that
#'   are returned by 12 noon on Saturday 8 October."  We have calculated
#'   nBallots from the votes as reported by the Electoral Officer, see
#'   data-raw/auckland2022.R for details.  Curiously, the reported votes are all
#'   integral, suggesting that some method other than Meek's was used to count
#'   the ballots, or that some postprocessing of the usual reporting of Meek's
#'   results was performed to avoid the (apparent) double-counting of votes
#'   which occurs whenever an excluded candidate's votes are both reported
#'   against this candidate *and* also distributed among the candidates still in
#'   play.
#' @keywords datasets
"auckland2022"

#' @title Results of Hamilton Local Elections 2022
#' @docType data
#' @format Results for the 2022 local body elections in Hamilton New Zealand, 
#'   as had been published at Hamilton City Council's election-only website
#'   yourcityelections.co.nz.  These results include quotas, keep values, 
#'   non-transferable votes(NTV), and the number of the round in which each 
#'   candidate was either elected or eliminated.
#' @keywords datasets
"hamilton2022"

#' @title Analysis of results from the Gisborne 2022 election.
#' @format a dataframe with a column labelled "closeness" -- which is easily
#'   calculated and might be a valid metric for the safety of the results of an
#'   STV election.
#' @keywords datasets
"gisborne2022analysis"

#' @title Analysis of results from the Hamilton 2022 election.
#' @format a dataframe with a column labelled "closeness" -- which is easily
#'   calculated and might be a valid metric for the safety of the results of an
#'   STV election.
#' @keywords datasets
"hamilton2022analysis"

#' @title Analysis of results from the Wellington 2022 election.
#' @format a dataframe with a column labelled "closeness" -- which is easily
#'   calculated and might be a valid metric for the safety of the results of an
#'   STV election.
#' @keywords datasets
"wellington2022analysis"

