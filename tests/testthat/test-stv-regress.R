test_that("vote.stv defaults on food_election", {
  skip_if_not_installed("vote")
  expect_equal(
    SafeVote::stv(food_election, backwards.compatible = TRUE),
    vote::stv(food_election, complete.ranking = TRUE)
  )
})

test_that("vote.stv defaults on ims_election", {
  skip_if_not_installed("vote")
  expect_equal(
    SafeVote::stv(ims_election, backwards.compatible = TRUE),
    vote::stv(ims_election, complete.ranking = TRUE)
  )
})

test_that("vote.stv defaults on dublin_west", {
  skip_if_not_installed("vote")
  expect_equal(
    SafeVote::stv(dublin_west, backwards.compatible = TRUE),
    vote::stv(dublin_west, complete.ranking = TRUE)
  )
})

test_that("vote.stv on dublin_west with three seats", {
  skip_if_not_installed("vote")
  expect_equal(
    SafeVote::stv(
      dublin_west,
      nseats = 3,
      backwards.compatible = TRUE
    ),
    vote::stv(
      dublin_west,
      nseats = 3,
      complete.ranking = TRUE
    )
  )
})

test_that("vote.stv on food_election with three seats and seed = 1234", {
  skip_if_not_installed("vote")
  expect_equal(
    SafeVote::stv(
      food_election,
      nseats = 3,
      seed = 1234,
      backwards.compatible = TRUE
    ),
    vote::stv(
      food_election,
      nseats = 3,
      seed = 1234,
      complete.ranking = TRUE
    )
  )
})

test_that("stv.STV on yale_ballots with seed = 1234", {
  skip_if_not_installed("STV")
  expect_equal(SafeVote::stv(
    yale_ballots,
    nseats = 4,
    seed = 1234,
    quota.hare = TRUE
  )$elected,
  {
    set.seed(1234)
    STV::stv(yale_ballots,
             seats = 4,
             surplusMethod = "Fractional")$elected
  })
  
})
