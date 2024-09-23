testthat::test_that("rds filtered results are equal", {
  expected_output_folder <- "tests/fixtures/rds_results/"
  actual_output_folder <- "output/rds_results/"
  expected_output <- list.files(expected_output_folder, full.names = T) |>
    map(~ readRDS(.x))
  actual_output <- list.files(actual_output_folder, full.names = T) |>
    map(~ readRDS(.x))
  testthat::expect_equal(actual_output, expected_output)
})
