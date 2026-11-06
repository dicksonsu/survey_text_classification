# Q22 reference coding protocol — synthetic development dataset (v0.8)

## Status and purpose
This protocol applies to **114 prepared mentions** in the corrected, wholly synthetic Q22 development sample. The researcher has reviewed and accepted all **114/114 reference labels**. Labels were initially **AI-proposed and subsequently researcher-reviewed**; they are **not independently human-coded ground truth**, and the development-set results cannot support generalizable claims of model accuracy. The reference labels must remain fixed when diagnosing errors in the rule-based classifier; any later changes require an explicit versioned adjudication record.

## Unit and fields
- One row per prepared mention; unique key is `(RESPID, mention_number)`.
- `Q22` is the prepared text; `Q22_original` preserves respondent context. Refer back to the original before making difficult determinations.
- `reference_type`: one of `entity`, `named_source`, `platform_or_topic`, `generic_nonentity`, `junk`, `mixed_or_needs_review`. Temporarily use `needs_adjudication` if the coding decision itself remains unresolved; this is a workflow marker, not a seventh substantive class.
- `reference_entity`: canonical person, creator, program, or organization for `entity`/`named_source`. Otherwise blank; do not invent identities for vague names.
- `nonresponse_subtype`: populate **only when `reference_type = junk`**; otherwise leave blank.
- `review_notes`: short explanation for difficult decisions, transformations, or uncertainties.
- `review_status`: `proposed_not_yet_adjudicated`, `human_verified`, `needs_adjudication`, or `not_reviewed`. Use `human_verified` when the researcher has reviewed and accepted a record, including explicit retrospective confirmation of a batch. Maintain the provenance note that initial reference labels were AI-proposed.

## Primary categories
| `reference_type` | Definition | Examples |
|---|---|---|
| `entity` | Identifiable person or creator identity | `joe rogen` -> Joe Rogan; `andrew huberman` -> Andrew Huberman |
| `named_source` | Identifiable titled program, creator brand, media outlet, or organization | `fresh & fit` -> Fresh and Fit; `the daily` -> The Daily; `espn` -> ESPN |
| `platform_or_topic` | Platform, genre, content type, format, or generic creator type without specific identity | `youtube`, `mostly fitness videos`, `a sports podcast` |
| `generic_nonentity` | Vague quantity or unspecified collection with no clear genre/platform/identity | `a lot of different ones`, `too many to list` |
| `junk` | Explicit not-following, non-recall, no specific names, refusal, or meaningless response | `i do not follow anyone`, `i cannot remember names` |
| `mixed_or_needs_review` | A mention whose **response type** is genuinely ambiguous after examining context | Ambiguous mixed-format or unclear text that cannot be assigned to another category |

## Nonresponse subtype (`junk` only)
| `nonresponse_subtype` | Use when | Example |
|---|---|---|
| `does_not_follow` | Explicit statement of not following or consuming creators | `i do not follow anyone` |
| `cannot_recall` | Indicates following or knowing creators but cannot recall names, or simply cannot remember | `i cannot remember names` |
| `no_specific_name` | No particular identifiable source supplied without claiming zero following | `no one in particular` |
| `refusal` | Declines to answer rather than saying none or cannot remember | `prefer not to say` |
| `unusable` | Uninterpretable placeholder or meaningless answer | `asdf` |
| `other_nonresponse` | Clear nonresponse not fitting other subtypes, with an explanation in notes | `no comment` if intent cannot be established |

If context cannot distinguish subtypes, use `other_nonresponse` and document uncertainty. **Missing Q22 values produce no prepared mention rows** and are tracked separately; do not manufacture `junk` records for them. A lack of a named creator is not by itself evidence of non-following.

## Decision hierarchy and examples
1. Inspect the original response to determine whether the prepared mention still has enough context to code. Correct splitting problems at the preparation stage; do not quietly create or delete rows inside the reference sheet.
2. Use `entity` for people; use `named_source` for explicitly named shows, organizations, and branded programs, including **Fresh & Fit**. A person-centric downstream crosswalk may relate programs to hosts without overwriting their canonical source identities.
3. Use `platform_or_topic` for meaningful descriptive content without a named source (e.g., `a podcast about science`, `researchers on youtube`); use `generic_nonentity` for uninformative quantities (e.g., `a few`).
4. For clear explicit no-following or no-name answers, use `junk` **and** the appropriate subtype. `no one in particular` -> `no_specific_name`, not `does_not_follow`.
5. Preserve spelling in `Q22`; put a documented canonical name in `reference_entity`. Do not infer that abbreviations and shows always refer to an individual person (e.g., `JRE` is a named program, even if a separate person-centered analysis maps it to Joe Rogan).
6. An explicitly named person with an unresolved identity (e.g., `Alex`) is `entity` with a **blank `reference_entity`** and a note explaining unresolved identity; do not guess a canonical person. Reserve `mixed_or_needs_review` for ambiguity about **response type**, not simply identity resolution.
7. Avoid viewing the rule-based classifier's `response_type` or `entity_clean` while assigning reference codes, to reduce anchoring.

