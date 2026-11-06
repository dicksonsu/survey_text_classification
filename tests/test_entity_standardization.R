# Run from repository root: Rscript tests/test_entity_standardization.R
suppressPackageStartupMessages({library(dplyr); library(stringr); library(readr)})
source('R/entity_standardization.R')
aliases <- readr::read_csv('data/entity_aliases.csv', show_col_types=FALSE)
stopifnot(!anyNA(aliases$mention), !anyNA(aliases$entity_clean))
normalized_keys <- stringr::str_squish(stringr::str_to_lower(aliases$mention))
stopifnot(!anyDuplicated(normalized_keys))
# Run the real standardization function against explicitly labeled test inputs.
examples <- data.frame(
  RESPID=sprintf('TEST%02d',1:7),
  mention_number=rep(1L,7),
  Q22=c('j0e rogan','dr mike','doctor mike','mkbhd',
        'marques brownlee','bbc news','npr'),
  response_type=c('entity','entity','entity','entity','entity',
                  'named_source','entity')
)
expected <- c('Joe Rogan','Doctor Mike','Doctor Mike',
              'Marques Brownlee','Marques Brownlee','BBC News','NPR')
actual <- standardize_entities(examples, aliases)
stopifnot(nrow(actual) == nrow(examples))
stopifnot(identical(actual$entity_clean, expected))
stopifnot(all(actual$standardization_status == 'alias_matched'))
message('PASS: alias uniqueness and ', nrow(examples), ' expected mappings')
