# LLM-assisted response classification — protocol v0.1

## Objective
Compare a frozen LLM classification procedure with frozen rule-based v2 on the same prepared mentions. Evaluate response type and canonical-name resolution separately. Do not edit the holdout references, change the segmentation denominator, or tune the prompt after looking at holdout performance.

## Input
Each classification request includes `RESPID`, `mention_number`, `Q22` (prepared mention), and `Q22_original` (context). Do not include reference labels, rule-based predictions, or other respondents' answers. The instructions below are specified before any holdout predictions are generated. A development smoke test uses `data/reference/reference_coding_workbook.csv`, not holdout data.

## Output schema
A JSON object with exactly these fields:
- `response_type`: one of `entity`, `named_source`, `platform_or_topic`, `generic_nonentity`, `junk`, `mixed_or_needs_review`.
- `entity_clean`: string only when the canonical person/source is reliably established; otherwise `null`.
- `resolution_status`: one of `resolved`, `unresolved`, `not_applicable`.
- `nonresponse_subtype`: one of `does_not_follow`, `cannot_recall`, `no_specific_name`, `refusal`, `unusable`, `other_nonresponse`, or `null`.
- `review_flag`: boolean.
- `review_reason`: short string or `null`.

## Rules
1. `entity`: named/identified individual; a first name can still indicate a person while remaining unresolved.
2. `named_source`: specifically named publisher, outlet, show, podcast, or channel. Do not automatically collapse a named program into its host.
3. `platform_or_topic`: generic platform, content topic, genre, type of creator or format, with no particular person/source identified; sports league names used generically belong here.
4. `generic_nonentity`: vague answer with no identifiable creator, source, platform, or topic.
5. `junk`: explicit nonresponse or unusable answer. Differentiate `cannot_recall`, `does_not_follow`, `no_specific_name`, etc. cautiously.
6. `mixed_or_needs_review`: insufficient information to choose category from text/context.
7. Never invent a canonical name. For an unresolved person such as 'a creator named Alex', use `entity`, null `entity_clean`, and `unresolved`.
8. A title mentioning a host may identify a source rather than the individual. Use the wording and original-response context; flag genuine ambiguity.
9. ESPN is `named_source`, while unqualified NBA and NFL are `platform_or_topic`.
10. Do not add or merge mentions; score only prepared mentions supplied to this stage. Segmentation is evaluated separately.

## Freeze and reproducibility
Before scoring holdout, record provider, model/version identifier, date, prompt file hash, parameter settings (including temperature), structured-output method, request IDs where available, and any retries/invalid outputs. Avoid sending genuine confidential respondent text to an external service without explicit authorization. Synthetic examples only in this public demonstration.

## Evaluation cautions
The holdout challenge set was authored after examining rule-based weaknesses and researcher labels were initially AI-proposed. It is a challenge-set comparison, not a representative real-world performance estimate. A fair comparison should evaluate both classifiers on the same 105 correctly segmented mentions; report segmentation errors separately. Mark failed or invalid LLM outputs explicitly rather than silently dropping them.