## Human coding workflow for remaining mentions
1. Work from `reference_remaining95_template.csv`, which has blank reference fields and `review_status = not_reviewed`.
2. For each row, read `Q22` and `Q22_original`, assign `reference_type`, fill `reference_entity` only when justified, and fill `nonresponse_subtype` only for `junk`.
3. Record explanatory notes on non-obvious decisions; mark a row `human_verified` when personally checked, or `needs_adjudication` if uncertain.
4. Review uncertain cases together, update the protocol if necessary, and only then use reference labels for development-set diagnostics.
5. Combine the confirmed labels with the proposed first 20 after their review; validate uniqueness of `(RESPID, mention_number)` and allowed label/subtype values.
6. Freeze this protocol and generate a **new, untouched** synthetic holdout set for a comparison of rule-based vs LLM-assisted coding. Do not tune either method to the holdout labels.

## Limitations and privacy
These examples are entirely synthetic and purposefully cover hard cases; the distribution is not representative. Separately assess splitting, class prediction, and canonical entity resolution; labels on prepared mentions alone cannot assess whether original-response splitting was correct. Do not publish real open-ended responses or linked demographic/respondent information without explicit organizational permission.


## Adjudication update: mentions 21–40 (November 2026)

- `none`: `junk`, subtype `does_not_follow`. This is the researcher's chosen contextual interpretation, not direct verification of behavior.
- `not sure`: `junk`, subtype `cannot_recall`. This is an operational coding choice; the response alone cannot establish that the respondent follows creators but forgot their names.
- `a few finance people`: `platform_or_topic` because finance is an identifiable content subject, even though no people are named. In general, topic-bearing vague references belong here; vague quantities with no discernible topic remain `generic_nonentity`.
- `jre` and `the joe rogan experience`: `named_source`, canonical **The Joe Rogan Experience**, kept distinct from the host **Joe Rogan**.

These decisions were discussed with the researcher. Other proposed batch labels remain pending record-by-record review. Reference coding is AI-proposed and researcher-adjudicated, not an independent human-only gold standard.


## Adjudication update: mentions 41–60 (November 2026)

