testthat::test_that("excel output are equal", {
  expected_output_excel <- "tests/fixtures/expected_education_results.xlsx"
  actual_output_excel <- "output/education_results.xlsx"

  expected_output <- readxl::excel_sheets(expected_output_excel) |>
    map(~ readxl::read_excel(expected_output_excel, sheet = .x))
  actual_output <- readxl::excel_sheets(actual_output_excel) |>
    map(~ readxl::read_excel(actual_output_excel, sheet = .x))
  all.equal(actual_output, expected_output)
  testthat::expect_equal(actual_output, expected_output)
})
#
# openXL(expected_output_excel)
# openXL(actual_output_excel)
