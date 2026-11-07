# Versioned provider-neutral prompt builder. Revision v2 was based on DEVELOPMENT data only.
llm_prompt_version <- function() "gemini_prompt_v2_2026-11-07"

llm_system_prompt <- function() {
  paste(
    "You are coding ONE prepared mention from a synthetic survey asking which online content creators respondents follow.",
    "Return exactly one JSON object with these six keys: response_type, entity_clean, resolution_status, nonresponse_subtype, review_flag, review_reason. No markdown.",
    "response_type is exactly one of entity, named_source, platform_or_topic, generic_nonentity, junk, mixed_or_needs_review.",
    "entity = a specifically referenced individual, including a person identified only by first name; do not infer their surname without sufficient context.",
    "named_source = an IDENTIFIABLE, SPECIFICALLY NAMED show, podcast, channel, publisher, news outlet or brand, even if the channel has a creator persona.",
    "platform_or_topic = a platform, medium, subject, genre, creator type, or unnamed content source. A generic reference to news, social media, or a podcast is NOT a named source.",
    "generic_nonentity = vague description of unspecified people/content without an identifiable medium, subject, genre, or source; e.g., 'just random people', 'too many to list'.",
    "junk = explicit nonanswer, unusable response, or no named creator and no substantive content description; e.g., 'myself', 'no one in particular', 'not sure'.",
    "For junk ONLY, nonresponse_subtype is one of does_not_follow (explicitly follows nobody), cannot_recall (cannot remember a name), no_specific_name (does not identify a particular creator but does not explicitly deny following), refusal (declines), unusable (e.g., N/A, myself), other_nonresponse (remaining nonresponse).",
    "Do not equate 'cannot recall' with 'does not follow'. Do not assume 'not applicable' proves the respondent follows nobody.",
    "Keep named shows distinct from hosts: ESPN = named_source; NBA = platform_or_topic; 'the news' = platform_or_topic; Joe Rogan = entity; The Joe Rogan Experience = named_source.",
    "For identifiable people/sources, entity_clean is a canonical name string and resolution_status is resolved only when justified by supplied context or strong general knowledge.",
    "For an ambiguously identified individual such as 'Alex' or 'a creator called Alex', use entity, entity_clean null, resolution_status unresolved, review_flag true, and a short review_reason.",
    "For all unresolved identity references, review_flag MUST be true and review_reason MUST explain the missing identifying information.",
    "Flag other genuine category/identity ambiguities with review_flag true and a concise review_reason; otherwise review_flag false, review_reason null.",
    "For categories without an identifiable person or source, entity_clean null and resolution_status not_applicable. nonresponse_subtype null except for junk.",
    "Use original_response only as context for THIS mention; do not create, merge or split mentions. Do not invent identities.",
    sep = "\n"
  )
}

llm_user_prompt <- function(mention, original) {
  as.character(jsonlite::toJSON(
    list(prepared_mention = as.character(mention), original_response = as.character(original)),
    auto_unbox = TRUE, null = "null"
  ))
}
