# Frozen holdout benchmark. Run from the repository root ONLY after reference lock.
# Reads the archived 113 prepared mentions, not a re-generated preparation output.
# Does NOT modify classify_q22, standardize_entities, or their inputs.
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr); library(stringr)})
source("R/classification_helpers.R")
source("R/entity_standardization.R")

p <- "data/holdout/"
frozen <- readr::read_csv(paste0(p,"holdout_preparation_frozen_113.csv"), na="",show_col_types=FALSE)
reference <- readr::read_csv(paste0(p,"holdout_reference_final_109.csv"),na="",show_col_types=FALSE)
seglog <- readr::read_csv(paste0(p,"segmentation_adjudications.csv"),na="",show_col_types=FALSE)
aliases <- readr::read_csv("data/entity_aliases.csv",na="",show_col_types=FALSE)

required <- c("RESPID","mention_number","Q22","Q22_original")
stopifnot(all(required %in% names(frozen)),all(c(required,"reference_type","reference_entity","review_status") %in% names(reference)))
stopifnot(nrow(frozen)==113L,nrow(reference)==109L,n_distinct(frozen$RESPID)==100L,n_distinct(reference$RESPID)==100L)
stopifnot(!anyDuplicated(frozen[c("RESPID","mention_number")]),!anyDuplicated(reference[c("RESPID","mention_number")]))
stopifnot(all(reference$review_status == "human_verified"), !anyNA(reference$reference_type),all(reference$reference_type!=""))
stopifnot(!anyNA(frozen$Q22),!anyNA(reference$Q22),!anyNA(frozen$Q22_original),!anyNA(reference$Q22_original))
stopifnot(setequal(frozen$RESPID,reference$RESPID))
stopifnot(all(c("RESPID","frozen_prepared_mentions","corrected_reference_mention") %in% names(seglog)),nrow(seglog)==4L)

# Verify each respondent's ordered sequence, including original-response context.
seq_for <- function(d) {
  d %>% arrange(RESPID,mention_number) %>%
    group_by(RESPID) %>% summarise(
      n_mentions=n(), original=paste(unique(Q22_original),collapse=" || "),
      mention_sequence=paste(Q22,collapse=" || "),.groups="drop")
}
fseq <- seq_for(frozen);rseq <- seq_for(reference)
by_resp <- full_join(fseq,rseq,by="RESPID",suffix=c("_frozen","_reference")) %>%
  mutate(segmentation_exact= n_mentions_frozen==n_mentions_reference &
           original_frozen==original_reference &
           mention_sequence_frozen==mention_sequence_reference)
stopifnot(!anyNA(by_resp$segmentation_exact))
seg_errors <- by_resp %>% filter(!segmentation_exact)
stopifnot(nrow(seg_errors)==4L,setequal(seg_errors$RESPID,seglog$RESPID))

# Only exact-matching respondent sequences are eligible for category/name evaluation.
valid_ids <- by_resp %>% filter(segmentation_exact) %>% pull(RESPID)
matched_ref <- reference %>% filter(RESPID %in% valid_ids)
matched_frozen <- frozen %>% filter(RESPID %in% valid_ids)
stopifnot(nrow(matched_ref)==105L,nrow(matched_frozen)==105L)
stopifnot(identical(matched_ref %>% arrange(RESPID,mention_number) %>% pull(Q22),
                    matched_frozen %>% arrange(RESPID,mention_number) %>% pull(Q22)))

# Generate predictions only after the reference has been fixed and validated.
# The classifier and alias dictionary must be the frozen v2 files from merged main.
predicted <- frozen %>% mutate(response_type=classify_q22(Q22))
predicted <- standardize_entities(predicted,aliases)
stopifnot(nrow(predicted)==113L, all(c("response_type","entity_clean") %in% names(predicted)))
comparison <- matched_ref %>% select(RESPID,mention_number,Q22,reference_type,reference_entity) %>%
 left_join(predicted %>% filter(RESPID %in% valid_ids) %>%
 select(RESPID,mention_number,Q22, response_type,entity_clean,standardization_status),
 by=c("RESPID","mention_number","Q22"))
