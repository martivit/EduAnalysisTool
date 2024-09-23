testthat::test_that("plots are the same", {
  expected_plots_folder <- "tests/fixtures/plots/"
  actual_plots_folder <- "output/plots/"
  
  expected_output <- list.files(expected_plots_folder, "*.rds",recursive = T,full.names = T) |> 
    purrr::map(readRDS)

  actual_output <- list.files(actual_plots_folder, "*.rds",recursive = T,full.names = T) |> 
    purrr::map(readRDS)
  
  testthat::expect_true(length(expected_output) == length(actual_output))
  purrr::map2(.x = actual_output, .y = expected_output,
              .f = \(.x,.y) {
                length(.x) == length(.y)
              }) |>  
    all() |> 
    suppressWarnings() |> 
    testthat::expect_true()
  # checks <- list()
  # 
  # ggplot2_to_check <- c("data", 
  #                       # "layers",
  #                       # "scales" ,
  #                       # "guides",
  #                       # "mapping", 
  #                       # "theme",
  #                       # "coordinates", 
  #                       # "facet",
  #                       # "plot_env",
  #                       # "layout", 
  #                       "labels")
  # for(i in 1:length(actual_output)) {
  #   checks[[i]] <- list()
  #   for(j in 1:length(actual_output[[i]])) {
  #     checks[[i]][[j]] <- list()
  #     for(k in seq_along(ggplot2_to_check)) {
  #       checks[[i]][[j]][[ggplot2_to_check[k]]] <- all.equal(actual_output[[i]][[j]][[k]], 
  #                                                            expected_output[[i]][[j]][[k]])
  #     }
  # 
  #     
  #   }
  # }
  
})

