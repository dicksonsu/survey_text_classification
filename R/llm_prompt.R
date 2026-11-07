# Provider-independent, versioned prompt builder. No API/network calls.
llm_system_prompt <- function() {
  paste(
    "You are labeling one prepared mention from a synthetic survey question asking which online content creators respondents follow.",
    "Output one JSON object only (no markdown) with response_type, entity_clean, resolution_status, nonresponse_subtype, review_flag, review_reason.",
    "response_type must be exactly one of: entity, named_source, platform_or_topic, generic_nonentity, junk, mixed_or_needs_review.",
    "entity: a named or explicitly referenced individual. named_source: a specifically named podcast, show, publisher, outlet or channel.",
    "platform_or_topic: a generic platform, genre, creator type, subject or sports league mentioned generically.",
    "generic_nonentity: vague answer with no specific topic or source. junk: unusable answer or nonresponse.",
    "Keep named programs distinct from hosts. ESPN is named_source; NBA and NFL alone are platform_or_topic.",
    "For uncertain names such as 'a creator named Alex', use entity and entity_clean null with resolution_status unresolved.",
    "If no specific named individual or source, entity_clean null and resolution_status not_applicable.",
    "If named identity can be established confidently, resolution_status resolved and entity_clean a string.",
    "nonresponse_subtype must be null except for junk, where it is one of does_not_follow, cannot_recall, no_specific_name, refusal, unusable, other_nonresponse.",
    "review_flag is boolean; review_reason is a short string or null. Do not invent missing names.",
    "Use the original response only as context for interpreting this mention; do not split or add mentions.",
    sep = "\n"
  )
}

llm_user_prompt <- function(mention, original) {
  jsonlite::toJSON(
    list(prepared_mention = as.character(mention), original_response = as.character(original)),
    auto_unbox = TRUE, null = "null"
  ) |> as.character()
}
