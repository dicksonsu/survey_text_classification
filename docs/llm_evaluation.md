# LLM-assisted classification of synthetic survey responses: evaluation

**Project:** `survey-text-classification`  
**Final LLM configuration:** Gemini prompt v2 (`gemini_prompt_v2_2026-11-07`) using model identifier `gemini-3.5-flash-lite`  
**Evaluation date:** November 7, 2026  
**Data:** Synthetic examples only; no confidential respondent-level survey records

## 1. Research objective

Open-ended survey responses can refer to individual creators, particular programs or outlets, general content categories, or no identifiable source at all. The project tests how consistently those distinctions can be coded, while keeping identity resolution and decisions requiring human review explicit.

The primary comparison is between a **frozen rule-based v2 classifier** and a **prompt-based Gemini v2 classifier**. Both are assessed against the same researcher-reviewed synthetic holdout references. The study evaluates categorization, canonical-name resolution, and uncertainty handling; it does not establish performance on a representative sample of real survey text.

## 2. Coding framework and reference data

The coding protocol distinguishes six possible labels:

| Category | Interpretation |
| --- | --- |
| `entity` | An identifiable or explicitly referenced individual creator/person, including a person whose full identity cannot be resolved |
| `named_source` | A specifically named show, channel, outlet, publication, or media brand |
| `platform_or_topic` | A platform, content medium, topic, or description of a creator type without a specific named source |
| `generic_nonentity` | A vague answer with no identifiable creator, source, or substantive content category |
| `junk` | A nonresponse or unusable answer; additionally coded with a nonresponse subtype |
| `mixed_or_needs_review` | A response not reliably classifiable under the other categories without further judgment |

For `junk`, relevant subtypes include `cannot_recall`, `does_not_follow`, `no_specific_name`, and `unusable`. For a person or named source, `entity_clean` records the canonical identity when supported. `resolution_status` distinguishes `resolved`, `unresolved`, and `not_applicable`. The LLM also returns `review_flag` and `review_reason`.

The development reference comprises **114 mentions**, used to construct and test the initial rules and later refine the LLM prompt. The holdout consists of **100 new synthetic respondent answers**, yielding **113 originally prepared mentions**. Researchers adjudicated four erroneous splits, producing **109 reference mentions**. Initial reference labels were AI-proposed and then researcher-reviewed; they are not independent, human-only annotations. See [`coding_protocol.md`](coding_protocol.md), [`development_evaluation.md`](development_evaluation.md), and [`holdout_evaluation.md`](holdout_evaluation.md).

### Matched holdout set

The preparation stage produced the correct mention sequence for **96 of 100 respondents**. Four respondents (`HOLD0013`, `HOLD0024`, `HOLD0073`, `HOLD0082`) had an incorrectly split response. Those four entire respondent-level cases were excluded from the *conditional classification* comparison, leaving **105 exactly matched mentions**. Their preparation errors remain counted in the separate segmentation result; they have not been silently relabeled or treated as category errors.

The LLM did **not** independently perform segmentation. Both classification systems were evaluated on the same 105 correctly prepared mentions. Gemini additionally received the **original full respondent answer** as context, whereas the frozen rule-based implementation operated principally on the prepared mention. Consequently this is a **workflow comparison**, not an experiment isolating model architecture under identical contextual information.

## 3. Model development and prompt revision

### Frozen rule-based baseline

The rule-based classifier uses ordered text rules and an exact-match alias mapping for canonical names. Its v2 development agreement was **114/114**, but this was in-sample agreement after rule revision, not independent validation. The rule-based pipeline, alias dictionary, and holdout reference were left unchanged during LLM evaluation.

### Gemini prompt v1

The first Gemini implementation applied the coding protocol using structured JSON responses. The script recorded the model identifier, prompt, output, validity, and API attempt history. Invalid or failed requests were retried without treating them as successful classifications. On the 114 development mentions, prompt v1 achieved **109/114 category accuracy (95.6%)** and **0.832 five-class macro F1**. Canonical names matched **62/65** resolvable references exactly. Neither of two unresolved identity predictions was flagged for review.

### One controlled development-stage revision: prompt v2

A single documented revision targeted three development-observed weaknesses:

1. Sharper distinctions among specifically named sources, general platforms/topics, and vague answers.
2. More explicit definitions for the nonresponse subtypes.
3. A requirement that `resolution_status = "unresolved"` entails `review_flag = true` and a short explanation.

