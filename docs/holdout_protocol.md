# New synthetic holdout: review and evaluation protocol

## What this set is
100 **new, fictional** source responses, intentionally varied in type, wording, and difficulty. They were authored after inspecting v2's development errors. Thus they provide an **unseen-response challenge set** once v2 is frozen, but they are not a representative probability sample or fully independent of knowledge of the model. No labels or model predictions are provided.

## Sequence (do not rearrange)
1. Merge and freeze v2 on `main` first. Record the merge commit SHA. Never revise v2 using outcomes from this holdout and then report the same set as untouched.
2. Create `feature/holdout-evaluation` from updated `main`. Add synthetic raw source CSV and `05_prepare_holdout_for_review.R`.
3. Run `source("scripts/05_prepare_holdout_for_review.R")` **only**. Review prepared spans and the source response for splitting errors **before scoring**. Do not ask an LLM to create gold labels if claiming human-only labeling.
4. Apply `docs/coding_protocol.md` (v0.8) with the same category rules and separate identity resolution; leave unresolvable persons' names blank, and record uncertainty. The draft may be AI-proposed, but mark `human_verified` only after researcher review and disclose assistance.
5. Resolve disagreements, check coverage and unique `(RESPID,mention_number)` keys, and finalize the reference file. Freeze its hash/commit. If splitting errors are discovered, log separately: avoid silently altering the classifier/preparation algorithm after seeing the test examples.
6. Run the frozen v2 on the same prepared mentions; calculate metrics and compare to reference. Record category accuracy, per-class precision/recall/F1, name agreement conditional on resolved names, unresolved-identification behavior, and preparation errors by original respondent.
7. Keep the results even if they are disappointing. Subsequent rule improvements require a **new** holdout to estimate their performance.

## Identity matching
Report type classification separately from canonical name resolution. Do not force 'a person named Ben' to a specific real-world identity. Program titles and hosts are distinct; NBA and NFL unqualified are content topics, ESPN and publishers are named sources.

## Synthetic data disclaimer
Names, demographics, and answers are invented examples. No real survey microdata are included. The constructed challenge distribution is not representative of survey respondents, and its score is not a field-study generalization estimate.
