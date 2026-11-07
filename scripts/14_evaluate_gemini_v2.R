# Versioned Gemini v2 evaluation on development or holdout matched mentions.
# Run from the survey-text-classification repository root.
# Does NOT make API calls. Run only after all predictions are complete.
# Usage: source("scripts/14_evaluate_gemini_v2.R"); evaluate_gemini_v2("development")
# or evaluate_gemini_v2("holdout") once prompt/settings are frozen.

evaluate_gemini_v2 <- function(dataset=c("development","holdout")) {
dataset <- match.arg(dataset)
reference_path <- if(dataset=="development") "data/reference/reference_coding_workbook.csv" else "data/holdout/holdout_reference_final_109.csv"
prediction_path <- if(dataset=="development") "output/llm_classification/gemini_dev_v2_parsed.csv" else "output/llm_classification/gemini_holdout_v2_parsed.csv"
output_dir <- if(dataset=="development") "output/llm_classification/development_evaluation_v2" else "output/llm_classification/holdout_evaluation_v2"
model_id <- "gemini-3.5-flash-lite"
expected_n <- if(dataset=="development") 114L else 105L

if (!file.exists(reference_path)) stop("Missing reference: ", reference_path)
if (!file.exists(prediction_path)) stop("Missing parsed Gemini predictions: ", prediction_path)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

read_data <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
           check.names = FALSE, colClasses = "character")
}
ref <- read_data(reference_path)
pred <- read_data(prediction_path)
if(dataset=="holdout") {
  frozen_path <- "data/holdout/holdout_preparation_frozen_113.csv"
  if(!file.exists(frozen_path)) stop("Missing frozen holdout prepared output")
  frozen <- read_data(frozen_path)
  seq_rows <- function(d) {
    ids <- unique(d$RESPID)
    setNames(lapply(ids,function(id){
      z <- d[d$RESPID==id,,drop=FALSE]
      z <- z[order(as.integer(z$mention_number)),,drop=FALSE]
      c(n=nrow(z), original=paste(unique(z$Q22_original),collapse=" || "),
        mention_sequence=paste(z$Q22,collapse=" || "))
    }),ids)
  }
  a <- seq_rows(ref); b <- seq_rows(frozen)
  ids <- intersect(names(a),names(b))
  good <- ids[vapply(ids,function(id) identical(a[[id]],b[[id]]),logical(1))]
  if(length(good)!=96L) stop("Unexpected segmentation match count: ",length(good))
  ref <- ref[ref$RESPID %in% good,,drop=FALSE]
  if(nrow(ref)!=105L) stop("Unexpected matched reference mention count")
}

ref_needed <- c("RESPID", "mention_number", "Q22", "reference_type",
                "reference_entity", "nonresponse_subtype", "review_status")
pred_needed <- c("RESPID", "mention_number", "Q22", "model", "response_type",
                 "entity_clean", "resolution_status", "nonresponse_subtype", "review_flag")
if (!all(ref_needed %in% names(ref))) stop("Reference missing columns: ", paste(setdiff(ref_needed, names(ref)), collapse=", "))
if (!all(pred_needed %in% names(pred))) stop("Prediction file missing columns: ", paste(setdiff(pred_needed, names(pred)), collapse=", "))

key_of <- function(x) paste(x$RESPID, x$mention_number, sep = "::")
ref_key <- key_of(ref)
pred_key <- key_of(pred)
if (nrow(ref) != expected_n) stop("Expected 114 development reference rows; found ", nrow(ref))
if (anyDuplicated(ref_key)) stop("Duplicate reference respondent/mention key")
if (anyDuplicated(pred_key)) stop("Duplicate prediction respondent/mention key. Run script 09 to deduplicate.")
if (any(is.na(ref$review_status) | ref$review_status != "human_verified")) {
  stop("Development reference includes non-verified rows")
}
if (nrow(pred) != expected_n || !setequal(ref_key, pred_key)) {
  stop("Predictions are not exactly the 114 reference mentions. Missing: ",
       paste(setdiff(ref_key, pred_key), collapse=", "),
       "; unexpected: ", paste(setdiff(pred_key, ref_key), collapse=", "))
}
if (any(is.na(pred$model) | pred$model != model_id)) stop("Predictions contain unexpected models")
if (!"prompt_version" %in% names(pred) || any(is.na(pred$prompt_version) | pred$prompt_version != "gemini_prompt_v2_2026-11-07")) stop("Predictions are not exclusively prompt v2")
if ("validation_ok" %in% names(pred) && any(is.na(pred$validation_ok) | toupper(pred$validation_ok) != "TRUE")) {
  stop("Predictions include invalid API responses")
}
idx <- match(ref_key, pred_key)
p <- pred[idx, , drop = FALSE]
if (any(ref$Q22 != p$Q22, na.rm = TRUE) || any(is.na(ref$Q22) != is.na(p$Q22))) {
  stop("Prepared mention text differs between reference and prediction for some keys")
}