The six categories, JSON field structure, underlying reference labels, and model identifier were retained. The revised prompt was tested on development mentions, then treated as **frozen before the scored holdout run**. Version details appear in [`llm_prompt_v2_change_log.md`](llm_prompt_v2_change_log.md). The prior prompt and outputs should remain archived for auditability.

## 4. Development results

| Metric | Gemini v1 | Gemini v2 |
| --- | ---: | ---: |
| Evaluated mentions | 114 | 114 |
| Correct categories | 109/114 | **113/114** |
| Category accuracy | 95.6% | **99.1%** |
| Macro F1, five reference-supported classes | 0.832 | **0.993** |
| Exact canonical-name agreement | 62/65 (95.4%) | **63/65 (96.9%)** |
| Reference `junk` subtype agreement | 8/13 (61.5%) | **13/13 (100%)** |
| Unresolved predictions flagged for review | 0/2 | **2/2** |

The sole prompt-v2 development category disagreement was `mkbhd`: the reference codes an individual (`entity`), while Gemini assigned `named_source` although it identified Marques Brownlee correctly. Two exact-name disagreements (`Fresh and Fit` versus `Fresh & Fit`; `Doctor Mike` versus `Dr. Mike`) were naming variants, not evidently different referents. Scores above retain strict string comparisons; equivalence should be reported separately if formally adjudicated.

These strong development scores **should not be interpreted as independent generalization evidence**: the v2 prompt was revised using development errors. The one remaining development error was not used for another prompt revision.

## 5. Frozen holdout results

### Main classification comparison

| Metric | Frozen rule-based v2 | Gemini prompt v2 |
| --- | ---: | ---: |
| Correctly segmented respondents (shared preparation stage) | 96/100 | Same 96/100; no LLM segmentation test |
| Evaluated, exactly matched mentions | 105 | 105 |
| Correct categories | 27/105 | **101/105** |
| Category accuracy | 25.7% | **96.2%** |
| Five-reference-class macro F1, undefined class F1 set to zero | 0.214 | **0.971** |
| Canonical-name coverage, among resolvable reference identities | 0/47 | **46/47 (97.9%)** |
| Exact canonical-name agreement, among resolvable references | 0/47 | **45/47 (95.7%)** |

**Macro F1 reporting note:** The original rule-based holdout script output macro F1 **0.268**, omitting undefined class F1 values. The **0.214** value above uses a consistent five-reference-class denominator, counting a missing/undefined class F1 as zero. Gemini's five-class macro F1 is **0.971**. Its script also reports an *all-six-class* macro F1 of **0.809**, which includes the unused `mixed_or_needs_review` class; that is not the primary comparison. The scoring convention must be stated whenever results are quoted.

Gemini correctly classified **74 additional mentions** in this 105-mention challenge comparison (101 rather than 27), a **70.5-percentage-point** difference in observed category accuracy. This is evidence of better performance for this *specific constructed task and workflow*, not an estimate of the improvement expected on all survey data.

### Canonical names and review decisions

Of **47** holdout references with resolvable canonical names, Gemini returned a canonical name for **46**, with **45** exact matches. One identifiable program was not resolved; one program was given a different, more specific attribution (see error analysis). In contrast, the frozen rule-based alias dictionary did not resolve any of the 47 holdout canonical names; its behavior was largely conservative abstention rather than assigning 47 incorrect identities.

Gemini marked **all five of its own unresolved identity predictions** for review (5/5), with no resolution-status inconsistencies in the evaluation summary. This is evidence of *internal consistency* between predicted uncertainty and review flags, **not** evidence that it found every response a researcher should review.

Exact `junk` subtype agreement was **9/11 (81.8%)** on reference junk mentions, down from 13/13 on development data. The subtype mismatches deserve separate inspection if downstream analysis depends on the reasons respondents did not provide a name.

## 6. Holdout error analysis

Only four category disagreements remained:

| Prepared mention | Reference category | Gemini v2 category | Interpretation |
| --- | --- | --- | --- |
| `my local radio station` | `platform_or_topic` | `named_source` | A source *type* was treated as a named source; Gemini left its identity unresolved and flagged review. |
| `the podcast search engine` | `named_source` | `platform_or_topic` | The title **Search Engine** was read as a generic phrase rather than a specific podcast. |
| `contrapoints` | `named_source` | `entity` | Creator/channel-persona boundary; Gemini returned the same canonical string, `ContraPoints`. |
| `mkbhds interview show` | `entity` | `named_source` | Gemini inferred `Waveform with MKBHD`, a more specific program identity than the reference's `Marques Brownlee`. |

