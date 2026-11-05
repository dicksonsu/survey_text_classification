# Run from repository root after scripts/02_classify_responses.R.
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
})
source('R/entity_standardization.R')
stopifnot(file.exists('output/q22_classified.csv'))
stopifnot(file.exists('data/entity_aliases.csv'))
classified <- readr::read_csv('output/q22_classified.csv', show_col_types = FALSE)
aliases <- readr::read_csv('data/entity_aliases.csv', show_col_types = FALSE)
standardized <- standardize_entities(classified, aliases)
stopifnot(nrow(standardized) == nrow(classified))
stopifnot(!anyNA(standardized$standardization_status))
stopifnot(!anyDuplicated(standardized[c('RESPID', 'mention_number')]))
dir.create('output', showWarnings = FALSE)
readr::write_csv(standardized, 'output/q22_standardized.csv')

cat('\nStandardization status:\n')
print(dplyr::count(standardized, standardization_status, sort = TRUE))
cat('\nMost frequently referenced standardized entities/sources:\n')
print(standardized |>
        dplyr::filter(response_type %in% c('entity', 'named_source')) |>
        dplyr::count(entity_clean, sort = TRUE) |>
        utils::head(20))
cat('\nUnmapped unique mentions to review (first 30):\n')
print(standardized |>
        dplyr::filter(standardization_status == 'unmapped_candidate') |>
        dplyr::distinct(Q22, entity_clean) |>
        utils::head(30))
