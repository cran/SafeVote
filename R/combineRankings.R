#' check the validity of a partial ranking
#'
#' @param r a numeric vector
#'
#' @return a partial ranking of the elements of 'r', using 'ties.method="min"'
#' @export
check.ranking <- function(r) {
    rc <- rank( r, ties.method="min" )
    if( ! all( r == rc ) ) {
        warning( "ranking (", paste(r,collapse=" "), ") corrected to (",
                paste(rc,collapse=" "), ")" )
    }
    return( rc )
}

#' the least upper bound on a pair of rankings
#'
#' @param r1,r2 numeric vectors 
#' @return the most complete (but possibly partial) ranking which is consistent
#'  with both r1 and r2.  Uses 'ties.method="min"'
#' @export
#' @examples combineRankings( c(3,1,2), c(2,1,3) )
combineRankings <- function(r1,r2) {
    if( length(r1) != length(r2) ){
        stop( "Error: can't combine rankings of different length" )
    }
    r1 <- check.ranking(r1)
    r2 <- check.ranking(r2)
    return( rank( pmin(r1,r2), ties.method="min" ) )
}
