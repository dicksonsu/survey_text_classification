# Run only after feature/holdout-evaluation branches from merged main.
# This script prepares a BLIND annotation template from new synthetic source responses.
# It deliberately DOES NOT run classify_q22() or load any model predictions.
suppressPackageStartupMessages({library(readr); library(dplyr)})
source('R/text_cleaning.R')
input <- readr::read_csv('data/holdout/holdout_raw_synthetic.csv', show_col_types=FALSE)
stopifnot(nrow(input) == 100L, !anyDuplicated(input$RESPID))
mentions <- prepare_q22(input)
stopifnot(all(c('RESPID','mention_number','Q22','Q22_original') %in% names(mentions)))
stopifnot(!anyDuplicated(mentions[c('RESPID','mention_number')]))
template <- mentions |>
  dplyr::select(RESPID, mention_number, Q22, Q22_original) |>
  dplyr::mutate(reference_type = NA_character_,
                reference_entity = NA_character_,
                nonresponse_subtype = NA_character_,
                review_notes = NA_character_,
                review_status = 'pending_review')
dir.create('data/holdout', recursive=TRUE, showWarnings=FALSE)
readr::write_csv(template, 'data/holdout/holdout_reference_to_review.csv', na='')
message('Created blank reference worksheet for ', nrow(template), ' prepared mentions from 100 synthetic responses.')
message('Do not run the frozen classifier or inspect predictions before human reference review is finished.')
