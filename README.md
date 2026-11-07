# Open-Ended Survey Response Classification

**An R-based methodological demonstration of rule-based and LLM-assisted coding of open-ended survey responses.** The project implements text preparation, mention-level classification, canonical-name resolution, structured output validation, and evaluation against researcher-reviewed synthetic examples.

> **Data and privacy:** All published response records are synthetic. They are invented test cases, not actual survey microdata, and their frequencies have no substantive interpretation. No confidential responses or API credentials should be committed to this repository.

## Research questions

- How reliably can an automated workflow distinguish individual creators, named media sources, platforms or topics, vague answers, and nonresponses?
- How should spelling variants and ambiguous references be standardized without inventing identities?
- Does LLM-assisted coding generalize better than an explicit rule-based classifier to new synthetic responses, and what errors and human-review needs remain?

## Coding and evaluation workflow

The workflow uses six response-type categories: `entity`, `named_source`, `platform_or_topic`, `generic_nonentity`, `junk`, and `mixed_or_needs_review`. Named people and sources may also receive canonical identities; nonresponses receive subtypes; uncertain identifications are tracked rather than forced. Definitions and edge cases are documented in [the coding protocol](docs/coding_protocol.md).

1. **Prepare mentions:** Normalize synthetic text and split multi-mention responses, preserving respondent and mention identifiers.
2. **Create reviewed references:** Use AI-proposed labels followed by researcher review. These are *not* independently human-only annotations.
3. **Develop the rule-based baseline:** Apply ordered classification rules and an exact-match alias table; validate with automated tests.
4. **Evaluate frozen rules:** Keep the v2 classifier unchanged on a new, intentionally challenging synthetic holdout set; evaluate segmentation separately from classification.
5. **Develop the LLM workflow:** Generate versioned prompts, request structured JSON classifications from Gemini, validate responses, and preserve attempts and model metadata. After a first development run, make one documented prompt revision and freeze v2 before scoring the holdout.
6. **Compare the workflows:** Score the same correctly segmented holdout mentions against the same reviewed reference labels.

## Main findings

The synthetic holdout contains **100 respondent answers**. The shared preparation stage exactly segmented **96/100 respondents**; four splitting errors were documented separately. The researcher-corrected reference has **109 mentions**, of which **105** belong to correctly segmented respondent answers and are used for the *conditional classification* comparison.

| Holdout measure | Frozen rule-based v2 | Gemini prompt v2 |
| --- | ---: | ---: |
| Correct categories | 27/105 | **101/105** |
| Category accuracy | 25.7% | **96.2%** |
| Macro F1, five reference-supported categories | 0.214 | **0.971** |
| Canonical-name coverage among 47 resolvable references | 0/47 | **46/47** |
| Strict canonical-name agreement | 0/47 | **45/47** |

The rule-based model attained **114/114 category agreement** after development-stage rule changes, but its holdout performance was much lower. Gemini prompt v2 attained **113/114** category agreement on development examples and **101/105** on the holdout. Its holdout errors included ambiguous outlet names, creator/channel distinctions, and an over-specific program identification. It flagged **5/5 of its own unresolved predictions** for review; this is *not* a measure of recall for all cases requiring human review.

**Interpretation:** Gemini performed substantially better on this constructed challenge set, but the results do not estimate accuracy on representative real-world survey responses. The holdout was designed with knowledge of earlier rule weaknesses; reference labels were AI-proposed and researcher-reviewed; and Gemini had access to the full original response as context while the rule-based classifier operated principally on prepared mentions. This is a **workflow comparison**, not an identical-input model-architecture experiment. The LLM did not independently perform segmentation.

The original rule-based evaluation script reported macro F1 of **0.268** under an undefined-class omission convention. The **0.214** figure above uses a consistent five-reference-class comparison, assigning zero to the missing class's F1. See the detailed evaluation documents for both conventions and limitations.

## Repository guide

| Location | Contents |
| --- | --- |
| `R/` | Reusable text-cleaning, classification, standardization, LLM prompt, and JSON-validation functions |
| `scripts/01_*.R` through `scripts/06_*.R` | Rule-based workflow, reference checks, and frozen holdout evaluation |
| `scripts/07_*.R` through `scripts/14_*.R` | Gemini development, revised-prompt inference, parsing, and evaluation |
| `data/` | Synthetic examples, alias data, reviewed reference labels, and frozen/corrected holdout data |
| `tests/` | Preparation, classification, standardization, and LLM-schema checks |
| `docs/` | Coding protocol, rule-based evaluations, LLM protocol, and full LLM evaluation |
| `results/` | Selected archived outputs, if included in the public repository |
| `output/` | Locally generated files; generally excluded from version control |

**Detailed reading:** [Rule-based development evaluation](docs/development_evaluation.md) · [Rule-based holdout evaluation](docs/holdout_evaluation.md) · [LLM protocol](docs/llm_protocol.md) · [LLM development and holdout evaluation](docs/llm_evaluation.md)

## Reproducing the analysis

Run R scripts from the repository root, with the required packages installed. The rule-based workflow and evaluation do not require a hosted model:

```r
source("scripts/01_prepare_data.R")
source("scripts/02_classify_responses.R")
source("scripts/03_standardize_entities.R")
source("scripts/04_evaluate_rule_based.R")
source("scripts/06_evaluate_holdout.R")
```

For Gemini v2, scripts `11`–`14` build prompts, call the API, parse outputs, and score predictions. **Generating new predictions requires a Gemini API key** stored locally as `GEMINI_API_KEY`; do not put the key in source code or GitHub. Evaluation from saved parsed predictions does not require a new API call:

```r
source("scripts/14_evaluate_gemini_v2.R")
evaluate_gemini_v2("development")
evaluate_gemini_v2("holdout")
```

The scoring commands above require the expected parsed-prediction CSVs at the paths used by the scripts. If those files are not committed, they must first be produced locally from the stored inference history or provided as archived results. Hosted model availability and outputs may vary over time, so preserve the model identifier, prompt version, settings, and scored predictions when sharing a reproducible benchmark.

## Scope and limitations

This is a **methodological portfolio demonstration**, not a release of substantive survey findings or an organizational endorsement. The synthetic data intentionally emphasize difficult cases and cannot support population-level performance claims. Any use with actual respondent text would require appropriate confidentiality, data-sharing, and organizational review. The project treats human review and transparent disagreement analysis as parts of automated coding, rather than assuming every returned label is definitive.
