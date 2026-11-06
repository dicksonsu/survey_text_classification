# Survey Text Classification

An R-based workflow for cleaning, classifying, and standardizing open-ended survey responses. The project demonstrates how rule-based text classification can be developed, tested, and evaluated against researcher-reviewed reference labels, with a planned extension to LLM-assisted classification.

The workflow is illustrated using **100 synthetic responses** modeled on an open-ended survey question asking respondents which content creators they follow. No confidential respondent-level survey data are included.

## Project workflow

The pipeline consists of four stages:

1. **Text preparation:** Normalize responses and separate multiple mentions while retaining original response text and respondent identifiers.
2. **Response classification:** Assign mentions to categories such as individual creators, named media sources, platforms/topics, and nonresponses.
3. **Entity standardization:** Resolve spelling variations and aliases to consistent canonical names while retaining unresolved identities for review.
4. **Validation and evaluation:** Run automated tests and compare classifications against a researcher-reviewed reference dataset.

The classification framework and adjudication procedures are documented in [the coding protocol](docs/coding_protocol.md).

## Repository structure

```text
R/          Core cleaning, classification, and standardization functions
data/       Synthetic input data, alias mappings, and reference labels
docs/       Coding protocol and methodological evaluation
scripts/    Reproducible pipeline and evaluation scripts
tests/      Automated validation and regression tests
```

## Getting started

The workflow requires R and the `dplyr`, `readr`, `stringr`, and `tidyr` packages.

Run the following commands from the repository's root directory:

```r
source("scripts/01_prepare_data.R")
source("scripts/02_classify_responses.R")
source("scripts/03_standardize_entities.R")
```

To run the automated tests:

```r
source("tests/test_data_preparation.R")
source("tests/test_classification.R")
source("tests/test_entity_standardization.R")
source("tests/test_rule_revision_v2.R")
```

To evaluate the classifier against the reviewed reference data:

```r
source("scripts/04_evaluate_rule_based.R")
```

Evaluation outputs are written to `output/evaluation/`, including accuracy metrics, confusion matrices, and record-level disagreements.

## Development evaluation

The initial rule-based classifier was evaluated against 114 prepared mentions from 100 synthetic respondents. Following an error analysis and revision of the classification rules, the results were:

| Metric | Baseline v1 | Revised v2 |
|---|---:|---:|
| Category accuracy | 85.1% | 100.0% |
| Macro F1 | 0.801 | 1.000 |

The revised classifier also achieved agreement on 65 of 65 resolvable canonical names, while retaining two unresolved person references without assigning unsupported identities.

**These are development-set results, not estimates of out-of-sample accuracy.** The reference labels were initially AI-proposed and subsequently researcher-reviewed, and the same synthetic examples informed classifier refinement.

For the evaluation design, results, error analysis, and limitations, see [Development Evaluation](docs/development_evaluation.md).

## Next steps

The next phase will evaluate the frozen rule-based classifier on a separate synthetic holdout dataset. A subsequent phase will compare rule-based and LLM-assisted classification using the same coding framework.

The goal is to assess classification accuracy, identify where each method performs well or poorly, and document reproducible procedures for reviewing uncertain responses.

## Data and reproducibility

All publicly included survey responses are synthetic. The repository is intended to demonstrate a reproducible analytical workflow rather than publish the underlying survey microdata.

The project separates response classification from entity resolution and retains the information necessary to review ambiguous or unresolved cases.
