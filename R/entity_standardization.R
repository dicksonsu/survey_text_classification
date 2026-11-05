# Exact-match alias standardization of mentions classified as entities/sources.
# Mappings are derived from selected hand-entered rules in the original Q22 script.
# Not every rule is copied: broad substring rules can misidentify unrelated names.
# Unmapped mentions are retained as title-cased candidates requiring review.

standardize_entities <- function(classified, aliases) {
  required <- c('RESPID', 'Q22', 'response_type')
  stopifnot(all(required %in% names(classified)))
  stopifnot(all(c('mention', 'entity_clean') %in% names(aliases)))
  if (anyNA(aliases$mention) || anyNA(aliases$entity_clean) ||
      any(aliases$mention == '') || any(aliases$entity_clean == '')) {
    stop('Alias table has missing or blank values')
  }
  if (anyDuplicated(aliases$mention)) stop('Duplicate alias keys; review data/entity_aliases.csv')

  source_types <- c('entity', 'named_source')
  aliases <- aliases |>
    dplyr::mutate(mention = stringr::str_squish(stringr::str_to_lower(mention)))
  if (anyDuplicated(aliases$mention)) stop('Aliases collide after lowercase/whitespace normalization')

  classified |>
    dplyr::mutate(.mention_key = stringr::str_squish(stringr::str_to_lower(Q22))) |>
    dplyr::left_join(aliases, by = c('.mention_key' = 'mention')) |>
    dplyr::mutate(
      standardization_status = dplyr::case_when(
        !response_type %in% source_types ~ 'not_applicable',
        !is.na(entity_clean) ~ 'alias_matched',
        TRUE ~ 'unmapped_needs_review'
      ),
      entity_clean = dplyr::case_when(
        !response_type %in% source_types ~ NA_character_,
        !is.na(entity_clean) ~ entity_clean,
        TRUE ~ stringr::str_to_title(Q22)
      )
    ) |>
    dplyr::select(-.mention_key)
}
