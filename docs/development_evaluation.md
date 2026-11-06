# Rule-based classification: development evaluation

## Scope and provenance

All records are **synthetic**, and the reference labels were initially AI-proposed and then reviewed and adjudicated by a researcher. The 114 prepared mentions come from 100 synthetic respondent records. This is a **development set**: its examples and errors informed rule changes. Do not report these metrics as independent test accuracy or generalization estimates.

| Metric | Baseline v1 | Revised v2 |
|---|---:|---:|
| Number of development mentions | 114 | 114 |
| Correct response categories | 97 | 114 |
| Response-type accuracy | 85.1% | 100.0% |
| Macro F1, reference-present categories | 0.801 | 1.000 |
| Canonical name agreement (resolved reference names) | Not captured in this summary | 65 / 65 (100%) |
| Unresolved person mentions | Not captured in this summary | 2 / 2 retained as unresolved |

Metrics are from the researcher's successful local RStudio evaluations. The current version was revised after inspecting baseline disagreements, including distinctions between media programs and hosts, sports leagues and media publishers, and nonresponse text. It is **not a blind holdout evaluation**.

## Evaluation procedure

From the repository root, run:

```r
source("scripts/01_prepare_data.R")
source("scripts/02_classify_responses.R")
source("scripts/03_standardize_entities.R")
source("tests/test_data_preparation.R")
source("tests/test_classification.R")
source("tests/test_entity_standardization.R")
source("tests/test_rule_revision_v2.R")
source("scripts/04_evaluate_rule_based.R")
```

Note: source the tests after pipeline scripts only if each test is known not to overwrite shared objects. The evaluation script reads `output/q22_classified.csv`, `output/q22_standardized.csv`, and `data/reference/reference_coding_workbook.csv` and checks that mention keys and text match exactly.

## Interpretation

The increase to 100% reflects fitting and adjudicating a **seen** development set. It supports internal consistency, not a performance guarantee. The next phase freezes the v2 implementation, labels fresh synthetic source responses **before inspecting predictions**, and scores the frozen classifier without revising it on the same holdout.

Further safeguards: avoid false canonical identities, treat unresolved people separately from no-entity responses, and analyze splitting errors at the original-response level.
