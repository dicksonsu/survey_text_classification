# Open-Ended Survey Response Classification

A reproducible R-based demonstration of methods for cleaning, splitting, classifying, and standardizing open-ended survey text. A planned extension will compare a rule-based workflow with LLM-assisted coding using an independently human-reviewed reference sample.

> **Data notice:** The included CSV is entirely synthetic. It contains invented response records, not real survey microdata. Frequencies and demographic variables in the example have no substantive interpretation.

## Research questions

1. How effectively can transparent rules identify named creators and media sources versus platforms, topics, nonresponses, and ambiguous text?
2. How should misspellings, alternate names, and multi-mention answers be standardized while retaining traceability?
3. Does LLM-assisted coding improve agreement with independently reviewed labels relative to the rule-based baseline, and where does it introduce errors?

## Synthetic dataset

`data/synthetic_q22.csv` has 100 **invented** records with columns matching the original input structure:

| Column | Description |
|---|---|
| `RESPID` | Artificial identifier (`SYN0001`, etc.); no real IDs |
| `Q22` | Fictional open-text response; may contain several mentions or be empty |
| `AGE` | Fabricated integer for interface compatibility only |
| `GENDER` | Fabricated numeric category for interface compatibility only |

The examples intentionally include clear names, multiple mentions, misspellings, generic topics, named media outlets, explicit nonresponses, ambiguous text, and blanks. They are **test fixtures**, not a representative simulated sample.

## Proposed workflow

| Stage | Location | Purpose |
|---|---|---|
| Preparation | `scripts/01_prepare_data.R` | Read approved input, normalize punctuation, split multiple mentions |
| Initial coding | `scripts/02_classify_responses.R` | Use documented rules to classify mention types |
| Entity normalization | `scripts/03_standardize_entities.R` | Map variants to standard names; flag uncertain matches |
| Validation | `tests/` and `docs/coding_protocol.md` | Add automated edge-case tests and a separate human-reviewed validation set |
| LLM prototype | `llm/` | Apply a versioned prompt and record outputs using only permitted data |
| Comparison | `results/` | Compare classification performance, disagreement patterns, and review requirements |

Reusable functions belong in `R/`; documentation and decision logs in `docs/`.

### Initial response-type labels

The original analysis uses the following labels; operational definitions will be refined and documented in `docs/coding_protocol.md`:

- `entity`: identifiable person or creator.
- `named_source`: identifiable branded outlet, show, or other named media source.
- `platform_or_topic`: platform, format, or broad content topic.
- `generic_nonentity`: vague reply without a specific identifiable entity.
- `junk`: nonresponse, explicit non-following, or unusable placeholder.
- `mixed_or_needs_review`: ambiguous or mixed reply that needs inspection.

These are **response-type** categories, not the same as later grouping named entities into `news_media`, `influencer`, or `celebrity`.

## Current status and reproduction

**Setup stage.** The original R code has not yet been refactored into the portable scripts listed above. Once implemented and tested, this section will include package versions, the exact run order, and output checks. To inspect the synthetic data in R:

```r
library(readr)
responses <- read_csv("data/synthetic_q22.csv", show_col_types = FALSE)
glimpse(responses)
```

The original research process combined rule-based text handling, manual corrections, and an additional AI-assisted entity-category worklist. Its output is **not** an independently human-reviewed ground truth. The comparison will use a separately reviewed reference sample and will disclose how it was produced.

## Evaluation standards

- Preserve record identifiers through mention splitting; verify row counts and duplicate joins.
- Keep rule outputs separate from human-reference labels.
- Evaluate precision, recall, and confusion by category, not just aggregate accuracy.
- Examine ambiguous predictions and false entity matches.
- Record prompts, model versions, settings, and human corrections for LLM experiments.
- Do not draw external-validity conclusions from synthetic data alone.

## Privacy and publication

No original survey responses, restricted-use datasets, respondent identifiers, API keys, or private organization file paths should be committed here. Real-data use requires appropriate permission and disclosure review. Local data and secrets should be excluded using `.gitignore`.

## Branch and review workflow

`main` holds reviewed work. Planned feature branches, each eventually merged through a pull request:

1. `feature/rule-based-pipeline`: refactor and test the R baseline.
2. `feature/validation-tests`: create reference labels and test edge cases.
3. `feature/llm-classification`: build an LLM-assisted prototype.
4. `feature/model-evaluation`: compare results and document tradeoffs.

## Scope

This is a methodological demonstration motivated by applied survey research. All public example records are fictional and do not constitute released study data or organizational endorsement.
