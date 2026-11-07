# Gemini prompt v2: controlled development revision

Version: `gemini_prompt_v2_2026-11-07`. Model: `gemini-3.5-flash-lite` as configured in the local runner. Dataset: synthetic survey text only.

## Frozen v1 development baseline (114 mentions)
- Category accuracy 109/114 (95.6%); reference-supported macro F1 0.832.
- Canonical exact string agreement 62/65, with three name-variant differences pending formal alias adjudication.
- Two unresolved identities, neither flagged for review.

## Three intentional modifications
1. Reinforce named specific outlets vs generic platforms/topics, and vague general descriptions vs nonresponses, with development-only examples.
2. Clarify junk subtypes: cannot recall vs does not follow vs no specific name vs unusable.
3. Require `review_flag=true` and a reason when `resolution_status=unresolved`.

The classification categories, six-key output structure, model identifier, generation settings, and finalized reference labels are unchanged. Do not use holdout examples or holdout scoring results to edit prompt v2. The holdout had been inspected during reference preparation, so this remains a synthetic challenge comparison, not a blind external evaluation.

## Gemini v2 development configuration
- Prompt: Gemini v2, with the three documented revisions
- Model: gemini-3.5-flash-lite
- Temperature: unchanged from the development run
- Response format: structured JSON
- Inputs: prepared mention plus original respondent response
- Reference dataset: finalized, unchanged
- No further prompt adjustments based on development or holdout results

## Important score interpretation
- The rule-v2 holdout classifier scored 27/105 correct conditional on the 96 correctly segmented responses.
- This LLM test uses the same 105 matched mentions; its inputs additionally include the original respondent response as context, making it a **workflow comparison**, not a perfectly context-matched algorithm-only test.
- Report strict canonical string match separately from human-adjudicated identity equivalence. Do not change predictions after evaluation.
- Preserve old prompt-v1 outputs and rule-v2 data untouched. Avoid committing API credentials or unapproved private respondent data.
