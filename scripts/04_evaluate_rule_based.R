# Run from repository root after scripts/01_prepare_data.R, 02_classify_responses.R,
# and 03_standardize_entities.R. Development-set diagnostics ONLY.
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(tidyr)
})

reference_file <- 'data/reference/reference_coding_workbook.csv'
classified_file <- 'output/q22_classified.csv'
standardized_file <- 'output/q22_standardized.csv'
stopifnot(file.exists(reference_file), file.exists(classified_file),
          file.exists(standardized_file))
reference <- readr::read_csv(reference_file, show_col_types = FALSE)
classified <- readr::read_csv(classified_file, show_col_types = FALSE)
standardized <- readr::read_csv(standardized_file, show_col_types = FALSE)

key <- c('RESPID', 'mention_number')
required_reference <- c(key, 'Q22', 'reference_type', 'reference_entity',
                        'review_status')
stopifnot(all(required_reference %in% names(reference)),
          all(c(key, 'Q22', 'response_type') %in% names(classified)),
          all(c(key, 'Q22', 'response_type', 'entity_clean') %in% names(standardized)))

# Fail on a stale data preparation output, mismatched mention keys, or imperfect review coverage.
stopifnot(nrow(reference) == 114L,
          nrow(classified) == 114L,
          nrow(standardized) == 114L,
          all(reference$review_status == 'human_verified'),
          !anyNA(reference[key]),
          !anyDuplicated(reference[key]),
          !anyDuplicated(classified[key]),
          !anyDuplicated(standardized[key]))

# Use anti_joins to explicitly confirm keys match in BOTH directions.
if (nrow(anti_join(reference, classified, by = key)) ||
    nrow(anti_join(classified, reference, by = key)) ||
    nrow(anti_join(reference, standardized, by = key)) ||
    nrow(anti_join(standardized, reference, by = key))) {
  stop('Mention keys differ: rerun pipeline and rebuild/reconcile reference worksheet.')
}

# Keep the reference columns independently suffixed.
comparison <- reference %>%
  select(all_of(key), Q22_reference = Q22, Q22_original,
         reference_type, reference_entity, review_notes, review_status) %>%
  inner_join(classified %>% select(all_of(key), Q22_classified = Q22, response_type),
             by = key) %>%
  inner_join(standardized %>% select(all_of(key), Q22_standardized = Q22,
                                       entity_clean, standardization_status), by = key)
stopifnot(nrow(comparison) == 114L)
if (any(is.na(comparison$Q22_reference)) ||
    any(comparison$Q22_reference != comparison$Q22_classified) ||
    any(comparison$Q22_reference != comparison$Q22_standardized)) {
  stop('Prepared Q22 text differs between reference and pipeline output: do not score.')
}
if (anyNA(comparison$reference_type) || anyNA(comparison$response_type)) {
  stop('Missing reference or predicted type.')
}

# Overall category accuracy.
comparison <- comparison %>% mutate(type_correct = reference_type == response_type)
category_accuracy <- tibble(
  n_mentions = nrow(comparison),
  n_correct = sum(comparison$type_correct),
  accuracy = mean(comparison$type_correct)
)

# Matrix includes rows as human-reviewed reference and columns as model prediction.
confusion <- comparison %>% count(reference_type, response_type, name = 'n') %>%
  tidyr::complete(reference_type, response_type, fill = list(n = 0L))
all_classes <- sort(unique(c(comparison$reference_type, comparison$response_type)))
class_metrics <- lapply(all_classes, function(cls) {
  tp <- sum(comparison$reference_type == cls & comparison$response_type == cls)
  fp <- sum(comparison$reference_type != cls & comparison$response_type == cls)
  fn <- sum(comparison$reference_type == cls & comparison$response_type != cls)
  precision <- if (tp + fp > 0L) tp / (tp + fp) else NA_real_
  recall <- if (tp + fn > 0L) tp / (tp + fn) else NA_real_
  f1 <- if (!is.na(precision) && !is.na(recall) && precision + recall > 0) {
    2 * precision * recall / (precision + recall)
  } else if (!is.na(precision) && !is.na(recall)) 0 else NA_real_
  tibble(class = cls, reference_support = tp + fn, predicted_count = tp + fp,
         true_positive = tp, false_positive = fp, false_negative = fn,
         precision = precision, recall = recall, f1 = f1)
}) %>% bind_rows()
macro_f1 <- mean(class_metrics$f1[class_metrics$reference_support > 0], na.rm = TRUE)

# Identity resolution evaluation: only on references with identifiable canonical names.
# NOTE: fallback title casing by the pipeline is NOT independently verified resolution.
named_types <- c('entity', 'named_source')
resolved <- comparison %>% filter(reference_type %in% named_types,
                                    !is.na(reference_entity),
                                    str_trim(reference_entity) != '') %>%
  mutate(name_correct = !is.na(entity_clean) &
           str_to_lower(str_squish(entity_clean)) ==
             str_to_lower(str_squish(reference_entity)),
         end_to_end_correct = type_correct & name_correct)
unresolved <- comparison %>% filter(reference_type %in% named_types,
                                      is.na(reference_entity) |
                                        str_trim(coalesce(reference_entity, '')) == '')
stopifnot(nrow(unresolved) == 2L,
          all(unresolved$Q22_reference %in% c('alex', 'a creator called alex')))
entity_metrics <- tibble(
  n_resolved_reference_names = nrow(resolved),
  n_correct_canonical_names = sum(resolved$name_correct),
  canonical_name_agreement = mean(resolved$name_correct),
  n_correct_category_and_name = sum(resolved$end_to_end_correct),
  end_to_end_agreement = mean(resolved$end_to_end_correct),
  n_unresolved_reference_person_mentions = nrow(unresolved),
  n_unresolved_predicted_entity = sum(unresolved$response_type == 'entity')
)

# Save inspectable disagreements; do not rewrite labels or algorithms on the basis of these alone.
dir.create('output/evaluation', recursive = TRUE, showWarnings = FALSE)
readr::write_csv(comparison, 'output/evaluation/mention_comparison.csv')
readr::write_csv(category_accuracy, 'output/evaluation/category_accuracy.csv')
readr::write_csv(confusion, 'output/evaluation/confusion_matrix_long.csv')
readr::write_csv(class_metrics, 'output/evaluation/class_metrics.csv')
readr::write_csv(entity_metrics, 'output/evaluation/entity_metrics.csv')
readr::write_csv(comparison %>% filter(!type_correct),
                 'output/evaluation/type_disagreements.csv')
readr::write_csv(resolved %>% filter(!name_correct | !type_correct),
                 'output/evaluation/identity_disagreements.csv')
readr::write_csv(unresolved,
                 'output/evaluation/unresolved_reference_entities.csv')

cat('\nCATEGORY ACCURACY (development set only)\n')
print(category_accuracy)
cat('\nCONFUSION MATRIX (reference rows, prediction columns)\n')
print(as.data.frame.matrix(table(comparison$reference_type, comparison$response_type)))
cat('\nPER-CLASS METRICS\n')
print(class_metrics, width = Inf)
cat('\nMACRO F1 (reference-present classes with defined F1): ',
    round(macro_f1, 3), '\n', sep = '')
cat('\nCANONICAL NAME AND END-TO-END AGREEMENT\n')
print(entity_metrics, width = Inf)
cat('\nResults saved in output/evaluation/\n')