categories <- c("entity", "named_source", "platform_or_topic", "generic_nonentity",
                "junk", "mixed_or_needs_review")
if (any(!ref$reference_type %in% categories) || any(!p$response_type %in% categories)) {
  stop("Unexpected category in reference or predictions")
}

out <- data.frame(RESPID = ref$RESPID, mention_number = ref$mention_number,
                  Q22 = ref$Q22, reference_type = ref$reference_type,
                  predicted_type = p$response_type,
                  reference_entity = ref$reference_entity,
                  predicted_entity = p$entity_clean,
                  reference_nonresponse_subtype = ref$nonresponse_subtype,
                  predicted_nonresponse_subtype = p$nonresponse_subtype,
                  resolution_status = p$resolution_status,
                  review_flag = p$review_flag,
                  stringsAsFactors = FALSE)
out$category_correct <- out$reference_type == out$predicted_type

# Category scoring: macro average across categories actually present in reference.
# Also preserve a separate six-class macro average with absent reference classes scored as zero.
class_rows <- lapply(categories, function(k) {
  tp <- sum(out$reference_type == k & out$predicted_type == k)
  fp <- sum(out$reference_type != k & out$predicted_type == k)
  fn <- sum(out$reference_type == k & out$predicted_type != k)
  support <- sum(out$reference_type == k)
  precision <- if (tp + fp == 0) 0 else tp / (tp + fp)
  recall <- if (tp + fn == 0) 0 else tp / (tp + fn)
  f1 <- if (precision + recall == 0) 0 else 2 * precision * recall / (precision + recall)
  data.frame(category = k, support = support, predicted = tp + fp,
             true_positive = tp, false_positive = fp, false_negative = fn,
             precision = precision, recall = recall, f1 = f1)
})
class_metrics <- do.call(rbind, class_rows)
accuracy <- mean(out$category_correct)
macro_f1_present <- mean(class_metrics$f1[class_metrics$support > 0])
macro_f1_all <- mean(class_metrics$f1)

confusion <- as.data.frame.matrix(table(
  reference = factor(out$reference_type, levels=categories),
  predicted = factor(out$predicted_type, levels=categories)))
confusion <- data.frame(reference_type = rownames(confusion), confusion, row.names=NULL,
                        check.names=FALSE)

# Identity metrics: denominator is only reference rows with a resolvable canonical name.
# Strict accuracy is exact string equality (case and whitespace sensitive).
# A second normalized-string comparison is descriptive, not a substitute for manual adjudication.
trim_or_na <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x) | x == ""] <- NA_character_
  x
}
out$reference_entity <- trim_or_na(out$reference_entity)
out$predicted_entity <- trim_or_na(out$predicted_entity)
resolvable <- !is.na(out$reference_entity)
out$identity_eligible <- resolvable
out$identity_predicted <- !is.na(out$predicted_entity)
out$identity_exact <- resolvable & out$identity_predicted &
                      out$reference_entity == out$predicted_entity
normalize_name <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[[:punct:]]", " ", x)
  gsub("[[:space:]]+", " ", trimws(x))
}
out$identity_normalized <- resolvable & out$identity_predicted &
  normalize_name(out$reference_entity) == normalize_name(out$predicted_entity)
identity_coverage <- if (any(resolvable)) mean(out$identity_predicted[resolvable]) else NA_real_
identity_exact_all <- if (any(resolvable)) mean(out$identity_exact[resolvable]) else NA_real_
identity_exact_resolved <- if (any(resolvable & out$identity_predicted))
  mean(out$identity_exact[resolvable & out$identity_predicted]) else NA_real_

