# Run from repository root: Rscript scripts/01_prepare_data.R
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})
source('R/text_cleaning.R')
input <- readr::read_csv('data/synthetic_q22.csv', show_col_types = FALSE)
stopifnot(nrow(input) == 100L)
prepared <- prepare_q22(input)
dir.create('output', showWarnings = FALSE)
readr::write_csv(prepared, 'output/q22_prepared.csv')
message('Input respondents: ', nrow(input),
        '; nonempty mentions after splitting: ', nrow(prepared),
        '; respondents with at least one mention: ', dplyr::n_distinct(prepared$RESPID))
