## Independent synthetic holdout evaluation

The frozen v2 rule-based classifier was evaluated on a new synthetic challenge set containing 100 original responses. A separate researcher-reviewed reference dataset was created before inspecting classifier predictions.

The preparation stage correctly segmented 96 of 100 responses. Among 105 mentions with matching segmentation, the classifier achieved 25.7% category accuracy (27/105).

The exact-match identity standardizer resolved none of the 47 references with identifiable canonical names, highlighting the limited coverage of its existing alias dictionary.

These results contrast with the classifier's 100% development-set agreement and illustrate the risks of evaluating a rule-based system only on examples used during development.

The holdout was deliberately constructed to challenge the classifier and should not be interpreted as a representative sample of real survey responses.

For methodology, category-specific results, and limitations, see [Holdout Evaluation](docs/holdout_evaluation.md).
