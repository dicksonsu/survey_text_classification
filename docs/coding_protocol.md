# Preliminary Q22 coding protocol

The pipeline uses the original project's *rule-based* response categories. These are **predictions**, not independently human-reviewed reference labels.

- `junk`: explicit nonresponses or unusable placeholders.
- `mixed_or_needs_review`: uncertain or mixed statements flagged for review.
- `named_source`: named programs, outlets, or branded media sources.
- `platform_or_topic`: generic platforms, content genres, or formats.
- `generic_nonentity`: vague non-identifying responses.
- `entity`: default category for remaining mentions, **not proof of a valid person or creator**.

## Processing order
1. Lowercase and normalize punctuation.
2. Protect `fresh and fit`; turn delimiters into commas; repair specific multi-name strings inherited from the source script.
3. Split into mentions and retain `RESPID`, `mention_number`, and `Q22_original`.
4. Assign one predicted `response_type` to each mention.

## Known limitations to review
- The original classifier defaults to `entity` for unrecognized strings, causing false positives.
- Some `named_source` rules use broad patterns; terms such as `sports podcast` may trigger them.
- Replacing `and` with a comma can incorrectly split titles or phrases; only `fresh and fit` is protected in the baseline.
- Removing punctuation may alter brand names and non-English text.
- Completely blank Q22 responses have **zero mention rows** in the baseline, so missingness should be reported at the respondent level, not treated as an observed `junk` mention.
- This first iteration intentionally does not implement the original script's later candidate-name extraction, entity standardization, or survey-weighted analyses. Those will be added and checked separately.

## Data use
Public input is synthetic and not representative. Do not commit original survey response records or internal paths.
