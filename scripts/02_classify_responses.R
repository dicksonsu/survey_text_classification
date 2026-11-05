# Run after 01_prepare_data.R from repository root.
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
})
source('R/classification_helpers.R')
stopifnot(file.exists('output/q22_prepared.csv'))
prepared <- readr::read_csv('output/q22_prepared.csv', show_col_types = FALSE)
classified <- prepared |>
  dplyr::mutate(response_type = classify_q22(Q22))
stopifnot(!anyNA(classified$response_type), nrow(classified) == nrow(prepared))
readr::write_csv(classified, 'output/q22_classified.csv')
print(classified |> dplyr::count(response_type, sort = TRUE))