stopifnot(nrow(comparison)==105L,!anyNA(comparison$response_type))
comparison <- comparison %>% mutate(
 type_correct=reference_type==response_type,
 # Identity agreement is only assessed where a reference identity is resolvable.
 resolved_reference=reference_type %in% c("entity","named_source") & !is.na(reference_entity) & reference_entity!="",
 identity_correct=if_else(resolved_reference,!is.na(entity_clean)&entity_clean==reference_entity,NA),
 end_to_end_correct=if_else(resolved_reference,type_correct & !is.na(identity_correct)&identity_correct,NA))

categories <- sort(unique(c(comparison$reference_type,comparison$response_type)))
confusion <- tidyr::expand_grid(reference_type=categories,response_type=categories) %>%
 left_join(comparison %>% count(reference_type,response_type,name="n"),by=c("reference_type","response_type")) %>%
 mutate(n=replace_na(n,0L))
metrics <- lapply(categories,function(cat){
 tp=sum(comparison$reference_type==cat & comparison$response_type==cat)
 fp=sum(comparison$reference_type!=cat & comparison$response_type==cat)
 fn=sum(comparison$reference_type==cat & comparison$response_type!=cat)
 precision=if((tp+fp)==0) NA_real_ else tp/(tp+fp)
 recall=if((tp+fn)==0) NA_real_ else tp/(tp+fn)
 f1=if(is.na(precision)||is.na(recall)||(precision+recall)==0) NA_real_ else 2*precision*recall/(precision+recall)
 tibble::tibble(category=cat,support=tp+fn,tp=tp,fp=fp,fn=fn,precision=precision,recall=recall,f1=f1)
}) %>% bind_rows()
summary <- tibble::tibble(
 measure=c("response_segmentation_exact","reference_mentions_correctly_segmented","type_accuracy_conditional_on_segmentation","macro_f1_conditional_on_segmentation","canonical_name_agreement_conditional_and_resolved","end_to_end_agreement_conditional_and_resolved"),
 numerator=c(sum(by_resp$segmentation_exact),nrow(matched_ref),sum(comparison$type_correct),NA_integer_,sum(comparison$identity_correct,na.rm=TRUE),sum(comparison$end_to_end_correct,na.rm=TRUE)),
 denominator=c(nrow(by_resp),nrow(reference),nrow(comparison),NA_integer_,sum(comparison$resolved_reference),sum(comparison$resolved_reference)),
 value=c(mean(by_resp$segmentation_exact),nrow(matched_ref)/nrow(reference),mean(comparison$type_correct),mean(metrics$f1,na.rm=TRUE),mean(comparison$identity_correct,na.rm=TRUE),mean(comparison$end_to_end_correct,na.rm=TRUE)))

out <- "output/holdout_evaluation"
dir.create(out,recursive=TRUE,showWarnings=FALSE)
readr::write_csv(by_resp,paste0(out,"/segmentation_by_respondent.csv"),na="")
readr::write_csv(seg_errors,paste0(out,"/segmentation_disagreements.csv"),na="")
readr::write_csv(summary,paste0(out,"/summary_metrics.csv"),na="")
readr::write_csv(metrics,paste0(out,"/class_metrics.csv"),na="")
readr::write_csv(confusion,paste0(out,"/confusion_matrix_long.csv"),na="")
readr::write_csv(comparison,paste0(out,"/mention_comparison_segment_matched.csv"),na="")
readr::write_csv(comparison %>% filter(!type_correct),paste0(out,"/type_disagreements.csv"),na="")
readr::write_csv(comparison %>% filter(resolved_reference & !identity_correct),paste0(out,"/identity_disagreements.csv"),na="")
readr::write_csv(comparison %>% filter(reference_type %in% c("entity","named_source") & !resolved_reference),paste0(out,"/unresolved_reference_entities.csv"),na="")
cat("Segmentation exact:",sum(by_resp$segmentation_exact),"/",nrow(by_resp),"respondents\n")
cat("Matched mentions:",nrow(matched_ref),"/",nrow(reference),"reference mentions\n")
cat("Category accuracy on matched mentions:",sum(comparison$type_correct),"/",nrow(comparison),"\n")
cat("Macro F1 on matched mentions:",round(mean(metrics$f1,na.rm=TRUE),3),"\n")
cat("Resolvable-name agreement:",sum(comparison$identity_correct,na.rm=TRUE),"/",sum(comparison$resolved_reference),"\n")
cat("Results:",out,"\n")
