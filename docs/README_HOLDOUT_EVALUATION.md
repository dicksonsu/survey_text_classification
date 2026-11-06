# Holdout evaluation — locked reference and frozen classifier

## Data artifacts

- `holdout_preparation_frozen_113.csv` — 113 mentions from the original unmodified text-preparation output. **Do not replace with the researcher-corrected file.**
- `holdout_reference_final_109.csv` — 109 human-reviewed reference mentions from 100 synthetic responses. Initial annotations were AI-proposed and subsequently researcher-reviewed.
- `segmentation_adjudications.csv` — four documented instances of a single response being erroneously split into two mentions.

The changed responses are `HOLD0013`, `HOLD0024`, `HOLD0073`, `HOLD0082`. All other 96 respondents have exactly matching mention sequences. The frozen output contains 113 mentions; the corrected reference contains 109.

## To evaluate

1. On branch `feature/holdout-evaluation`, place files at the paths in this package; keep the frozen v2 classifier and aliases unchanged from the merged `main` commit.
2. From the repository root, run `source("scripts/06_evaluate_holdout.R")` in RStudio after installing `readr`, `dplyr`, `tidyr`, `stringr`.
3. Inspect `output/holdout_evaluation/summary_metrics.csv`, `class_metrics.csv`, `type_disagreements.csv` and `identity_disagreements.csv`.

## What is scored

**Segmentation:** exact respondent-level mention sequences versus researcher-adjudicated sequences, with original-response context. Expected preparation agreement: 96/100 respondents. Four changed respondents are never silently matched to incorrect individual mentions.

**Classification:** category accuracy, classwise precision/recall/F1 and canonical-name agreement on the **105 reference mentions belonging to the 96 correctly segmented respondents**. This is intentionally conditional on correct segmentation, not an end-to-end accuracy estimate across all 109 reference mentions.

**Identity:** canonical-name agreement considers only reference entries with an identified person or source. Unresolved reference identities remain separate and are not scored as correct canonical-name matches. No imputation of names is permitted.

## Interpretation constraints

This is a postdevelopment **synthetic challenge set**, authored with knowledge of the original classification failure modes. It measures generalization to new constructed examples but is not a representative sample of real survey responses, and the annotation process was AI-proposed then researcher-reviewed. Do not tune frozen v2 on this set and then call the resulting score a fresh holdout result. This script does not alter the model or source rules.

The original `05_prepare_holdout_for_review.R` regenerates the *unadjudicated* template; do not overwrite the finalized reference by rerunning it.