The last two cases illustrate the coding distinction between an individual and a program or creator-brand closely associated with that individual. They are not grounds for changing the finalized reference after observing predictions.

There were **two** strict canonical-name disagreements among the 47 resolvable references: `the podcast search engine` (no canonical name returned) and `mkbhds interview show` (`Waveform with MKBHD` versus reference `Marques Brownlee`). The second illustrates a potential **over-resolution** risk: a plausible name can be more specific than the response supports. The `contrapoints` category mismatch was *not* an identity-string mismatch.

## 7. Interpretation and limitations

- **Synthetic and intentionally challenging sample:** The holdout was constructed with knowledge of earlier rule-based weaknesses. Its case mix is not representative of real respondent text; do not extrapolate the 96.2% accuracy as a population performance estimate.
- **Reference creation:** Labels began as AI suggestions and were researcher-reviewed. Human adjudication improves consistency but does not establish independent inter-rater reliability.
- **Prior exposure to holdout characteristics:** The team reviewed holdout examples while preparing reference labels before finalizing the LLM protocol. The holdout labels were not included in Gemini requests, and Gemini v2 was not revised after its holdout results, but this was **not a fully blind external test**.
- **Unequal information:** Gemini received the original respondent response alongside the prepared mention; the rule-based classifier had less contextual processing. The comparison is between implemented workflows, not equivalent-input model architectures.
- **Conditional evaluation:** The 105-mention comparison excludes four missegmented respondent cases. It is not an end-to-end accuracy estimate for all 100 responses.
- **Coverage versus correctness:** Exact matching may penalize harmless aliases and overlook semantically incorrect attributions that share a string. Preserve strict metrics and document any later researcher adjudication separately.
- **Model and reproducibility:** Model behavior and hosted API availability can change. Preserve prompt version, model identifier, generation settings, validation schema, predictions, and scoring code. Failed request attempts are operational diagnostics, not additional observations.
- **Risk and use constraints:** This prototype used synthetic text. Applying the method to confidential real survey records would require appropriate data-sharing, privacy, and organizational review.

## 8. Reproducing the evaluation

From the repository root in RStudio, with the relevant packages installed and the committed synthetic inputs/reference files in place:

```r
# Existing frozen rule-based benchmark
source("scripts/06_evaluate_holdout.R")

# Gemini v1 development scoring from saved, parsed predictions
source("scripts/10_evaluate_gemini_development.R")

# Gemini v2 scoring from existing parsed predictions (no API calls)
source("scripts/14_evaluate_gemini_v2.R")
evaluate_gemini_v2("development")
evaluate_gemini_v2("holdout")
```

The Gemini v2 workflow is implemented by scripts `11_build_gemini_v2_requests.R` through `14_evaluate_gemini_v2.R`. The inference runner requires an API key held outside the repository (`GEMINI_API_KEY`) **only if generating new predictions**. Scoring an archived parsed-prediction file does not require an API call. For exact script input paths and output locations, refer to the individual scripts and [`llm_protocol.md`](llm_protocol.md).

**Authoritative result files:** `output/llm_classification/development_evaluation_v2/` and `output/llm_classification/holdout_evaluation_v2/` in the local analysis workflow. If outputs are ignored by Git, commit a small archived subset of final summaries, scored predictions, and disagreements under `results/gemini/` so readers can inspect and reproduce the scoring without an API key. Do not commit secrets or unapproved real survey data.

## 9. Conclusion

On the constructed 105-mention holdout comparison, the frozen Gemini v2 workflow achieved **96.2% category accuracy** versus **25.7%** for the frozen rule-based v2 classifier, while resolving **46 of 47** identifiable references and flagging all five of its own unresolved predictions. The gain is substantial on this benchmark, but the remaining errors expose important boundaries: ordinary phrases that are also titles, distinctions between creator personas and channels, and the risk of over-specific identity resolution.

The practical result is not that LLM coding removes the need for researchers. It is that a carefully specified, validated, and audited LLM workflow can handle a wider range of unfamiliar synthetic responses than the particular handcrafted rules tested here, **provided human review and explicit uncertainty handling remain part of the process**.
