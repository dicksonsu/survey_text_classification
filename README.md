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
source("scripts