# Nonresponse subtype comparisons are restricted to reference junk responses.
junk_ref <- out$reference_type == "junk"
subtype_correct <- junk_ref & out$predicted_type == "junk" &
  !is.na(out$reference_nonresponse_subtype) &
  !is.na(out$predicted_nonresponse_subtype) &
  out$reference_nonresponse_subtype == out$predicted_nonresponse_subtype

# Validate that model-reported resolution status matches output presence.
status_bad <- (p$resolution_status == "resolved" & is.na(trim_or_na(p$entity_clean))) |
              (p$resolution_status %in% c("unresolved", "not_applicable") &
                 !is.na(trim_or_na(p$entity_clean)))
if (any(is.na(p$resolution_status) | status_bad)) {
  warning("Resolution-status consistency issues detected; inspect resolution_inconsistencies.csv")
}

# Review flags: preserve actual observed decisions; do not infer a target flag from reference labels.
flag_true <- tolower(trimws(p$review_flag)) == "true"
flag_true[is.na(flag_true)] <- FALSE
unresolved <- p$resolution_status == "unresolved"
unresolved[is.na(unresolved)] <- FALSE

metrics <- data.frame(
  metric = c("development_mentions", "category_correct", "category_accuracy",
             "macro_f1_reference_supported_classes", "macro_f1_all_six_classes",
             "category_disagreements", "resolvable_reference_names",
             "canonical_name_coverage", "canonical_name_exact_count",
             "canonical_name_exact_rate_all_resolvable",
             "canonical_name_exact_rate_among_predicted",
             "canonical_name_normalized_match_count",
             "reference_junk_count", "junk_subtype_exact_count",
             "junk_subtype_exact_rate_all_reference_junk",
             "unresolved_predictions", "unresolved_predictions_flagged",
             "total_review_flags", "resolution_status_inconsistencies"),
  value = c(nrow(out), sum(out$category_correct), accuracy,
            macro_f1_present, macro_f1_all, sum(!out$category_correct),
            sum(resolvable), identity_coverage, sum(out$identity_exact),
            identity_exact_all, identity_exact_resolved,
            sum(out$identity_normalized), sum(junk_ref), sum(subtype_correct),
            if (any(junk_ref)) mean(subtype_correct[junk_ref]) else NA_real_,
            sum(unresolved), sum(unresolved & flag_true), sum(flag_true),
            sum(status_bad, na.rm=TRUE)), stringsAsFactors=FALSE)

write.csv(metrics, file.path(output_dir, "summary_metrics.csv"), row.names=FALSE, na="")
write.csv(class_metrics, file.path(output_dir, "class_metrics.csv"), row.names=FALSE)
write.csv(confusion, file.path(output_dir, "confusion_matrix.csv"), row.names=FALSE)
write.csv(out, file.path(output_dir, "joined_classifications.csv"), row.names=FALSE, na="")
write.csv(out[!out$category_correct, ], file.path(output_dir, "category_disagreements.csv"), row.names=FALSE, na="")
write.csv(out[resolvable & !out$identity_exact, ], file.path(output_dir, "identity_disagreements.csv"), row.names=FALSE, na="")
write.csv(out[junk_ref, ], file.path(output_dir, "junk_subtype_audit.csv"), row.names=FALSE, na="")
write.csv(out[unresolved | flag_true, ], file.path(output_dir, "uncertainty_audit.csv"), row.names=FALSE, na="")
write.csv(out[status_bad %in% TRUE, ], file.path(output_dir, "resolution_inconsistencies.csv"), row.names=FALSE, na="")

cat("Dataset:",dataset,"\nReference:", reference_path, "\nModel:", model_id,
    "\nMentions:", nrow(out),
    "\nCategory accuracy:", sum(out$category_correct), "/", nrow(out),
    sprintf(" (%.1f%%)", 100 * accuracy),
    "\nMacro F1 (reference-supported classes):", sprintf("%.3f", macro_f1_present),
    "\nMacro F1 (all six classes):", sprintf("%.3f", macro_f1_all),
    "\nStrict canonical-name agreement:", sum(out$identity_exact), "/", sum(resolvable),
    "\nUnresolved identities flagged:", sum(unresolved & flag_true), "/", sum(unresolved),
    "\nResults:", output_dir, "\n", sep="")

}