- **`n/a` is one original nonresponse**, not two mentions. Protect it before `/` is used to split multiple mentions. Its prepared form is `n/a`; code `reference_type = junk`, `nonresponse_subtype = unusable`. The prior `n` and `a` rows were an artifact and must not be counted as two responses. This changes the synthetic prepared dataset from 115 to **114 mentions**, provided nothing else changes.
- **`idk`** is `junk` with subtype **`cannot_recall`**, a contextual coding convention (not proof of the respondent's actual following behavior).
- **Repeated mentions of the same canonical source by one respondent** remain separate observations in the mention-level dataset; count unique `(RESPID, reference_entity)` when calculating respondent-level indicators. Preserve mentions from the original text and document the deduplication as a distinct downstream analytical operation.
- Preserve named media sources (`cnn`, `bbc news`, `npr`, `the daily`) as `named_source`, not people. The classifications for other records in this batch are AI-proposed and remain pending individual human verification.
- After any preparation change, regenerate the prepared, classified, and standardized output files, **rebuild the reference worksheet from the new prepared data**, rejoin previous reviewed decisions by `(RESPID, mention_number)` only after verifying that keys still refer to identical `Q22` and `Q22_original`, and rerun the validation tests. Do not rely on row-number positions after a split correction.
- This 114-row worksheet is the **development** sample, not a held-out performance evaluation dataset.


## Earlier proposals for mentions 61–80 (historical, superseded by adjudication below)

- The researcher confirmed that all classifications in revised prepared-mention positions 1–60 were reviewed and accepted. These rows have `review_status = human_verified`, with provenance recorded as AI-proposed, researcher-reviewed.
- Proposed (not yet confirmed): `nba` and `nfl` -> `named_source` when denoting the named organizations/leagues; `nba highlights` -> `platform_or_topic` because the publisher is not identified. The researcher should confirm whether the organizational definition encompasses sports leagues.
- Proposed (not yet confirmed): `veritasium` and `kurzgesagt` -> `named_source` as branded channels, rather than individual personalities. Clarify person-versus-brand treatment consistently.
- Proposed (not yet confirmed): `i do not know` -> `junk` / `cannot_recall`, and `nobody` (originally `I follow nobody`) -> `junk` / `does_not_follow`. These are contextual interpretations.
- A prior codebook instruction said `no one in particular` should be `no_specific_name`; that remains distinct from explicit `does_not_follow`.
- These 114 mentions remain a development dataset, not a held-out model evaluation set. Do not use model predictions to modify reference labels.


## Adjudication update: mentions 61–80 (researcher confirmed)
- `NBA`, `NFL`, and `NBA highlights` -> `platform_or_topic`; preserve raw league mentions for later subject-matter analysis. An unqualified league mention is treated as a sports interest rather than as a specific publisher. A clearly titled league-associated show may still be `named_source`.
- `ESPN` remains `named_source` because it identifies a distinct media publisher, not merely a sports subject. `SportsCenter` likewise would be `named_source` when clearly identified.
- `Veritasium`, `Kurzgesagt` remain `named_source` as branded channels. The researcher approved the entire batch 61–80 as reviewed.
- The distinction between `reference_type` (what was identified) and a future `content_topic` dimension (what the content is about) is deliberate. Do not collapse ESPN into sports topic simply because its content domain is sports.

## Proposed batch: mentions 81–100
- `The Daily Show` and `The Daily` are different named programs, and must not be standardized together. `Call Her Daddy` and `The Pat McAfee Show` are `named_source`, separately from their named hosts.
- `reddit`, `twitch`, and generic `podcast shows` -> `platform_or_topic` using existing platform/format convention.
- `myself` (record 90) remains `mixed_or_needs_review` pending explicit researcher adjudication, because this could be a joking unusable response or a meaningful self-reference; do not invent a person.
- `good` (record 91) proposed `junk` / `unusable` as noninformative. `a few on social media` proposed `platform_or_topic` because of platform context, consistent with other generic-platform mentions.
- All proposed classifications need researcher review. The batch was prepared without consulting the rule-based classifier's outputs.


## Adjudication update: mentions 81–100 (researcher confirmed)
- Researcher reviewed and accepted all 20 proposed classifications.
- `myself` (90) and `good` (91) -> `junk`, subtype `unusable`; in this dataset neither identifies a usable creator or content topic. The contextual interpretation is not a universal rule that self-reference always means junk.
- `a few on social media` (92) -> `platform_or_topic`; a general platform class is identified even without specific creators.
- Named programs remain distinct from their hosts: `The Daily` vs `The Daily Show`; `Pat McAfee` vs `The Pat McAfee Show`; `Call Her Daddy` is a named show.

## Final proposed batch: mentions 101–114
- Typographical/formatting variants `KAI cenat`, `Mr.Beast`, `J0e Rogan` retain `entity` type with canonical `Kai Cenat`, `MrBeast`, and `Joe Rogan`.
- `dr mike`/`doctor mike` -> `entity`, canonical `Doctor Mike` following the established alias dictionary. If ambiguity with other people named Doctor Mike arises in actual data, reassess based on context rather than assuming identity.
- `researchers on youtube` and `some basketball players` -> `platform_or_topic`; a content domain or creator type is discernible, but no specific identifiable creator.
- `ESPN`, `NPR`, `BBC News`, `The Daily` -> `named_source`; retain media publisher / titled show distinction.
- `I do not follow anybody` -> `junk` / `does_not_follow`.
- `a creator called Alex` and `Alex` have insufficient identifying context. Proposed `mixed_or_needs_review`, no canonical person, and `needs_adjudication` status. Alternative worth discussing: allow `entity` with a blank `reference_entity` for explicit but unresolved first-name-only person mentions. Any choice must be applied consistently, and should not invent a full identity.
- All 14 remain pending researcher review; none should be treated as `human_verified` on the basis of these proposals alone.


## Final researcher adjudication: mentions 101–114 (November 2026)
- Researcher reviewed and accepted all proposed labels for records 101–112.
- `a creator called Alex` (113) and `Alex` (114) are `entity` with **blank `reference_entity`**. The respondent named a person, but the source does not establish which person. The absence of canonical reference is **unresolved identity**, not failure to identify a person mention, and should be handled separately in evaluation.
- All records 1–114 have `review_status = human_verified`, with disclosure that initial labels were AI-proposed and reviewed by the researcher.
- Retain `named_source` for ESPN, NPR, BBC News, The Daily; `platform_or_topic` for NBA/NFL and generic creator or content descriptions. Preserve person/program distinctions.

## Evaluation policy (v0.8)
1. Run preparation, classification and standardization scripts on the corrected **114-mention** synthetic data. Join on unique `(RESPID, mention_number)`; verify prepared `Q22` text matches the reference and fail rather than silently scoring mismatched rows.
2. Report class accuracy, a confusion matrix, and per-class precision, recall and F1 with denominators. Use **macro-F1** only for classes present in reference, and mark undefined precision or recall as `NA`, not zero.
3. For canonical name comparisons: assess exact match **among named-source or person reference rows with a resolved `reference_entity`**. Also report an **end-to-end** named-source-or-person metric requiring the predicted category and canonical name both to match. Exclude (and enumerate) the two Alex rows from resolved-name accuracy.
4. For Alex, separately track whether the classifier predicted `entity`; an algorithm's guessed proper name does not establish real-world resolution. The current fallback title-case of unmapped candidates (`Alex`) must not be mistaken for verified canonical identification.
5. Preserve `nonresponse_subtype` as a reference-only analytic dimension until the rule-based classifier is modified to predict it; do not score a variable the model does not produce.
6. These statistics are **in-sample development diagnostics**, not unbiased estimates of generalization. Create new held-out synthetic responses and lock their independent reference labels before comparing with an LLM-assisted system.
